require 'test_helper'

# Quedarse sin ningún Pokémon dejaba la cuenta inservible: explorar exige equipo y
# la Pokédex ya no captura, así que no había forma de conseguir uno. Estos tests
# cubren las dos puertas de salida.
class NoPokemonTest < ActionDispatch::IntegrationTest

  include Devise::Test::IntegrationHelpers

  setup do
    @yo = users(:entrenador)
    sign_in @yo
  end

  test 'no se puede soltar el último Pokémon' do
    @yo.pokemon.where.not(id: @yo.pokemon.order(:id).first.id).destroy_all
    ultimo = @yo.pokemon.order(:id).first

    assert_no_difference -> { @yo.pokemon.count } do
      patch "/user/#{@yo.id}/pokemon/#{ultimo.id}/liberate_pokemon"
    end
    assert_match(/last Pokémon/, flash[:alert])
  end

  test 'con más de uno sí se puede soltar' do
    @yo.pokemon.create!(@yo.pokemon.first.attributes.except('id', 'party_position')
                            .merge('nickname' => 'Sobrante'))
    sobrante = @yo.pokemon.order(:id).last

    assert_difference -> { @yo.pokemon.count }, -1 do
      patch "/user/#{@yo.id}/pokemon/#{sobrante.id}/liberate_pokemon"
    end
  end

  test 'sin ninguno, el PC ofrece elegir un inicial' do
    @yo.pokemon.destroy_all

    get "/user/#{@yo.id}/pokemon"

    assert_response :success
    assert_match(/You do not have any Pokémon/, response.body)
    assert_match(%r{pokemon/starter}, response.body)
  end

  test 'elegir un inicial lo entrega y lo pone en el equipo' do
    con_pokeapi_simulada do
      @yo.pokemon.destroy_all

      assert_difference -> { @yo.pokemon.count }, 1 do
        post "/user/#{@yo.id}/pokemon/starter", params: { starter_num_pokedex: 25 }
      end

      recibido = @yo.pokemon.order(:id).last
      assert_equal 'Pikachu', recibido.name
      assert_equal 1, recibido.party_position, 'el inicial entra al equipo, no al PC'
    end
  end

  test 'teniendo Pokémon no se puede pedir otro inicial' do
    con_pokeapi_simulada do
      # Sin esto, cualquiera podría fabricarse Pokémon gratis repitiendo la
      # petición: es la única acción que crea uno sin combatir.
      assert_no_difference -> { @yo.pokemon.count } do
        post "/user/#{@yo.id}/pokemon/starter", params: { starter_num_pokedex: 25 }
      end
    end
  end

  test 'una especie que no es inicial cae en el primero de la lista' do
    con_pokeapi_simulada do
      @yo.pokemon.destroy_all

      # Mewtwo no está en la lista; el formulario manipulado no debe colar.
      post "/user/#{@yo.id}/pokemon/starter", params: { starter_num_pokedex: 150 }

      assert_equal User::STARTERS.keys.first, @yo.pokemon.order(:id).last.num_pokedex
    end
  end

end
