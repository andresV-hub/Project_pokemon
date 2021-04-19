module Pokemons
  class SearchByUser < BaseService

    def initialize(user_id:)
      @user_id = user_id
    end

    def service_execute
      Pokemon.where(user_id: @user_id)
    end

  end
end