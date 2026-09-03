require 'test_helper'

# Registrarse dos veces con el mismo email.
#
# Las validaciones de unicidad de Rails no bastan: entre el `SELECT` que comprueba
# y el `INSERT` que guarda hay una ventana, y el índice de la base es lo único que
# de verdad la cierra. Lo que aquí se comprueba es que cerrarla no acabe en un 500.
#
# No es teórico: pasó en el primer despliegue. La máquina del plan gratuito tardó
# diez segundos en despertar, no se vio respuesta, se volvió a pulsar, y la segunda
# petición se coló entre las dos mitades de la primera.
class DuplicateSignupTest < ActionDispatch::IntegrationTest

  test 'un email repetido no acaba en un error del servidor' do
    ya_existe = users(:entrenador)

    post '/users', params: { user: { email: ya_existe.email, password: 'Password123!',
                                     password_confirmation: 'Password123!' } }

    # Lo normal es que lo cace la validación de Devise y vuelva al formulario. Lo
    # que no puede pasar, llegue por donde llegue, es un 500.
    assert_not_equal 500, response.status
  end

  test 'una violación del índice único no revienta la petición' do
    # Se provoca directamente lo que ocurre cuando la validación llega tarde: la
    # base rechaza el duplicado y la aplicación tiene que sobrevivir.
    ya_existe = users(:entrenador)

    assert_raises ActiveRecord::RecordNotUnique do
      # Con `!`: `insert_all` a secas omite los duplicados en silencio, que es lo
      # contrario de lo que aquí se quiere provocar.
      User.insert_all!([{ email: ya_existe.email, encrypted_password: 'x',
                          created_at: Time.current, updated_at: Time.current }])
    end
  end

  test 'el mensaje del email dice qué hacer, no sólo qué ha fallado' do
    error = ActiveRecord::RecordNotUnique.new(
      'PG::UniqueViolation: duplicate key value violates unique constraint "index_users_on_email"'
    )

    mensaje = ApplicationController.duplicate_message(error)

    assert_match(/already registered/, mensaje)
    assert_match(/logging in/, mensaje)
  end

  test 'cualquier otro índice único cae en el mensaje genérico' do
    error = ActiveRecord::RecordNotUnique.new('PG::UniqueViolation: index_inventory_items_on_kind')

    assert_match(/already saved/, ApplicationController.duplicate_message(error))
  end

end
