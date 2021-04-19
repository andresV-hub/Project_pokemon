class PokedexController < ApplicationController
	
	def index
		pokemons = JSON.parse(RestClient.get("https://pokeapi.co/api/v2/pokemon?limit=16"))
		@pokemons = []
		@descriptions = []
		id=0
		pokemons['results'].each do |pokemon|
			url = pokemon['url']
			pokemon_temp = JSON.parse(RestClient.get(url))
			@pokemons << (Pokedex::PokedexDecorator.decorate(pokemon_temp))
			description = JSON.parse(RestClient.get("https://pokeapi.co/api/v2/pokemon-species/#{pokemon['name']}"))
			@descriptions << Descriptions::DescriptionDecorator.decorate(description)
			id= id+1
		end
		@pokemons
	end
	
	def show
		pokemon = JSON.parse(RestClient.get("https://pokeapi.co/api/v2/pokemon/#{params[:id]}"))
		@pokemon = Pokedex::PokedexDecorator.decorate(pokemon)
		description = JSON.parse(RestClient.get("https://pokeapi.co/api/v2/pokemon-species/#{params[:id]}"))
		@description = Descriptions::DescriptionDecorator.decorate(description)
	end
	
	def information
		pokemon_names = [1,4,7]
		@pokemons = []
		@descriptions = []
		pokemon_names.each do |pokemon|
			pokemon_temp = JSON.parse(RestClient.get("https://pokeapi.co/api/v2/pokemon/#{pokemon}"))
			@pokemons << (Pokedex::PokedexDecorator.decorate(pokemon_temp))
			description = JSON.parse(RestClient.get("https://pokeapi.co/api/v2/pokemon-species/#{pokemon}"))
			@descriptions << Descriptions::DescriptionDecorator.decorate(description)
		end
		@pokemons
	end

	def add_pokemon_to_team
		pokemon = JSON.parse(RestClient.get("https://pokeapi.co/api/v2/pokemon/#{params[:pokemon_id]}"))
		@pokemon = Pokedex::PokedexDecorator.decorate(pokemon)
		description = JSON.parse(RestClient.get("https://pokeapi.co/api/v2/pokemon-species/#{params[:pokemon_id]}"))
		@description = Descriptions::DescriptionDecorator.decorate(description)
		nickname = params[:nickname]
		user = params[:user_id]
		#TODO create use case pokemon
		Pokemons::CreateUseCase.execute(pokemon: @pokemon, user: user, description: @description, nickname: nickname)
		redirect_to user_pokemon_index_path
	end

end