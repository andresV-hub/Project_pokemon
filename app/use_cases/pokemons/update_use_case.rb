module Pokemons
  class UpdateUseCase < BaseService

    def initialize(pokemon:,  nickname:)
      @pokemon = pokemon
      @nickname = nickname
    end

    def service_execute
      pokemon = ::Pokemons::Update.execute(pokemon: @pokemon, nickname: @nickname)
    end

  end
end