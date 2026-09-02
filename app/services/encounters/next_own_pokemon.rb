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
        SendOut.call(@state, following)
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
