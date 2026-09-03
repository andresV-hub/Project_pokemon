# La habilidad del Pokémon.
#
# Las habilidades **no son de primera generación** —llegaron en la tercera— y se
# incorporan por decisión de producto, no por descuido. La API las trae en cada
# consulta de `/pokemon/{id}` y se ignoraban por completo.
#
# Se guarda la de la primera ranura y nunca una oculta: las ocultas llegaron aún
# más tarde y en varias especies son claramente mejores, así que darlas al azar
# convertiría la captura en una lotería con premio.
class AddAbilityToPokemons < ActiveRecord::Migration[8.1]
  def change
    add_column :pokemons, :ability, :string
  end
end
