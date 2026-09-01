module Pokemons
  # Devuelve un Pokémon del equipo al PC, dejando su hueco libre.
  class SendToPc < BaseService

    def initialize(pokemon:)
      @pokemon = pokemon
    end

    def service_execute
      @pokemon.update!(party_position: nil)
      ServiceResult.new(value: @pokemon)
    end

  end
end
