json.data @pokemons, partial: 'api/v1/pokemons/pokemon', as: :pokemon
json.meta { json.partial! 'api/v1/pagination', paginator: @pokemons }
