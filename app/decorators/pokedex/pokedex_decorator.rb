module Pokedex
  class PokedexDecorator < ApplicationDecorator

    decorates :pokedex

    # Sprite preferido y alternativas. Con la paginación ya se llega a pokémon
    # posteriores a la sexta generación, que no tienen sprite de OmegaRuby /
    # AlphaSapphire, así que hay que ir cayendo a las siguientes opciones.
    ORAS_SPRITES = %w[sprites versions generation-vi omegaruby-alphasapphire].freeze
    OFFICIAL_ARTWORK = %w[sprites other official-artwork].freeze
    PLACEHOLDER_IMAGE = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/0.png'.freeze

    def name
      model.dig('forms', 0, 'name').to_s.capitalize
    end

    def num_pokedex
      model['id']
    end

    def height
      model['height']
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

  end
end
