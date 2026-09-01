json.id              pokemon.num_pokedex
json.num_pokedex     pokemon.num_pokedex
json.name            pokemon.name
json.height          pokemon.height
json.type_of_pokemon pokemon.type_of_pokemon
json.specie          pokemon.specie
json.image           pokemon.image
json.image_shiny     pokemon.image_shiny

json.stats do
  json.hp              pokemon.stats(num: 0)
  json.attack          pokemon.stats(num: 1)
  json.special_attack  pokemon.stats(num: 2)
  json.defense         pokemon.stats(num: 3)
  json.special_defense pokemon.stats(num: 4)
  json.speed           pokemon.stats(num: 5)
end

if defined?(description) && description
  json.description do
    json.text           description.description
    json.habitat        description.habitat
    json.capture_rate   description.capture_rate
    json.base_happiness description.base_happiness
  end
else
  json.description nil
end
