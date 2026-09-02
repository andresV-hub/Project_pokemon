module Pokemons
  # Resuelve la pregunta de qué movimiento se olvida.
  #
  # `slot` es el hueco que se sacrifica (0-3), o cualquier otra cosa para no
  # aprenderlo. Decir que no es una respuesta válida en el juego y aquí también:
  # un movimiento nuevo no siempre es mejor que los cuatro que ya tienes.
  class ResolvePendingMove < BaseService

    def initialize(pokemon:, slot:)
      @pokemon = pokemon
      @slot = slot
    end

    def service_execute
      nuevo = @pokemon.pending_move
      return ServiceResult.new(value: nil) if nuevo.blank?

      indice = Integer(@slot, exception: false)

      if indice.nil? || !indice.between?(0, MoveSet::SLOTS - 1)
        @pokemon.update!(pending_move: nil)
        return ServiceResult.new(value: { outcome: :declined, learned: nuevo })
      end

      olvidado = @pokemon.public_send("atack#{indice}")
      @pokemon.public_send("atack#{indice}=", nuevo)
      @pokemon.update!(pending_move: nil)

      # Se devuelven los dos nombres porque los dos hacen falta para contarlo, y
      # después de guardar ya no se pueden recuperar del objeto.
      ServiceResult.new(value: { outcome: :forgotten, forgot: olvidado, learned: nuevo })
    end

  end
end
