# Registro de qué especies ha visto cada usuario. Es estado propio de la
# aplicación, no viene de la PokeAPI: una Pokédex se completa a base de
# encontrarse Pokémon, y sin esta tabla el catálogo es un listado igual para
# todo el mundo.
class CreatePokedexSightings < ActiveRecord::Migration[8.1]

  def change
    create_table :pokedex_sightings do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :num_pokedex, null: false

      t.timestamps
    end

    # Un avistamiento por especie y usuario: el alta se hace en cada visita a la
    # ficha, así que el índice es lo que la vuelve idempotente.
    add_index :pokedex_sightings, %i[user_id num_pokedex], unique: true
  end

end
