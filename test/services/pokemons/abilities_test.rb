require 'test_helper'

# Las habilidades. No son de primera generación y están aquí por decisión de
# producto; lo que estos tests protegen es que **sólo se anuncien las que hacen
# algo**, porque prometer una habilidad inerte es peor que no tenerla.
class Pokemons::AbilitiesTest < ActiveSupport::TestCase

  test 'sólo se dan por buenas las que el combate sabe aplicar' do
    assert Pokemons::Abilities.supported?('intimidate')
    assert Pokemons::Abilities.supported?('levitate')
    assert Pokemons::Abilities.supported?('overgrow')

    # Las tres más comunes de Kanto dependen del clima, y aquí no hay clima.
    assert_not Pokemons::Abilities.supported?('chlorophyll')
    assert_not Pokemons::Abilities.supported?('swift-swim')
    assert_not Pokemons::Abilities.supported?('sand-veil')
  end

  test 'la inmunidad por tipo sólo cubre su tipo' do
    assert_equal 'ground', Pokemons::Abilities.immune_type('levitate')
    assert_nil Pokemons::Abilities.immune_type('overgrow')
  end

  test 'sólo dos inmunidades curan' do
    assert Pokemons::Abilities.absorbs?('water-absorb')
    assert Pokemons::Abilities.absorbs?('volt-absorb')
    # Levitate esquiva, pero no cura: son cosas distintas.
    assert_not Pokemons::Abilities.absorbs?('levitate')
  end

  test 'el impulso por apuro sólo entra con un tercio de vida o menos' do
    assert Pokemons::Abilities.pinch_boost?('overgrow', 'grass', 66, 200)
    assert_not Pokemons::Abilities.pinch_boost?('overgrow', 'grass', 67, 200)
  end

  test 'el impulso por apuro sólo vale para su tipo' do
    assert_not Pokemons::Abilities.pinch_boost?('overgrow', 'fire', 10, 200)
    assert Pokemons::Abilities.pinch_boost?('blaze', 'fire', 10, 200)
  end

  test 'la inmunidad a estado es a uno concreto' do
    assert Pokemons::Abilities.blocks_status?('limber', 'paralysis')
    assert_not Pokemons::Abilities.blocks_status?('limber', 'burn')
    assert Pokemons::Abilities.blocks_status?('insomnia', 'sleep')
  end

  test 'la protección de estadísticas distingue entre una y todas' do
    # Hyper Cutter protege sólo el ataque; Clear Body, todas.
    assert Pokemons::Abilities.guards_stat?('hyper-cutter', 'attack')
    assert_not Pokemons::Abilities.guards_stat?('hyper-cutter', 'defense')
    assert Pokemons::Abilities.guards_stat?('clear-body', 'defense')
    assert_not Pokemons::Abilities.guards_stat?('overgrow', 'attack')
  end

  test 'thick fat sólo rebaja fuego y hielo' do
    assert Pokemons::Abilities.thick_fat?('thick-fat', 'fire')
    assert Pokemons::Abilities.thick_fat?('thick-fat', 'ice')
    assert_not Pokemons::Abilities.thick_fat?('thick-fat', 'water')
  end

  test 'el nombre se escribe como en el juego' do
    assert_equal 'Poison Point', Pokemons::Abilities.label('poison-point')
    assert_equal 'Overgrow', Pokemons::Abilities.label('overgrow')
  end

  test 'se guarda la de la primera ranura y nunca una oculta' do
    con_pokeapi_simulada do
      pikachu = Pokedex::PokedexDecorator.decorate(Pokeapi::Client.get('pokemon/25'))

      # Pikachu tiene Static en la ranura 1 y Lightning Rod como oculta. Repartir
      # las ocultas convertiría la captura en una lotería con premio.
      assert_equal 'static', pikachu.ability
    end
  end

end
