module Encounters
  # Sortea qué aparece en una zona, con las probabilidades y los niveles del juego.
  #
  # Sustituye a `DrawOpponent`, que sorteaba entre los 151 y ajustaba el nivel al
  # del jugador. Aquello resolvía un problema real —a un inicial le tocaba
  # Dragonite uno de cada tres encuentros— pero a costa de que no hubiera sitios:
  # todo salía en todas partes y encontrar un Clefairy valía lo mismo que encontrar
  # un Rattata.
  #
  # El emparejamiento por fuerza ya no hace falta, y por eso desaparece: **la zona
  # es el emparejamiento**. La Ruta 1 tiene Pokémon de nivel 2 y la Cueva Celeste
  # de nivel 53, y a la segunda no se entra hasta tener con qué. Es como lo resuelve
  # el juego, y de paso devuelve el sentido de la rareza: Clefairy sale al 1% en el
  # Monte Moon y vale lo que costó encontrarlo.
  class DrawFromZone < BaseService

    def initialize(zone_key:)
      @zone = Zones.find(zone_key) || Zones.default
    end

    def service_execute
      table = ::Pokeapi::FindZoneEncounters.execute(area: @zone[:area]).value
      return ServiceResult.new(error: :pokeapi_unavailable) if table.blank?

      row = weighted_pick(table)
      pokemon = ::Pokeapi::FindPokemon.execute(id: row['num_pokedex']).value
      return ServiceResult.new(error: :pokeapi_unavailable) if pokemon.nil?

      ServiceResult.new(value: { pokemon: pokemon, level: level_for(row), zone: @zone })
    end

    private

    # Tirada proporcional al peso. No se normaliza a 100 porque los pesos de la API
    # no suman 100 en todas las zonas, y forzarlo sólo añadiría redondeos: lo que
    # importa es la proporción entre especies, no la cifra.
    def weighted_pick(table)
      total = table.sum { |row| row['weight'].to_i }
      return table.sample if total <= 0

      draw = rand(1..total)
      running = 0
      table.find do |row|
        running += row['weight'].to_i
        running >= draw
      end || table.last
    end

    def level_for(row)
      low = row['min_level'].to_i
      high = [row['max_level'].to_i, low].max

      rand(low..high)
    end

  end
end
