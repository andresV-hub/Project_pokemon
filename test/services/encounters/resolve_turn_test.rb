require 'test_helper'

# El turno de combate. Es el servicio con más reglas de la aplicación y hasta
# ahora el único sin cubrir: se escribieron sus tests antes de añadirle los
# movimientos de estado, precisamente porque esa fase lo reescribe por dentro.
class Encounters::ResolveTurnTest < ActiveSupport::TestCase

  def pikachu_crudo
    JSON.parse(File.read(PokeapiStub::RUTA.join('pokemon_25.json')))
  end

  # El rival, tal y como lo construye el controlador: decorado sobre la respuesta
  # de la PokeAPI.
  def salvaje
    Pokedex::PokedexDecorator.decorate(pikachu_crudo)
  end

  def propio
    Pokemons::PokemonDecorator.decorate(pokemons(:bulbasaur_del_entrenador))
  end

  def movimiento(nombre)
    Pokeapi::FindMove.execute(name: nombre).value.merge('pp_left' => 10)
  end

  # Un estado de combate con los dos a tope y un movimiento cada uno.
  def estado(mio: 'tackle', rival: 'tackle', **extra)
    {
      'name' => 'Pikachu', 'num_pokedex' => 25, 'level' => 20, 'trainer_level' => 20,
      'wild_hp' => 200, 'wild_max_hp' => 200,
      'trainer_hp' => 200, 'trainer_max_hp' => 200,
      'own_moves' => [movimiento(mio)], 'rival_moves' => [movimiento(rival)],
      'log' => []
    }.merge(extra)
  end

  def resolver(state, indice = 0)
    Encounters::ResolveTurn.execute(state: state, trainer_pokemon: propio,
                                    wild: salvaje, move_index: indice).value
  end

  # Para los movimientos que pueden fallar la tirada de precisión —Thunder Wave
  # tiene 90— y cuyo efecto es justo lo que se quiere comprobar. Sin esto el test
  # falla una de cada diez veces por el azar y no por el comportamiento.
  def resolver_acertando(state, indice = 0)
    10.times do
      final = resolver(state, indice)
      return final unless final['log'].join(' ').include?('missed')
    end

    flunk 'el movimiento falló diez veces seguidas: revisa la precisión del fixture'
  end

  test 'ambos atacan y ambos pierden vida' do
    con_pokeapi_simulada do
      final = resolver(estado)

      assert_operator final['wild_hp'], :<, 200, 'el rival debería recibir daño'
      assert_operator final['trainer_hp'], :<, 200, 'el propio debería recibir daño'
      assert_match(/used Tackle!/, final['log'].join(' '))
    end
  end

  test 'atacar gasta un PP del movimiento usado' do
    con_pokeapi_simulada do
      final = resolver(estado)

      assert_equal 9, final['own_moves'].first['pp_left']
    end
  end

  test 'el rival no gasta PP: sus movimientos no se agotan' do
    con_pokeapi_simulada do
      final = resolver(estado)

      assert_equal 10, final['rival_moves'].first['pp_left']
    end
  end

  test 'un índice fuera de rango cae en el primer movimiento en vez de reventar' do
    con_pokeapi_simulada do
      final = resolver(estado, 99)

      assert_operator final['wild_hp'], :<, 200
    end
  end

  test 'cuando el rival cae el combate termina y no contraataca' do
    con_pokeapi_simulada do
      # Tackle y no Thunder: Thunder tiene 70 de precisión y el test fallaría
      # una de cada tres veces por la tirada, no por el comportamiento.
      #
      # Y con la iniciativa asegurada: desde que el orden lo decide la velocidad,
      # Pikachu (90) pega antes que Bulbasaur (45), y lo que aquí se comprueba es
      # lo que ocurre *después* de derribarlo.
      final = resolver(estado('wild_hp' => 1, 'wild_max_hp' => 200, 'own_stages' => { 'speed' => 6 }))

      assert_equal 'wild_fainted', final['over']
      assert_equal 200, final['trainer_hp'], 'un rival derribado no debería devolver el golpe'
      assert_match(/fainted/, final['log'].join(' '))
    end
  end

  test 'cuando cae el propio se marca la derrota' do
    con_pokeapi_simulada do
      final = resolver(estado('trainer_hp' => 1, 'trainer_max_hp' => 200))

      assert_equal 'trainer_fainted', final['over']
      assert_match(/no energy left/, final['log'].join(' '))
    end
  end

  test 'la efectividad de tipo se calcula con el tipo del movimiento, no el del Pokémon' do
    con_pokeapi_simulada do
      # Bulbasaur es Grass/Poison y el rival Pikachu es Electric. Thunder Shock,
      # eléctrico, es poco efectivo contra Grass.
      final = resolver(estado(rival: 'thunder-shock'))

      assert_match(/not very effective/, final['log'].join(' '))
    end
  end

  test 'el log no arrastra las líneas del turno anterior' do
    con_pokeapi_simulada do
      final = resolver(estado('log' => ['línea vieja que no debe seguir ahí']))

      assert_not_includes final['log'].join(' '), 'línea vieja'
    end
  end

  test 'la vida nunca baja de cero' do
    con_pokeapi_simulada do
      final = resolver(estado('wild_hp' => 1))

      assert_equal 0, final['wild_hp']
    end
  end

  # --- Movimientos que no hacen daño --------------------------------------

  test 'un movimiento de estado paraliza al rival y no le quita vida' do
    con_pokeapi_simulada do
      final = resolver_acertando(estado(mio: 'thunder-wave'))

      assert_equal 'paralysis', final['rival_status']
      assert_equal 200, final['wild_hp'], 'Thunder Wave no hace daño'
      assert_match(/is paralyzed/, final['log'].join(' '))
    end
  end

  test 'un cambio de estadística negativo va contra el rival' do
    con_pokeapi_simulada do
      final = resolver(estado(mio: 'growl'))

      assert_equal(-1, final['rival_stages']['attack'])
      assert_match(/attack fell!/, final['log'].join(' '))
    end
  end

  test 'un cambio de estadística positivo va sobre uno mismo' do
    con_pokeapi_simulada do
      final = resolver(estado(mio: 'agility'))

      assert_equal 2, final['own_stages']['speed']
      assert_nil final['rival_stages']['speed'], 'Agility no toca al rival'
      assert_match(/sharply rose/, final['log'].join(' '))
    end
  end

  test 'los escalones se acumulan entre turnos' do
    con_pokeapi_simulada do
      primero = resolver(estado(mio: 'agility'))
      segundo = resolver(primero.merge('own_moves' => [movimiento('agility')]))

      assert_equal 4, segundo['own_stages']['speed']
    end
  end

  test 'bajar el ataque del rival reduce el daño que hace' do
    con_pokeapi_simulada do
      base = resolver(estado)
      dano_normal = 200 - base['trainer_hp']

      debilitado = resolver(estado('rival_stages' => { 'attack' => -6 }))
      dano_reducido = 200 - debilitado['trainer_hp']

      assert_operator dano_reducido, :<=, dano_normal
    end
  end

  test 'un movimiento de curación recupera vida y no pasa del máximo' do
    con_pokeapi_simulada do
      final = resolver(estado(mio: 'recover', 'trainer_hp' => 100, 'trainer_max_hp' => 200))

      # Recover cura el 50% del máximo, pero el rival contraataca en el mismo
      # turno: lo que se comprueba es que subió respecto a los 100 de partida.
      assert_operator final['trainer_hp'], :>, 100
      assert_operator final['trainer_hp'], :<=, 200
      assert_match(/regained health/, final['log'].join(' '))
    end
  end

  test 'curar a tope avisa en vez de desperdiciar el turno en silencio' do
    con_pokeapi_simulada do
      # Con la iniciativa: si pega el rival primero, ya no está a tope y curarse
      # sería legítimo.
      final = resolver(estado(mio: 'recover', 'own_stages' => { 'speed' => 6 }))

      assert_match(/already full/, final['log'].join(' '))
    end
  end

  test 'un movimiento sin efecto conocido lo dice en vez de no contar nada' do
    con_pokeapi_simulada do
      final = resolver(estado(mio: 'splash'))

      assert_match(/nothing happened/, final['log'].join(' '))
    end
  end

  test 'un estado no sustituye a otro' do
    con_pokeapi_simulada do
      final = resolver(estado(mio: 'thunder-wave', 'rival_status' => 'sleep', 'rival_status_turns' => 3))

      assert_equal 'sleep', final['rival_status'], 'dormido no debería pasar a paralizado'
    end
  end

  test 'el veneno desgasta al cerrar el turno' do
    con_pokeapi_simulada do
      final = resolver(estado('own_status' => 'poison', 'trainer_max_hp' => 160, 'trainer_hp' => 160))

      assert_match(/hurt by poison/, final['log'].join(' '))
      assert_operator final['trainer_hp'], :<, 160
    end
  end

  test 'quien está dormido pierde el turno y no ataca' do
    con_pokeapi_simulada do
      final = resolver(estado('own_status' => 'sleep', 'own_status_turns' => 2))

      assert_equal 200, final['wild_hp'], 'dormido no debería llegar a golpear'
      assert_match(/is fast asleep/, final['log'].join(' '))
      assert_equal 1, final['own_status_turns'], 'la cuenta atrás tiene que avanzar'
    end
  end

  # --- Orden del turno ----------------------------------------------------

  test 'pega primero el más rápido' do
    con_pokeapi_simulada do
      # Pikachu tiene 90 de velocidad y Bulbasaur 45: sin ayuda, pega el rival.
      final = resolver(estado)

      assert_match(/\APikachu used/, final['log'].first)
    end
  end

  test 'subir la velocidad da la iniciativa' do
    con_pokeapi_simulada do
      final = resolver(estado('own_stages' => { 'speed' => 6 }))

      assert_match(/\AVerdecito used/, final['log'].first)
    end
  end

  test 'la parálisis también quita la iniciativa, no sólo turnos' do
    con_pokeapi_simulada do
      # Paralizado, la velocidad de Pikachu cae a un cuarto y pasa por detrás de
      # Bulbasaur. Es la mitad de la parálisis que no se ve en el registro.
      final = resolver(estado('rival_status' => 'paralysis'))

      assert_match(/\AVerdecito used/, final['log'].first)
    end
  end

  test 'relanzar un estado sobre quien ya lo tiene falla y lo dice' do
    con_pokeapi_simulada do
      final = resolver_acertando(estado(mio: 'thunder-wave', 'rival_status' => 'paralysis',
                                        'own_stages' => { 'speed' => 6 }))

      assert_match(/But it failed!/, final['log'].join(' '))
      assert_no_match(/nothing happened/, final['log'].join(' '))
    end
  end

end
