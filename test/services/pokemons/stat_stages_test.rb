require 'test_helper'

# Los escalones de estadística del combate.
class Pokemons::StatStagesTest < ActiveSupport::TestCase

  test 'sin escalones la estadística no cambia' do
    assert_equal 1.0, Pokemons::StatStages.multiplier(0)
    assert_equal 100, Pokemons::StatStages.apply(100, 0)
  end

  test 'subir dos escalones dobla, bajar dos parte por la mitad' do
    assert_equal 200, Pokemons::StatStages.apply(100, 2)
    assert_equal 50, Pokemons::StatStages.apply(100, -2)
  end

  test 'los escalones se topan en seis' do
    assert_equal Pokemons::StatStages.multiplier(6), Pokemons::StatStages.multiplier(99)
    assert_equal Pokemons::StatStages.multiplier(-6), Pokemons::StatStages.multiplier(-99)
  end

  test 'una estadística nunca cae a cero' do
    # Con un mínimo de 1 el combate sigue siendo jugable aunque bajen la defensa
    # seis veces; sin él, una división por cero en la fórmula de daño.
    assert_operator Pokemons::StatStages.apply(1, -6), :>=, 1
  end

  test 'sumar avisa cuando ya no se puede bajar más' do
    valor, movido = Pokemons::StatStages.add(-6, -1)

    assert_equal(-6, valor)
    assert_not movido, 'estando al tope no debería contar como cambio'
  end

  test 'sumar dentro del rango sí cuenta como cambio' do
    valor, movido = Pokemons::StatStages.add(0, 2)

    assert_equal 2, valor
    assert movido
  end

  test 'dos escalones se cuentan como un cambio brusco' do
    assert_match(/sharply rose/, Pokemons::StatStages.message('speed', 2))
    assert_match(/\Aattack fell!/, Pokemons::StatStages.message('attack', -1))
  end

  test 'los nombres con guion de la API se leen como palabras' do
    assert_match(/special attack/, Pokemons::StatStages.message('special-attack', 1))
  end

end
