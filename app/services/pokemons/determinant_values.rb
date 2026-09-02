module Pokemons
  # Los DV de primera generación: cuatro números de 0 a 15 que hacen que dos
  # Pokémon de la misma especie y nivel no sean idénticos.
  #
  # El de HP no se guarda porque en el juego **no existe como dato propio**: se
  # arma con el bit menos significativo de los otros cuatro. Guardarlo aparte
  # permitiría combinaciones que el juego no puede producir —un HP perfecto con
  # cuatro estadísticas pares, por ejemplo—, y ese detalle es justo lo que hace que
  # un Pokémon con DV 15 en todo sea tan raro.
  module DeterminantValues

    MAX = 15
    KEYS = %w[attack defense speed special].freeze

    module_function

    def random
      KEYS.index_with { rand(0..MAX) }
    end

    # El DV de HP a partir de los otros cuatro, como en el juego.
    def hp_from(attack:, defense:, speed:, special:)
      ((attack.to_i & 1) << 3) | ((defense.to_i & 1) << 2) |
        ((speed.to_i & 1) << 1) | (special.to_i & 1)
    end

  end
end
