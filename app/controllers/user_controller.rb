class UserController < ApplicationController

	def show
		pokemons = JSON.parse(RestClient.get("https://pokeapi.co/api/v2/pokemon?limit=151&offset=0"))
	end
	
	
end