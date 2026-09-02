# El daño que arrastra un Pokémon fuera del combate.
#
# Hasta ahora la vida sólo existía dentro del encuentro, en la sesión, y se
# restauraba sola y gratis al salir. Perder no costaba nada, así que el dinero no
# servía para nada salvo comprar bolas y las pociones no habrían tenido sentido:
# nunca habrían hecho falta.
#
# Se guarda el **daño acumulado** y no la vida actual. Con la vida actual, subir de
# nivel —que aumenta el máximo— habría dejado a un Pokémon con menos vida de la que
# le corresponde, o con más de la que puede tener si el máximo bajase. Con el daño,
# subir de nivel sube el máximo y la vida actual a la vez, que es lo que hacen los
# juegos, y el valor por defecto —cero— significa «sano» sin necesidad de rellenar
# los que ya existen.
class AddDamageToPokemons < ActiveRecord::Migration[8.1]
  def change
    add_column :pokemons, :damage, :integer, default: 0, null: false
  end
end
