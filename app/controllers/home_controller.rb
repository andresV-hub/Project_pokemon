class HomeController < ApplicationController

	def pokemons_index
		pokemons = JSON.parse(RestClient.get("https://pokeapi.co/api/v2/pokemon?limit=20"))
		@pokemons = []
		pokemons['results'].each do |pokemon|
			#TODO filters y pokemons species(de la APi, para la descripcion pokedex)
			url = pokemon['url']
			pokemon = JSON.parse(RestClient.get(url))
			@pokemons << (Pokemons::PokemonDecorator.decorate(pokemon))
		end
		@pokemons
	end
	
	def show
		pokemon_names = ["bulbasaur","charmander","squirtle"]
		@pokemons = []
		pokemon_names.each do |pokemon|
			pokemon = JSON.parse(RestClient.get("https://pokeapi.co/api/v2/pokemon/#{pokemon}"))
			@pokemons << (Pokemons::PokemonDecorator.decorate(pokemon))
		end
		@pokemons
	end

	def show_pokemon#TODO Cambiar nombre del show
		pokemon = JSON.parse(RestClient.get("https://pokeapi.co/api/v2/pokemon/#{params[:id]}"))
		Pokemons::PokemonDecorator.decorate(pokemon)
	end

end