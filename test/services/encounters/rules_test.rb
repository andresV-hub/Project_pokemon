require 'test_helper'

# Las reglas del combate. Son las de primera generación, y estos tests las
# comprueban como tales: el daño lleva variación aleatoria y críticos, así que se
# mide con muestras y no con igualdades exactas.
class Encounters::RulesTest < ActiveSupport::TestCase

  # El daño varía entre el 85% y el 100%, y un crítico dispara el resultado, así
  # que comparar dos golpes sueltos no dice nada: se comparan medias.
  def media(veces: 60, **opciones)
    base = { attack: 60, defense: 60, level: 25, power: 60 }.merge(opciones)

    (veces.times.sum { Encounters::Rules.damage(**base)[:amount] } / veces.to_f)
  end

  # --- Daño ---------------------------------------------------------------

  test 'un tipo inmune no recibe daño, ni siquiera el mínimo' do
    golpe = Encounters::Rules.damage(attack: 200, defense: 10, effectiveness: 0.0,
                                     defender_max_hp: 100, level: 50, power: 120)

    assert_equal 0, golpe[:amount]
    assert_not golpe[:critical], 'contra un inmune no llega ni a mirarse el crítico'
  end

  test 'el bonus por tipo propio aumenta el daño' do
    assert_operator media(same_type: true), :>, media(same_type: false)
  end

  test 'un movimiento más potente hace más daño en igualdad de condiciones' do
    assert_operator media(power: 120), :>, media(power: 40)
  end

  test 'la efectividad multiplica el daño' do
    assert_operator media(effectiveness: 2.0), :>, media(effectiveness: 0.5)
  end

  test 'el suelo de daño acota los combates contra rivales muy resistentes' do
    # Snorlax tardaba dieciséis turnos en caer. El suelo garantiza que ninguno
    # pase de `MAX_TURNS`, sin tocar los que ya se resolvían rápido.
    golpe = Encounters::Rules.damage(attack: 1, defense: 255, defender_max_hp: 160,
                                     level: 5, power: 10)

    assert_operator golpe[:amount], :>=, (160.0 / Encounters::Rules::MAX_TURNS).ceil
  end

  # --- Lo que se añadió: variación y críticos ------------------------------

  test 'el mismo golpe no siempre hace el mismo daño' do
    # El factor (217..255)/255 de primera generación. Sin él, dos combates
    # idénticos daban exactamente el mismo resultado y no había nada que jugar.
    resultados = 60.times.map do
      Encounters::Rules.damage(attack: 80, defense: 60, level: 30, power: 60)[:amount]
    end

    assert_operator resultados.uniq.size, :>, 1
  end

  test 'la variación se queda entre el 85% y el 100%' do
    muestras = 200.times.map do
      Encounters::Rules.damage(attack: 80, defense: 60, level: 30, power: 60,
                               base_speed: 0)[:amount]
    end

    # Con `base_speed: 0` no hay críticos, así que la única dispersión es la del
    # factor aleatorio: el mínimo no puede bajar del 85% del máximo.
    assert_operator muestras.min, :>=, (muestras.max * 0.84).floor
  end

  test 'sin velocidad base no hay críticos' do
    # Es la salvaguarda para cuando no se conoce la especie: mejor ningún crítico
    # que uno inventado.
    assert_not Encounters::Rules.critical?(nil)
    assert_not Encounters::Rules.critical?(0)
  end

  test 'los Pokémon rápidos critican más' do
    rapidos = 400.times.count { Encounters::Rules.critical?(115) }
    lentos = 400.times.count { Encounters::Rules.critical?(15) }

    # En primera generación la probabilidad es la velocidad base entre 512, así
    # que Persian critica casi ocho veces más que Slowpoke. Es la rareza de esta
    # generación y no la tiene ninguna otra.
    assert_operator rapidos, :>, lentos
  end

  test 'un crítico pega más que un golpe normal' do
    normal = 200.times.map { Encounters::Rules.damage(attack: 80, defense: 60, level: 30,
                                                      power: 60, base_speed: 0)[:amount] }.max
    critico = nil
    300.times do
      golpe = Encounters::Rules.damage(attack: 80, defense: 60, level: 30, power: 60,
                                       base_speed: 255)
      critico = golpe[:amount] if golpe[:critical]
      break if critico
    end

    assert critico, 'con velocidad base máxima tendría que salir algún crítico'
    assert_operator critico, :>, normal
  end

  # --- Captura ------------------------------------------------------------

  test 'una especie sin ratio de captura no se puede capturar' do
    assert_not Encounters::Rules.caught?(capture_rate: 0, current_hp: 1, max_hp: 100,
                                         kind: 'ultra_ball')
  end

  test 'debilitar al rival mejora la captura' do
    lleno = 300.times.count do
      Encounters::Rules.caught?(capture_rate: 120, current_hp: 100, max_hp: 100, kind: 'poke_ball')
    end
    tocado = 300.times.count do
      Encounters::Rules.caught?(capture_rate: 120, current_hp: 5, max_hp: 100, kind: 'poke_ball')
    end

    assert_operator tocado, :>, lleno
  end

  test 'una bola mejor captura más' do
    normal = 300.times.count do
      Encounters::Rules.caught?(capture_rate: 60, current_hp: 50, max_hp: 100, kind: 'poke_ball')
    end
    ultra = 300.times.count do
      Encounters::Rules.caught?(capture_rate: 60, current_hp: 50, max_hp: 100, kind: 'ultra_ball')
    end

    assert_operator ultra, :>, normal
  end

  test 'dormir al rival mejora la captura más que envenenarlo' do
    dormido = 400.times.count do
      Encounters::Rules.caught?(capture_rate: 30, current_hp: 100, max_hp: 100,
                                kind: 'poke_ball', status: 'sleep')
    end
    envenenado = 400.times.count do
      Encounters::Rules.caught?(capture_rate: 30, current_hp: 100, max_hp: 100,
                                kind: 'poke_ball', status: 'poison')
    end

    # La jugada clásica del juego: dormirlo antes de lanzar. Ahora que los estados
    # existen, se puede aprovechar.
    assert_operator dormido, :>, envenenado
  end

  test 'una especie difícil se resiste incluso a tope de bolas' do
    # Mewtwo tiene ratio 3 de 255.
    exitos = 300.times.count do
      Encounters::Rules.caught?(capture_rate: 3, current_hp: 1, max_hp: 200, kind: 'ultra_ball')
    end

    assert_operator exitos, :<, 120, 'un legendario no puede caer una de cada dos veces'
  end

  # --- Premio de entrenador -----------------------------------------------

  test 'el premio depende de la clase y del nivel' do
    joven = Encounters::Rules.trainer_reward(rival: 'Youngster', level: 10)
    montanero = Encounters::Rules.trainer_reward(rival: 'Hiker', level: 10)

    assert_equal 150, joven
    assert_operator montanero, :>, joven
  end

  test 'un rival de más nivel paga más' do
    bajo = Encounters::Rules.trainer_reward(rival: 'Lass', level: 5)
    alto = Encounters::Rules.trainer_reward(rival: 'Lass', level: 40)

    # Antes era un número al azar entre 100 y 300, así que ganar a un Bug Catcher
    # de nivel 3 pagaba lo mismo que ganar a un Hiker de nivel 40.
    assert_operator alto, :>, bajo
  end

  test 'una clase desconocida sigue pagando algo' do
    assert_operator Encounters::Rules.trainer_reward(rival: 'Fantasma', level: 10), :>, 0
  end

  # --- Precisión ----------------------------------------------------------

  test 'un movimiento sin precisión declarada nunca falla' do
    assert Encounters::Rules.hits?(nil)
  end

  test 'la precisión se respeta' do
    aciertos = 400.times.count { Encounters::Rules.hits?(50) }

    assert_includes 120..280, aciertos
  end

end
