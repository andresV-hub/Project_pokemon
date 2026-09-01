module Encounters
  # Tras derribar a un Pokémon del entrenador, saca al siguiente. Si no queda
  # ninguno, el combate está ganado y se paga el premio.
  #
  # El pago se hace aquí y no en el controlador para que ganar y cobrar sean la
  # misma operación: no puede quedarse a medias.
  class NextOpponent < BaseService

    def initialize(state:, user:)
      @state = state.dup
      @user = user
    end

    def service_execute
      @state['index'] = @state['index'].to_i + 1
      following = Array(@state['team'])[@state['index']]

      following ? send_next(following) : win

      ServiceResult.new(value: @state)
    end

    private

    def send_next(pokemon)
      @state['name'] = pokemon['name']
      @state['num_pokedex'] = pokemon['num_pokedex']
      @state['wild_hp'] = pokemon['hp']
      @state['wild_max_hp'] = pokemon['hp']
      @state['level'] = pokemon['level']
      @state['base_experience'] = pokemon['base_experience']
      @state['rival_moves'] = pokemon['moves']
      @state.delete('over')
      @state['log'] += ["#{@state['rival']} sent out #{pokemon['name']} (Lv. #{pokemon['level']})!"]
    end

    def win
      reward = @state['reward'].to_i
      @user.increment!(:money, reward)

      @state['over'] = 'trainer_defeated'
      @state['log'] += ["You defeated #{@state['rival']}!", "You earned ₽#{reward}."]
    end

  end
end
