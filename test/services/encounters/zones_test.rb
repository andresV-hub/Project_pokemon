require 'test_helper'

# Las zonas y su tabla de encuentros. Lo que se protege aquí es sobre todo que la
# tabla se lea bien: la API tiene una trampa en este endpoint y ya nos costó
# encontrarla una vez.
class Encounters::ZonesTest < ActiveSupport::TestCase

  # --- El catálogo --------------------------------------------------------

  test 'las zonas van de menor a mayor exigencia' do
    niveles = Encounters::Zones.all.map { |zone| zone[:unlock] }

    assert_equal niveles.sort, niveles, 'el orden del catálogo es el del mapa: hacia arriba'
  end

  test 'la primera zona está abierta desde el primer momento' do
    assert_equal 1, Encounters::Zones.default[:unlock]
    assert Encounters::Zones.unlocked?(Encounters::Zones.default[:key], 1)
  end

  test 'una zona alta está cerrada para un equipo flojo' do
    assert_not Encounters::Zones.unlocked?('cerulean_cave', 5)
    assert Encounters::Zones.unlocked?('cerulean_cave', 46)
  end

  test 'una zona inventada no está desbloqueada ni con nivel 100' do
    # La zona llega como parámetro de la petición, así que esto es lo que impide
    # colarse escribiendo cualquier cosa.
    assert_not Encounters::Zones.unlocked?('kanto-fake-area', 100)
    assert_nil Encounters::Zones.find('kanto-fake-area')
  end

  test 'subir de nivel abre zonas y no cierra ninguna' do
    pocas = Encounters::Zones.unlocked_for(5)
    muchas = Encounters::Zones.unlocked_for(50)

    assert_operator muchas.size, :>, pocas.size
    assert_equal pocas, muchas.first(pocas.size)
  end

  # --- La tabla de la API -------------------------------------------------

  test 'la tabla trae especie, peso y niveles' do
    con_pokeapi_simulada do
      tabla = Pokeapi::FindZoneEncounters.execute(area: 'kanto-route-1-area').value

      assert_equal %w[pidgey rattata].sort, tabla.map { |row| row['name'] }.sort
      pidgey = tabla.find { |row| row['name'] == 'pidgey' }
      assert_equal 16, pidgey['num_pokedex']
      assert_operator pidgey['weight'], :>, 0
      assert_operator pidgey['min_level'], :>, 0
      assert_operator pidgey['max_level'], :>=, pidgey['min_level']
    end
  end

  test 'el peso se suma de los detalles y no se toma de max_chance' do
    con_pokeapi_simulada do
      tabla = Pokeapi::FindZoneEncounters.execute(area: 'kanto-power-plant-area').value
      voltorb = tabla.find { |row| row['name'] == 'voltorb' }

      # `max_chance` da 630 para este Voltorb, que ni es un porcentaje ni guarda
      # proporción con sus compañeros. La suma de sus dos entradas a pie da 30, en
      # línea con Magnemite. Si esto se rompe, Voltorb se come la zona entera.
      assert_equal 30, voltorb['weight']
    end
  end

  test 'quien no aparece a pie no entra en la tabla' do
    con_pokeapi_simulada do
      nombres = Pokeapi::FindZoneEncounters.execute(area: 'kanto-power-plant-area').value
                                           .map { |row| row['name'] }

      # Electrode y Zapdos figuran en la zona con un `max_chance` alto pero sin un
      # solo encuentro a pie: son encuentros fijos del juego, no hierba.
      assert_not_includes nombres, 'electrode'
      assert_not_includes nombres, 'zapdos'
    end
  end

  # --- La tirada ----------------------------------------------------------

  test 'sólo sale lo que vive en la zona, y a su nivel' do
    con_pokeapi_simulada do
      30.times do
        salida = Encounters::DrawFromZone.execute(zone_key: 'route_1').value

        assert_includes %w[Pidgey Rattata], salida[:pokemon].name
        assert_includes 2..5, salida[:level], 'los niveles son los del juego, no los del jugador'
      end
    end
  end

  test 'una zona desconocida cae en la primera en vez de reventar' do
    con_pokeapi_simulada do
      salida = Encounters::DrawFromZone.execute(zone_key: 'no-existe').value

      assert_equal 'route_1', salida[:zone][:key]
    end
  end

end
