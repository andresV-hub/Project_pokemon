require 'test_helper'

# La vida fuera del combate. Se guarda el daño acumulado y no la vida actual, y
# esa decisión es justo lo que estos tests protegen.
class PokemonHealthTest < ActiveSupport::TestCase

  def pokemon
    @pokemon ||= pokemons(:bulbasaur_del_entrenador)
  end

  test 'recién creado está sano' do
    assert_equal 0, pokemon.damage
    assert pokemon.full_health?
    assert_equal pokemon.max_hp, pokemon.current_hp
  end

  test 'la vida máxima sale del nivel, no de la estadística base' do
    assert_equal Pokemons::LevelStats.hp(pokemon.hp, pokemon.level), pokemon.max_hp

    # 45 es la estadística base de Bulbasaur, y a nivel 5 su vida real es *menor*
    # —29—, no mayor. Por eso el relevo, que usaba la base como vida, entraba
    # inflado a nivel bajo y ridículamente flojo a nivel alto.
    assert_operator pokemon.max_hp, :<, pokemon.hp

    pokemon.update!(level: 40)
    assert_operator pokemon.max_hp, :>, pokemon.hp
  end

  test 'subir de nivel sube la vida actual, no sólo el máximo' do
    pokemon.take_damage!(5)
    antes_max = pokemon.max_hp
    antes_actual = pokemon.current_hp

    pokemon.update!(level: 30)

    assert_operator pokemon.max_hp, :>, antes_max
    assert_operator pokemon.current_hp, :>, antes_actual
    # Guardando la vida actual en vez del daño, el Pokémon se habría quedado con
    # los mismos puntos de siempre tras subir veinticinco niveles.
    assert_equal 5, pokemon.damage
  end

  test 'la vida nunca baja de cero por mucho daño que reciba' do
    pokemon.take_damage!(pokemon.max_hp * 10)

    assert_equal 0, pokemon.current_hp
    assert pokemon.fainted?
  end

  test 'curar del todo lo deja como nuevo' do
    pokemon.take_damage!(pokemon.max_hp)
    assert pokemon.fainted?

    pokemon.heal!

    assert pokemon.full_health?
    assert_not pokemon.fainted?
  end

  test 'curar una cantidad devuelve lo que se ha recuperado de verdad' do
    pokemon.take_damage!(3)

    # Se piden 20 pero sólo faltaban 3: la poción se desperdicia y hay que poder
    # decirlo, en vez de anunciar veinte puntos que nadie recuperó.
    assert_equal 3, pokemon.heal!(20)
    assert pokemon.full_health?
  end

  test 'curar a quien está sano no recupera nada' do
    assert_equal 0, pokemon.heal!(20)
  end

  test 'el Centro cura a todo el equipo de una vez' do
    otro = pokemon.user.pokemon.create!(pokemon.attributes.except('id', 'party_position')
                                                .merge('nickname' => 'Segundo', 'party_position' => 2))
    pokemon.take_damage!(10)
    otro.take_damage!(7)

    assert_equal 2, Pokemons::HealAll.execute(user: pokemon.user).value
    assert pokemon.reload.full_health?
    assert otro.reload.full_health?
  end

  test 'el Centro no cuenta a los que ya estaban sanos' do
    assert_equal 0, Pokemons::HealAll.execute(user: pokemon.user).value
  end

end
