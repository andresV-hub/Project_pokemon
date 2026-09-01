module Pokeapi
  # Busca un pokémon concreto en la PokeAPI por número de Pokédex o por nombre.
  class FindPokemon < BaseService

    def initialize(id:)
      @id = id
    end

    def service_execute
      detail = Client.get("pokemon/#{@id}")
      return ServiceResult.new(error: ActiveRecord::RecordNotFound.new("Pokemon #{@id} no encontrado")) if detail.nil?

      ServiceResult.new(value: ::Pokedex::PokedexDecorator.decorate(detail))
    end

  end
end
