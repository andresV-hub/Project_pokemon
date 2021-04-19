module Homes
  class HomeDecorator < ApplicationDecorator
    
  	def generation
  		"Generacion 1"
  	end

  	def bulbasaur_name
  		model['pokemon_entries'][0]['pokemon_species']['name']
  	end

  	def charmander_name
  		model['pokemon_entries'][3]['pokemon_species']['name']
  	end

  	def squirtle_name
  		model['pokemon_entries'][6]['pokemon_species']['name']
  	end

  	def squirtle_name
  		model['pokemon_entries'][6]['pokemon_species']['name']
  	end

  	def squirtle
  		model['pokemon_entries'][6]['pokemon_species']['url']
  	end

  	def image
  		pokemon_species['sprites']["front_default"]
  	end

  end
end