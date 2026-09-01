# Nivel y experiencia. Hasta ahora todo se resolvía con las estadísticas base y
# un nivel ficticio igual para todos, así que capturar más Pokémon era la única
# forma de progresar y la dificultad se aplanaba en cuanto tenías tres.
class AddLevelToPokemons < ActiveRecord::Migration[8.1]

  STARTING_LEVEL = 5

  def up
    add_column :pokemons, :level, :integer, default: STARTING_LEVEL, null: false
    add_column :pokemons, :experience, :integer, default: 0, null: false

    # Los ya capturados arrancan en el nivel inicial con la experiencia que le
    # corresponde, para que no empiecen con la barra a cero debiendo un nivel.
    execute "UPDATE pokemons SET level = #{STARTING_LEVEL}, experience = #{STARTING_LEVEL**3}"
  end

  def down
    remove_column :pokemons, :level
    remove_column :pokemons, :experience
  end

end
