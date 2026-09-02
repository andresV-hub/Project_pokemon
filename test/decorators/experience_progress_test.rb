require 'test_helper'

# El progreso de nivel es una resta entre dos puntos de la curva `n³`, y es fácil
# equivocarse tomando el total acumulado como si empezara en cero: eso daría un
# 58% recién subido a nivel 5, y la barra parecería medio llena nada más empezar.
class ExperienceProgressTest < ActiveSupport::TestCase

  def decorado(level:, experience:)
    pokemon = pokemons(:bulbasaur_del_entrenador)
    pokemon.update!(level: level, experience: experience)
    ::Pokemons::PokemonDecorator.decorate(pokemon)
  end

  test 'recién subido de nivel el progreso es cero, no el acumulado' do
    # 125 es exactamente 5³: acaba de entrar en el nivel 5.
    assert_equal 0, decorado(level: 5, experience: 125).experience_percent
  end

  test 'a mitad del tramo el progreso es la mitad' do
    # El nivel 5 va de 125 a 216: 91 de recorrido, 45 es la mitad justa.
    assert_equal 49, decorado(level: 5, experience: 125 + 45).experience_percent
  end

  test 'lo que falta se cuenta hasta el siguiente nivel' do
    pokemon = decorado(level: 5, experience: 164)
    assert_equal 216, pokemon.next_level_experience
    assert_equal 52, pokemon.experience_to_next_level
  end

  test 'a nivel máximo no queda nada por delante' do
    pokemon = decorado(level: 100, experience: 1_000_000)
    assert pokemon.max_level?
    assert_equal 100, pokemon.experience_percent
    assert_equal 0, pokemon.experience_to_next_level
  end

end
