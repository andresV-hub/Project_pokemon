require 'test_helper'

class Pokemons::LevelStatsTest < ActiveSupport::TestCase

  test 'las estadísticas crecen con el nivel' do
    assert_operator Pokemons::LevelStats.stat(55, 50), :>, Pokemons::LevelStats.stat(55, 5)
    assert_operator Pokemons::LevelStats.hp(35, 50), :>, Pokemons::LevelStats.hp(35, 5)
  end

  test 'el HP es exactamente el del juego' do
    # Sin inventos: hubo un `HP_SCALE = 1.5` que inflaba esto un 40% por encima
    # del original para compensar unas estadísticas que salían bajas porque
    # faltaban los DV. Corregida la causa, el parche sobra.
    assert_equal ((2 * 35 * 45) / 100) + 45 + 10, Pokemons::LevelStats.hp(35, 45)
  end

  test 'un DV alto sube la estadística, y el HP más que el resto' do
    # Es lo que hace que dos Pokémon de la misma especie y nivel no sean iguales.
    assert_operator Pokemons::LevelStats.hp(45, 50, 15), :>, Pokemons::LevelStats.hp(45, 50, 0)
    assert_operator Pokemons::LevelStats.stat(49, 50, 15), :>, Pokemons::LevelStats.stat(49, 50, 0)
  end

  test 'el DV de HP se arma con los bits de los otros cuatro' do
    # En primera generación no se guarda aparte. Con las cuatro estadísticas
    # impares sale 15, el máximo; con las cuatro pares, 0.
    assert_equal 15, Pokemons::DeterminantValues.hp_from(attack: 15, defense: 15, speed: 15, special: 15)
    assert_equal 0, Pokemons::DeterminantValues.hp_from(attack: 0, defense: 0, speed: 0, special: 0)
    # 1010 en binario: ataque y velocidad impares.
    assert_equal 10, Pokemons::DeterminantValues.hp_from(attack: 5, defense: 2, speed: 7, special: 4)
  end

  # La ida y vuelta entre experiencia y nivel se comprueba ahora en
  # `ExperienceCurveTest`, que es donde vive la curva desde que depende de la
  # especie y no sólo del nivel.

  test 'derrotar a un rival de más nivel da más experiencia' do
    bajo = Pokemons::LevelStats.experience_from(base_experience: 112, level: 5)
    alto = Pokemons::LevelStats.experience_from(base_experience: 112, level: 50)

    assert_operator alto, :>, bajo
  end

  test 'siempre se gana al menos un punto de experiencia' do
    assert_operator Pokemons::LevelStats.experience_from(base_experience: 1, level: 1), :>=, 1
  end

  test 'el nivel inicial tiene la experiencia que le corresponde, en cualquier curva' do
    con_pokeapi_simulada do
      # Nacer con nivel 5 y experiencia 0 hacía que el primer combate recalculara
      # el nivel a 3: el jugador veía a su Pokémon *bajar* de nivel. Ahora hay que
      # comprobarlo en todas las curvas, porque un Pokémon con la experiencia de
      # una curva y el nivel de otra vuelve a tener el mismo problema.
      nivel = Pokemons::LevelStats::STARTING_LEVEL

      %w[medium slow medium-slow fast].each do |curva|
        coste = Pokemons::ExperienceCurve.experience_for(nivel, curva)

        assert_equal nivel, Pokemons::ExperienceCurve.level_for(coste, curva), "falla en #{curva}"
      end
    end
  end

end
