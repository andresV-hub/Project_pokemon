module Pokemons
  # Calcula cuánto daño recibe un Pokémon de cada tipo atacante, a partir de sus
  # propios tipos.
  #
  # Con dos tipos los factores **se multiplican**: un Grass/Poison recibe ×2 de
  # psychic por ser Poison y ×1 por ser Grass, pero ×4 de fire (×2 por Grass,
  # ×2 por Poison... según la tabla real de cada uno). Esa multiplicación es la
  # que produce los ×4 y los ×¼, y es el motivo de no quedarse con el tipo
  # primario.
  #
  #   Pokemons::TypeMatchup.execute(type_slugs: %w[grass poison]).value
  #   # => { "fire" => 2.0, "psychic" => 2.0, "water" => 0.5, ... }
  #
  # Sólo devuelve los tipos cuyo multiplicador es distinto de 1: el resto no
  # aporta información y ensuciaría la vista.
  class TypeMatchup < BaseService

    NEUTRAL = 1.0

    def initialize(type_slugs:)
      @type_slugs = Array(type_slugs).compact_blank
    end

    def service_execute
      multipliers = Hash.new(NEUTRAL)

      @type_slugs.each do |slug|
        relations = ::Pokeapi::FindType.execute(name: slug).value
        next if relations.nil?

        apply(multipliers, relations['double_damage_from'], 2.0)
        apply(multipliers, relations['half_damage_from'], 0.5)
        apply(multipliers, relations['no_damage_from'], 0.0)
      end

      ServiceResult.new(value: multipliers.reject { |_, factor| factor == NEUTRAL })
    end

    private

    def apply(multipliers, types, factor)
      Array(types).each do |type|
        name = type['name']
        multipliers[name] = multipliers[name] * factor
      end
    end

  end
end
