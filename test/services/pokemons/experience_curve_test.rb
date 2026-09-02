require 'test_helper'

# Las curvas de experiencia. Lo que se protege aquí es que **nadie baje de nivel**:
# cambiar de curva cambia lo que cuesta cada nivel, y una experiencia que antes
# valía nivel 20 puede valer 18 en una curva más lenta.
class Pokemons::ExperienceCurveTest < ActiveSupport::TestCase

  test 'la curva por defecto es la que todos usaban: n³' do
    con_pokeapi_simulada do
      # `medium` de los juegos y `n³` calculado a mano dan el mismo número. Que
      # coincidan es lo que permite que el respaldo sin API no cambie nada.
      assert_equal 8_000, Pokemons::ExperienceCurve.experience_for(20, 'medium')
      assert_equal 20**3, Pokemons::ExperienceCurve.experience_for(20, 'medium')
      assert_equal 125_000, Pokemons::ExperienceCurve.experience_for(50, 'medium')
    end
  end

  test 'cada curva cuesta lo suyo' do
    con_pokeapi_simulada do
      lento = Pokemons::ExperienceCurve.experience_for(20, 'slow')
      medio = Pokemons::ExperienceCurve.experience_for(20, 'medium')
      medio_lento = Pokemons::ExperienceCurve.experience_for(20, 'medium-slow')
      rapido = Pokemons::ExperienceCurve.experience_for(20, 'fast')

      assert_equal 10_000, lento
      assert_equal 5_460, medio_lento
      assert_operator medio_lento, :<, medio
      assert_operator rapido, :<, medio
      assert_operator lento, :>, medio
    end
  end

  test 'el nivel y la experiencia son la misma cuenta en los dos sentidos' do
    con_pokeapi_simulada do
      %w[medium slow medium-slow fast].each do |curva|
        [2, 17, 40, 88].each do |nivel|
          coste = Pokemons::ExperienceCurve.experience_for(nivel, curva)

          assert_equal nivel, Pokemons::ExperienceCurve.level_for(coste, curva),
                       "#{curva} no cuadra en el nivel #{nivel}"
        end
      end
    end
  end

  test 'un punto por debajo del siguiente nivel sigue siendo el anterior' do
    con_pokeapi_simulada do
      coste = Pokemons::ExperienceCurve.experience_for(30, 'slow')

      assert_equal 29, Pokemons::ExperienceCurve.level_for(coste - 1, 'slow')
    end
  end

  test 'sin curva guardada se usa medium, que es lo que se usaba antes' do
    con_pokeapi_simulada do
      assert_equal Pokemons::ExperienceCurve.experience_for(20, 'medium'),
                   Pokemons::ExperienceCurve.experience_for(20, nil)
    end
  end

  test 'el nivel se topa arriba y abajo' do
    con_pokeapi_simulada do
      assert_equal 1, Pokemons::ExperienceCurve.level_for(0, 'medium')
      assert_equal 100, Pokemons::ExperienceCurve.level_for(999_999_999, 'medium')
    end
  end

  test 'sin API se sigue pudiendo jugar' do
    # El respaldo no es una invención: `n³` es la curva `medium` calculada a mano,
    # así que caerse la API degrada la fidelidad pero no rompe el combate.
    original = Pokeapi::Client.method(:get)
    Pokeapi::Client.define_singleton_method(:get) { |*| nil }
    Rails.cache.clear

    assert_equal 8_000, Pokemons::ExperienceCurve.experience_for(20, 'slow')
    assert_equal 20, Pokemons::ExperienceCurve.level_for(8_000, 'slow')
  ensure
    Pokeapi::Client.define_singleton_method(:get, original)
    Rails.cache.clear
  end

end
