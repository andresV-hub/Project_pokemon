class PokemonController < ApplicationController
	
	def index
		pokemons = ::Pokemons::SearchByUser.execute(user_id: current_user.id)
		@pokemons = Pokemons::PokemonDecorator.decorate_collection(pokemons)
	end

	def show
		pokemon = ::Base::Find.execute(klass: Pokemon,id: params[:id])

		@pokemon = Pokemons::PokemonDecorator.decorate(pokemon)
	end

	def liberate_pokemon
		::Pokemons::Liberate.execute(id: params[:id])
		redirect_to user_pokemon_index_path(user_id: current_user.id)
	end

	def edit_nickname
		pokemon = ::Base::Find.execute(klass: Pokemon,id: params[:id])
		nickname = params[:pokemon][:nickname]
		@pokemon = Pokemons::UpdateUseCase.execute(pokemon: pokemon, nickname: nickname)
		redirect_to user_pokemon_path(user_id: current_user.id, id: params[:id])
	end

	def compare_with
		pokemon = ::Base::Find.execute(klass: Pokemon,id: params[:id])
		pokemon_api = JSON.parse(RestClient.get("https://pokeapi.co/api/v2/pokemon/#{params[:pokemon][:id]}"))
		@pokemon_api = Pokedex::PokedexDecorator.decorate(pokemon_api)
		@stats = Pokemons::ComparePokemonUseCase.execute(pokemon1: pokemon, pokemon_api: @pokemon_api)
		@pokemon = Pokemons::PokemonDecorator.decorate(pokemon)
	end

end