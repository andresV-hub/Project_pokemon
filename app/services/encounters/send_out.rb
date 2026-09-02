module Encounters
  # Pone a un Pokémon en el campo y deja el estado listo para su turno.
  #
  # Lo comparten el relevo forzado —cuando el tuyo cae— y el cambio voluntario, que
  # son la misma operación con distinto motivo. Estaba escrito sólo en
  # `NextOwnPokemon`, y duplicarlo habría significado que un arreglo de la vida al
  # entrar valdría para un caso y no para el otro.
  module SendOut

    module_function

    # `state` se modifica en el sitio y se devuelve, para poder encadenarlo.
    def call(state, pokemon)
      # `hp` es la estadística base de la especie, no la vida que tiene: un
      # Bulbasaur de nivel 40 entraría con 45 puntos en vez de los 133 que le
      # tocan. Y entra con la vida que arrastra, que es de lo que va tener un
      # equipo y no sólo una lista.
      state['trainer_pokemon_id'] = pokemon.id
      state['trainer_hp'] = pokemon.current_hp
      state['trainer_max_hp'] = pokemon.max_hp

      # Entra limpio. Los escalones se pierden al salir del campo, como en el
      # juego; el estado alterado también, que es una simplificación consciente:
      # aquí no se guarda en la base de datos, así que dura lo que dura el Pokémon
      # en el campo y no lo que dura el combate.
      state['own_status'] = nil
      state['own_status_turns'] = 0
      state['own_stages'] = {}
      state.delete('over')

      state
    end

  end
end
