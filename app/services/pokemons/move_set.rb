module Pokemons
  # Los cuatro movimientos que un Pokémon sabe a su nivel.
  #
  # Hasta ahora se cogían los cuatro primeros del array que devuelve la PokeAPI,
  # que **no son los que aprende subiendo de nivel** sino los de máquina: un
  # Pikachu de nivel 5 aparecía sabiendo Mega Punch.
  #
  # Se toman los últimos aprendidos hasta su nivel, como en el juego, y sólo los
  # que hacen daño: sin efectos de estado implementados, un Growl sería un turno
  # perdido sin nada que enseñar.
  class MoveSet < BaseService

    SLOTS = 4

    # Versión de referencia: la primera generación, que es el catálogo de la
    # aplicación.
    VERSION_GROUP = 'red-blue'.freeze

    # Cuando no hay ningún movimiento ofensivo disponible —Magikarp a nivel 5
    # sólo sabe Splash— se recurre a este, como el Struggle del juego. Sin él,
    # dos Pokémon así se quedarían mirándose para siempre.
    STRUGGLE = {
      'name' => 'struggle', 'label' => 'Struggle', 'type' => 'normal',
      'power' => 50, 'accuracy' => 100, 'pp' => 99, 'damage_class' => 'physical'
    }.freeze

    def initialize(raw_pokemon:, level:)
      @raw = raw_pokemon
      @level = level.to_i
    end

    def service_execute
      names = learnable_names
      moves = names.filter_map { |name| ::Pokeapi::FindMove.execute(name: name).value }
      offensive = moves.select { |move| move['power'].to_i.positive? }

      ServiceResult.new(value: offensive.any? ? offensive.last(SLOTS) : [STRUGGLE.dup])
    end

    private

    # Nombres de los movimientos que aprende por nivel hasta el suyo, del más
    # antiguo al más reciente.
    def learnable_names
      Array(@raw['moves']).filter_map do |entry|
        detail = Array(entry['version_group_details']).find do |version|
          version.dig('version_group', 'name') == VERSION_GROUP &&
            version.dig('move_learn_method', 'name') == 'level-up' &&
            version['level_learned_at'].to_i <= @level
        end
        next if detail.nil?

        [entry.dig('move', 'name'), detail['level_learned_at'].to_i]
      end.sort_by(&:last).map(&:first)
    end

  end
end
