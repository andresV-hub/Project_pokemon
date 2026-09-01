module ApplicationHelper

  # Multiplicadores de daño con la notación de la franquicia: las fracciones se
  # escriben ½ y ¼, no 0.5 y 0.25 (styles.md §6.17).
  MULTIPLIER_LABELS = { 0.0 => '×0', 0.25 => '×¼', 0.5 => '×½', 2.0 => '×2', 4.0 => '×4' }.freeze

  def type_multiplier_label(factor)
    MULTIPLIER_LABELS.fetch(factor.to_f) { "×#{(factor % 1).zero? ? factor.to_i : factor}" }
  end

  # Agrupa el resultado de `Pokemons::TypeMatchup` en los tres bloques que se
  # muestran, cada uno ordenado de mayor a menor efecto.
  def group_matchups(matchups)
    {
      weaknesses: matchups.select { |_, factor| factor > 1 }.sort_by { |_, factor| -factor },
      resistances: matchups.select { |_, factor| factor.positive? && factor < 1 }.sort_by { |_, factor| factor },
      immunities: matchups.select { |_, factor| factor.zero? }.sort_by(&:first)
    }
  end

end
