require 'test_helper'

class Pokemons::LevelStatsTest < ActiveSupport::TestCase

  test 'las estadísticas crecen con el nivel' do
    assert_operator Pokemons::LevelStats.stat(55, 50), :>, Pokemons::LevelStats.stat(55, 5)
    assert_operator Pokemons::LevelStats.hp(35, 50), :>, Pokemons::LevelStats.hp(35, 5)
  end

  test 'el HP lleva margen de resistencia sobre la fórmula base' do
    # Sin ese margen, un movimiento potente con bonus de tipo dejaba KO de un
    # solo golpe y el combate no llegaba a jugarse.
    sin_margen = ((2 * 35 * 45) / 100) + 45 + 10

    assert_operator Pokemons::LevelStats.hp(35, 45), :>, sin_margen
  end

  test 'la experiencia y el nivel son inversos' do
    (2..40).step(7) do |nivel|
      assert_equal nivel, Pokemons::LevelStats.level_for(Pokemons::LevelStats.experience_for(nivel))
    end
  end

  test 'sin experiencia el nivel no baja de uno' do
    assert_equal 1, Pokemons::LevelStats.level_for(0)
  end

  test 'el nivel tiene tope' do
    enorme = Pokemons::LevelStats.experience_for(500)

    assert_equal Pokemons::LevelStats::MAX_LEVEL, Pokemons::LevelStats.level_for(enorme)
  end

  test 'derrotar a un rival de más nivel da más experiencia' do
    bajo = Pokemons::LevelStats.experience_from(base_experience: 112, level: 5)
    alto = Pokemons::LevelStats.experience_from(base_experience: 112, level: 50)

    assert_operator alto, :>, bajo
  end

  test 'siempre se gana al menos un punto de experiencia' do
    assert_operator Pokemons::LevelStats.experience_from(base_experience: 1, level: 1), :>=, 1
  end

  test 'el nivel inicial tiene la experiencia que le corresponde' do
    # Nacer con nivel 5 y experiencia 0 hacía que el primer combate recalculara
    # el nivel a 3: el jugador veía a su Pokémon *bajar* de nivel.
    nivel = Pokemons::LevelStats::STARTING_LEVEL

    assert_equal nivel, Pokemons::LevelStats.level_for(Pokemons::LevelStats.experience_for(nivel))
  end

end
