json.data @pokemons do |pokemon|
  json.partial! 'api/v1/pokedex/pokemon', pokemon: pokemon, description: @descriptions[pokemon.num_pokedex]
end

json.meta { json.partial! 'api/v1/pagination', paginator: @pokemons }
