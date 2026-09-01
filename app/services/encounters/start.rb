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

    # Fuerza del Pokémon que va a combatir, para emparejar al rival con él.
    def reference_total
      @trainer_pokemon.stat_list.sum { |stat| stat[:value].to_i }
    end

    def service_execute
      wild = DrawOpponent.execute(reference_total: reference_total).value
      description = wild && ::Pokeapi::FindDescription.execute(id: wild.num_pokedex).value
      return ServiceResult.new(error: :pokeapi_unavailable) if wild.nil? || description.nil?

      level = Rules.rival_level(@trainer_pokemon.level)
      base_hp = wild.stat_list.find { |stat| stat[:key] == 'hp' }&.dig(:value).to_i
      wild_hp = ::Pokemons::LevelStats.hp(base_hp, level)
      own_hp = ::Pokemons::LevelStats.hp(@trainer_pokemon.hp, @trainer_pokemon.level)

      ServiceResult.new(value: {
        'num_pokedex' => wild.num_pokedex,
        'name' => wild.name,
        'capture_rate' => description.capture_rate.to_i,
        'level' => level,
        'base_experience' => wild.base_experience,
        'wild_hp' => wild_hp,
        'wild_max_hp' => wild_hp,
        'trainer_pokemon_id' => @trainer_pokemon.id,
        'trainer_hp' => own_hp,
        'trainer_max_hp' => own_hp,
        'trainer_level' => @trainer_pokemon.level,
        'log' => ["A wild #{wild.name} (Lv. #{level}) appeared!"]
      })
    end

  end
end
