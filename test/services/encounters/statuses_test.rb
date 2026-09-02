require 'test_helper'

# Los estados alterados. Son la primera cosa del combate que dura más de un
# turno, así que lo que se comprueba aquí es sobre todo que la cuenta atrás
# termine: un estado que no se quita nunca deja el combate decidido sin que el
# jugador pueda hacer nada.
class Encounters::StatusesTest < ActiveSupport::TestCase

  test 'el sueño descuenta un turno cada vez y acaba despertando' do
    primero = Encounters::Statuses.blocked(status: 'sleep', turns: 2)
    assert_equal 'sleep', primero[:status]
    assert_equal 1, primero[:turns]
    assert_match(/asleep/, primero[:message])

    segundo = Encounters::Statuses.blocked(status: 'sleep', turns: 0)
    assert_nil segundo[:status], 'al agotarse los turnos tiene que despertar'
    assert_match(/woke up/, segundo[:message])
  end

  test 'sin estado no se bloquea el turno' do
    assert_nil Encounters::Statuses.blocked(status: nil, turns: 0)
  end

  test 'el veneno y la quemadura quitan una fracción de la vida máxima' do
    assert_equal 10, Encounters::Statuses.residual_damage(status: 'poison', max_hp: 160)
    assert_equal 10, Encounters::Statuses.residual_damage(status: 'burn', max_hp: 160)
  end

  test 'el desgaste nunca es cero, ni con un Pokémon diminuto' do
    assert_equal 1, Encounters::Statuses.residual_damage(status: 'poison', max_hp: 4)
  end

  test 'la parálisis no desgasta: sólo hace perder turnos' do
    assert_equal 0, Encounters::Statuses.residual_damage(status: 'paralysis', max_hp: 160)
  end

  test 'sólo se dan por buenos los estados que sabemos aplicar' do
    assert Encounters::Statuses.supported?('paralysis')
    # La API los nombra, pero son otra cosa y aplicarlos a medias sería peor que
    # no tenerlos.
    assert_not Encounters::Statuses.supported?('confusion')
    assert_not Encounters::Statuses.supported?('leech-seed')
  end

  test 'el congelado siempre acaba deshelándose' do
    resultados = 200.times.map { Encounters::Statuses.blocked(status: 'freeze', turns: 0)[:status] }

    assert_includes resultados, nil, 'con 200 turnos tendría que haberse deshelado alguna vez'
  end

  test 'la parálisis deja actuar la mayoría de los turnos' do
    perdidos = 400.times.count { Encounters::Statuses.blocked(status: 'paralysis', turns: 0) }

    # Es un cuarto de las veces; el margen es ancho a propósito para que el test
    # no falle por el azar de una tirada.
    assert_includes 40..260, perdidos
  end

end
