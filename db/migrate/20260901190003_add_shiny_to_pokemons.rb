# Marca de variocolor. Se decide en el momento de la captura y no vuelve a
# cambiar, así que es una columna del Pokémon y no un cálculo de presentación.
class AddShinyToPokemons < ActiveRecord::Migration[8.1]

  def change
    add_column :pokemons, :shiny, :boolean, default: false, null: false
  end

end
