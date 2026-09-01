module Encounters
  # Constantes de equilibrio del encuentro, todas juntas y en un solo sitio.
  #
  # Son los números que hay que tocar cuando el juego se hace aburrido o
  # imposible; repartidos por los servicios serían imposibles de calibrar.
  module Rules

    module_function

    # Cuánto puede variar el nivel del rival respecto al tuyo. Un margen estrecho:
    # con rivales muy por encima el combate se pierde antes de empezar, y muy por
    # debajo no da experiencia que merezca la pena.
    LEVEL_SPREAD = 2

    def rival_level(own_level)
      (own_level.to_i + rand(-LEVEL_SPREAD..LEVEL_SPREAD)).clamp(2, Pokemons::LevelStats::MAX_LEVEL)
    end

    # Potencia de reserva, para un movimiento sin datos de potencia.
    BASE_POWER = 40

    # Bonus por usar un movimiento del propio tipo, el STAB del juego.
    SAME_TYPE_BONUS = 1.5

    # Los intentos de captura ya no son un número fijo: se gastan bolas del
    # inventario, y quedarse sin ellas es lo que da valor a la tienda.

    # Tope blando de turnos. La fórmula sólo mira ataque y defensa, así que un
    # rival con mucha vida y defensa media —Snorlax, 160 PS— se eternizaba: 16
    # turnos pulsando el mismo botón. El suelo de daño garantiza que ningún
    # combate pase de aquí, sin tocar los que ya se resolvían rápido.
    MAX_TURNS = 8

    # Cuánto mejora la captura tener al rival debilitado: ×1 a HP completo y
    # hasta ×3 con un punto de vida. Es lo que hace que valga la pena pelear
    # antes de lanzar la bola.
    MAX_HP_BONUS = 3.0

    # --- Entrenadores -------------------------------------------------------

    # Cuántos Pokémon lleva un entrenador rival, como mucho. El número real se
    # limita además al tamaño de tu equipo, así que con el inicial solo el rival
    # lleva uno.
    #
    # Medido con simulación: equipo de 1 gana el 50% de los combates, y de 3 en
    # adelante sube al 95%. Tener equipo *debe* dar ventaja, pero esa curva se
    # aplana demasiado pronto; la solución de fondo son los niveles (fase 10),
    # que permitirán escalar también la fuerza del rival y no sólo su número.
    # Cuatro y no seis: contra un equipo completo el combate sería correcto de
    # equilibrio pero tedioso de jugar, más de treinta clics en el mismo botón.
    TRAINER_TEAM_RANGE = (1..4).freeze

    # Premio por ganar, calibrado contra el precio de una Poké Ball (200 en la
    # fase de tienda): una victoria compra un objeto, pero no dos. Es lo que
    # mantiene la tienda como una decisión y no como un trámite.
    REWARD_RANGE = (100..300).freeze

    def trainer_reward
      rand(REWARD_RANGE)
    end

    # ¿Acierta el movimiento? Una precisión vacía significa que nunca falla.
    def hits?(accuracy)
      return true if accuracy.nil?

      rand(1..100) <= accuracy.to_i
    end

    # Daño de un atacante a un defensor, con la efectividad de tipos de la fase 2.
    # Es la fórmula de primera generación, simplificada: sin críticos, sin STAB y
    # sin variación aleatoria, para que el resultado sea predecible y ajustable.
    def damage(attack:, defense:, effectiveness: 1.0, defender_max_hp: nil, level: 25,
               power: BASE_POWER, same_type: false)
      attack = attack.to_i.clamp(1, 255)
      defense = defense.to_i.clamp(1, 255)
      power = power.to_i.positive? ? power.to_i : BASE_POWER

      base = ((2 * level / 5.0 + 2) * power * attack / defense / 50.0) + 2
      base *= SAME_TYPE_BONUS if same_type
      dealt = (base * effectiveness).round

      # Contra un tipo inmune no hay suelo que valga: cero es cero.
      return 0 if effectiveness.zero?

      floor = defender_max_hp.to_i.positive? ? (defender_max_hp.to_f / MAX_TURNS).ceil : 1
      [dealt, floor, 1].max
    end

    # Probabilidad de captura: el ratio de la especie, mejorado por el daño ya
    # hecho. `capture_rate` llega como porcentaje (0-100) desde el decorador.
    def capture_probability(capture_rate:, current_hp:, max_hp:, multiplier: 1.0)
      return 0.0 unless capture_rate.to_i.positive?

      missing = max_hp.positive? ? (1.0 - current_hp.to_f / max_hp) : 0.0
      hp_bonus = 1 + (MAX_HP_BONUS - 1) * missing

      [(capture_rate / 100.0) * hp_bonus * multiplier, 1.0].min
    end

  end
end
