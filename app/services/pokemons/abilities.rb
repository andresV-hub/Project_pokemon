module Pokemons
  # Las habilidades, y qué hace cada una en este combate.
  #
  # No son de primera generación —llegaron en la tercera— y están aquí por decisión
  # de producto. La API las da en cada consulta de un Pokémon y no se usaban.
  #
  # **Sólo se implementan las que tienen dónde aplicarse.** De las 48 que aparecen
  # en Kanto, las tres más comunes dependen del clima —`chlorophyll`,
  # `swift-swim`, `sand-veil`— y aquí no hay clima; otras necesitan mecánicas que
  # no existen, como enamorar o el retroceso. Anunciar una habilidad que no hace
  # nada sería peor que no tenerla: el jugador contaría con ella.
  module Abilities

    module_function

    # --- Al entrar al campo -------------------------------------------------

    # Baja el ataque del rival un escalón nada más salir.
    INTIMIDATE = 'intimidate'.freeze

    # --- Inmunidad por tipo -------------------------------------------------

    # El movimiento de ese tipo no hace nada. Las dos primeras además curan, que es
    # lo que las hace peligrosas de verdad.
    TYPE_IMMUNITY = {
      'levitate' => 'ground', 'water-absorb' => 'water',
      'volt-absorb' => 'electric', 'flash-fire' => 'fire'
    }.freeze

    HEALING_IMMUNITY = %w[water-absorb volt-absorb].freeze

    # Cuánto cura la absorción: un cuarto de la vida máxima.
    ABSORB_FRACTION = 4

    def immune_type(ability) = TYPE_IMMUNITY[ability.to_s]

    def absorbs?(ability) = HEALING_IMMUNITY.include?(ability.to_s)

    # --- Al recibir un golpe ------------------------------------------------

    # Estado que provoca al que te toca. Sólo con movimientos físicos: es lo que
    # significa «por contacto».
    CONTACT_STATUS = {
      'static' => 'paralysis', 'poison-point' => 'poison', 'flame-body' => 'burn'
    }.freeze

    CONTACT_CHANCE = 30

    def contact_status(ability) = CONTACT_STATUS[ability.to_s]

    # --- Inmunidad a estados ------------------------------------------------

    STATUS_IMMUNITY = {
      'limber' => 'paralysis', 'immunity' => 'poison', 'insomnia' => 'sleep',
      'vital-spirit' => 'sleep', 'water-veil' => 'burn', 'magma-armor' => 'freeze'
    }.freeze

    def blocks_status?(ability, status)
      STATUS_IMMUNITY[ability.to_s] == status.to_s
    end

    # --- Daño ---------------------------------------------------------------

    # Con un tercio de vida o menos, los movimientos de su tipo pegan un 50% más.
    # Es la habilidad de los iniciales, y la que hace que un combate perdido pueda
    # darse la vuelta.
    PINCH_BOOST = {
      'overgrow' => 'grass', 'blaze' => 'fire', 'torrent' => 'water', 'swarm' => 'bug'
    }.freeze

    PINCH_FRACTION = 3
    PINCH_FACTOR = 1.5

    def pinch_boost?(ability, move_type, current_hp, max_hp)
      return false unless PINCH_BOOST[ability.to_s] == move_type.to_s
      return false unless max_hp.to_i.positive?

      current_hp.to_i <= max_hp.to_i / PINCH_FRACTION
    end

    # Guts: estar mal aumenta el ataque en vez de estorbarlo. Cancela además la
    # rebaja de la quemadura, que es lo que la hace interesante.
    GUTS = 'guts'.freeze
    GUTS_FACTOR = 1.5

    # Thick Fat: la mitad de daño de Fuego y de Hielo.
    THICK_FAT = 'thick-fat'.freeze
    THICK_FAT_TYPES = %w[fire ice].freeze
    THICK_FAT_FACTOR = 0.5

    def thick_fat?(ability, move_type)
      ability.to_s == THICK_FAT && THICK_FAT_TYPES.include?(move_type.to_s)
    end

    # --- Estadísticas -------------------------------------------------------

    # A quién no se le pueden bajar las estadísticas, y cuáles.
    STAT_GUARD = {
      'hyper-cutter' => %w[attack], 'keen-eye' => %w[accuracy],
      'clear-body' => :all, 'white-smoke' => :all
    }.freeze

    def guards_stat?(ability, stat)
      guard = STAT_GUARD[ability.to_s]
      return false if guard.nil?

      guard == :all || guard.include?(stat.to_s)
    end

    # --- Fin de turno -------------------------------------------------------

    # Shed Skin: se quita el estado solo de vez en cuando.
    SHED_SKIN = 'shed-skin'.freeze
    SHED_SKIN_CHANCE = 0.30

    # --- Presentación -------------------------------------------------------

    def label(ability)
      ability.to_s.tr('-', ' ').split.map(&:capitalize).join(' ')
    end

    # Todas las que el combate sabe aplicar. Sirve para no anunciar en la ficha una
    # que no va a hacer nada.
    def supported
      @supported ||= (TYPE_IMMUNITY.keys + CONTACT_STATUS.keys + STATUS_IMMUNITY.keys +
                      PINCH_BOOST.keys + STAT_GUARD.keys + [INTIMIDATE, GUTS, THICK_FAT, SHED_SKIN]).uniq
    end

    def supported?(ability) = supported.include?(ability.to_s)

  end
end
