class PokedexController < ApplicationController

	INFORMATION_POKEMONS = [1, 4, 7].freeze

	# La portada es la única página pública.
	skip_before_action :authenticate_user!, only: :information

	# Listado paginado del catálogo completo de la PokeAPI. La paginación se hace
	# contra la propia API (limit/offset), así que sólo se descarga la página pedida.
	def index
		@pokemons = ::Pokeapi::SearchPokemons.execute(page: params[:page], per_page: params[:per_page]).value
		@captured_numbers = captured_numbers
	end

	def show
		@pokemon = ::Pokeapi::FindPokemon.execute(id: params[:id]).value
		return redirect_to(user_pokedex_index_path(user_id: current_user.id), alert: 'Pokémon not found') if @pokemon.nil?

		@description = ::Pokeapi::FindDescription.execute(id: params[:id]).value
	end

	def information
		@pokemons = INFORMATION_POKEMONS.filter_map { |id| ::Pokeapi::FindPokemon.execute(id: id).value }
		@descriptions = descriptions_for(@pokemons)
	end

	def add_pokemon_to_team
		@pokemon = ::Pokeapi::FindPokemon.execute(id: params[:pokemon_id]).value
		@description = ::Pokeapi::FindDescription.execute(id: params[:pokemon_id]).value

		::Pokemons::CreateUseCase.execute(
			pokemon: @pokemon,
			user: params[:user_id],
			description: @description,
			nickname: params[:nickname]
		)

		redirect_to user_pokemon_index_path(user_id: params[:user_id]), status: :see_other
	end

	private

	# Números de Pokédex que el usuario ya tiene en su PC, en una sola consulta:
	# la tarjeta del catálogo marca con un badge las especies capturadas
	# (styles.md §6.5) y hacerlo por tarjeta sería una N+1.
	def captured_numbers
		current_user.pokemon.pluck(:num_pokedex).to_set
	end

	# Las descripciones se indexan por número de Pokédex para que la vista no
	# dependa de que ambos arrays vayan en el mismo orden.
	def descriptions_for(pokemons)
		pokemons.each_with_object({}) do |pokemon, descriptions|
			descriptions[pokemon.num_pokedex] = ::Pokeapi::FindDescription.execute(id: pokemon.num_pokedex).value
		end
	end

end
