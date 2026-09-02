module Encounters
  # Los estados alterados del combate: paralizado, dormido, congelado, envenenado
  # y quemado.
  #
  # Es lo primero del combate que **persiste entre turnos**. Hasta ahora el estado
  # del encuentro sólo guardaba vida y PP, y cada turno se resolvía sin memoria de
  # lo anterior; un Pokémon dormido tiene que seguir dormido el turno siguiente, y
  # eso obliga a llevar la cuenta.
  #
  # Se implementan los cinco de primera generación y ninguno más. La PokeAPI
  # nombra unos cuantos que son otra cosa —`confusion`, `leech-seed`, `trap`—, y
  # aplicarlos a medias sería peor que no tenerlos: el movimiento diría que
  # confunde y no pasaría nada. Los no soportados se anuncian como sin efecto.
  module Statuses

    module_function

    # Los que sabemos aplicar. Todo lo demás que devuelva la API se ignora.
    SUPPORTED = %w[paralysis sleep freeze poison burn].freeze

    # Cómo se llama cada uno en pantalla. En inglés, como el resto de la
    # interfaz.
    LABELS = {
      'paralysis' => 'PAR', 'sleep' => 'SLP', 'freeze' => 'FRZ',
      'poison' => 'PSN', 'burn' => 'BRN'
    }.freeze

    def supported?(ailment) = SUPPORTED.include?(ailment.to_s)

    def label(status) = LABELS[status.to_s]

    # Cuántos turnos dura el sueño. Como en el juego, no se sabe de antemano:
    # despertar es la parte que hace que dormir al rival sea una jugada y no una
    # victoria.
    SLEEP_TURNS = (1..3).freeze

    # Probabilidad de perder el turno estando paralizado.
    PARALYSIS_SKIP = 0.25

    # Y lo que frena al que la sufre. Es la otra mitad de la parálisis, y la que
    # importa desde que el orden del turno lo decide la velocidad: paralizar al
    # rival no sólo le hace perder turnos, también le hace perder la iniciativa.
    PARALYSIS_SPEED_FACTOR = 0.25

    # Probabilidad de descongelarse cada turno. En primera generación el hielo no
    # se iba solo nunca, lo que dejaba el combate decidido sin que el jugador
    # pudiera hacer nada; aquí sale por su propio pie.
    THAW_CHANCE = 0.20

    # Fracción de la vida máxima que se pierde por turno envenenado o quemado.
    RESIDUAL_FRACTION = 16

    # La quemadura, además del daño, deja el ataque a la mitad.
    BURN_ATTACK_FACTOR = 0.5

    def turns_for(status)
      status.to_s == 'sleep' ? rand(SLEEP_TURNS) : 0
    end

    # ¿Puede moverse este turno? Devuelve `nil` si sí, y si no, qué contar y en
    # qué queda el estado.
    #
    # Devolver el estado siguiente en lugar de modificarlo aquí mantiene esto como
    # una función sin efectos: quien llama decide cuándo escribirlo.
    def blocked(status:, turns:)
      case status.to_s
      when 'sleep'
        remaining = turns.to_i - 1
        if remaining.negative?
          { message: 'woke up!', status: nil, turns: 0 }
        else
          { message: 'is fast asleep.', status: 'sleep', turns: remaining }
        end
      when 'freeze'
        if rand < THAW_CHANCE
          { message: 'thawed out!', status: nil, turns: 0 }
        else
          { message: 'is frozen solid.', status: 'freeze', turns: 0 }
        end
      when 'paralysis'
        return nil unless rand < PARALYSIS_SKIP

        { message: 'is paralyzed! It cannot move.', status: 'paralysis', turns: 0 }
      end
    end

    # Daño de fin de turno del veneno y la quemadura.
    def residual_damage(status:, max_hp:)
      return 0 unless %w[poison burn].include?(status.to_s)

      [(max_hp.to_i / RESIDUAL_FRACTION), 1].max
    end

    def residual_message(status)
      case status.to_s
      when 'poison' then 'is hurt by poison.'
      when 'burn' then 'is hurt by its burn.'
      end
    end

    # Qué se cuenta al aplicarlo por primera vez.
    def applied_message(status)
      case status.to_s
      when 'paralysis' then 'is paralyzed! It may not attack.'
      when 'sleep' then 'fell asleep!'
      when 'freeze' then 'was frozen solid!'
      when 'poison' then 'was poisoned!'
      when 'burn' then 'was burned!'
      end
    end

  end
end
