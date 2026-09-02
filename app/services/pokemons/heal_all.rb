module Pokemons
  # Restaura la vida de todos los Pokémon de un entrenador.
  #
  # Todos y no sólo los del equipo: en el juego el PC guarda a los Pokémon tal como
  # los dejaste, pero aquí el que está en el PC no combate, así que dejar a uno
  # herido allí sólo sería una tarea pendiente sin ninguna decisión detrás.
  #
  # Devuelve cuántos estaban heridos, para poder decir si el viaje sirvió de algo.
  class HealAll < BaseService

    def initialize(user:)
      @user = user
    end

    def service_execute
      hurt = @user.pokemon.where('damage > 0')
      healed = hurt.count
      hurt.update_all(damage: 0)

      ServiceResult.new(value: healed)
    end

  end
end
