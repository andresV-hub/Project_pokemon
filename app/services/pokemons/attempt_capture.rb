module Pokemons
  # Tirada de captura. Es lo que convierte capturar en un acto con riesgo en vez
  # de en el envío de un formulario que nunca falla.
  #
  # La probabilidad sale sólo del ratio de captura de la especie, que ya venía
  # guardándose y hasta ahora se mostraba como un porcentaje decorativo. El
  # `multiplier` existe para las Poké Balls de la fase de tienda: hoy vale
  # siempre 1.0, pero deja la fórmula preparada para no tener que reescribirla.
  #
  #   Pokemons::AttemptCapture.execute(capture_rate: 18).value
  #   # => { caught: false, probability: 0.18 }
  #
  class AttemptCapture < BaseService

    # Intentos por encuentro. Si se agotan, se puede volver a entrar en la ficha
    # y probar otra vez: sin mapa ni economía, una huida definitiva sólo frustra.
    MAX_ATTEMPTS = 3

    def initialize(capture_rate:, multiplier: 1.0)
      # El decorador de especie ya devuelve el ratio como porcentaje (0-100).
      @capture_rate = capture_rate.to_i
      @multiplier = multiplier.to_f
    end

    def service_execute
      ServiceResult.new(value: { caught: caught?, probability: probability })
    end

    def probability
      return 0.0 unless @capture_rate.positive?

      [(@capture_rate / 100.0) * @multiplier, 1.0].min
    end

    private

    # Aislado para poder fijarlo en las pruebas.
    def caught?
      rand < probability
    end

  end
end
