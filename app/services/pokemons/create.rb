module Pokemons
  class Create < BaseService

  	def initialize(pokemon:, user:, description:, nickname:)
  		@pokemon = pokemon
  		@user = user
  		@description = description
  		@nickname = nickname
  	end

  	def service_execute
       pokemon = Pokemon.new(
       	name: @pokemon.name,
        nickname: @nickname,
        hp: @pokemon.stats(num: 0),
        atack: @pokemon.stats(num: 1),
        special_atack: @pokemon.stats(num: 2),
        defense: @pokemon.stats(num: 3),
        special_defense: @pokemon.stats(num: 4),
        speed: @pokemon.stats(num: 5),
        description: @description.description,
        atack0: @pokemon.attacks(num: 0),
        atack1: @pokemon.attacks(num: 2),
        atack2: @pokemon.attacks(num: 4),
        atack3: @pokemon.attacks(num: 6),
        user: @user,
        type_of_pokemon: @pokemon.type_of_pokemon,
        habitat: @description.habitat,
        capture_rate: @description.capture_rate,
        base_happiness: @description.base_happiness,
        num_pokedex: @pokemon.num_pokedex,
        image: @pokemon.image
       )
       pokemon.save!
    end

  end
end