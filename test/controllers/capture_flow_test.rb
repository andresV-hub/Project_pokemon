require 'test_helper'

# Capturar es un flujo de dos pasos: primero la tirada, y sólo si sale bien se
# guarda el Pokémon con su apodo.
#
# Lo que se protege aquí es que el segundo paso no se pueda invocar por su cuenta:
# sin la comprobación, bastaba con llamar directamente al guardado para saltarse
# la tirada y capturar siempre.
class CaptureFlowTest < ActionDispatch::IntegrationTest

  include Devise::Test::IntegrationHelpers

  setup do
    @yo = users(:entrenador)
    sign_in @yo
    @yo.inventory_items.create!(kind: Shop::Catalog::STARTING_KIND, quantity: 5)
  end

  test 'no se puede guardar un Pokémon sin haber ganado la tirada' do
    con_pokeapi_simulada do
      assert_no_difference -> { @yo.pokemon.count } do
        post "/user/#{@yo.id}/pokedex/add_pokemon_to_team",
             params: { pokemon_id: 25, nickname: 'Colado', user_id: @yo.id }
      end

      assert_response :see_other
    end
  end

  test 'la tirada ganada autoriza el guardado, y sólo una vez' do
    con_pokeapi_simulada do
      # El fixture de Pikachu lleva `capture_rate: 255`, con lo que la
      # probabilidad es 1.0 y la tirada siempre acierta: aquí se comprueba la
      # autorización, no el azar.
      post "/user/#{@yo.id}/pokedex/attempt_capture",
           params: { pokemon_id: 25 }.to_json,
           headers: { 'Content-Type' => 'application/json' }

      assert_response :success
      assert JSON.parse(response.body)['caught']

      assert_difference -> { @yo.pokemon.count }, 1 do
        post "/user/#{@yo.id}/pokedex/add_pokemon_to_team",
             params: { pokemon_id: 25, nickname: 'Sparky', user_id: @yo.id }
      end

      # El permiso se consume: repetir el guardado no duplica el Pokémon.
      assert_no_difference -> { @yo.pokemon.count } do
        post "/user/#{@yo.id}/pokedex/add_pokemon_to_team",
             params: { pokemon_id: 25, nickname: 'Otra vez', user_id: @yo.id }
      end
    end
  end

  test 'el apodo en blanco se queda con el nombre de la especie' do
    con_pokeapi_simulada do
      post "/user/#{@yo.id}/pokedex/attempt_capture",
           params: { pokemon_id: 25 }.to_json,
           headers: { 'Content-Type' => 'application/json' }

      post "/user/#{@yo.id}/pokedex/add_pokemon_to_team",
           params: { pokemon_id: 25, nickname: '', user_id: @yo.id }

      # El modelo exige apodo: sin este respaldo, dejarlo vacío reventaba.
      assert_equal 'Pikachu', @yo.pokemon.order(:id).last.nickname
    end
  end

end
