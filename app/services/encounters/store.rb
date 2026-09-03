module Encounters
  # Dónde vive el estado del encuentro.
  #
  # Estuvo en la cookie de sesión, y no cabía. La cookie son 4 KB y el estado
  # guarda dos equipos con sus movimientos: **desbordó dos veces**. La primera se
  # arregló adelgazando lo que se guardaba de cada movimiento, y aun así volvió a
  # pasar en cuanto el combate ganó estados, DV, habilidades y zona. Cada mejora
  # del combate acercaba el siguiente desbordamiento, que además revienta en la
  # cara del jugador a mitad de partida.
  #
  # Ahora vive en el caché, que aquí es Solid Cache y por tanto la base de datos.
  # Deja de haber límite práctico y el estado puede crecer con el juego.
  #
  # Sigue siendo efímero, sólo que ahora por tiempo y no por pestaña: seis horas
  # bastan para cualquier combate y evitan que un encuentro olvidado reaparezca
  # semanas después. De propina, recargar la página ya no lo pierde.
  class Store

    TTL = 6.hours

    class << self

      def read(user) = user && Rails.cache.read(key(user))

      def write(user, state)
        return if user.nil?

        Rails.cache.write(key(user), state, expires_in: TTL)
        state
      end

      def clear(user) = user && Rails.cache.delete(key(user))

      private

      # Por usuario y no por sesión: un entrenador tiene un combate, lo mire desde
      # donde lo mire. Con clave de sesión, abrir una pestaña nueva empezaría un
      # encuentro paralelo con el mismo Pokémon.
      def key(user) = "encounter/#{user.id}"

    end

  end
end
