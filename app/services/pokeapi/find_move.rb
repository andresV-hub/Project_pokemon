module Pokeapi
  # Datos de un movimiento: tipo, potencia, precisión, PP y si es físico o
  # especial. Son unos pocos cientos de recursos que no cambian nunca, así que el
  # caché del cliente los sirve casi siempre.
  class FindMove < BaseService

    def initialize(name:)
      @name = name.to_s.downcase.tr(' ', '-')
    end

    def service_execute
      move = Client.get("move/#{@name}")
      return ServiceResult.new(value: nil) if move.nil?

      ServiceResult.new(value: {
        'name' => move['name'],
        'label' => move['name'].to_s.tr('-', ' ').capitalize,
        'type' => move.dig('type', 'name'),
        'power' => move['power'],
        'accuracy' => move['accuracy'],
        'pp' => move['pp'],
        # Físico o especial decide qué estadísticas entran en la fórmula; los de
        # estado no hacen daño y aquí no se usan.
        'damage_class' => move.dig('damage_class', 'name')
      })
    end

  end
end
