module Pokeapi
  # Cadena evolutiva de una especie. La PokeAPI la sirve en dos saltos: la ficha
  # de especie apunta a la cadena, y la cadena es un árbol independiente de qué
  # miembro se haya pedido (Bulbasaur, Ivysaur y Venusaur devuelven la misma).
  class FindEvolutionChain < BaseService

    def initialize(id:)
      @id = id
    end

    def service_execute
      species = Client.get("pokemon-species/#{@id}")
      url = species&.dig('evolution_chain', 'url')
      return ServiceResult.new(value: nil) if url.blank?

      chain = Client.get_url(url)
      ServiceResult.new(value: chain&.dig('chain'))
    end

  end
end
