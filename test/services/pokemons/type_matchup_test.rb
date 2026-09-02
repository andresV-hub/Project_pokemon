require 'test_helper'

# Efectividades de tipo. La parte delicada es que con dos tipos los factores se
# multiplican, y de ahí salen los ×4 y los ×¼ que un solo tipo nunca produce.
class Pokemons::TypeMatchupTest < ActiveSupport::TestCase

  test 'con dos tipos los factores se multiplican en ambos sentidos' do
    con_pokeapi_simulada do
      # Charizard es Fire/Flying: Rock le hace ×2 por cada uno, y la inmunidad de
      # Flying a Ground anula la debilidad de Fire.
      matchups = Pokemons::TypeMatchup.execute(type_slugs: %w[fire flying]).value

      assert_equal 4.0, matchups['rock']
      assert_equal 0.0, matchups['ground']
    end
  end

  test 'la doble resistencia produce un cuarto de daño' do
    con_pokeapi_simulada do
      # Bulbasaur es Grass/Poison, y los dos resisten Grass.
      matchups = Pokemons::TypeMatchup.execute(type_slugs: %w[grass poison]).value

      assert_equal 0.25, matchups['grass']
    end
  end

  test 'un solo tipo da los factores de ese tipo' do
    con_pokeapi_simulada do
      matchups = Pokemons::TypeMatchup.execute(type_slugs: ['electric']).value

      assert_equal 2.0, matchups['ground']
      assert_equal 0.5, matchups['electric']
    end
  end

  test 'los tipos neutrales no se devuelven' do
    con_pokeapi_simulada do
      matchups = Pokemons::TypeMatchup.execute(type_slugs: ['electric']).value

      # Un multiplicador de 1 no aporta información y llenaría la ficha de ruido.
      assert_not matchups.key?('normal')
      assert matchups.values.none? { |factor| factor == 1.0 }
    end
  end

  test 'sin tipos no hay efectividades' do
    con_pokeapi_simulada do
      assert_empty Pokemons::TypeMatchup.execute(type_slugs: []).value
    end
  end

end
