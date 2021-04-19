=begin

Cada servicio debe sobreescribir `service_execute`, donde se ejecuta la lógica
del servicio. Este método no debe invocarse nunca directamente, sino que siempre
se debe invocar el método `execute`.

Los servicios tienen que devolver SIEMPRE un objeto `ServiceResult`. 
Para saber si un servicio funcionó bien o no, estos objetos tienen un método `success?`.
- Si funcionan bien, el resultado está accesible a través del método `.value`.
- Si fallan, el resultado captura la expeción, y la deja disponible en
el método `.error`.

=end
class BaseService

  # Permite definir los métodos de instancia y no de clase en las subclases,
  # pero a la vez permite llamarlos como si fuesen de clase.
  #
  # Por convención, se utilizará de la siguiente manera:
  #
  #   MyService.execute(param1: arg1, param2: arg2...)
  #
  # aunque también se puede utilizar así:
  #
  #   my_service = MyService.new(param1: arg1, param2: arg2...)
  #   my_service.execute
  #
  # Ambas son equivalentes. La segunda permite obtener una referencia al servicio,
  # que puede ser útil para obtener el estado interno.
  def self.execute(*args, &block)
    new(*args, &block).execute
  end

  def execute
    # begin
      result = service_execute
    # rescue Exception => e
    #   return ServiceResult.new(error: e)
    # end
    
    # raise TypeError, 'Los servicios tienen que devolver un objeto de tipo ServiceResult' unless result.is_a?(ServiceResult)

    result
  end

  def service_execute
    raise 'Must be implemented by subclasses'
  end

end