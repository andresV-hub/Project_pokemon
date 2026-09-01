module Encounters
  # Empieza un encuentro salvaje: sortea una especie de la primera generación y
  # deja el estado listo para el primer turno.
  #
  # El estado vive en la sesión, no en base de datos: un encuentro es efímero y
  # no sobrevive a cerrar la pestaña, igual que en el juego.
  class Start < BaseService

    def initialize(trainer_pokemon:)
      @trainer_pokemon = trainer_pokemon
    end

    def service_execute
      wild = ::Pokeapi::FindPokemon.execute(id: rand(1..::Pokeapi::SearchPokemons::POKEDEX_LIMIT)).value
      description = wild && ::Pokeapi::FindDescription.execute(id: wild.num_pokedex).value
      return ServiceResult.new(error: :pokeapi_unavailable) if wild.nil? || description.nil?

      wild_hp = wild.stat_list.find { |stat| stat[:key] == 'hp' }&.dig(:value).to_i

      ServiceResult.new(value: {
        'num_pokedex' => wild.num_pokedex,
        'name' => wild.name,
        'capture_rate' => description.capture_rate.to_i,
        'wild_hp' => wild_hp,
        'wild_max_hp' => wild_hp,
        'balls' => Rules::MAX_BALLS,
        'trainer_pokemon_id' => @trainer_pokemon.id,
        'trainer_hp' => @trainer_pokemon.hp.to_i,
        'trainer_max_hp' => @trainer_pokemon.hp.to_i,
        'log' => ["A wild #{wild.name} appeared!"]
      })
    end

  end
end
