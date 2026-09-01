json.id              pokemon.id
json.name            pokemon.name
json.nickname        pokemon.nickname
json.num_pokedex     pokemon.num_pokedex
json.type_of_pokemon pokemon.type_of_pokemon
json.habitat         pokemon.habitat
json.capture_rate    pokemon.capture_rate
json.base_happiness  pokemon.base_happiness
json.description     pokemon.description
json.image           pokemon.image

json.stats do
  json.hp              pokemon.hp
  json.attack          pokemon.atack
  json.special_attack  pokemon.special_atack
  json.defense         pokemon.defense
  json.special_defense pokemon.special_defense
  json.speed           pokemon.speed
end

json.attacks [pokemon.atack0, pokemon.atack1, pokemon.atack2, pokemon.atack3].compact
