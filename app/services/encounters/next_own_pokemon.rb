module Encounters
  # Cuando tu Pokémon cae, sale el siguiente del equipo. Sólo cuando no queda
  # ninguno se pierde el combate.
  #
  # Sin esto, un entrenador con dos o tres Pokémon era casi invencible: tu único
  # combatiente los encadenaba sin recuperar vida. Medido, se ganaba uno de cada
  # seis. Además es lo que da sentido a tener un equipo de seis y no uno solo.
  class NextOwnPokemon < BaseService

    def initialize(state:, user:)
      @state = state.dup
      @user = user
    end

    def service_execute
      following = remaining.first

      if following.nil?
        @state['over'] = 'trainer_fainted'
        @state['log'] += ['You have no Pokémon left. You flee.']
      else
        @state['fainted'] = Array(@state['fainted']) + [@state['trainer_pokemon_id']]
        @state['trainer_pokemon_id'] = following.id
        # `hp` es la estadística base de la especie, no la vida que tiene: un
        # Bulbasaur de nivel 40 entraba al relevo con 45 puntos en vez de los 133
        # que le tocan, y caía de un golpe. Y entra con la vida que arrastra, que
        # es de lo que va tener un equipo y no sólo una lista.
        @state['trainer_hp'] = following.current_hp
        @state['trainer_max_hp'] = following.max_hp
        # Entra descansado: el estado alterado y los escalones eran del que cayó.
        @state['own_status'] = nil
        @state['own_status_turns'] = 0
        @state['own_stages'] = {}
        @state.delete('over')
        @state['log'] += ["Go, #{following.nickname}!"]
      end

      ServiceResult.new(value: @state)
    end

    private

    # Los del equipo que pueden seguir peleando: ni han caído en este combate ni
    # venían ya debilitados de antes.
    def remaining
      down = Array(@state['fainted']) + [@state['trainer_pokemon_id']]
      @user.pokemon.in_party.reject { |pokemon| down.include?(pokemon.id) || pokemon.fainted? }
    end

  end
end
