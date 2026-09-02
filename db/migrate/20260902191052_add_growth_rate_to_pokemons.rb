# La curva de experiencia de cada especie.
#
# Hasta ahora todos los Pokémon usaban `n³`, que resulta ser **exactamente** la
# curva `medium` de los juegos: coincide al número —8.000 puntos para el nivel 20,
# 125.000 para el 50—. Pero cada especie tiene la suya, y la API la dice: Bulbasaur
# es `medium-slow` y llega a nivel 20 con un 32% menos de experiencia, mientras que
# Snorlax es `slow` y necesita un 25% más.
#
# Se deja nulo a propósito para los que ya existen. Al leerlo, un valor nulo cuenta
# como `medium`, que es justo lo que estaban usando: así ningún Pokémon capturado
# antes de este cambio se encuentra de pronto con que su experiencia corresponde a
# otro nivel. Un Snorlax con 8.000 puntos es de nivel 20 en la curva vieja y de
# nivel 18 en la suya, y verlo *bajar* de nivel sería exactamente el fallo que ya
# tuvimos una vez.
class AddGrowthRateToPokemons < ActiveRecord::Migration[8.1]
  def change
    add_column :pokemons, :growth_rate, :string
  end
end
