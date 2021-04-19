module Pokemons
  class Update < BaseService

    def initialize(pokemon:, nickname:)
      @pokemon = pokemon
      @nickname = nickname
    end

    def service_execute
    	@pokemon.update(
    		nickname: @nickname
    	)
      @pokemon.save!
      @pokemon
    end

  end
end