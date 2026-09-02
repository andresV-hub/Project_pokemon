require 'test_helper'

class ShopTest < ActionDispatch::IntegrationTest

  include Devise::Test::IntegrationHelpers

  setup do
    @yo = users(:entrenador)
    sign_in @yo
  end

  test 'la tienda muestra el catálogo con lo que ya se tiene' do
    @yo.inventory_items.create!(kind: 'poke_ball', quantity: 3)

    get "/user/#{@yo.id}/shop"

    assert_response :success
    Shop::Catalog::ITEMS.each_value { |item| assert_match item[:name], response.body }
    assert_match 'x3', response.body
  end

  test 'comprar desde la tienda descuenta y avisa' do
    post "/user/#{@yo.id}/shop/buy", params: { kind: 'poke_ball' }

    assert_response :see_other
    follow_redirect!
    assert_match 'Poké Ball', response.body
    assert_equal 1000 - Shop::Catalog.price('poke_ball'), @yo.reload.money
  end

  test 'comprar sin saldo avisa y no cobra' do
    @yo.update!(money: 0)

    post "/user/#{@yo.id}/shop/buy", params: { kind: 'ultra_ball' }

    assert_response :see_other
    follow_redirect!
    assert_match(/afford/i, response.body)
    assert_equal 0, @yo.reload.money
  end

  test 'sin sesión la tienda no es accesible' do
    sign_out @yo

    get "/user/#{@yo.id}/shop"

    assert_response :redirect
  end

end
