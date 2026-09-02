module Encounters
  # Empieza un encuentro salvaje: sortea una especie de la primera generación y
  # deja el estado listo para el primer turno.
  #
  # El estado vive en la sesión, no en base de datos: un encuentro es efímero y
  # no sobrevive a cerrar la pestaña, igual que en el juego.
  class Start < BaseService

    def initialize(trainer_pokemon:, zone_key: nil)
      @trainer_pokemon = trainer_pokemon
      @zone_key = zone_key
    end

    def service_execute
      draw = DrawFromZone.execute(zone_key: @zone_key).value
      return ServiceResult.new(error: :pokeapi_unavailable) if draw.nil?

      wild = draw[:pokemon]
      # El nivel lo pone la zona, no el jugador. Es lo que hace que ir a la Cueva
      # Celeste con un equipo de nivel 20 sea una mala idea y no un trámite
      # escalado a tu medida.
      level = draw[:level]
      zone = draw[:zone]

      description = ::Pokeapi::FindDescription.execute(id: wild.num_pokedex).value
      return ServiceResult.new(error: :pokeapi_unavailable) if description.nil?
      base_hp = wild.stat_list.find { |stat| stat[:key] == 'hp' }&.dig(:value).to_i
      wild_hp = ::Pokemons::LevelStats.hp(base_hp, level)
      # Con la vida que traiga, no a tope: desde que el daño se guarda, salir a
      # explorar con el equipo tocado es una decisión y no un trámite.
      own_max = @trainer_pokemon.max_hp
      own_hp = @trainer_pokemon.current_hp

      ServiceResult.new(value: {
        'own_moves' => ::Pokemons::MoveSet.for_battle(num_pokedex: @trainer_pokemon.num_pokedex,
                                                     level: @trainer_pokemon.level,
                                                     known: @trainer_pokemon.move_names),
        'rival_moves' => ::Pokemons::MoveSet.for_battle(num_pokedex: wild.num_pokedex, level: level),
        'num_pokedex' => wild.num_pokedex,
        'name' => wild.name,
        # El valor crudo de la API, de 0 a 255: es el que usa la fórmula del juego.
        # El porcentaje se sigue enseñando en la ficha, pero convertir y volver
        # perdía precisión justo en las especies difíciles.
        'capture_rate' => description.raw_capture_rate.to_i,
        'level' => level,
        'base_experience' => wild.base_experience,
        'wild_hp' => wild_hp,
        'wild_max_hp' => wild_hp,
        'trainer_pokemon_id' => @trainer_pokemon.id,
        'trainer_hp' => own_hp,
        'trainer_max_hp' => own_max,
        'trainer_level' => @trainer_pokemon.level,
        'zone' => zone[:key],
        'zone_name' => zone[:name],
        'log' => ["A wild #{wild.name} (Lv. #{level}) appeared!"]
      })
    end

  end
end
