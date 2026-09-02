# El movimiento que un Pokémon está a punto de aprender y todavía no ha aprendido.
#
# Con los cuatro huecos llenos, el juego **pregunta** cuál olvidar. Esa pregunta no
# se puede responder en el mismo instante en que se sube de nivel —ocurre a mitad
# de un turno de combate—, así que la elección queda pendiente y se resuelve
# después, en su propia pantalla.
#
# Se guarda en el Pokémon y no en la sesión a propósito: si viviera en la sesión,
# cerrar la pestaña haría desaparecer un movimiento que el Pokémon ya se había
# ganado.
class AddPendingMoveToPokemons < ActiveRecord::Migration[8.1]
  def change
    add_column :pokemons, :pending_move, :string
  end
end
