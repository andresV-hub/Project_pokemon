module Pokemons
  class CreateUseCase < BaseService

    def initialize(pokemon:, user:, description:, nickname:, level: nil)
      @pokemon = pokemon
      @user = user
      @description = description
      @nickname = nickname
      @level = level
    end

    def service_execute
      @user=User.find(@user)
      ::Pokemons::Create.execute(pokemon: @pokemon, user: @user, description: @description,
                                 nickname: @nickname, level: @level)
    end

  end
end