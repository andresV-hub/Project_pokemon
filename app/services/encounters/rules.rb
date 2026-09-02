module Encounters
  # Constantes de equilibrio del encuentro, todas juntas y en un solo sitio.
  #
  # Son los números que hay que tocar cuando el juego se hace aburrido o
  # imposible; repartidos por los servicios serían imposibles de calibrar.
  module Rules

    module_function

    # Cuánto puede variar el nivel del rival respecto al tuyo. Sólo se usa ya para
    # los entrenadores: el nivel de un Pokémon salvaje lo pone la zona, con los
    # valores del juego, y no se ajusta al jugador.
    #
    # Un margen estrecho: con rivales muy por encima el combate se pierde antes de
    # empezar, y muy por debajo no da experiencia que merezca la pena.
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

    # Lo que paga cada clase de entrenador **por nivel de su último Pokémon**, que
    # es como se calcula en primera generación. Antes era un número al azar entre
    # 100 y 300, así que ganar a un Bug Catcher de nivel 3 pagaba lo mismo que
    # ganar a un Hiker de nivel 40.
    #
    # Con esto el premio escala solo: los sitios difíciles pagan más porque sus
    # entrenadores llevan Pokémon de más nivel, sin tener que tocar ninguna
    # constante.
    BASE_PAYOUT = {
      'Youngster' => 15, 'Bug Catcher' => 12, 'Lass' => 22, 'Sailor' => 35,
      'Camper' => 25, 'Picnicker' => 25, 'Super Nerd' => 25, 'Hiker' => 35
    }.freeze

    DEFAULT_PAYOUT = 20

    def trainer_reward(rival:, level:)
      BASE_PAYOUT.fetch(rival.to_s, DEFAULT_PAYOUT) * level.to_i.clamp(1, Pokemons::LevelStats::MAX_LEVEL)
    end

    # --- Perder -------------------------------------------------------------

    # Qué parte del dinero se pierde al caer el equipo entero. La mitad, como en
    # Rojo y Azul.
    #
    # Es lo único que hace que el dinero importe: el Centro Pokémon cura gratis
    # —también como en el juego—, así que si perder no costara nada, no habría
    # ninguna razón para comprar una poción ni para huir de un combate perdido.
    DEFEAT_MONEY_DIVISOR = 2

    def defeat_penalty(money)
      money.to_i / DEFEAT_MONEY_DIVISOR
    end

    # ¿Acierta el movimiento? Una precisión vacía significa que nunca falla.
    def hits?(accuracy)
      return true if accuracy.nil?

      rand(1..100) <= accuracy.to_i
    end

    # Variación aleatoria del daño en primera generación: un factor de 217 a 255
    # sobre 255, es decir entre el 85% y el 100%. Estaba sin implementar, y sin
    # ella dos combates idénticos daban exactamente el mismo resultado.
    DAMAGE_SPREAD = (217..255).freeze

    # Probabilidad de golpe crítico: la **velocidad base** de la especie dividida
    # entre 512. Es la de gen 1 y tiene una consecuencia que no tiene ninguna otra
    # generación: los Pokémon rápidos critican mucho más. Persian, con 115 de
    # velocidad base, lo hace una de cada cuatro o cinco veces.
    CRITICAL_DIVISOR = 512.0

    def critical?(base_speed)
      return false if base_speed.to_i <= 0

      rand < [base_speed.to_i / CRITICAL_DIVISOR, 255 / 256.0].min
    end

    # Daño de un atacante a un defensor. Es la fórmula de primera generación
    # **completa**: sólo le faltaban el factor aleatorio y los críticos, que son
    # justo lo que hace que un combate no esté decidido de antemano.
    #
    # Devuelve el daño y si fue crítico, porque eso último hay que contarlo: un
    # golpe que quita el triple sin explicación parece un fallo.
    def damage(attack:, defense:, effectiveness: 1.0, defender_max_hp: nil, level: 25,
               power: BASE_POWER, same_type: false, base_speed: nil)
      # Contra un tipo inmune no hay suelo ni crítico que valga: cero es cero.
      return { amount: 0, critical: false } if effectiveness.zero?

      attack = attack.to_i.clamp(1, 255)
      defense = defense.to_i.clamp(1, 255)
      power = power.to_i.positive? ? power.to_i : BASE_POWER
      critical = critical?(base_speed)

      # En primera generación un crítico **dobla el nivel dentro de la fórmula**,
      # no multiplica el resultado por dos. A nivel bajo eso es más del doble; a
      # nivel alto, algo menos.
      effective_level = critical ? level.to_i * 2 : level.to_i

      base = ((2 * effective_level / 5.0 + 2) * power * attack / defense / 50.0) + 2
      base *= SAME_TYPE_BONUS if same_type
      base *= effectiveness
      base *= rand(DAMAGE_SPREAD) / 255.0

      floor = defender_max_hp.to_i.positive? ? (defender_max_hp.to_f / MAX_TURNS).ceil : 1

      { amount: [base.round, floor, 1].max, critical: critical }
    end

    # --- Captura -------------------------------------------------------------
    #
    # La fórmula de primera generación, con sus dos tiradas. Sustituye a una
    # aproximación propia que multiplicaba el ratio por un bonus de vida inventado.

    # Tope de la primera tirada según la bola: cuanto más baja, más fácil pasar el
    # primer filtro. Es lo que hace mejor a una Ultra Ball, y no un multiplicador.
    BALL_LIMIT = { 'poke_ball' => 255, 'great_ball' => 200, 'ultra_ball' => 150 }.freeze

    # Divisor de la segunda tirada. La Poké Ball divide por 12 y las otras por 8,
    # así que las buenas también aprovechan mejor el daño hecho.
    BALL_FACTOR = { 'poke_ball' => 12, 'great_ball' => 8, 'ultra_ball' => 8 }.freeze

    # Un rival dormido o congelado se captura mucho mejor que uno paralizado,
    # envenenado o quemado. Es el motivo por el que dormir antes de lanzar es la
    # jugada clásica, y ahora que los estados existen se puede aprovechar.
    STATUS_BONUS = { 'sleep' => 25, 'freeze' => 25,
                     'paralysis' => 12, 'poison' => 12, 'burn' => 12 }.freeze

    # ¿Se queda dentro? `capture_rate` es el valor crudo de la API, de 0 a 255.
    def caught?(capture_rate:, current_hp:, max_hp:, kind: nil, status: nil)
      rate = capture_rate.to_i
      return false unless rate.positive?

      limit = BALL_LIMIT.fetch(kind.to_s, 255)
      factor = BALL_FACTOR.fetch(kind.to_s, 12)

      # Primera tirada: el estado alterado puede capturar directamente, y si no,
      # hay que quedar por debajo del ratio de la especie.
      first = rand(0..limit)
      return true if first < STATUS_BONUS.fetch(status.to_s, 0)
      return false if first > rate

      # Segunda: cuanto menos vida le queda, más alto sale `f` y más fácil es
      # superar la tirada.
      current = [current_hp.to_i, 1].max
      f = [(max_hp.to_i * 255 * 4) / (current * factor), 255].min

      f >= rand(0..255)
    end

  end
end
