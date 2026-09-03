module Encounters
  # Resuelve un turno con movimientos de verdad: el jugador elige uno, el rival
  # responde con uno de los suyos al azar.
  #
  # Sustituye a `Encounters::Attack`, que golpeaba con una potencia fija de 40 y
  # calculaba la efectividad con el tipo del Pokémon en lugar del del movimiento.
  #
  # == Los movimientos que no hacen daño
  #
  # Un turno ya no es «los dos se pegan». Puede ser dormir al rival, subirse el
  # ataque, curarse o perder el turno por estar paralizado. Eso obliga a tres
  # cosas que antes no existían:
  #
  # * **Comprobar si se puede atacar** antes de atacar (`Statuses.blocked`).
  # * **Ramificar por clase de movimiento**: los de estado no pasan por la fórmula
  #   de daño en absoluto.
  # * **Cerrar el turno** con el desgaste del veneno y la quemadura, que ocurre
  #   después de que los dos hayan actuado.
  #
  # El estado alterado y los escalones de estadística viven en la sesión del
  # encuentro, no en la base de datos: se pierden al acabar el combate, como en
  # los juegos.
  class ResolveTurn < BaseService

    # `skip_own` resuelve el turno sin que el jugador ataque: es lo que pasa cuando
    # gasta su turno en usar un objeto. El rival responde igual, y el desgaste de
    # fin de turno y las comprobaciones de KO son las mismas, así que reutilizar
    # este servicio evita tener dos sitios donde vivan las reglas del combate.
    def initialize(state:, trainer_pokemon:, wild:, move_index:, skip_own: false)
      @state = state.dup
      @trainer_pokemon = trainer_pokemon
      @wild = wild
      @move_index = move_index.to_i
      @skip_own = skip_own
    end

    def service_execute
      log = []

      # Usando un objeto sólo actúa el rival, y le toca sí o sí: la iniciativa ya
      # se ha gastado en el objeto.
      actores = @skip_own ? [:rival] : turn_order
      actores.each do |actor|
        break unless both_standing?

        log.concat(take_turn(actor: actor, move: chosen_move(actor)))
      end
      log.concat(end_of_turn) if both_standing?
      log.concat(resolve_outcome)

      @state['log'] = log.compact
      ServiceResult.new(value: @state)
    end

    private

    # El movimiento guardado en la sesión sólo trae lo justo para pintar su botón
    # (`MoveSet::SESSION_FIELDS`). Lo que hace falta para resolver el turno
    # —potencia, precisión, estado que provoca, cambios de estadística— se pide
    # aquí, donde el caché lo sirve sin coste y sin ocupar la cookie.
    def hydrate(move)
      return ::Pokemons::MoveSet::STRUGGLE.merge(move) if move['name'] == ::Pokemons::MoveSet::STRUGGLE['name']

      full = ::Pokeapi::FindMove.execute(name: move['name']).value
      full ? full.merge('pp_left' => move['pp_left']) : move
    end

    def own_moves = Array(@state['own_moves'])

    def rival_moves = Array(@state['rival_moves'])

    def own_level = @state['trainer_level'].presence || @trainer_pokemon.level

    def rival_level = @state['level'].presence || own_level

    def both_standing? = @state['wild_hp'].to_i.positive? && @state['trainer_hp'].to_i.positive?

    def display_name(actor) = actor == :own ? @trainer_pokemon.display_name : @state['name']

    def chosen_move(actor)
      actor == :own ? (own_moves[@move_index] || own_moves.first) : rival_moves.sample
    end

    # Quién pega primero. Hasta ahora era siempre el jugador, lo que dejaba la
    # velocidad —y con ella Agility, y la mitad de lo que hace la parálisis— sin
    # ningún efecto sobre el combate: un movimiento que subía un número que nadie
    # miraba.
    #
    # Se resuelve el empate al azar en vez de dar la ventaja fija al jugador.
    def turn_order
      mine = speed_of(:own)
      theirs = speed_of(:rival)
      return %i[own rival].shuffle if mine == theirs

      mine > theirs ? %i[own rival] : %i[rival own]
    end

    def speed_of(actor)
      base = actor == :own ? @trainer_pokemon.speed : api_stat(@wild, 'speed')
      value = ::Pokemons::LevelStats.stat(base, actor == :own ? own_level : rival_level)
      value = ::Pokemons::StatStages.apply(value, stages_of(actor)['speed'])
      value = (value * Statuses::PARALYSIS_SPEED_FACTOR).round if status_of(actor) == 'paralysis'

      [value, 1].max
    end

    # --- Estado alterado en la sesión ---------------------------------------
    #
    # Las claves van por actor para que un relevo pueda limpiar sólo las suyas.

    def status_key(actor) = actor == :own ? 'own_status' : 'rival_status'

    def turns_key(actor) = actor == :own ? 'own_status_turns' : 'rival_status_turns'

    def stages_key(actor) = actor == :own ? 'own_stages' : 'rival_stages'

    def status_of(actor) = @state[status_key(actor)]

    def stages_of(actor) = @state[stages_key(actor)] ||= {}

    def other(actor) = actor == :own ? :rival : :own

    # --- El turno de uno ----------------------------------------------------

    def take_turn(actor:, move:)
      return [] if move.blank?

      move = hydrate(move)
      name = display_name(actor)

      # Dormido, congelado o paralizado se pierde el turno. Se comprueba antes de
      # anunciar el movimiento: en el juego no dices lo que ibas a hacer.
      blocked = Statuses.blocked(status: status_of(actor), turns: @state[turns_key(actor)])
      if blocked
        @state[status_key(actor)] = blocked[:status]
        @state[turns_key(actor)] = blocked[:turns]
        return ["#{name} #{blocked[:message]}"]
      end

      lines = ["#{name} used #{move['label']}!"]
      spend_pp(move) if actor == :own

      unless Rules.hits?(move['accuracy'])
        lines << "#{name}'s attack missed!"
        return lines
      end

      lines.concat(
        move['damage_class'] == 'status' ? apply_support(actor:, move:) : apply_damage(actor:, move:)
      )
      lines
    end

    # --- Movimientos que no hacen daño --------------------------------------

    def apply_support(actor:, move:)
      # Volver a lanzar un estado sobre quien ya lo tiene falla, y hay que
      # decirlo así: «nothing happened» es lo que hace Splash, y confundir las dos
      # cosas hace parecer roto un movimiento que funciona.
      if move['ailment'].present? && Statuses.supported?(move['ailment']) &&
         status_of(other(actor)).present?
        return ['But it failed!']
      end

      lines = []
      lines.concat(inflict_status(actor: actor, move: move, chance: 100))
      lines.concat(shift_stats(actor: actor, move: move))
      lines.concat(heal(actor: actor, move: move))

      # Splash, y cualquier movimiento cuyo efecto no sepamos aplicar todavía.
      # Decirlo es mejor que dejar el turno en silencio y que parezca roto.
      lines.presence || ['But nothing happened!']
    end

    # Aplica el estado al objetivo. Vale tanto para un movimiento de estado puro
    # —donde es seguro— como para el efecto secundario de uno ofensivo, que la
    # API da como `ailment_chance` (Thunder paraliza un 10% de las veces).
    def inflict_status(actor:, move:, chance: nil)
      ailment = move['ailment']
      return [] if ailment.blank? || !Statuses.supported?(ailment)

      probability = chance || move['ailment_chance'].to_i
      return [] unless probability.positive? && rand(1..100) <= probability

      target = other(actor)
      # Un estado no sustituye a otro: en el juego no puedes envenenar a quien ya
      # duerme, y encadenarlos sería un combate ganado con un solo movimiento.
      return [] if status_of(target).present?

      if blocked_status?(target, ailment)
        return ["#{display_name(target)}'s #{::Pokemons::Abilities.label(ability_of(target))} prevents it!"]
      end

      @state[status_key(target)] = ailment
      @state[turns_key(target)] = Statuses.turns_for(ailment)

      ["#{display_name(target)} #{Statuses.applied_message(ailment)}"]
    end

    # Los cambios de estadística de la API vienen con signo: negativo es contra el
    # rival —Growl baja su ataque— y positivo sobre uno mismo —Swords Dance sube
    # el propio—. Es la convención de la primera generación y se cumple sin
    # excepciones en su catálogo.
    def shift_stats(actor:, move:)
      Array(move['stat_changes']).filter_map do |change|
        amount = change['change'].to_i
        next if amount.zero?

        target = amount.positive? ? actor : other(actor)

        # Hyper Cutter, Keen Eye, Clear Body: a su dueño no se le baja. Sólo
        # protege de lo que le hacen, no de lo que se hace él mismo.
        if amount.negative? && ::Pokemons::Abilities.guards_stat?(ability_of(target), change['stat'])
          next "#{display_name(target)}'s #{::Pokemons::Abilities.label(ability_of(target))} prevents it!"
        end

        stages = stages_of(target)
        updated, moved = ::Pokemons::StatStages.add(stages[change['stat']], amount)
        stages[change['stat']] = updated

        if moved
          "#{display_name(target)}'s #{::Pokemons::StatStages.message(change['stat'], amount)}"
        else
          "#{display_name(target)}'s #{change['stat'].to_s.tr('-', ' ')} won't go any #{amount.positive? ? 'higher' : 'lower'}!"
        end
      end
    end

    # `healing` llega como porcentaje de la vida máxima: Recover cura 50.
    def heal(actor:, move:)
      percent = move['healing'].to_i
      return [] unless percent.positive?

      max = actor == :own ? @state['trainer_max_hp'].to_i : @state['wild_max_hp'].to_i
      current = actor == :own ? @state['trainer_hp'].to_i : @state['wild_hp'].to_i
      return ["#{display_name(actor)}'s HP is already full!"] if current >= max

      restored = [(max * percent / 100.0).round, max - current].min
      write_hp(actor, current + restored)

      ["#{display_name(actor)} regained health!"]
    end

    # --- Movimientos que sí hacen daño --------------------------------------

    def apply_damage(actor:, move:)
      own = actor == :own
      target = other(actor)

      # La habilidad del que recibe puede anular el golpe entero, y en dos casos
      # además curarle. Se comprueba antes de calcular nada: si es inmune, no hay
      # daño que repartir ni efecto secundario que aplicar.
      blocked = absorb_if_immune(target: target, move: move)
      return blocked if blocked

      factor = effectiveness(move['type'], own ? @wild.type_slugs : @trainer_pokemon.type_slugs)
      factor *= ::Pokemons::Abilities::THICK_FAT_FACTOR if
        ::Pokemons::Abilities.thick_fat?(ability_of(target), move['type'])

      # Overgrow, Blaze, Torrent y Swarm: con un tercio de vida o menos, los
      # movimientos de su tipo pegan un 50% más. Va sobre el ataque y no sobre la
      # efectividad porque es lo que hace el juego, y así no se confunde con una
      # ventaja de tipo en el registro.
      atacante = offensive_value(actor, move)
      if ::Pokemons::Abilities.pinch_boost?(ability_of(actor), move['type'], current_hp(actor),
                                            actor == :own ? @state['trainer_max_hp'] : @state['wild_max_hp'])
        atacante = (atacante * ::Pokemons::Abilities::PINCH_FACTOR).round
      end

      golpe = Rules.damage(
        attack: atacante,
        defense: defensive_value(actor, move),
        effectiveness: factor,
        defender_max_hp: own ? @state['wild_max_hp'] : @state['trainer_max_hp'],
        level: own ? own_level : rival_level,
        power: move['power'],
        same_type: same_type?(actor, move),
        # La velocidad **base** de la especie, no la del nivel: en primera
        # generación es lo que decide la probabilidad de crítico.
        base_speed: base_speed_of(actor)
      )
      dealt = golpe[:amount]

      write_hp(target, current_hp(target) - dealt)

      lines = []
      # El crítico se anuncia antes del daño, como en el juego: primero pasa, luego
      # se ve cuánto. Sin decirlo, un golpe que quita el triple parece un fallo.
      lines << 'A critical hit!' if golpe[:critical]
      lines << "#{display_name(target)} takes #{dealt} damage.#{note(factor)}"

      # Un movimiento inmune por tipo no envenena ni paraliza: si no llegó a
      # tocarle, no le hizo nada.
      if factor.positive?
        lines.concat(drain(actor: actor, move: move, dealt: dealt))
        lines.concat(inflict_status(actor: actor, move: move))
        lines.concat(contact_effect(attacker: actor, move: move))
      end
      lines
    end

    # Static, Poison Point y Flame Body: tocar a su dueño sale caro. Sólo con
    # movimientos físicos, que es lo que significa «por contacto».
    def contact_effect(attacker:, move:)
      return [] unless move['damage_class'] == 'physical'

      defender = other(attacker)
      status = ::Pokemons::Abilities.contact_status(ability_of(defender))
      return [] if status.blank?
      return [] unless rand(1..100) <= ::Pokemons::Abilities::CONTACT_CHANCE
      return [] if status_of(attacker).present? || blocked_status?(attacker, status)

      @state[status_key(attacker)] = status
      @state[turns_key(attacker)] = Statuses.turns_for(status)

      ["#{display_name(defender)}'s #{::Pokemons::Abilities.label(ability_of(defender))}!",
       "#{display_name(attacker)} #{Statuses.applied_message(status)}"]
    end

    # Levitate, Water Absorb, Volt Absorb y Flash Fire.
    def absorb_if_immune(target:, move:)
      ability = ability_of(target)
      return nil unless ::Pokemons::Abilities.immune_type(ability) == move['type']

      lines = ["#{display_name(target)}'s #{::Pokemons::Abilities.label(ability)}!"]

      if ::Pokemons::Abilities.absorbs?(ability)
        max = target == :own ? @state['trainer_max_hp'].to_i : @state['wild_max_hp'].to_i
        curado = [(max / ::Pokemons::Abilities::ABSORB_FRACTION.to_f).round, max - current_hp(target)].min
        if curado.positive?
          write_hp(target, current_hp(target) + curado)
          lines << "#{display_name(target)} absorbed the attack and regained health!"
          return lines
        end
      end

      lines << "It doesn't affect #{display_name(target)}…"
      lines
    end

    # Limber, Immunity, Insomnia y compañía.
    def blocked_status?(actor, status)
      ::Pokemons::Abilities.blocks_status?(ability_of(actor), status)
    end

    def drain(actor:, move:, dealt:)
      percent = move['drain'].to_i
      return [] unless percent.positive? && dealt.positive?

      max = actor == :own ? @state['trainer_max_hp'].to_i : @state['wild_max_hp'].to_i
      restored = [(dealt * percent / 100.0).round, max - current_hp(actor)].min
      return [] unless restored.positive?

      write_hp(actor, current_hp(actor) + restored)
      ["#{display_name(actor)} drained health!"]
    end

    # --- Cierre del turno ---------------------------------------------------

    # El veneno y la quemadura desgastan cuando los dos ya han actuado, no en
    # mitad del intercambio.
    def end_of_turn
      lineas = shed_skin
      lineas + %i[own rival].filter_map do |actor|
        status = status_of(actor)
        max = actor == :own ? @state['trainer_max_hp'] : @state['wild_max_hp']
        dealt = Statuses.residual_damage(status: status, max_hp: max)
        next if dealt.zero?

        write_hp(actor, current_hp(actor) - dealt)
        "#{display_name(actor)} #{Statuses.residual_message(status)}"
      end
    end

    # Shed Skin: se quita el estado solo de vez en cuando.
    def shed_skin
      %i[own rival].filter_map do |actor|
        next unless ability_of(actor).to_s == ::Pokemons::Abilities::SHED_SKIN
        next if status_of(actor).blank?
        next unless rand < ::Pokemons::Abilities::SHED_SKIN_CHANCE

        @state[status_key(actor)] = nil
        @state[turns_key(actor)] = 0
        "#{display_name(actor)}'s Shed Skin cured its status!"
      end
    end

    def resolve_outcome
      lines = []

      if @state['wild_hp'].to_i <= 0
        lines << (@state['kind'] == 'trainer' ? "#{@state['name']} fainted!" : "#{@state['name']} fainted. It got away.")
        @state['over'] = 'wild_fainted'
      end

      # Se comprueba después, y sin `elsif`: si los dos caen en el mismo turno
      # —el veneno puede rematar a quien acaba de ganar— pierde el jugador, como
      # en el juego.
      if @state['trainer_hp'].to_i <= 0
        lines << "#{@trainer_pokemon.display_name} has no energy left!"
        @state['over'] = 'trainer_fainted'
      end

      lines
    end

    # --- Vida y estadísticas ------------------------------------------------

    def current_hp(actor) = actor == :own ? @state['trainer_hp'].to_i : @state['wild_hp'].to_i

    def write_hp(actor, value)
      key = actor == :own ? 'trainer_hp' : 'wild_hp'
      max = actor == :own ? @state['trainer_max_hp'].to_i : @state['wild_max_hp'].to_i

      @state[key] = value.clamp(0, max)
    end

    # Los movimientos físicos usan ataque y defensa; los especiales, las
    # estadísticas especiales.
    def offensive_stat(actor, move)
      special = move['damage_class'] == 'special'
      if actor == :own
        special ? @trainer_pokemon.special_atack : @trainer_pokemon.atack
      else
        api_stat(@wild, special ? 'special-attack' : 'attack')
      end
    end

    def defensive_stat(actor, move)
      special = move['damage_class'] == 'special'
      if actor == :own
        api_stat(@wild, special ? 'special-defense' : 'defense')
      else
        special ? @trainer_pokemon.special_defense : @trainer_pokemon.defense
      end
    end

    # El valor que entra en la fórmula: la estadística al nivel, corregida por los
    # escalones que se hayan ganado o perdido en este combate y, si está quemado,
    # por la mitad de ataque que trae la quemadura.
    def offensive_value(actor, move)
      key = move['damage_class'] == 'special' ? 'special-attack' : 'attack'
      base = ::Pokemons::LevelStats.stat(offensive_stat(actor, move), actor == :own ? own_level : rival_level,
                                         dv_of(actor, move['damage_class'] == 'special' ? 'special' : 'attack'))
      value = ::Pokemons::StatStages.apply(base, stages_of(actor)[key])

      # Guts convierte el estado alterado en ventaja, y de paso cancela la rebaja
      # de la quemadura: es lo que la hace interesante y no un simple bonus.
      if ability_of(actor).to_s == ::Pokemons::Abilities::GUTS && status_of(actor).present?
        value = (value * ::Pokemons::Abilities::GUTS_FACTOR).round
      elsif status_of(actor) == 'burn' && key == 'attack'
        value = (value * Statuses::BURN_ATTACK_FACTOR).round
      end

      [value, 1].max
    end

    def defensive_value(actor, move)
      target = other(actor)
      key = move['damage_class'] == 'special' ? 'special-defense' : 'defense'
      base = ::Pokemons::LevelStats.stat(defensive_stat(actor, move), actor == :own ? rival_level : own_level,
                                         dv_of(target, move['damage_class'] == 'special' ? 'special' : 'defense'))

      ::Pokemons::StatStages.apply(base, stages_of(target)[key])
    end

    # El DV que toca. Los del jugador salen de su fila; los del rival se sortearon
    # al aparecer y viajan en el estado del encuentro, porque un rival salvaje no
    # tiene fila donde guardarlos y tienen que ser los mismos durante todo el
    # combate.
    #
    # En primera generación **una sola estadística especial** cubre ataque y
    # defensa especiales, así que las dos comparten DV.
    def dv_of(actor, key)
      if actor == :own
        @trainer_pokemon.dv(key)
      else
        Hash(@state['rival_dv'])[key].to_i
      end
    end

    def ability_of(actor)
      actor == :own ? @trainer_pokemon.ability : @state['rival_ability']
    end

    # Velocidad base de la especie. La del jugador está en su fila; la del rival,
    # en la respuesta de la API.
    def base_speed_of(actor)
      actor == :own ? @trainer_pokemon.speed : api_stat(@wild, 'speed')
    end

    def api_stat(pokemon, key)
      pokemon.stat_list.find { |stat| stat[:key] == key }&.dig(:value)
    end

    def same_type?(actor, move)
      types = actor == :own ? @trainer_pokemon.type_slugs : @wild.type_slugs
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
