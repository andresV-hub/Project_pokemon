require 'test_helper'

# Comprar mueve dinero y entrega objeto. Lo que se protege es que las dos cosas
# ocurran juntas o no ocurra ninguna: nadie puede quedarse sin saldo y sin bola,
# ni al revés.
class Shop::BuyTest < ActiveSupport::TestCase

  setup do
    @rico = users(:entrenador)   # ₽1000
    @pobre = users(:rival)       # ₽0
  end

  test 'comprar descuenta el precio y entrega el objeto' do
    resultado = Shop::Buy.execute(user: @rico, kind: 'great_ball')

    assert_nil resultado.error
    assert_equal 1000 - Shop::Catalog.price('great_ball'), @rico.reload.money
    assert_equal 1, @rico.inventory_items.find_by(kind: 'great_ball').quantity
  end

  test 'sin saldo no se compra ni se descuenta nada' do
    resultado = Shop::Buy.execute(user: @pobre, kind: 'poke_ball')

    assert_equal :not_enough_money, resultado.error
    assert_equal 0, @pobre.reload.money
    assert_empty @pobre.inventory_items
  end

  test 'no se puede comprar algo que no existe en el catálogo' do
    resultado = Shop::Buy.execute(user: @rico, kind: 'master_ball')

    assert_equal :unknown_item, resultado.error
    assert_equal 1000, @rico.reload.money
  end

  test 'comprar dos veces acumula en la misma fila' do
    2.times { Shop::Buy.execute(user: @rico, kind: 'poke_ball') }

    assert_equal 1, @rico.inventory_items.where(kind: 'poke_ball').count
    assert_equal 2, @rico.inventory_items.find_by(kind: 'poke_ball').quantity
  end

  test 'una cantidad no positiva se rechaza' do
    resultado = Shop::Buy.execute(user: @rico, kind: 'poke_ball', quantity: 0)

    assert_equal :invalid_quantity, resultado.error
    assert_equal 1000, @rico.reload.money
  end

  test 'gastar una bola la descuenta del inventario' do
    @rico.inventory_items.create!(kind: 'poke_ball', quantity: 2)

    Shop::UseBall.execute(user: @rico, kind: 'poke_ball')

    assert_equal 1, @rico.inventory_items.find_by(kind: 'poke_ball').reload.quantity
  end

  test 'no se puede gastar una bola que no se tiene' do
    resultado = Shop::UseBall.execute(user: @rico, kind: 'ultra_ball')

    assert_equal :out_of_stock, resultado.error
  end

  test 'el inventario no baja de cero' do
    @rico.inventory_items.create!(kind: 'poke_ball', quantity: 1)

    Shop::UseBall.execute(user: @rico, kind: 'poke_ball')
    resultado = Shop::UseBall.execute(user: @rico, kind: 'poke_ball')

    assert_equal :out_of_stock, resultado.error
    assert_equal 0, @rico.inventory_items.find_by(kind: 'poke_ball').quantity
  end

end
