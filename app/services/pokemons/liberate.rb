module Pokemons
  class Liberate < BaseService

    def initialize(id:)
      @id = id
    end

    def service_execute
      item = ::Pokemons::FindPokemon.execute(id: @id)
      item.destroy!
    end

  end
end