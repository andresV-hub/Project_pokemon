module Pokeapi
  # Cliente mínimo de la PokeAPI. Centraliza la URL base, el parseo de JSON y
  # el tratamiento de los 404, que antes estaban repetidos en cada controlador.
  #
  # Las respuestas se cachean: los recursos de la PokeAPI son inmutables en la
  # práctica (los datos de un Pokémon de la primera generación no van a cambiar),
  # y sin caché cada página del catálogo dispara 1 + 15 peticiones de red.
  module Client

    BASE_URL = 'https://pokeapi.co/api/v2'.freeze
    TIMEOUT = 10
    CACHE_TTL = 30.days

    module_function

    # Devuelve el JSON del recurso, o nil si la PokeAPI responde 404.
    def get(path, params = {})
      cached("#{BASE_URL}/#{path}", params) do
        request(url: "#{BASE_URL}/#{path}", params: params)
      end
    end

    def get_url(url)
      cached(url) { request(url: url) }
    end

    def parse(response)
      JSON.parse(response.body)
    end

    # `skip_nil` evita guardar los 404: son pocos y así un recurso que aparezca
    # más adelante no queda marcado como inexistente durante un mes.
    def cached(url, params = {}, &block)
      Rails.cache.fetch(cache_key(url, params), expires_in: CACHE_TTL, skip_nil: true, &block)
    end

    def cache_key(url, params = {})
      key = params.present? ? "#{url}?#{params.to_query}" : url
      "pokeapi/#{Digest::SHA256.hexdigest(key)}"
    end

    # Cualquier fallo de la PokeAPI se traduce a `nil`, que es lo que los
    # servicios de arriba ya saben tratar: `SearchPokemons` devuelve una página
    # vacía y las vistas pintan el estado de error, y `FindPokemon` devuelve un
    # ServiceResult con error y el controlador redirige.
    #
    # Se captura aquí, en el borde con el sistema externo, y no en BaseService:
    # un `rescue` genérico en la clase base convertiría también los errores
    # internos —por ejemplo el RecordNotFound de `Base::Find`, que hoy produce un
    # 404 correcto— en un ServiceResult que reventaría más adelante, en la vista
    # y con un mensaje incomprensible.
    def request(url:, params: {})
      parse(RestClient::Request.execute(method: :get, url: url, headers: { params: params }, timeout: TIMEOUT))
    rescue RestClient::NotFound
      nil
    rescue RestClient::Exception, SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, JSON::ParserError => e
      Rails.logger.error("[Pokeapi] #{e.class}: #{e.message} (#{url})")
      nil
    end

  end
end
