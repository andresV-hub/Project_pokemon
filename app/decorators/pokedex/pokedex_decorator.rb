module Pokedex
  class PokedexDecorator < ApplicationDecorator
    
    decorates :pokedex

  	def name
  		model['forms'][0]['name'].capitalize()
  	end

    def num_pokedex
      model['id']
    end

    def height
      model['height']
    end

  	def image
      model['sprites']['versions']['generation-vi']['omegaruby-alphasapphire']["front_default"]
    end
    def image_shiny
      model['sprites']['versions']['generation-vi']['omegaruby-alphasapphire']["front_shiny"]
    end

    def id
      model['id']
    end

    def type_of_pokemon
      model['types'][0]['type']['name'].capitalize
    end

    def specie
      model['species']['name'].capitalize
    end

    def stats(num:)
      model['stats'][num]['base_stat']
    end

    def attacks(num:)
      model['moves'][num]['move']['name'].capitalize
    end

  end
end