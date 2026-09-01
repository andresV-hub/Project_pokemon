# Encuentros salvajes: la única vía para descubrir y capturar Pokémon nuevos.
#
# El estado del encuentro vive en `session[:encounter]`. Es efímero por diseño:
# cerrar la pestaña lo pierde, igual que en el juego, y no merece una tabla.
class EncountersController < ApplicationController

	before_action :require_party, only: %i[new create]
	before_action :require_encounter, only: %i[show attack catch flee]

	# Pantalla de exploración.
	def new
		@lead_pokemon = lead_pokemon
	end

	def create
		result = ::Encounters::Start.execute(trainer_pokemon: lead_pokemon)

		if result.error
			return redirect_to user_explore_path(user_id: current_user.id),
				alert: 'We could not reach the PokeAPI. Try again in a few seconds.', status: :see_other
		end

		session[:encounter] = result.value
		# Encontrarse una especie es lo que la registra en la Pokédex: ya no basta
		# con abrir su ficha.
		record_sighting(result.value['num_pokedex'])

		redirect_to user_encounter_path(user_id: current_user.id), status: :see_other
	end

	def show
		@state = session[:encounter]
		@wild = ::Pokeapi::FindPokemon.execute(id: @state['num_pokedex']).value
		@trainer_pokemon = lead_pokemon
	end

	def attack
		wild = ::Pokeapi::FindPokemon.execute(id: encounter_state['num_pokedex']).value
		result = ::Encounters::Attack.execute(state: encounter_state,
		                                     trainer_pokemon: lead_pokemon,
		                                     wild: wild)
		session[:encounter] = result.value
		finish_if_over

		redirect_to user_encounter_path(user_id: current_user.id), status: :see_other
	end

	def catch
		state = encounter_state
		if state['balls'].to_i <= 0
			return redirect_to user_encounter_path(user_id: current_user.id), status: :see_other
		end

		state['balls'] -= 1
		probability = ::Encounters::Rules.capture_probability(
			capture_rate: state['capture_rate'],
			current_hp: state['wild_hp'],
			max_hp: state['wild_max_hp']
		)

		if rand < probability
			store_captured(state)
			session.delete(:encounter)
			return redirect_to user_pokemon_index_path(user_id: current_user.id),
				notice: "Gotcha! #{state['name']} was caught and sent to your PC.", status: :see_other
		end

		state['log'] = ["Oh no! #{state['name']} broke free!"]
		state['log'] << "#{state['name']} ran away." if state['balls'].zero?
		state['over'] = 'out_of_balls' if state['balls'].zero?
		session[:encounter] = state
		finish_if_over

		redirect_to user_encounter_path(user_id: current_user.id), status: :see_other
	end

	def flee
		session.delete(:encounter)
		redirect_to user_explore_path(user_id: current_user.id),
			notice: 'You got away safely.', status: :see_other
	end

	private

	def encounter_state
		session[:encounter]
	end

	# El primero del equipo es quien combate. Sin equipo no hay encuentro.
	def lead_pokemon
		pokemon = current_user.pokemon.in_party.first
		pokemon && ::Pokemons::PokemonDecorator.decorate(pokemon)
	end

	def require_party
		return if current_user.pokemon.in_party.exists?

		redirect_to user_pokemon_index_path(user_id: current_user.id),
			alert: 'You need a Pokémon in your party before exploring.', status: :see_other
	end

	def require_encounter
		return if session[:encounter].present?

		redirect_to user_explore_path(user_id: current_user.id), status: :see_other
	end

	# El encuentro se cierra en el siguiente `show`: así el jugador llega a leer
	# el último mensaje antes de que desaparezca la escena.
	def finish_if_over
		return if session[:encounter].blank? || session[:encounter]['over'].blank?

		session[:encounter]['closing'] = true
	end

	def store_captured(state)
		wild = ::Pokeapi::FindPokemon.execute(id: state['num_pokedex']).value
		description = ::Pokeapi::FindDescription.execute(id: state['num_pokedex']).value
		return if wild.nil? || description.nil?

		::Pokemons::CreateUseCase.execute(pokemon: wild, user: current_user.id,
		                                  description: description, nickname: wild.name)
	end

	def record_sighting(num_pokedex)
		current_user.pokedex_sightings.find_or_create_by(num_pokedex: num_pokedex)
	rescue ActiveRecord::RecordNotUnique
		nil
	end

end
