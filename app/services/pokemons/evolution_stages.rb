module Pokemons
  # Aplana el árbol de evolución de la PokeAPI a una lista de etapas, que es como
  # se lee en el juego: una fila por escalón, y dentro de cada fila todas las
  # formas posibles.
  #
  #   [[{ Bulbasaur }], [{ Ivysaur, 'Lv. 16' }], [{ Venusaur, 'Lv. 32' }]]
  #
  # La mayoría de cadenas son lineales, pero hay que soportar la ramificación:
  # Eevee tiene ocho evoluciones en la misma etapa.
  class EvolutionStages < BaseService

    # Tope de seguridad: ninguna cadena real pasa de tres escalones, y evita un
    # bucle infinito si la API devolviera una estructura inesperada.
    MAX_DEPTH = 5

    # El sprite se construye a partir del id en lugar de pedir `/pokemon/{id}`
    # por cada eslabón: la cadena de Eevee tiene nueve, y serían nueve peticiones
    # sólo para pintar unas miniaturas. Es el mismo `front_default` que sirve la
    # PokeAPI, y el que el decorador ya usa como última alternativa.
    SPRITE_URL = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/%d.png'.freeze

    def initialize(chain:)
      @chain = chain
    end

    def service_execute
      return ServiceResult.new(value: []) if @chain.blank?

      stages = []
      current = [@chain]
      depth = 0

      while current.any? && depth < MAX_DEPTH
        stages << current.filter_map { |node| link_for(node) }
        current = current.flat_map { |node| Array(node['evolves_to']) }
        depth += 1
      end

      ServiceResult.new(value: stages.reject(&:empty?))
    end

    private

    def link_for(node)
      id = species_id(node)
      return nil if id.nil?

      {
        id: id,
        name: node.dig('species', 'name').to_s.capitalize,
        image: format(SPRITE_URL, id),
        condition: condition_for(node['evolution_details'])
      }
    end

    # El id no viene como campo: hay que sacarlo del final de la URL de especie.
    def species_id(node)
      node.dig('species', 'url').to_s[%r{/pokemon-species/(\d+)/?$}, 1]&.to_i
    end

    # Se muestra sólo el primer detalle: una evolución puede tener varias
    # condiciones alternativas según la versión del juego, y enumerarlas todas
    # llenaría la ficha de ruido.
    def condition_for(details)
      detail = Array(details).first
      return nil if detail.blank?

      case detail.dig('trigger', 'name')
      when 'level-up' then level_up_condition(detail)
      when 'use-item' then humanize(detail.dig('item', 'name'))
      when 'trade' then trade_condition(detail)
      when 'shed' then 'Empty slot + Poké Ball'
      else humanize(detail.dig('trigger', 'name')) || 'Special'
      end
    end

    def level_up_condition(detail)
      return "Lv. #{detail['min_level']}" if detail['min_level'].present?
      return 'High friendship' if detail['min_happiness'].present?
      return "Knows #{humanize(detail.dig('known_move', 'name'))}" if detail.dig('known_move', 'name').present?
      return "At #{humanize(detail.dig('location', 'name'))}" if detail.dig('location', 'name').present?

      'Level up'
    end

    def trade_condition(detail)
      item = humanize(detail.dig('held_item', 'name'))
      item.present? ? "Trade holding #{item}" : 'Trade'
    end

    def humanize(value)
      return nil if value.blank?

      value.to_s.tr('-', ' ').capitalize
    end

  end
end
