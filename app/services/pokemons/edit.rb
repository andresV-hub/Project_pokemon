module Pokemons
  class FindPokemon < BaseService

    def initialize(pokemon:, nickname:)
      @pokemon = pokemon
      @nickname = nickname
    end

    def service_execute
    	pokemon.update(
    		nickname: @nickname
    	)
    end

  end
end