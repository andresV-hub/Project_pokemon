# Los DV de primera generación: lo que hace que dos Pokémon de la misma especie y
# el mismo nivel no tengan las mismas estadísticas.
#
# Se omitían, y esa omisión es la que obligó a inventar `HP_SCALE`. La fórmula del
# juego es:
#
#   HP    = ((2 × (Base + DV)) × Nivel) / 100 + Nivel + 10
#   Resto = ((2 × (Base + DV)) × Nivel) / 100 + 5
#
# Sin el DV salían **todas** las estadísticas bajas, y el HP proporcionalmente más
# que el ataque. El parche multiplicaba el HP por 1.5 para que los combates durasen
# más de un golpe, y acababa inflándolo un 40% por encima del juego: un Snorlax de
# nivel 50 tenía 330 puntos donde le tocaban 228.
#
# Son cuatro y no cinco a propósito: en primera generación el DV de HP **no se
# guarda**, se deriva del bit menos significativo de los otros cuatro. Guardarlo
# aparte permitiría combinaciones que el juego no puede producir.
class AddDeterminantValuesToPokemons < ActiveRecord::Migration[8.1]
  def change
    add_column :pokemons, :dv_attack, :integer
    add_column :pokemons, :dv_defense, :integer
    add_column :pokemons, :dv_speed, :integer
    add_column :pokemons, :dv_special, :integer
  end
end
