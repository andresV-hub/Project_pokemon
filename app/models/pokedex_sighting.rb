# Una especie que el usuario ya se ha encontrado. Ver la ficha de un Pokémon
# cuenta como avistamiento; capturarlo lo implica.
class PokedexSighting < ApplicationRecord

  belongs_to :user

  validates :num_pokedex, presence: true,
                          uniqueness: { scope: :user_id },
                          numericality: { only_integer: true, greater_than: 0 }

end
