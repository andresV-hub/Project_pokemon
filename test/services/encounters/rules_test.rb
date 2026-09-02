require 'test_helper'

# Las constantes de equilibrio del combate. Son funciones puras —ni base de datos
# ni red—, y es donde un fallo pasa más desapercibido: no revienta nada, sólo
# devuelve un número equivocado que nadie mira.
class Encounters::RulesTest < ActiveSupport::TestCase

  # --- Daño ----------------------------------------------------------------

  test 'un tipo inmune no recibe daño, ni siquiera el mínimo' do
    # El suelo de daño garantiza al menos 1 punto para que los combates avancen,
    # pero una inmunidad tiene que seguir siendo cero: Ground contra Flying no
    # hace cosquillas, no hace nada.
    dealt = Encounters::Rules.damage(attack: 200, defense: 10, effectiveness: 0.0,
                                     defender_max_hp: 300, level: 50)

    assert_equal 0, dealt
  end

  test 'el suelo de daño acota los combates contra rivales muy resistentes' do
    # Un Snorlax (160 PS) contra un atacante flojo daba dieciséis turnos pulsando
    # el mismo botón. El suelo lo deja en el tope de MAX_TURNS.
    max_hp = 160
    dealt = Encounters::Rules.damage(attack: 10, defense: 250, defender_max_hp: max_hp, level: 5)

    turnos = (max_hp.to_f / dealt).ceil
    assert_operator turnos, :<=, Encounters::Rules::MAX_TURNS
  end

  test 'el bonus por tipo propio aumenta el daño' do
    sin_bonus = Encounters::Rules.damage(attack: 80, defense: 60, level: 30, power: 60)
    con_bonus = Encounters::Rules.damage(attack: 80, defense: 60, level: 30, power: 60, same_type: true)

    assert_operator con_bonus, :>, sin_bonus
  end

  test 'un movimiento más potente hace más daño en igualdad de condiciones' do
    flojo = Encounters::Rules.damage(attack: 80, defense: 60, level: 30, power: 40)
    fuerte = Encounters::Rules.damage(attack: 80, defense: 60, level: 30, power: 110)

    assert_operator fuerte, :>, flojo
  end

  test 'la efectividad multiplica el daño' do
    neutral = Encounters::Rules.damage(attack: 80, defense: 60, effectiveness: 1.0, level: 30, power: 60)
    superefectivo = Encounters::Rules.damage(attack: 80, defense: 60, effectiveness: 2.0, level: 30, power: 60)

    assert_operator superefectivo, :>, neutral
  end

  # --- Captura --------------------------------------------------------------

  test 'debilitar al rival mejora la probabilidad de captura' do
    lleno = Encounters::Rules.capture_probability(capture_rate: 20, current_hp: 100, max_hp: 100)
    tocado = Encounters::Rules.capture_probability(capture_rate: 20, current_hp: 1, max_hp: 100)

    assert_in_delta 0.20, lleno, 0.001
    assert_operator tocado, :>, lleno
    # El bonus máximo es el declarado, ni más ni menos.
    assert_in_delta 0.20 * Encounters::Rules::MAX_HP_BONUS, tocado, 0.01
  end

  test 'una especie sin ratio de captura no se puede capturar' do
    assert_equal 0.0, Encounters::Rules.capture_probability(capture_rate: 0, current_hp: 1, max_hp: 100)
  end

  test 'la probabilidad nunca pasa de uno' do
    probabilidad = Encounters::Rules.capture_probability(capture_rate: 100, current_hp: 1,
                                                        max_hp: 100, multiplier: 2.0)

    assert_equal 1.0, probabilidad
  end

  # --- Precisión y nivel del rival -----------------------------------------

  test 'un movimiento sin precisión declarada nunca falla' do
    assert Encounters::Rules.hits?(nil)
  end

  test 'el rival sale dentro del margen de nivel y nunca por debajo de dos' do
    50.times do
      assert_includes 8..12, Encounters::Rules.rival_level(10)
    end

    assert_operator Encounters::Rules.rival_level(1), :>=, 2
  end

end
