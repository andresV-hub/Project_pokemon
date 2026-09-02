module Encounters
  # Empieza un combate contra entrenador: uno a tres Pokémon que hay que derribar
  # en orden.
  #
  # A diferencia del salvaje, aquí no se captura. Contra un entrenador se lucha, y
  # lo que se saca es dinero.
  class StartTrainer < BaseService

    NAMES = ['Youngster', 'Lass', 'Bug Catcher', 'Hiker', 'Sailor', 'Camper',
             'Picnicker', 'Super Nerd'].freeze

    def initialize(trainer_pokemon:, party_size: 1)
      @trainer_pokemon = trainer_pokemon
      @party_size = party_size.to_i.clamp(1, Pokemon::PARTY_SIZE)
    end

    def service_execute
      team = build_team
      return ServiceResult.new(error: :pokeapi_unavailable) if team.empty?

      rival = NAMES.sample
      first = team.first
      own_hp = ::Pokemons::LevelStats.hp(@trainer_pokemon.hp, @trainer_pokemon.level)

      ServiceResult.new(value: {
        'kind' => 'trainer',
        'own_moves' => ::Pokemons::MoveSet.for_battle(num_pokedex: @trainer_pokemon.num_pokedex, level: @trainer_pokemon.level),
        'rival_moves' => first['moves'],
        'rival' => rival,
        'team' => team,
        'index' => 0,
        'reward' => Rules.trainer_reward,
        'name' => first['name'],
        'num_pokedex' => first['num_pokedex'],
        'wild_hp' => first['hp'],
        'wild_max_hp' => first['hp'],
        'level' => first['level'],
        'base_experience' => first['base_experience'],
        'trainer_pokemon_id' => @trainer_pokemon.id,
        'trainer_hp' => own_hp,
        'trainer_max_hp' => own_hp,
        'trainer_level' => @trainer_pokemon.level,
        'log' => ["#{rival} wants to battle!", "#{rival} sent out #{first['name']}!"]
      })
    end

    private

    def build_team
      reference = @trainer_pokemon.stat_list.sum { |stat| stat[:value].to_i }

      # El rival nunca lleva más de los que llevas tú. Medido: con un equipo de
      # tres contra rivales de uno a dos se ganaba el 100% de los combates, y con
      # el inicial solo contra rivales de dos se perdía casi siempre. Escalarlo
      # mantiene la tensión en los dos extremos.
      size = rand(1..[@party_size, Rules::TRAINER_TEAM_RANGE.max].min)

      size.times.filter_map do
        pokemon = DrawOpponent.execute(reference_total: reference).value
        next if pokemon.nil?

        level = Rules.rival_level(@trainer_pokemon.level)
        base_hp = pokemon.stat_list.find { |stat| stat[:key] == 'hp' }&.dig(:value).to_i

        {
          'num_pokedex' => pokemon.num_pokedex,
          'name' => pokemon.name,
          'level' => level,
          'base_experience' => pokemon.base_experience,
          'hp' => ::Pokemons::LevelStats.hp(base_hp, level),
          'moves' => ::Pokemons::MoveSet.for_battle(num_pokedex: pokemon.num_pokedex, level: level)
        }
      end
    end

  end
end
