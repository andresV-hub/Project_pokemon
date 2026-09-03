module Pokedex
  class PokedexDecorator < ApplicationDecorator

    decorates :pokedex

    # Sprite preferido y alternativas. Con la paginación ya se llega a pokémon
    # posteriores a la sexta generación, que no tienen sprite de OmegaRuby /
    # AlphaSapphire, así que hay que ir cayendo a las siguientes opciones.
    ORAS_SPRITES = %w[sprites versions generation-vi omegaruby-alphasapphire].freeze
    OFFICIAL_ARTWORK = %w[sprites other official-artwork].freeze
    PLACEHOLDER_IMAGE = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/0.png'.freeze

    # Las estadísticas se leen por nombre y no por posición: el orden del array
    # que devuelve la PokeAPI no está garantizado y confundir dos índices
    # intercambia dos barras en la ficha sin que nada falle.
    STAT_LABELS = {
      'hp' => 'HP',
      'attack' => 'Attack',
      'defense' => 'Defense',
      'special-attack' => 'Sp. Atk',
      'special-defense' => 'Sp. Def',
      'speed' => 'Speed'
    }.freeze

    # Techo canónico de una estadística base. La escala de las barras es fija
    # para que dos fichas sean comparables de un vistazo (styles.md §6.7).
    STAT_MAX = 255.0

    MOVES_SHOWN = 4

    def name
      model.dig('forms', 0, 'name').to_s.capitalize
    end

    def num_pokedex
      model['id']
    end

    def height
      model['height']
    end

    # Experiencia que otorga derrotarlo, tal cual la da la PokeAPI.
    def base_experience
      model['base_experience'].to_i
    end

    def image
      model.dig(*ORAS_SPRITES, 'front_default') ||
        model.dig(*OFFICIAL_ARTWORK, 'front_default') ||
        model.dig('sprites', 'front_default') ||
        PLACEHOLDER_IMAGE
    end

    def image_shiny
      model.dig(*ORAS_SPRITES, 'front_shiny') ||
        model.dig(*OFFICIAL_ARTWORK, 'front_shiny') ||
        model.dig('sprites', 'front_shiny') ||
        image
    end

    # Artwork oficial para la ficha; el sprite pequeño se reserva a listados
    # (styles.md §6.13).
    def artwork
      model.dig(*OFFICIAL_ARTWORK, 'front_default') || image
    end

    def id
      model['id']
    end

    def type_of_pokemon
      model.dig('types', 0, 'type', 'name').to_s.capitalize
    end

    def specie
      model.dig('species', 'name').to_s.capitalize
    end

    def stats(num:)
      model.dig('stats', num, 'base_stat')
    end

    def attacks(num:)
      model.dig('moves', num, 'move', 'name')&.capitalize
    end

    # ---- Presentación (styles.md §6) --------------------------------------

    # Número con relleno a cuatro cifras: en una rejilla de veinte tarjetas es
    # lo que hace que los números se alineen (styles.md §3).
    def dex_number
      format('#%04d', num_pokedex.to_i)
    end

    # Claves inglesas de la PokeAPI: son la clave estable con la que se forma el
    # modificador `dex-type--{tipo}` (styles.md §6.2).
    # La habilidad de la primera ranura, nunca una oculta: las ocultas llegaron más
    # tarde todavía y en varias especies son claramente mejores, así que repartirlas
    # al azar convertiría la captura en una lotería con premio.
    def ability
      Array(model['abilities']).reject { |entry| entry['is_hidden'] }
                               .min_by { |entry| entry['slot'].to_i }
                               &.dig('ability', 'name')
    end

    def type_slugs
      Array(model['types']).filter_map { |type| type.dig('type', 'name') }
    end

    def type_slug
      type_slugs.first || 'normal'
    end

    def type_names
      type_slugs.map(&:capitalize)
    end

    def stat_list
      Array(model['stats']).filter_map do |stat|
        key = stat.dig('stat', 'name')
        label = STAT_LABELS[key]
        next if label.nil?

        { key: key, label: label, value: stat['base_stat'].to_i }
      end
    end

    # Los cuatro primeros del array que devuelve la PokeAPI **no son** los que se
    # aprenden subiendo de nivel, sino los de máquina: la ficha de Pikachu decía
    # que sabía Mega Punch. Ahora se listan los de nivel, con el nivel al lado,
    # que es lo que de verdad describe a la especie.
    def move_list
      level_moves.first(MOVES_SHOWN).map { |name, _level| name }
    end

    def level_moves
      Array(model['moves']).filter_map do |entry|
        detail = Array(entry['version_group_details']).find do |version|
          version.dig('version_group', 'name') == ::Pokemons::MoveSet::VERSION_GROUP &&
            version.dig('move_learn_method', 'name') == 'level-up'
        end
        next if detail.nil?

        [entry.dig('move', 'name').to_s.tr('-', ' ').capitalize, detail['level_learned_at'].to_i]
      end.sort_by(&:last)
    end

    def sprite_alt
      "#{name}, Pokédex ##{num_pokedex}"
    end

    # La PokeAPI da la altura en decímetros y el peso en hectogramos.
    def height_in_metres
      return nil if model['height'].blank?

      (model['height'] / 10.0).round(1)
    end

    def weight_in_kilos
      return nil if model['weight'].blank?

      (model['weight'] / 10.0).round(1)
    end

    # Sonido del Pokémon. Sólo lo tienen las especies principales, así que puede
    # venir vacío y la vista tiene que poder prescindir de él.
    def cry_url
      model.dig('cries', 'latest').presence
    end

  end
end
