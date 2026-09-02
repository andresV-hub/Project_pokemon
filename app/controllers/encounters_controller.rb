# Encuentros salvajes: la única vía para descubrir y capturar Pokémon nuevos.
#
# El estado del encuentro vive en `session[:encounter]`. Es efímero por diseño:
# cerrar la pestaña lo pierde, igual que en el juego, y no merece una tabla.
class EncountersController < ApplicationController

	before_action :require_party, only: %i[new create]
	before_action :require_encounter, only: %i[show attack catch item switch flee]

	# Pantalla de exploración: el mapa de zonas.
	def new
		@lead_pokemon = lead_pokemon
		@best_level = party_best_level
		@zones = ::Encounters::Zones.all
	end

	def create
		zone_key = params[:zone].presence || ::Encounters::Zones.default[:key]

		# Se comprueba en el servidor y no sólo escondiendo el botón: la zona llega
		# como parámetro y sin esto bastaría con escribirla a mano para plantarse en
		# la Cueva Celeste con un equipo de nivel 5.
		unless ::Encounters::Zones.unlocked?(zone_key, party_best_level)
			return redirect_to user_explore_path(user_id: current_user.id),
				alert: 'Your team is not strong enough for that place yet.', status: :see_other
		end

		result = ::Encounters::Start.execute(trainer_pokemon: lead_pokemon, zone_key: zone_key)

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

	# Combate contra entrenador: no se captura, se cobra.
	def create_trainer
		result = ::Encounters::StartTrainer.execute(trainer_pokemon: lead_pokemon,
		                                           party_size: current_user.pokemon.in_party.count)

		if result.error
			return redirect_to user_explore_path(user_id: current_user.id),
				alert: 'We could not reach the PokeAPI. Try again in a few seconds.', status: :see_other
		end

		session[:encounter] = result.value
		redirect_to user_encounter_path(user_id: current_user.id), status: :see_other
	end

	def show
		@state = session[:encounter]
		@wild = ::Pokeapi::FindPokemon.execute(id: @state['num_pokedex']).value
		@trainer_pokemon = lead_pokemon
	end

	def attack
		wild = ::Pokeapi::FindPokemon.execute(id: encounter_state['num_pokedex']).value
		result = ::Encounters::ResolveTurn.execute(state: encounter_state,
		                                          trainer_pokemon: lead_pokemon,
		                                          wild: wild,
		                                          move_index: params[:move].to_i)
		state = result.value

		# El daño se guarda aquí, en cuanto se recibe, y no al final del método: si
		# se guardara después, la derrota —que cura al equipo al recogerte— dejaría
		# escrito otra vez el daño que acababa de borrar.
		persist_damage(state)

		# Derribar a un rival da experiencia, sea salvaje o de entrenador: es lo
		# que hace que combatir sirva para algo aunque no captures nada.
		state = award_experience(state) if state['over'] == 'wild_fainted'

		# Contra un entrenador, derribar a uno no acaba el combate: sale el
		# siguiente, y sólo al agotar el equipo se cobra.
		if state['kind'] == 'trainer' && state['over'] == 'wild_fainted'
			state = ::Encounters::NextOpponent.execute(state: state, user: current_user).value
		end

		# Y si el que cae es el tuyo, entra el siguiente de tu equipo: por eso
		# tener seis huecos llenos importa.
		#
		# Vale igual contra un salvaje que contra un entrenador. El relevo se
		# escribió resolviendo los combates de entrenador, y se quedó atado a
		# ellos: contra un salvaje el combate terminaba al caer el primero, con
		# los otros cinco intactos en el equipo. Sólo se acaba cuando no queda
		# ninguno en pie, que es de lo que `NextOwnPokemon` ya se ocupa.
		if state['over'] == 'trainer_fainted'
			state = ::Encounters::NextOwnPokemon.execute(state: state, user: current_user).value
			# Los movimientos son los del que entra, y sólo si entra alguien: si
			# el equipo se agotó, el combate ha terminado y no hay turno que armar.
			if state['over'].blank?
				state = reload_own_moves(state)
			else
				# Se agotó el equipo: esto ya es la derrota, no un relevo más.
				state = lose_battle(state)
			end
		end

		session[:encounter] = state
		finish_if_over

		redirect_to user_encounter_path(user_id: current_user.id), status: :see_other
	end

	def catch
		state = encounter_state

		# En el juego lanzar una bola a un Pokémon ajeno no funciona, y aquí
		# además dejaría al entrenador sin equipo a mitad de combate.
		if state['kind'] == 'trainer'
			state['log'] = ["You can't catch another trainer's Pokémon!"]
			session[:encounter] = state
			return redirect_to user_encounter_path(user_id: current_user.id), status: :see_other
		end

		kind = params[:kind].presence || ::Shop::Catalog::STARTING_KIND
		spent = ::Shop::UseBall.execute(user: current_user, kind: kind)

		if spent.error == :out_of_stock
			state['log'] = ["You have no #{::Shop::Catalog.name(kind) || 'balls'} left!"]
			session[:encounter] = state
			return redirect_to user_encounter_path(user_id: current_user.id), status: :see_other
		end

		probability = ::Encounters::Rules.capture_probability(
			capture_rate: state['capture_rate'],
			current_hp: state['wild_hp'],
			max_hp: state['wild_max_hp'],
			multiplier: ::Shop::Catalog.multiplier(kind)
		)

		if rand < probability
			# Capturar también entrena, como en los juegos: si no, la opción que
			# el juego quiere premiar era la única que no daba nada a cambio de
			# gastarte una bola, y convenía debilitar al rival y rematarlo.
			gained = grant_experience(state)
			store_captured(state)
			session.delete(:encounter)
			return redirect_to user_pokemon_index_path(user_id: current_user.id),
				notice: ["Gotcha! #{state['name']} was caught and sent to your PC.", *gained].join(' '),
				status: :see_other
		end

		state['log'] = ["You threw a #{::Shop::Catalog.name(kind)}…", "Oh no! #{state['name']} broke free!"]
		session[:encounter] = state
		finish_if_over

		redirect_to user_encounter_path(user_id: current_user.id), status: :see_other
	end

	# Usar un objeto de curación. Gasta el turno, como en el juego: si curar fuese
	# gratis en tiempo, la decisión sería siempre «cúrate», y no habría decisión.
	def item
		state = encounter_state
		fighter = current_user.pokemon.find_by(id: state['trainer_pokemon_id'])

		result = ::Shop::UseItem.execute(user: current_user, kind: params[:kind], pokemon: fighter)

		if result.error
			state['log'] = [item_error_message(result.error)]
			session[:encounter] = state
			return redirect_to user_encounter_path(user_id: current_user.id), status: :see_other
		end

		state['trainer_hp'] = fighter.current_hp
		usado = ["You used a #{::Shop::Catalog.name(params[:kind])}!",
		         "#{fighter.nickname} recovered #{result.value} HP."]

		# El rival aprovecha el turno. Se resuelve con el mismo motor de siempre
		# pasándole un movimiento nulo por nuestra parte, para no duplicar aquí las
		# reglas de estado, precisión y daño.
		wild = ::Pokeapi::FindPokemon.execute(id: state['num_pokedex']).value
		state = ::Encounters::ResolveTurn.execute(state: state, trainer_pokemon: pokemon_in_field(state),
		                                          wild: wild, move_index: -1, skip_own: true).value

		# El motor reemplaza el registro con las líneas de *su* turno, así que lo
		# del objeto se antepone después: si no, curarse no aparecía por ningún
		# lado y sólo se veía el golpe del rival.
		state['log'] = usado + Array(state['log'])
		persist_damage(state)

		session[:encounter] = state
		finish_if_over
		redirect_to user_encounter_path(user_id: current_user.id), status: :see_other
	end

	# Cambiar de Pokémon a voluntad. Gasta el turno, como en el juego.
	def switch
		result = ::Encounters::SwitchPokemon.execute(state: encounter_state, user: current_user,
		                                            pokemon_id: params[:pokemon_id])

		if result.error
			state = encounter_state
			state['log'] = [switch_error_message(result.error)]
			session[:encounter] = state
			return redirect_to user_encounter_path(user_id: current_user.id), status: :see_other
		end

		state = reload_own_moves(result.value)
		entrada = state['log']

		# El rival aprovecha el turno, con el mismo motor de siempre: así el cambio
		# tiene el mismo coste que usar un objeto y las reglas de estado, precisión
		# y daño viven en un solo sitio.
		wild = ::Pokeapi::FindPokemon.execute(id: state['num_pokedex']).value
		state = ::Encounters::ResolveTurn.execute(state: state, trainer_pokemon: pokemon_in_field(state),
		                                          wild: wild, move_index: -1, skip_own: true).value
		state['log'] = entrada + Array(state['log'])
		persist_damage(state)

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

	# El relevo entra con sus propios movimientos, no con los del que ha caído.
	def reload_own_moves(state)
		fighter = current_user.pokemon.find_by(id: state['trainer_pokemon_id'])
		return state if fighter.nil?

		moves = ::Pokemons::MoveSet.for_battle(num_pokedex: fighter.num_pokedex, level: fighter.level,
		                                       known: fighter.move_names)
		return state if moves.empty?

		state.merge('own_moves' => moves)
	end

	def award_experience(state)
		state.merge('log' => state['log'] + grant_experience(state))
	end

	# Reparte la experiencia del rival y devuelve las líneas que contarlo.
	#
	# Está separado de `award_experience` porque la captura también la reparte y
	# no tiene registro donde escribirla: sale por el aviso de la página
	# siguiente. Lo común es el reparto, no dónde se cuenta.
	def grant_experience(state)
		fighter = current_user.pokemon.find_by(id: state['trainer_pokemon_id'])
		return [] if fighter.nil?

		amount = ::Pokemons::LevelStats.experience_from(
			base_experience: state['base_experience'],
			level: state['level']
		)
		result = ::Pokemons::GainExperience.execute(pokemon: fighter, amount: amount).value

		lines = ["#{fighter.nickname} gained #{amount} EXP."]
		Array(result[:events]).each do |event|
			lines << case event[:type]
			         when :level_up then "#{fighter.nickname} grew to Lv. #{event[:to]}!"
			         when :evolution then "#{fighter.nickname} evolved into #{event[:into]}!"
			         when :learned then "#{fighter.nickname} learned #{event[:move]}!"
			         # Se dice cuál se ha perdido: con los cuatro huecos llenos algo
			         # tiene que salir, y enterarse a mitad del combate siguiente
			         # sería peor.
			         when :replaced then "#{fighter.nickname} forgot #{event[:forgot]} and learned #{event[:move]}!"
			         end
		end
		lines.compact
	end

	# Quien está combatiendo: durante un combate lo dice el estado, porque puede
	# haber relevado al primero del equipo.
	def lead_pokemon
		current = session[:encounter] && session[:encounter]['trainer_pokemon_id']
		pokemon = current && current_user.pokemon.find_by(id: current)
		pokemon ||= current_user.pokemon.in_party.first
		pokemon && ::Pokemons::PokemonDecorator.decorate(pokemon)
	end

	# Quién está en el campo **según un estado concreto**, y no según el que hay
	# guardado en la sesión.
	#
	# Hace falta cuando el estado ya ha cambiado pero todavía no se ha escrito: al
	# cambiar de Pokémon, `lead_pokemon` devolvía el que acababa de salir, así que
	# el rival golpeaba contra las estadísticas del que ya no estaba y el registro
	# anunciaba su nombre. El daño se calculaba mal, no sólo el texto.
	def pokemon_in_field(state)
		pokemon = current_user.pokemon.find_by(id: state['trainer_pokemon_id'])
		pokemon && ::Pokemons::PokemonDecorator.decorate(pokemon)
	end

	# El nivel del mejor del equipo. Con el mejor y no con la media: llevar un
	# Pokémon flojo de acompañante no debería cerrar una zona ya ganada.
	def party_best_level
		current_user.pokemon.in_party.maximum(:level).to_i
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
	def switch_error_message(error)
		case error
		when :already_out then 'That Pokémon is already in battle!'
		when :fainted then 'That Pokémon has no energy left!'
		else 'That Pokémon is not in your party.'
		end
	end

	def item_error_message(error)
		case error
		when :out_of_stock then 'You have none left!'
		when :already_full then 'Its HP is already full!'
		when :not_fainted then 'That Pokémon is not fainted.'
		when :already_fainted then "It won't have any effect on a fainted Pokémon."
		else "That item can't be used here."
		end
	end

	# Caer con todo el equipo cuesta la mitad del dinero, y luego te recogen y te
	# curan, como en el juego. Lo segundo no es un regalo: sin ello el jugador se
	# quedaría con el equipo entero debilitado y sin poder hacer nada más que ir a
	# pie al Centro, que es exactamente el paso que el juego te ahorra.
	def lose_battle(state)
		lost = ::Encounters::Rules.defeat_penalty(current_user.money)
		current_user.update!(money: current_user.money - lost) if lost.positive?
		::Pokemons::HealAll.execute(user: current_user)

		lines = ['You are out of usable Pokémon!']
		lines << "You panicked and dropped ₽#{ActiveSupport::NumberHelper.number_to_delimited(lost)}." if lost.positive?
		lines << 'You scurried to the Pokémon Center, healing your team.'

		state.merge('log' => state['log'] + lines)
	end

	# Guarda en el Pokémon el daño que lleva en el combate.
	#
	# Se hace en cada turno y no al terminar: si se guardara al final, cerrar la
	# pestaña a media pelea curaría al equipo, y huir de un combate perdido saldría
	# gratis. El daño tiene que ser real en el momento en que se recibe.
	def persist_damage(state)
		fighter = current_user.pokemon.find_by(id: state['trainer_pokemon_id'])
		return if fighter.nil?

		fighter.update!(damage: [state['trainer_max_hp'].to_i - state['trainer_hp'].to_i, 0].max)
	end

	def finish_if_over
		return if session[:encounter].blank? || session[:encounter]['over'].blank?

		session[:encounter]['closing'] = true
	end

	def store_captured(state)
		wild = ::Pokeapi::FindPokemon.execute(id: state['num_pokedex']).value
		description = ::Pokeapi::FindDescription.execute(id: state['num_pokedex']).value
		return if wild.nil? || description.nil?

		# Con el nivel al que se encontró: es el que has visto en la pantalla de
		# combate y el que corresponde a la zona.
		::Pokemons::CreateUseCase.execute(pokemon: wild, user: current_user.id,
		                                  description: description, nickname: wild.name,
		                                  level: state['level'])
	end

	def record_sighting(num_pokedex)
		current_user.pokedex_sightings.find_or_create_by(num_pokedex: num_pokedex)
	rescue ActiveRecord::RecordNotUnique
		nil
	end

end
