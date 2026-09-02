require 'test_helper'

# Que cada página se pinte sin reventar.
#
# La suite tenía 127 tests en verde mientras la pantalla de combate devolvía un
# 500: un comentario `<%# %>` mal colocado dentro de un `<%= render %>`. Se
# descubrió jugando a mano, y podría haber llegado a producción. Ningún test
# renderizaba una sola vista.
#
# Estos no comprueban qué dice cada página —de eso se ocupan los tests de cada
# flujo— sino que existe y responde. Es la red más barata contra la clase entera de
# fallo: errores de sintaxis en ERB, partials renombrados, helpers que ya no
# existen y rutas mal escritas en una vista.
class PagesRenderTest < ActionDispatch::IntegrationTest

  include Devise::Test::IntegrationHelpers

  setup do
    @yo = users(:entrenador)
    @mio = @yo.pokemon.order(:id).first
    @mio.update!(party_position: 1)
  end

  test 'la portada se pinta sin sesión' do
    con_pokeapi_simulada do
      get root_path

      assert_response :success
    end
  end

  test 'las páginas de acceso se pintan' do
    get new_user_session_path
    assert_response :success

    get new_user_registration_path
    assert_response :success

    get new_user_password_path
    assert_response :success
  end

  test 'las páginas del entrenador se pintan' do
    sign_in @yo

    con_pokeapi_simulada do
      {
        'Mi PC' => "/user/#{@yo.id}/pokemon",
        'equipo' => "/user/#{@yo.id}/pokemon/party",
        'ficha propia' => "/user/#{@yo.id}/pokemon/#{@mio.id}",
        'tienda' => "/user/#{@yo.id}/shop",
        'Centro Pokémon' => "/user/#{@yo.id}/center",
        'exploración' => "/user/#{@yo.id}/explore",
        'ajustes de cuenta' => '/users/edit'
      }.each do |nombre, ruta|
        get ruta

        assert_response :success, "la página de #{nombre} (#{ruta}) no se pinta"
      end
    end
  end

  test 'el catálogo y la ficha de especie se pintan' do
    sign_in @yo

    con_pokeapi_simulada do
      # `per_page: 1` a propósito: el catálogo pide el detalle de cada especie de
      # la página, y con la página completa harían falta quince fixtures por cada
      # rama que se quiera probar. Lo que aquí importa es que la vista se pinte,
      # no cuántas tarjetas trae.
      get "/user/#{@yo.id}/pokedex", params: { per_page: 1 }
      assert_response :success

      # Con filtro puesto, que es otra rama de la misma vista.
      get "/user/#{@yo.id}/pokedex", params: { habitat: 'rare', per_page: 1 }
      assert_response :success

      get "/user/#{@yo.id}/pokedex/25"
      assert_response :success
    end
  end

  test 'la pantalla de combate se pinta' do
    sign_in @yo

    con_pokeapi_simulada do
      # Justo el caso que se coló: la vista más compleja de la aplicación, y la
      # única que no se puede alcanzar sin montar antes un encuentro.
      post "/user/#{@yo.id}/encounter/start", params: { zone: 'route_1' }
      follow_redirect!

      assert_response :success
      assert_match(/Wild encounter/, response.body)
    end
  end

  test 'la pantalla de elegir movimiento se pinta' do
    sign_in @yo
    @mio.update!(atack0: 'Tackle', atack1: 'Growl', atack2: 'Leech seed',
                 atack3: 'Poison powder', pending_move: 'Vine whip')

    get "/user/#{@yo.id}/pokemon/#{@mio.id}/learn_move"

    assert_response :success
    assert_match(/Vine whip/, response.body)
  end

  test 'sin movimiento pendiente esa pantalla no se queda colgada' do
    sign_in @yo
    @mio.update!(pending_move: nil)

    get "/user/#{@yo.id}/pokemon/#{@mio.id}/learn_move"

    assert_redirected_to user_pokemon_path(user_id: @yo.id, id: @mio.id)
  end

  test 'la API en JSON responde' do
    sign_in @yo

    con_pokeapi_simulada do
      get '/api/v1/pokemons', as: :json

      assert_response :success
      assert_nothing_raised { JSON.parse(response.body) }
    end
  end

end
