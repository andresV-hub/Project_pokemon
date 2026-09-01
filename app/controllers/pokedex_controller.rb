class PokedexController < ApplicationController

	INFORMATION_POKEMONS = [1, 4, 7].freeze

	# La portada es la única página pública.
	skip_before_action :authenticate_user!, only: :information

	# Listado paginado del catálogo completo de la PokeAPI. La paginación se hace
	# contra la propia API (limit/offset), así que sólo se descarga la página pedida.
	def index
		@pokemons = ::Pokeapi::SearchPokemons.execute(page: params[:page], per_page: params[:per_page]).value
		@descriptions = descriptions_for(@pokemons)
	end

	def show
		@pokemon = ::Pokeapi::FindPokemon.execute(id: params[:id]).value
		return redirect_to(user_pokedex_index_path(user_id: current_user.id), alert: 'Pokemon no encontrado') if @pokemon.nil?

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

	# Las descripciones se indexan por número de Pokédex para que la vista no
	# dependa de que ambos arrays vayan en el mismo orden.
	def descriptions_for(pokemons)
		pokemons.each_with_object({}) do |pokemon, descriptions|
			descriptions[pokemon.num_pokedex] = ::Pokeapi::FindDescription.execute(id: pokemon.num_pokedex).value
		end
	end

end
