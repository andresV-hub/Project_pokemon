module Encounters
  # Resuelve un turno con movimientos de verdad: el jugador elige uno, el rival
  # responde con uno de los suyos al azar.
  #
  # Sustituye a `Encounters::Attack`, que golpeaba con una potencia fija de 40 y
  # calculaba la efectividad con el tipo del Pokémon en lugar del del movimiento.
  class ResolveTurn < BaseService

    def initialize(state:, trainer_pokemon:, wild:, move_index:)
      @state = state.dup
      @trainer_pokemon = trainer_pokemon
      @wild = wild
      @move_index = move_index.to_i
    end

    def service_execute
      log = []

      mine = own_moves[@move_index] || own_moves.first
      log.concat(strike(attacker: :own, move: mine))

      if @state['wild_hp'].positive?
        log.concat(strike(attacker: :rival, move: rival_moves.sample))
      else
        log << (@state['kind'] == 'trainer' ? "#{@state['name']} fainted!" : "#{@state['name']} fainted. It got away.")
        @state['over'] = 'wild_fainted'
      end

      if @state['trainer_hp'] <= 0
        log << "#{@trainer_pokemon.display_name} has no energy left!"
        @state['over'] = 'trainer_fainted'
      end

      @state['log'] = log
      ServiceResult.new(value: @state)
    end

    private

    def own_moves = Array(@state['own_moves'])

    def rival_moves = Array(@state['rival_moves'])

    def own_level = @state['trainer_level'].presence || @trainer_pokemon.level

    def rival_level = @state['level'].presence || own_level

    # Un turno: gasta PP, tira precisión y aplica daño.
    def strike(attacker:, move:)
      return [] if move.blank?

      own = attacker == :own
      name = own ? @trainer_pokemon.display_name : @state['name']
      lines = ["#{name} used #{move['label']}!"]

      spend_pp(move) if own

      unless Rules.hits?(move['accuracy'])
        lines << "#{name}'s attack missed!"
        return lines
      end

      factor = effectiveness(move['type'], own ? @wild.type_slugs : @trainer_pokemon.type_slugs)
      dealt = Rules.damage(
        attack: ::Pokemons::LevelStats.stat(offensive_stat(attacker, move), own ? own_level : rival_level),
        defense: ::Pokemons::LevelStats.stat(defensive_stat(attacker, move), own ? rival_level : own_level),
        effectiveness: factor,
        defender_max_hp: own ? @state['wild_max_hp'] : @state['trainer_max_hp'],
        level: own ? own_level : rival_level,
        power: move['power'],
        same_type: same_type?(attacker, move)
      )

      if own
        @state['wild_hp'] = [@state['wild_hp'] - dealt, 0].max
      else
        @state['trainer_hp'] = [@state['trainer_hp'] - dealt, 0].max
      end

      lines << "#{own ? @state['name'] : @trainer_pokemon.display_name} takes #{dealt} damage.#{note(factor)}"
      lines
    end

    # Los movimientos físicos usan ataque y defensa; los especiales, las
    # estadísticas especiales, que hasta ahora no entraban en el combate.
    def offensive_stat(attacker, move)
      special = move['damage_class'] == 'special'
      if attacker == :own
        special ? @trainer_pokemon.special_atack : @trainer_pokemon.atack
      else
        api_stat(@wild, special ? 'special-attack' : 'attack')
      end
    end

    def defensive_stat(attacker, move)
      special = move['damage_class'] == 'special'
      if attacker == :own
        api_stat(@wild, special ? 'special-defense' : 'defense')
      else
        special ? @trainer_pokemon.special_defense : @trainer_pokemon.defense
      end
    end

    def api_stat(pokemon, key)
      pokemon.stat_list.find { |stat| stat[:key] == key }&.dig(:value)
    end

    def same_type?(attacker, move)
      types = attacker == :own ? @trainer_pokemon.type_slugs : @wild.type_slugs
      types.include?(move['type'])
    end

    def spend_pp(move)
      index = own_moves.index { |candidate| candidate['name'] == move['name'] }
      return if index.nil?

      @state['own_moves'][index]['pp_left'] = [own_moves[index]['pp_left'].to_i - 1, 0].max
    end

    def effectiveness(attacking_type, defender_types)
      matchups = ::Pokemons::TypeMatchup.execute(type_slugs: defender_types).value || {}
      matchups.fetch(attacking_type, 1.0)
    end

    def note(factor)
      return " It's super effective!" if factor > 1
      return ' It has no effect…' if factor.zero?
      return " It's not very effective…" if factor < 1

      ''
    end

  end
end
