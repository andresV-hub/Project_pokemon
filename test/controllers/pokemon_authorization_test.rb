require 'test_helper'

# Nadie puede operar sobre los Pokémon de otra persona.
#
# Esto no es hipotético: el controlador resolvía el Pokémon con
# `Base::Find.execute(id: params[:id])`, que busca por identificador sin mirar de
# quién es. Bastaba conocer un id ajeno para liberarlo, renombrarlo o moverlo, y
# el `user_id` de la ruta no protegía nada porque lo pone quien llama.
#
# Está arreglado, y estos tests existen para que no vuelva.
class PokemonAuthorizationTest < ActionDispatch::IntegrationTest

  include Devise::Test::IntegrationHelpers

  setup do
    @yo = users(:entrenador)
    @otro = users(:rival)
    @suyo = pokemons(:charmander_del_rival)
    @mio = pokemons(:bulbasaur_del_entrenador)
    sign_in @yo
  end

  # Las acciones que no llaman a la PokeAPI: el 404 salta antes de que haga falta.
  ACCIONES_AJENAS = {
    'liberar' => :liberate_pokemon,
    'renombrar' => :edit_nickname,
    'llevar al equipo' => :add_to_party,
    'devolver al PC' => :send_to_pc
  }.freeze

  ACCIONES_AJENAS.each do |descripcion, accion|
    test "no se puede #{descripcion} el Pokémon de otro usuario" do
      patch "/user/#{@yo.id}/pokemon/#{@suyo.id}/#{accion}",
            params: { pokemon: { nickname: 'Robado' } }

      assert_response :not_found
    end
  end

  test 'el Pokémon ajeno queda intacto tras intentarlo todo' do
    antes = @suyo.attributes.slice('nickname', 'party_position')

    ACCIONES_AJENAS.each_value do |accion|
      patch "/user/#{@yo.id}/pokemon/#{@suyo.id}/#{accion}",
            params: { pokemon: { nickname: 'Robado' } }
    end

    assert Pokemon.exists?(@suyo.id), 'el Pokémon ajeno fue borrado'
    assert_equal antes, @suyo.reload.attributes.slice('nickname', 'party_position')
  end

  test 'poner el user_id ajeno en la ruta tampoco sirve' do
    # El `user_id` viene de la URL: si se usara como filtro, bastaría con
    # cambiarlo para saltarse la comprobación.
    patch "/user/#{@otro.id}/pokemon/#{@suyo.id}/liberate_pokemon"

    assert_response :not_found
    assert Pokemon.exists?(@suyo.id)
  end

  test 'devuelve 404 y no 403, para no delatar que ese id existe' do
    patch "/user/#{@yo.id}/pokemon/#{@suyo.id}/edit_nickname",
          params: { pokemon: { nickname: 'Robado' } }

    assert_response :not_found
    assert_no_match(/rival|Llamita|Charmander/i, response.body)
  end

  # --- Y sobre lo propio sí se puede -----------------------------------------

  test 'sobre el Pokémon propio las acciones funcionan' do
    patch "/user/#{@yo.id}/pokemon/#{@mio.id}/send_to_pc"
    assert_response :see_other
    assert_nil @mio.reload.party_position

    patch "/user/#{@yo.id}/pokemon/#{@mio.id}/add_to_party"
    assert_response :see_other
    assert_equal 1, @mio.reload.party_position
  end

  test 'renombrar el propio cambia el apodo' do
    patch "/user/#{@yo.id}/pokemon/#{@mio.id}/edit_nickname",
          params: { pokemon: { nickname: 'Nuevo nombre' } }

    assert_response :see_other
    assert_equal 'Nuevo nombre', @mio.reload.nickname
  end

  test 'sin sesión no se llega a ninguna parte' do
    sign_out @yo

    patch "/user/#{@yo.id}/pokemon/#{@mio.id}/liberate_pokemon"

    assert_response :redirect
    assert_equal 'Verdecito', @mio.reload.nickname
  end

end
