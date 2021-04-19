module Pokemons
  class CreateUseCase < BaseService

    def initialize(pokemon:, user:, description:, nickname:)
      @pokemon = pokemon
      @user = user
      @description = description
      @nickname = nickname
    end

    def service_execute
      @user=User.find(@user)
      ::Pokemons::Create.execute(pokemon: @pokemon, user: @user, description: @description, nickname: @nickname)
    end

  end
end