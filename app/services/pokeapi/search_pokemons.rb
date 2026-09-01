module Pokeapi
  # Devuelve una página de pokémon de la PokeAPI, ya decorados y envueltos en un
  # paginador de Kaminari.
  #
  # La paginación se delega en los parámetros `limit` y `offset` de la propia
  # API: sólo se descarga la página solicitada, no el catálogo completo. Kaminari
  # recibe el total real (`count`) para poder pintar los enlaces de página.
  #
  #   Pokeapi::SearchPokemons.execute(page: 3, per_page: 16).value
  #
  class SearchPokemons < BaseService

    DEFAULT_PER_PAGE = 16
    MAX_PER_PAGE = 60

    attr_reader :page, :per_page

    def initialize(page: nil, per_page: nil)
      @page = normalize_page(page)
      @per_page = normalize_per_page(per_page)
    end

    def service_execute
      listing = Client.get('pokemon', limit: per_page, offset: offset)
      return ServiceResult.new(value: empty_page) if listing.nil?

      ServiceResult.new(
        value: Kaminari.paginate_array(
          decorated_pokemons(listing['results']),
          total_count: listing['count'],
          limit: per_page,
          offset: offset
        )
      )
    end

    def offset
      (page - 1) * per_page
    end

    private

    # Cada elemento del listado sólo trae nombre y URL; hay que pedir el detalle
    # de cada uno para poder decorarlo.
    def decorated_pokemons(results)
      results.filter_map do |result|
        detail = Client.get_url(result['url'])
        ::Pokedex::PokedexDecorator.decorate(detail) if detail
      end
    end

    def empty_page
      Kaminari.paginate_array([], total_count: 0, limit: per_page, offset: 0)
    end

    def normalize_page(value)
      number = value.to_i
      number.positive? ? number : 1
    end

    def normalize_per_page(value)
      number = value.to_i
      return DEFAULT_PER_PAGE unless number.positive?

      [number, MAX_PER_PAGE].min
    end

  end
end
