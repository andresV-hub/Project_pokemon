require 'test_helper'

# Cambiar de Pokémon a voluntad.
class Encounters::SwitchPokemonTest < ActiveSupport::TestCase

  setup do
    @yo = users(:entrenador)
    @activo = @yo.pokemon.order(:id).first
    @activo.update!(party_position: 1)
    @banquillo = @yo.pokemon.create!(@activo.attributes.except('id')
                                            .merge('nickname' => 'Relevo', 'party_position' => 2))
  end

  def estado(**extra)
    {
      'trainer_pokemon_id' => @activo.id,
      'trainer_hp' => 10, 'trainer_max_hp' => @activo.max_hp,
      'own_status' => 'poison', 'own_status_turns' => 0,
      'own_stages' => { 'attack' => -2 },
      'log' => []
    }.merge(extra)
  end

  def cambiar(id, state = estado)
    Encounters::SwitchPokemon.execute(state: state, user: @yo, pokemon_id: id)
  end

  test 'el que entra pasa a ser el del campo, con su vida' do
    final = cambiar(@banquillo.id).value

    assert_equal @banquillo.id, final['trainer_pokemon_id']
    assert_equal @banquillo.current_hp, final['trainer_hp']
    assert_equal @banquillo.max_hp, final['trainer_max_hp']
  end

  test 'entra limpio de estado y de escalones' do
    final = cambiar(@banquillo.id).value

    # Los escalones se pierden al salir del campo, como en el juego. El estado
    # alterado también, que es una simplificación consciente: no se guarda en la
    # base de datos, así que dura lo que dura el Pokémon en el campo.
    assert_nil final['own_status']
    assert_empty final['own_stages']
  end

  test 'se cuentan los dos movimientos, quién vuelve y quién sale' do
    log = cambiar(@banquillo.id).value['log'].join(' ')

    assert_match(/come back!/, log)
    assert_match(/Go, Relevo!/, log)
  end

  test 'no se cambia al que ya está peleando' do
    assert_equal :already_out, cambiar(@activo.id).error
  end

  test 'no se saca a uno debilitado' do
    @banquillo.take_damage!(@banquillo.max_hp)

    assert_equal :fainted, cambiar(@banquillo.id).error
  end

  test 'no se saca a uno que no está en el equipo' do
    guardado = @yo.pokemon.create!(@activo.attributes.except('id')
                                         .merge('nickname' => 'Guardado', 'party_position' => nil))

    # Llega como parámetro de la petición: sin esto bastaría con el id de
    # cualquier Pokémon del PC —o del de otro— para meterlo en combate.
    assert_equal :not_in_party, cambiar(guardado.id).error
  end

  test 'no se saca al Pokémon de otro entrenador' do
    ajeno = pokemons(:charmander_del_rival)

    assert_equal :not_in_party, cambiar(ajeno.id).error
  end

  test 'el relevo forzado y el cambio dejan el campo igual' do
    # Los dos usan `SendOut`: si se separan, un arreglo de la vida al entrar
    # valdría para un caso y no para el otro.
    voluntario = cambiar(@banquillo.id).value
    @activo.take_damage!(@activo.max_hp)
    forzado = Encounters::NextOwnPokemon.execute(state: estado, user: @yo).value

    assert_equal forzado['trainer_pokemon_id'], voluntario['trainer_pokemon_id']
    assert_equal forzado['trainer_hp'], voluntario['trainer_hp']
    assert_equal forzado['own_stages'], voluntario['own_stages']
  end

end
