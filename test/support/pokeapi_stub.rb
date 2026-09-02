# Sirve respuestas guardadas de la PokeAPI en lugar de ir a la red.
#
# Sin esto, los tests de todo lo que consulta la API serían lentos, dependerían de
# que pokeapi.co esté disponible y podrían cambiar de resultado si la API cambia
# un dato. Las respuestas de `test/fixtures/files/pokeapi/` son reales, recortadas
# a los campos que la aplicación lee.
module PokeapiStub

  RUTA = Rails.root.join('test/fixtures/files/pokeapi')

  # Envuelve el bloque con `Pokeapi::Client.get` sirviendo ficheros.
  #
  # Se sustituye el método a mano en lugar de usar el `stub` de Minitest porque
  # Minitest 6 ya no incluye `minitest/mock`, y añadir una gema sólo para esto no
  # compensa: son cuatro líneas.
  def con_pokeapi_simulada
    original = ::Pokeapi::Client.method(:get)

    ::Pokeapi::Client.define_singleton_method(:get) do |path, _params = {}|
      fichero = RUTA.join("#{path.tr('/', '_')}.json")
      raise "Falta el fixture #{fichero.basename} — guárdalo o revisa la ruta pedida" unless fichero.exist?

      JSON.parse(File.read(fichero))
    end

    # El caché guardaría las respuestas simuladas y las arrastraría a otros
    # tests; se limpia para que cada uno parta de cero.
    Rails.cache.clear
    yield
  ensure
    ::Pokeapi::Client.define_singleton_method(:get, original) if original
    Rails.cache.clear
  end

end
