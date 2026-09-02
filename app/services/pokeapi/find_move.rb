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

      meta = move['meta'] || {}

      ServiceResult.new(value: {
        'name' => move['name'],
        'label' => move['name'].to_s.tr('-', ' ').capitalize,
        'type' => move.dig('type', 'name'),
        'power' => move['power'],
        'accuracy' => move['accuracy'],
        'pp' => move['pp'],
        # Físico, especial o de estado. Decide qué estadísticas entran en la
        # fórmula y, en el tercer caso, que no haya fórmula en absoluto.
        'damage_class' => move.dig('damage_class', 'name'),

        # Lo que hace un movimiento además de —o en lugar de— quitar vida. La API
        # lo trae todo en `meta` y `stat_changes`, y hasta ahora se descartaba
        # entero: por eso los movimientos sin potencia no llegaban al combate.
        #
        # `ailment` vale 'none' cuando no hay ninguno, y se normaliza a nil para
        # no tener que comprobar la cadena mágica en cada sitio.
        'ailment' => meta.dig('ailment', 'name').presence&.then { |a| a == 'none' ? nil : a },
        # Probabilidad del estado como efecto secundario de un movimiento que sí
        # hace daño (Thunder paraliza un 10% de las veces). Los movimientos de
        # estado puros traen 0 aquí: el suyo es seguro si acierta.
        'ailment_chance' => meta['ailment_chance'].to_i,
        'healing' => meta['healing'].to_i,
        'drain' => meta['drain'].to_i,
        'flinch_chance' => meta['flinch_chance'].to_i,
        'stat_changes' => Array(move['stat_changes']).map do |change|
          { 'stat' => change.dig('stat', 'name'), 'change' => change['change'].to_i }
        end
      })
    end

  end
end
