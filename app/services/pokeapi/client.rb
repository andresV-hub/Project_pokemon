module Pokeapi
  # Cliente mínimo de la PokeAPI. Centraliza la URL base, el parseo de JSON y
  # el tratamiento de los 404, que antes estaban repetidos en cada controlador.
  module Client

    BASE_URL = 'https://pokeapi.co/api/v2'.freeze
    TIMEOUT = 10

    module_function

    # Devuelve el JSON del recurso, o nil si la PokeAPI responde 404.
    def get(path, params = {})
      parse(RestClient::Request.execute(method: :get, url: "#{BASE_URL}/#{path}", headers: { params: params }, timeout: TIMEOUT))
    rescue RestClient::NotFound
      nil
    end

    def get_url(url)
      parse(RestClient::Request.execute(method: :get, url: url, timeout: TIMEOUT))
    rescue RestClient::NotFound
      nil
    end

    def parse(response)
      JSON.parse(response.body)
    end

  end
end
