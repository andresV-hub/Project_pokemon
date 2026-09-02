require 'test_helper'

# Aprender movimientos al subir de nivel.
#
# Además del aviso, estos tests protegen algo más de fondo: que el repertorio
# guardado sea **el único**. Antes había dos —el de la base de datos, congelado en
# la captura, y el que el combate recalculaba por nivel— y no coincidían.
class Pokemons::LearnMovesTest < ActiveSupport::TestCase

  def pikachu
    @pikachu ||= begin
      pokemon = pokemons(:bulbasaur_del_entrenador)
      pokemon.update!(name: 'Pikachu', num_pokedex: 25, level: 5,
                      atack0: 'Thunder shock', atack1: 'Growl',
                      atack2: nil, atack3: nil)
      pokemon
    end
  end

  def subir_a(nivel, desde: 5)
    pikachu.update!(level: nivel)
    Pokemons::LearnMoves.execute(pokemon: pikachu, from_level: desde).value
  end

  test 'con hueco libre, aprende y lo cuenta' do
    con_pokeapi_simulada do
      # Pikachu aprende Thunder Wave a nivel 9.
      eventos = subir_a(9)

      assert_equal [:learned], eventos.map { |e| e[:type] }
      assert_equal 'Thunder wave', eventos.first[:move]
      assert_includes pikachu.reload.move_names, 'Thunder wave'
    end
  end

  test 'sin subir de nivel no aprende nada' do
    con_pokeapi_simulada do
      assert_empty Pokemons::LearnMoves.execute(pokemon: pikachu, from_level: 5).value
    end
  end

  test 'no vuelve a aprender lo que ya sabe' do
    con_pokeapi_simulada do
      # Growl lo aprende a nivel 1 y ya está en la lista; subir de nivel no debe
      # meterlo otra vez ni gastar un hueco.
      subir_a(9, desde: 0)

      assert_equal pikachu.reload.move_names.uniq, pikachu.move_names
    end
  end

  test 'con los cuatro huecos llenos olvida el más antiguo y dice cuál' do
    con_pokeapi_simulada do
      pikachu.update!(atack0: 'Thunder shock', atack1: 'Growl',
                      atack2: 'Thunder wave', atack3: 'Quick attack')

      # Swift a nivel 26.
      eventos = subir_a(26, desde: 16)
      reemplazo = eventos.find { |e| e[:type] == :replaced }

      assert reemplazo, 'debería contarse como reemplazo, no como aprendizaje limpio'
      assert_equal 'Thunder shock', reemplazo[:forgot], 'el más antiguo es el que sale'
      assert_equal 'Swift', reemplazo[:move]
      assert_not_includes pikachu.reload.move_names, 'Thunder shock'
      assert_includes pikachu.move_names, 'Swift'
    end
  end

  test 'nunca pasa de cuatro movimientos' do
    con_pokeapi_simulada do
      subir_a(100, desde: 0)

      assert_operator pikachu.reload.move_names.size, :<=, Pokemons::MoveSet::SLOTS
    end
  end

  test 'el repertorio guardado es el que se lleva al combate' do
    con_pokeapi_simulada do
      subir_a(43, desde: 5)
      guardados = pikachu.reload.move_names

      combate = Pokemons::MoveSet.for_battle(num_pokedex: pikachu.num_pokedex,
                                             level: pikachu.level,
                                             known: guardados)

      assert_equal guardados, combate.map { |move| move['label'] }
    end
  end

  test 'quien sólo sabe movimientos de estado sigue pudiendo pelear' do
    con_pokeapi_simulada do
      pikachu.update!(atack0: 'Growl', atack1: nil, atack2: nil, atack3: nil)

      combate = Pokemons::MoveSet.for_battle(num_pokedex: pikachu.num_pokedex,
                                             level: 5, known: pikachu.move_names)

      # Struggle, como en el juego: si no, dos Pokémon así se mirarían para siempre.
      # Se comprueba por nombre y no por potencia: lo que se guarda en la sesión
      # son sólo los campos para pintar el botón (`SESSION_FIELDS`), y la potencia
      # se vuelve a pedir al resolver el turno.
      assert_includes combate.map { |move| move['name'] }, Pokemons::MoveSet::STRUGGLE['name']
      assert_includes combate.map { |move| move['name'] }, 'growl', 'lo que sabe se conserva'
    end
  end

end
