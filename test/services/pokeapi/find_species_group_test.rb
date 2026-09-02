require 'test_helper'

# Los grupos de especies por hábitat y por color, que es lo que hace posible
# filtrar el catálogo sin pedir las 151 especies una a una.
class Pokeapi::FindSpeciesGroupTest < ActiveSupport::TestCase

  def grupo(kind, name)
    Pokeapi::FindSpeciesGroup.execute(kind: kind, name: name).value
  end

  test 'el hábitat raro es exactamente la lista de legendarios de Kanto' do
    con_pokeapi_simulada do
      # Articuno, Zapdos, Moltres, Mewtwo y Mew. Por eso el filtro de legendarios
      # sale de la API y no de una lista escrita a mano.
      assert_equal [144, 145, 146, 150, 151], grupo(:habitat, 'rare')
    end
  end

  test 'se recorta a la primera generación' do
    con_pokeapi_simulada do
      numeros = grupo(:color, 'pink')

      assert numeros.any?
      assert numeros.all? { |n| n <= Pokeapi::SearchPokemons::POKEDEX_LIMIT },
             'el grupo trae especies de todas las generaciones y el catálogo es sólo Kanto'
    end
  end

  test 'vienen ordenados' do
    con_pokeapi_simulada do
      numeros = grupo(:color, 'pink')

      assert_equal numeros.sort, numeros
    end
  end

  test 'un nombre inventado no llega a pedirse a la API' do
    con_pokeapi_simulada do
      # El nombre llega por la URL. Sin validarlo antes, cualquier cosa acabaría
      # en una petición a un recurso que no existe — y aquí, en un fixture que
      # falta y hace reventar el test.
      assert_nil grupo(:habitat, 'inventado')
      assert_nil grupo(:color, 'turquesa')
    end
  end

  test 'un color no vale como hábitat' do
    con_pokeapi_simulada do
      assert_nil grupo(:habitat, 'pink')
    end
  end

  test 'una clase de grupo desconocida no revienta' do
    con_pokeapi_simulada do
      assert_nil grupo(:tamano, 'grande')
    end
  end

  test 'la página filtrada pagina sobre el grupo, no sobre el catálogo' do
    con_pokeapi_simulada do
      pagina = Pokeapi::SearchPokemons.execute(page: 1, per_page: 15,
                                               ids: [16, 19]).value

      assert_equal 2, pagina.total_count, 'el total es el del grupo, no las 151'
      assert_equal [16, 19], pagina.map(&:num_pokedex)
    end
  end

end
