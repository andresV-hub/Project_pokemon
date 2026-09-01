# Corrige los Pokémon capturados con `Pokemons::Create` antes de que leyera las
# estadísticas por clave.
#
# La PokeAPI devuelve el array `stats` en el orden hp, attack, defense,
# special-attack, special-defense, speed. El servicio cogía la posición 2 para
# `special_atack` y la 3 para `defense`, así que todas las filas existentes
# tienen esas dos columnas intercambiadas.
#
# OJO: el intercambio NO es idempotente. Ejecutarlo dos veces deja los datos como
# estaban. Rails no repite una migración ya aplicada, pero conviene saberlo antes
# de replicar esto a mano en otra base de datos.
#
# El intercambio se hace en Ruby y no con un UPDATE de dos asignaciones porque
# MySQL evalúa el SET de izquierda a derecha usando los valores ya escritos: un
# `SET defense = special_atack, special_atack = defense` dejaría las dos columnas
# con el mismo valor.
class FixSwappedDefenseAndSpecialAttack < ActiveRecord::Migration[8.1]

  # Modelo mínimo y aislado: la migración no debe depender de la clase Pokemon
  # de la aplicación, que puede cambiar (validaciones, callbacks, asociaciones).
  class MigrationPokemon < ActiveRecord::Base
    self.table_name = 'pokemons'
  end

  def up
    swap_columns
  end

  # Revertir es volver a intercambiarlas: la operación es su propia inversa.
  def down
    swap_columns
  end

  private

  def swap_columns
    MigrationPokemon.reset_column_information

    total = 0
    MigrationPokemon.find_each do |pokemon|
      pokemon.update_columns(
        defense: pokemon.special_atack,
        special_atack: pokemon.defense
      )
      total += 1
    end

    say "Intercambiadas `defense` y `special_atack` en #{total} pokémon"
  end

end
