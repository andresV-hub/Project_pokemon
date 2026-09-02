module Encounters
  # Los sitios de Kanto a los que se puede ir a buscar Pokémon.
  #
  # Catálogo en código, como `Shop::Catalog`: son las reglas del juego y no datos
  # que nadie administre. Lo que sale en cada zona **no** está aquí —eso lo da la
  # API en `Pokeapi::FindZoneEncounters`— y por eso la lista sólo guarda el nombre
  # del área, cómo llamarla en pantalla y a partir de qué nivel se abre.
  #
  # == Cómo se eligieron
  #
  # Comprobando una a una contra la API. De las 157 áreas de Kanto, muchas no
  # sirven: las ciudades no tienen encuentros salvajes, `kanto-route-2-area` y
  # `kanto-route-21-area` ni siquiera existen con ese nombre, y `rock-tunnel-1f`
  # responde pero no trae un solo encuentro a pie en la versión roja. Construir la
  # lista por patrón de nombre habría dado una docena de zonas vacías.
  #
  # == El desbloqueo
  #
  # Por nivel del mejor Pokémon del equipo, que es el criterio más simple que
  # funciona. En el juego lo que abre zonas es la historia —medallas, la Caña, el
  # Pase—, y aquí no hay historia que contar: lo que hay es un equipo que se hace
  # fuerte. Los niveles de cada zona son los del juego, así que la progresión sale
  # sola: la Ruta 1 tiene Pokémon de nivel 2 y la Cueva Celeste de nivel 53.
  module Zones

    ALL = [
      { key: 'route_1', name: 'Route 1', area: 'kanto-route-1-area', unlock: 1,
        blurb: 'The first stretch of grass out of Pallet Town.' },
      { key: 'viridian_forest', name: 'Viridian Forest', area: 'viridian-forest-area', unlock: 5,
        blurb: 'A maze of trees full of bugs — and the odd Pikachu.' },
      { key: 'mt_moon', name: 'Mt. Moon', area: 'mt-moon-1f', unlock: 8,
        blurb: 'Caves crawling with Zubat. Clefairy hides here, rarely.' },
      { key: 'route_4', name: 'Route 4', area: 'kanto-route-4-area', unlock: 10,
        blurb: 'Dry ledges above Cerulean City.' },
      { key: 'route_24', name: 'Route 24', area: 'kanto-route-24-area', unlock: 12,
        blurb: 'The Nugget Bridge road, thick with grass.' },
      { key: 'route_6', name: 'Route 6', area: 'kanto-route-6-area', unlock: 14,
        blurb: 'The path down to Vermilion, patrolled by Mankey.' },
      { key: 'route_11', name: 'Route 11', area: 'kanto-route-11-area', unlock: 16,
        blurb: 'Open country east of Vermilion City.' },
      { key: 'route_12', name: 'Route 12', area: 'kanto-route-12-area', unlock: 22,
        blurb: 'The long fishing road along the coast.' },
      { key: 'power_plant', name: 'Power Plant', area: 'kanto-power-plant-area', unlock: 26,
        blurb: 'Abandoned and live with electricity.' },
      { key: 'seafoam', name: 'Seafoam Islands', area: 'seafoam-islands-1f', unlock: 30,
        blurb: 'Frozen caves battered by the sea.' },
      { key: 'mansion', name: 'Pokémon Mansion', area: 'pokemon-mansion-1f', unlock: 34,
        blurb: 'A burnt-out ruin on Cinnabar Island.' },
      { key: 'victory_road', name: 'Victory Road', area: 'kanto-victory-road-2-1f', unlock: 38,
        blurb: 'The last climb before the Pokémon League.' },
      { key: 'cerulean_cave', name: 'Cerulean Cave', area: 'cerulean-cave-1f', unlock: 46,
        blurb: 'Where the strongest Pokémon in Kanto are said to live.' }
    ].freeze

    module_function

    def all = ALL

    def find(key) = ALL.find { |zone| zone[:key] == key.to_s }

    def default = ALL.first

    # Las que ya puede visitar un entrenador. Se mide con **el mejor del equipo** y
    # no con la media: llevar un Pokémon flojo de acompañante no debería cerrarte
    # una zona que ya te habías ganado.
    def unlocked_for(level)
      ALL.select { |zone| zone[:unlock] <= level.to_i }
    end

    def unlocked?(key, level)
      zone = find(key)
      zone.present? && zone[:unlock] <= level.to_i
    end

  end
end
