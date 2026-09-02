class PokedexController < ApplicationController

	# Los mismos que se pueden elegir al registrarse: la portada enseña
	# exactamente entre lo que vas a escoger.
	INFORMATION_POKEMONS = User::STARTERS.keys.freeze

	# La portada es la única página pública.
	skip_before_action :authenticate_user!, only: :information

	# Listado paginado del catálogo completo de la PokeAPI. La paginación se hace
	# contra la propia API (limit/offset), así que sólo se descarga la página pedida.
	def index
		@filter_kind, @filter_name = filter_from_params
		ids = @filter_kind && ::Pokeapi::FindSpeciesGroup.execute(kind: @filter_kind, name: @filter_name).value

		@pokemons = ::Pokeapi::SearchPokemons.execute(page: params[:page], per_page: params[:per_page],
		                                              ids: ids).value
		@captured_numbers = captured_numbers
		@seen_numbers = seen_numbers
		@pokedex_total = ids ? ids.size : ::Pokeapi::SearchPokemons::POKEDEX_LIMIT
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

	private

	# Un filtro y sólo uno: hábitat **o** color. Cruzarlos exigiría intersecar dos
	# listas y una interfaz con dos desplegables que se contradicen entre sí, y
	# para 151 especies no compensa.
	#
	# Se valida contra la lista de la API: el nombre llega por la URL y sin esto
	# cualquier cosa acabaría en una petición a un recurso inventado.
	def filter_from_params
		%i[habitat color].each do |kind|
			name = params[kind].presence
			return [kind, name] if name && ::Pokeapi::FindSpeciesGroup.valid?(kind, name)
		end

		[nil, nil]
	end

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
