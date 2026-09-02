require 'test_helper'

# Los objetos de curación. Lo que más importa aquí es que **no se gasten en
# balde**: un objeto consumido sin efecto es dinero perdido por un despiste de la
# interfaz, y eso el juego no lo hace.
class Shop::UseItemTest < ActiveSupport::TestCase

  def pokemon
    @pokemon ||= pokemons(:bulbasaur_del_entrenador)
  end

  def usuario
    pokemon.user
  end

  def con(kind, cantidad = 1)
    usuario.inventory_items.create!(kind: kind, quantity: cantidad)
  end

  def usar(kind)
    Shop::UseItem.execute(user: usuario, kind: kind, pokemon: pokemon)
  end

  test 'una poción cura y se gasta' do
    con('potion')
    pokemon.take_damage!(25)

    resultado = usar('potion')

    assert_nil resultado.error
    assert_equal 20, resultado.value
    assert_equal 0, usuario.inventory_items.find_by(kind: 'potion').quantity
  end

  test 'una poción no cura más de lo que falta ni se pasa del máximo' do
    con('super_potion')
    pokemon.take_damage!(5)

    # Super Potion cura 50, pero sólo faltaban 5.
    assert_equal 5, usar('super_potion').value
    assert pokemon.reload.full_health?
  end

  test 'no se gasta una poción en un Pokémon a tope' do
    con('potion')

    assert_equal :already_full, usar('potion').error
    assert_equal 1, usuario.inventory_items.find_by(kind: 'potion').quantity
  end

  test 'no se gasta una poción en un Pokémon debilitado' do
    con('potion')
    pokemon.take_damage!(pokemon.max_hp)

    assert_equal :already_fainted, usar('potion').error
    assert_equal 1, usuario.inventory_items.find_by(kind: 'potion').quantity
  end

  test 'un Revive devuelve la mitad de la vida a un debilitado' do
    con('revive')
    pokemon.take_damage!(pokemon.max_hp)

    assert_nil usar('revive').error
    assert_not pokemon.reload.fainted?
    assert_equal (pokemon.max_hp / 2.0).ceil, pokemon.current_hp
  end

  test 'un Revive no sirve con uno que sigue en pie' do
    con('revive')
    pokemon.take_damage!(5)

    assert_equal :not_fainted, usar('revive').error
    assert_equal 1, usuario.inventory_items.find_by(kind: 'revive').quantity
  end

  test 'sin existencias no se cura nada' do
    pokemon.take_damage!(20)

    assert_equal :out_of_stock, usar('potion').error
  end

  test 'una bola no es un objeto de curación' do
    con('poke_ball', 5)
    pokemon.take_damage!(20)

    # Lanzarle una Poké Ball a tu propio Pokémon no lo cura, y sobre todo no debe
    # gastarla: las bolas se usan por su propia acción.
    assert_equal :unknown_item, usar('poke_ball').error
    assert_equal 5, usuario.inventory_items.find_by(kind: 'poke_ball').quantity
  end

  test 'perder cuesta la mitad del dinero' do
    assert_equal 500, Encounters::Rules.defeat_penalty(1000)
    assert_equal 0, Encounters::Rules.defeat_penalty(1), 'sin dinero no hay nada que perder'
  end

end
