module Pokeapi
  # La tabla de encuentros de una zona: qué sale allí, con qué probabilidad y a
  # qué nivel.
  #
  # Es lo que convierte «explorar» en ir a un sitio. Antes se sorteaba una especie
  # entre las 151 con el nivel escalado al tuyo, así que encontrar un Dratini valía
  # lo mismo que encontrar un Rattata y no había ningún lugar al que ir a buscar
  # algo concreto.
  #
  # == Por qué no se usa `max_chance`
  #
  # La API trae un `max_chance` por especie y **no sirve**: en la Central Eléctrica
  # da 630 para Voltorb y 200 para Electrode, que ni siquiera tiene un solo
  # encuentro a pie. Parece acumular entre métodos y versiones. La probabilidad
  # real es la **suma de las `chance` de los `encounter_details`** una vez filtrados
  # por método, que para ese mismo Voltorb da 30, en línea con sus compañeros.
  #
  # Los pesos no tienen por qué sumar 100 —la API es irregular—, así que la tirada
  # es proporcional al total y no a un porcentaje absoluto.
  class FindZoneEncounters < BaseService

    # Sólo encuentros a pie. Pescar y surfear son otras mecánicas del juego que
    # aquí no existen, y mezclarlas haría aparecer Pokémon de agua en mitad de una
    # ruta de tierra.
    METHOD = 'walk'.freeze

    # La versión de referencia del proyecto, la misma que usa `MoveSet`.
    VERSION = 'red'.freeze

    def initialize(area:)
      @area = area.to_s
    end

    def service_execute
      raw = Client.get("location-area/#{@area}")
      return ServiceResult.new(error: :pokeapi_unavailable) if raw.nil?

      ServiceResult.new(value: Array(raw['pokemon_encounters']).filter_map { |entry| row_for(entry) })
    end

    private

    def row_for(entry)
      version = Array(entry['version_details']).find { |v| v.dig('version', 'name') == VERSION }
      return nil if version.nil?

      details = Array(version['encounter_details']).select { |d| d.dig('method', 'name') == METHOD }
      return nil if details.empty?

      {
        'num_pokedex' => id_from(entry.dig('pokemon', 'url')),
        'name' => entry.dig('pokemon', 'name'),
        'weight' => details.sum { |d| d['chance'].to_i },
        'min_level' => details.map { |d| d['min_level'].to_i }.min,
        'max_level' => details.map { |d| d['max_level'].to_i }.max
      }
    end

    # La API no repite el id en el cuerpo, sólo en la URL del recurso.
    def id_from(url)
      url.to_s[%r{/pokemon/(\d+)/?$}, 1].to_i
    end

  end
end
