module Encounters
  # Resuelve un turno: golpeas tú y, si el salvaje sigue en pie, responde.
  #
  # Devuelve el estado actualizado con el registro de lo que ha pasado, para que
  # la vista sólo tenga que pintarlo.
  class Attack < BaseService

    def initialize(state:, trainer_pokemon:, wild:)
      @state = state.dup
      @trainer_pokemon = trainer_pokemon
      @wild = wild
    end

    def service_execute
      log = []

      log << hit_wild
      if @state['wild_hp'].positive?
        log << hit_trainer
      else
        # Un salvaje derribado se pierde; el de un entrenador simplemente cae y
        # deja paso al siguiente.
        log << if @state['kind'] == 'trainer'
          "#{@state['name']} fainted!"
        else
          "#{@state['name']} fainted. It got away."
        end
        @state['over'] = 'wild_fainted'
      end

      if @state['trainer_hp'] <= 0
        # Sin desenlace aquí: contra un entrenador puede quedar relevo, y quien
        # sabe si el combate acaba es quien mira el equipo.
        log << "#{@trainer_pokemon.display_name} has no energy left!"
        @state['over'] = 'trainer_fainted'
      end

      @state['log'] = log
      ServiceResult.new(value: @state)
    end

    private

    # Cuánto daño hace un tipo atacante contra los tipos del defensor: es el
    # matchup defensivo del defensor leído en el tipo del atacante (fase 2).
    def effectiveness(attacker_type, defender_types)
      matchups = ::Pokemons::TypeMatchup.execute(type_slugs: defender_types).value || {}
      matchups.fetch(attacker_type, 1.0)
    end

    def hit_wild
      factor = effectiveness(@trainer_pokemon.type_slug, @wild.type_slugs)
      damage = Rules.damage(attack: @trainer_pokemon.atack,
                            defense: defensive_stat(@wild),
                            effectiveness: factor,
                            defender_max_hp: @state['wild_max_hp'])
      @state['wild_hp'] = [@state['wild_hp'] - damage, 0].max

      "#{@trainer_pokemon.display_name} attacks! #{@state['name']} takes #{damage} damage.#{note(factor)}"
    end

    def hit_trainer
      factor = effectiveness(@wild.type_slug, @trainer_pokemon.type_slugs)
      damage = Rules.damage(attack: offensive_stat(@wild),
                            defense: @trainer_pokemon.defense,
                            effectiveness: factor,
                            defender_max_hp: @state['trainer_max_hp'])
      @state['trainer_hp'] = [@state['trainer_hp'] - damage, 0].max

      "#{@state['name']} strikes back! #{@trainer_pokemon.display_name} takes #{damage} damage."
    end

    def offensive_stat(pokemon)
      pokemon.stat_list.find { |stat| stat[:key] == 'attack' }&.dig(:value)
    end

    def defensive_stat(pokemon)
      pokemon.stat_list.find { |stat| stat[:key] == 'defense' }&.dig(:value)
    end

    def note(factor)
      return " It's super effective!" if factor > 1
      return ' It has no effect…' if factor.zero?
      return " It's not very effective…" if factor < 1

      ''
    end

  end
end
