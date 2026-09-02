module Pokeapi
  # Las especies de Kanto que comparten un hábitat o un color.
  #
  # La alternativa era pedir `/pokemon-species/{id}` de las 151 y quedarse con las
  # que cuadran: 151 peticiones para pintar un filtro. Estos dos endpoints
  # devuelven el grupo entero **en una sola**, así que filtrar sale prácticamente
  # gratis.
  #
  # De propina, el hábitat `rare` es exactamente la lista de legendarios y míticos
  # de la región —Articuno, Zapdos, Moltres, Mewtwo y Mew—, así que ese filtro sale
  # del mismo sitio y no de una lista escrita a mano.
  class FindSpeciesGroup < BaseService

    HABITATS = %w[cave forest grassland mountain rare rough-terrain sea urban waters-edge].freeze
    COLORS = %w[black blue brown gray green pink purple red white yellow].freeze

    KINDS = { habitat: 'pokemon-habitat', color: 'pokemon-color' }.freeze

    def initialize(kind:, name:)
      @kind = kind.to_sym
      @name = name.to_s
    end

    def self.valid?(kind, name)
      case kind.to_sym
      when :habitat then HABITATS.include?(name.to_s)
      when :color then COLORS.include?(name.to_s)
      else false
      end
    end

    # Devuelve los números de Pokédex, ordenados. `nil` si el grupo no existe o la
    # API no responde: quien llama distingue «no hay filtro» de «filtro vacío».
    def service_execute
      path = KINDS[@kind]
      return ServiceResult.new(value: nil) if path.nil? || !self.class.valid?(@kind, @name)

      raw = Client.get("#{path}/#{@name}")
      return ServiceResult.new(value: nil) if raw.nil?

      numbers = Array(raw['pokemon_species']).filter_map do |species|
        number = species['url'].to_s[%r{/(\d+)/?$}, 1].to_i
        number if number.positive? && number <= SearchPokemons::POKEDEX_LIMIT
      end

      ServiceResult.new(value: numbers.sort)
    end

  end
end
