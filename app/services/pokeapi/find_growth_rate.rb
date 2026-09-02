module Pokeapi
  # La tabla de experiencia de una curva de crecimiento.
  #
  # La API devuelve los cien niveles ya calculados, así que no hace falta
  # implementar las fórmulas —`medium-slow` es `6x³/5 − 15x² + 100x − 140`— ni
  # arriesgarse a equivocarse en ellas. Son seis recursos que no cambian nunca y el
  # caché los sirve siempre después de la primera vez.
  class FindGrowthRate < BaseService

    def initialize(name:)
      @name = name.to_s.presence || ::Pokemons::ExperienceCurve::DEFAULT
    end

    # Devuelve `{ 1 => 0, 2 => 15, ... 100 => 1000000 }`.
    def service_execute
      raw = Client.get("growth-rate/#{@name}")
      return ServiceResult.new(value: nil) if raw.nil?

      table = Array(raw['levels']).each_with_object({}) do |entry, memo|
        memo[entry['level'].to_i] = entry['experience'].to_i
      end

      ServiceResult.new(value: table.presence)
    end

  end
end
