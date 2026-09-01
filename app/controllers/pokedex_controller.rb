class PokedexController < ApplicationController

	# Los mismos que se pueden elegir al registrarse: la portada enseña
	# exactamente entre lo que vas a escoger.
	INFORMATION_POKEMONS = User::STARTERS.keys.freeze

	# La portada es la única página pública.
	skip_before_action :authenticate_user!, only: :information

	# Listado paginado del catálogo completo de la PokeAPI. La paginación se hace
	# contra la propia API (limit/offset), así que sólo se descarga la página pedida.
	def index
		@pokemons = ::Pokeapi::SearchPokemons.execute(page: params[:page], per_page: params[:per_page]).value
		@captured_numbers = captured_numbers
		@seen_numbers = seen_numbers
		@pokedex_total = ::Pokeapi::SearchPokemons::POKEDEX_LIMIT
	end

	def show
		@pokemon = ::Pokeapi::FindPokemon.execute(id: params[:id]).value
		return redirect_to(user_pokedex_index_path(user_id: current_user.id), alert: 'Pokémon not found') if @pokemon.nil?

		@description = ::Pokeapi::FindDescription.execute(id: params[:id]).value
		@matchups = ::Pokemons::TypeMatchup.execute(type_slugs: @pokemon.type_slugs).value
		@evolution_stages = ::Pokemons::EvolutionStages.execute(
			chain: ::Pokeapi::FindEvolutionChain.execute(id: params[:id]).value
		).value
	end

	def information
		@pokemons = INFORMATION_POKEMONS.filter_map { |id| ::Pokeapi::FindPokemon.execute(id: id).value }
		@descriptions = descriptions_for(@pokemons)
	end

	# Paso 1 de la captura: la tirada. Responde en JSON porque el modal cambia de
	# estado sin recargar la página.
	def attempt_capture
		pokemon = ::Pokeapi::FindPokemon.execute(id: params[:pokemon_id]).value
		description = ::Pokeapi::FindDescription.execute(id: params[:pokemon_id]).value

		if pokemon.nil? || description.nil?
			return render json: { error: 'We could not reach the PokeAPI.' }, status: :service_unavailable
		end

		result = ::Pokemons::AttemptCapture.execute(capture_rate: description.capture_rate).value

		# El éxito se anota en la sesión: es lo que autoriza el paso 2. Sin esto,
		# bastaría con llamar directamente a `add_pokemon_to_team` para saltarse
		# la tirada.
		session[:pending_capture] = pokemon.num_pokedex if result[:caught]

		render json: {
			caught: result[:caught],
			name: pokemon.name,
			probability: (result[:probability] * 100).round
		}
	end

	# Paso 2: sólo se llega aquí con una tirada ganada en la sesión.
	def add_pokemon_to_team
		@pokemon = ::Pokeapi::FindPokemon.execute(id: params[:pokemon_id]).value
		@description = ::Pokeapi::FindDescription.execute(id: params[:pokemon_id]).value

		if session[:pending_capture] != params[:pokemon_id].to_i
			return redirect_to user_pokedex_index_path(user_id: params[:user_id]),
				alert: 'You have to catch that Pokémon first.',
				status: :see_other
		end

		# Si la PokeAPI no responde, el cliente devuelve nil y aquí no hay nada que
		# guardar: sin esta guarda se intentaría leer las estadísticas de un nil.
		if @pokemon.nil? || @description.nil?
			return redirect_to user_pokedex_index_path(user_id: params[:user_id]),
				alert: 'We could not reach the PokeAPI. Please try again in a few seconds.',
				status: :see_other
		end

		::Pokemons::CreateUseCase.execute(
			pokemon: @pokemon,
			user: params[:user_id],
			description: @description,
			# El modelo exige apodo, y el formulario permite dejarlo en blanco: en ese
			# caso se queda con el nombre de la especie, como en el juego.
			nickname: params[:nickname].presence || @pokemon.name
		)

		session.delete(:pending_capture)
		redirect_to user_pokemon_index_path(user_id: params[:user_id]), status: :see_other
	end

	private

	# Números de Pokédex que el usuario ya tiene en su PC, en una sola consulta:
	# la tarjeta del catálogo marca con un badge las especies capturadas
	# (styles.md §6.5) y hacerlo por tarjeta sería una N+1.
	def captured_numbers
		@captured_numbers_set ||= current_user.pokemon.pluck(:num_pokedex).to_set
	end

	# Especies que el usuario ya ha encontrado. Capturar implica haber visto, así
	# que se unen los dos conjuntos: de ese modo los Pokémon que ya estaban en el
	# PC antes de existir esta tabla salen revelados sin migrar nada.
	def seen_numbers
		current_user.pokedex_sightings.pluck(:num_pokedex).to_set | captured_numbers
	end

	# El alta se repite en cada visita a la ficha; el índice único de la tabla es
	# lo que la hace idempotente. `RecordNotUnique` sólo puede saltar si dos
	# peticiones simultáneas insertan a la vez, y en ese caso el avistamiento ya
	# está registrado: no hay nada que hacer.
	def record_sighting(num_pokedex)
		current_user.pokedex_sightings.find_or_create_by(num_pokedex: num_pokedex)
	rescue ActiveRecord::RecordNotUnique
		nil
	end

	# Las descripciones se indexan por número de Pokédex para que la vista no
	# dependa de que ambos arrays vayan en el mismo orden.
	def descriptions_for(pokemons)
		pokemons.each_with_object({}) do |pokemon, descriptions|
			descriptions[pokemon.num_pokedex] = ::Pokeapi::FindDescription.execute(id: pokemon.num_pokedex).value
		end
	end

end
