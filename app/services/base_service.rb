=begin

Base de los servicios de la aplicación.

Cada servicio implementa `service_execute`, que no debe invocarse directamente:
se llama siempre a través de `execute`, que es lo que permitiría añadir
instrumentación o control de errores en un solo sitio.

== Qué devuelve un servicio

No todos devuelven lo mismo, y es deliberado:

* Los que hablan con la PokeAPI (`Pokeapi::*`, `Encounters::Start`…) devuelven un
  `ServiceResult`, porque necesitan distinguir «no hay resultado» de «falló la
  consulta», y quien los llama tiene que poder reaccionar a cada caso.
* Los de escritura sencilla (`Pokemons::Create`, `Pokemons::Update`…) devuelven el
  objeto o el resultado del guardado. Envolverlos no aportaría nada: si algo va
  mal, `save!` ya levanta la excepción.

El comentario original de esta clase afirmaba que **todos** devolvían
`ServiceResult` y traía comentada una comprobación que lo habría impuesto. No era
cierto, así que se ha documentado la convención real en lugar de mantener una
promesa que el código no cumple.

== Por qué no hay un rescue genérico aquí

Lo hubo comentado, y se decidió no activarlo. Un `rescue` en la clase base
convertiría también los errores internos en objetos de resultado: el
`RecordNotFound` de `Base::Find`, por ejemplo, produce hoy un 404 correcto, y
envuelto reventaría más tarde en la vista y lejos de la causa.

Los fallos del sistema externo se capturan donde ocurren, en
`Pokeapi::Client#request`, que traduce a `nil` la red caída, los tiempos de espera
y las respuestas ilegibles.

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
  def self.execute(*args, **kwargs, &block)
    new(*args, **kwargs, &block).execute
  end

  def execute
    service_execute
  end

  def service_execute
    raise 'Must be implemented by subclasses'
  end

end
