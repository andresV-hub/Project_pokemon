# Hueco que ocupa el Pokémon en el equipo, de 1 a 6. `NULL` significa que está
# guardado en el PC, que es donde vive todo por defecto.
class AddPartyPositionToPokemons < ActiveRecord::Migration[8.1]

  def change
    add_column :pokemons, :party_position, :integer

    # Único por usuario: dos Pokémon no pueden ocupar el mismo hueco. En MySQL
    # un índice único admite varios NULL, así que el PC sigue pudiendo tener
    # tantos como haga falta.
    add_index :pokemons, %i[user_id party_position], unique: true
  end

end
