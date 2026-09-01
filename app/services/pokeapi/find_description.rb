module Pokeapi
  # Recupera la ficha de especie (descripción, hábitat, ratio de captura).
  # Devuelve nil cuando la PokeAPI no tiene especie para ese identificador, algo
  # habitual en las formas alternativas con id por encima de 10000.
  class FindDescription < BaseService

    def initialize(id:)
      @id = id
    end

    def service_execute
      species = Client.get("pokemon-species/#{@id}")
      return ServiceResult.new(value: nil) if species.nil?

      ServiceResult.new(value: ::Descriptions::DescriptionDecorator.decorate(species))
    end

  end
end
