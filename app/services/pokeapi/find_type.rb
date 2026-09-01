module Pokeapi
  # Relaciones de daño de un tipo (`/type/{name}`). Son 18 recursos que no
  # cambian nunca, así que el caché del cliente los sirve casi siempre.
  class FindType < BaseService

    def initialize(name:)
      @name = name.to_s.downcase
    end

    def service_execute
      type = Client.get("type/#{@name}")
      return ServiceResult.new(error: ActiveRecord::RecordNotFound.new("Type #{@name} not found")) if type.nil?

      ServiceResult.new(value: type['damage_relations'])
    end

  end
end
