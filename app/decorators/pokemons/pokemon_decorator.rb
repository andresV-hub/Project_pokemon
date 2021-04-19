module Pokemons
  class PokemonDecorator < ApplicationDecorator

  	decorates :pokemon

  	delegate_all

  end
end