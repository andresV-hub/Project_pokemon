module Pokemons
  # Los cuatro movimientos que un Pokémon sabe a su nivel.
  #
  # Hasta ahora se cogían los cuatro primeros del array que devuelve la PokeAPI,
  # que **no son los que aprende subiendo de nivel** sino los de máquina: un
  # Pikachu de nivel 5 aparecía sabiendo Mega Punch.
  #
  # Se toman los últimos aprendidos hasta su nivel, como en el juego.
  #
  # Durante un tiempo se descartaban además los que no hacían daño, porque los
  # efectos de estado no estaban implementados y un Growl habría sido un turno
  # perdido. El precio era que a un Bulbasaur de nivel 20 le salían **dos**
  # movimientos en cuatro huecos, sin nada que explicara el hueco. Ahora que los
  # estados y los cambios de estadística existen, el filtro sobra.
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

    # Lo único que se guarda en la sesión del encuentro: lo justo para pintar el
    # botón del movimiento.
    #
    # La cookie de sesión son 4 KB y el estado guarda ocho movimientos, cuatro por
    # bando. Al añadirles los datos de estado —`ailment`, `stat_changes`,
    # `healing`, `drain`— el encuentro dejó de caber y el combate reventaba con
    # `CookieOverflow` nada más empezar.
    #
    # Todo lo demás se vuelve a pedir al resolver el turno: está en el caché de
    # `Pokeapi::Client` y es gratis, mientras que arrastrarlo en cada petición no
    # lo era.
    SESSION_FIELDS = %w[name label type pp damage_class].freeze

    # Los movimientos con los que un Pokémon entra en combate, recortados y con
    # los PP llenos.
    #
    # Vivía copiado en `Encounters::Start`, en `Encounters::StartTrainer` y en el
    # controlador, con el mismo cuerpo en los tres sitios.
    # `known` son los movimientos que el Pokémon tiene guardados. Cuando se pasan,
    # el combate usa **esos** y no los que le tocarían por nivel: son la misma
    # cosa, y tenerlas separadas hacía que la ficha enseñara un repertorio y el
    # combate usara otro. Un Bulbasaur capturado a nivel 5 y subido a 30 mostraba
    # Tackle y Growl mientras peleaba con Razor Leaf.
    def self.for_battle(num_pokedex:, level:, known: nil)
      moves = if known.present?
        known.filter_map { |name| ::Pokeapi::FindMove.execute(name: name).value }
      else
        raw = ::Pokeapi::Client.get("pokemon/#{num_pokedex}")
        raw && execute(raw_pokemon: raw, level: level).value
      end
      return [] if moves.blank?

      # Struggle ocupa el último hueco y no reemplaza al repertorio entero: un
      # Magikarp sigue sabiendo Splash aunque no le sirva para ganar, igual que en
      # `service_execute`.
      moves = moves.last(SLOTS - 1) + [STRUGGLE.dup] if moves.none? { |move| move['power'].to_i.positive? }

      moves.map { |move| move.slice(*SESSION_FIELDS).merge('pp_left' => move['pp']) }
    end

    # Los movimientos que se aprenden **al pasar** de un nivel a otro. Es lo que
    # permite anunciarlo: hasta ahora el repertorio se recalculaba entero en cada
    # combate y cambiaba sin que nadie lo contase.
    def self.learned_between(num_pokedex:, from:, to:)
      raw = ::Pokeapi::Client.get("pokemon/#{num_pokedex}")
      return [] if raw.nil?

      names_with_levels(raw, to).select { |_, level| level > from.to_i }.map(&:first)
    end

    # Nombres y nivel de aprendizaje, del más antiguo al más reciente.
    def self.names_with_levels(raw, level)
      Array(raw['moves']).filter_map do |entry|
        detail = Array(entry['version_group_details']).find do |version|
          version.dig('version_group', 'name') == VERSION_GROUP &&
            version.dig('move_learn_method', 'name') == 'level-up' &&
            version['level_learned_at'].to_i <= level.to_i
        end
        next if detail.nil?

        [entry.dig('move', 'name'), detail['level_learned_at'].to_i]
      end.sort_by(&:last)
    end

    def initialize(raw_pokemon:, level:)
      @raw = raw_pokemon
      @level = level.to_i
    end

    def service_execute
      names = learnable_names
      moves = names.filter_map { |name| ::Pokeapi::FindMove.execute(name: name).value }
      known = moves.last(SLOTS)

      # Sin nada que haga daño no hay forma de ganar un combate: Magikarp a nivel
      # 5 sólo sabe Splash. Struggle ocupa entonces el último hueco en lugar de
      # añadirse a los cuatro, para no dar un movimiento de más.
      known = known.last(SLOTS - 1) + [STRUGGLE.dup] if known.none? { |move| move['power'].to_i.positive? }

      ServiceResult.new(value: known)
    end

    private

    def learnable_names
      self.class.names_with_levels(@raw, @level).map(&:first)
    end

  end
end
