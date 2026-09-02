require 'test_helper'

# Los movimientos que un Pokémon sabe a su nivel.
#
# Antes se cogían los cuatro primeros del array de la PokeAPI, que son los de
# máquina: la ficha decía que un Pikachu de nivel 5 sabía Mega Punch.
class Pokemons::MoveSetTest < ActiveSupport::TestCase

  def pikachu
    JSON.parse(File.read(PokeapiStub::RUTA.join('pokemon_25.json')))
  end

  def magikarp
    JSON.parse(File.read(PokeapiStub::RUTA.join('pokemon_129.json')))
  end

  test 'a nivel bajo sólo sabe lo que ha aprendido hasta ahí' do
    con_pokeapi_simulada do
      movimientos = Pokemons::MoveSet.execute(raw_pokemon: pikachu, level: 5).value

      # Growl entra igual que Thunder Shock: los dos se aprenden a nivel 1, y
      # desde que los estados existen un movimiento sin potencia también es una
      # jugada.
      assert_equal %w[growl thunder-shock], movimientos.map { |m| m['name'] }
    end
  end

  test 'los movimientos de estado también entran' do
    con_pokeapi_simulada do
      movimientos = Pokemons::MoveSet.execute(raw_pokemon: pikachu, level: 40).value

      # Agility no hace daño: sube la velocidad dos escalones. Cuando se
      # descartaba lo que no tenía potencia, un Pikachu de nivel 40 salía al
      # combate con menos movimientos de los que sabe y nada lo explicaba.
      assert_includes movimientos.map { |m| m['name'] }, 'agility'
      assert movimientos.any? { |m| m['damage_class'] == 'status' }
    end
  end

  test 'aunque no haga daño, un movimiento de estado trae su efecto' do
    con_pokeapi_simulada do
      movimientos = Pokemons::MoveSet.execute(raw_pokemon: pikachu, level: 40).value
      agility = movimientos.find { |m| m['name'] == 'agility' }

      assert_equal [{ 'stat' => 'speed', 'change' => 2 }], agility['stat_changes']
      assert_nil agility['power']
    end
  end

  test 'nunca devuelve más de cuatro' do
    con_pokeapi_simulada do
      movimientos = Pokemons::MoveSet.execute(raw_pokemon: pikachu, level: 100).value

      assert_operator movimientos.size, :<=, Pokemons::MoveSet::SLOTS
    end
  end

  test 'a nivel alto conserva los últimos aprendidos' do
    con_pokeapi_simulada do
      movimientos = Pokemons::MoveSet.execute(raw_pokemon: pikachu, level: 50).value

      # Thunder se aprende a nivel 43 y es el más potente que tiene.
      assert_includes movimientos.map { |m| m['name'] }, 'thunder'
    end
  end

  test 'quien no tiene ningún ataque recibe Struggle' do
    con_pokeapi_simulada do
      # Magikarp a nivel 5 sólo sabe Splash, que no hace daño. Sin esto, dos
      # Pokémon así se mirarían eternamente.
      movimientos = Pokemons::MoveSet.execute(raw_pokemon: magikarp, level: 5).value

      # Splash se conserva —lo sabe— y Struggle se añade para que pueda pelear.
      assert_equal %w[splash struggle], movimientos.map { |m| m['name'] }
      assert movimientos.any? { |m| m['power'].to_i.positive? }
    end
  end

  test 'los movimientos traen los datos que el combate necesita' do
    con_pokeapi_simulada do
      movimiento = Pokemons::MoveSet.execute(raw_pokemon: pikachu, level: 50).value.first

      assert movimiento['type'].present?
      assert movimiento['power'].to_i.positive?
      assert movimiento['pp'].to_i.positive?
      assert_includes %w[physical special], movimiento['damage_class']
    end
  end

end
