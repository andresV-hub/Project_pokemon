module Pokemons
  class PokemonDecorator < ApplicationDecorator

  	decorates :pokemon

  	delegate_all

  	def self.collection_decorator_class
  		ApplicationCollectionDecorator
  	end

  end
end
