module Pokemons
  class ComparePokemonUseCase < BaseService

    def initialize(pokemon1:, pokemon_api:)
      @pokemon1 = pokemon1
      @pokemon_api = pokemon_api
    end

    def service_execute

      hp = ::Pokemons::CompareStat.execute(my_stat: @pokemon1.hp, your_stat: @pokemon_api.stats(num: 0))
      attack = ::Pokemons::CompareStat.execute(my_stat: @pokemon1.atack, your_stat: @pokemon_api.stats(num: 1))
      special_attack = ::Pokemons::CompareStat.execute(my_stat: @pokemon1.special_atack, your_stat: @pokemon_api.stats(num: 2))
      defense = ::Pokemons::CompareStat.execute(my_stat: @pokemon1.defense, your_stat: @pokemon_api.stats(num: 3))
      special_defense = ::Pokemons::CompareStat.execute(my_stat: @pokemon1.special_defense, your_stat: @pokemon_api.stats(num: 4))
      speed = ::Pokemons::CompareStat.execute(my_stat: @pokemon1.speed, your_stat: @pokemon_api.stats(num: 5))
      
      winner=hp+attack+special_attack+defense+special_defense+speed
      return [hp,attack,special_attack,defense,special_defense,speed,winner]

    end

  end
end