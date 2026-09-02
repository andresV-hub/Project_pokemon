module Pokemons
  # Estadísticas efectivas de un Pokémon según su nivel.
  #
  # Hasta la fase 10 el combate usaba las estadísticas base tal cual y un nivel
  # ficticio igual para todos: subir de nivel no cambiaba nada y la única forma
  # de progresar era acumular Pokémon.
  #
  # Es la fórmula de primera generación sin IVs ni EVs, que aquí no existen.
  module LevelStats

    module_function

    # Margen de resistencia. Con movimientos reales, cuya potencia llega a 120,
    # la fórmula de HP a secas dejaba a un Pokémon KO de un solo golpe: un Petal
    # Dance con bonus de tipo hacía el 124% de su vida.
    #
    # No se toca el daño porque su dispersión es deseable —que un movimiento
    # fuerte y súper efectivo se lleve el combate es lo que hace que elegir
    # importe—; lo que faltaba era aguante para que esa decisión llegue a
    # tomarse más de una vez.
    HP_SCALE = 1.5

    # El HP crece más deprisa que el resto: es lo que hace que un Pokémon de
    # nivel alto aguante, y no sólo pegue más fuerte.
    def hp(base, level)
      ((((2 * base.to_i * level.to_i) / 100) + level.to_i + 10) * HP_SCALE).round
    end

    def stat(base, level)
      ((2 * base.to_i * level.to_i) / 100) + 5
    end

    # La curva de experiencia **ya no vive aquí**: está en
    # `Pokemons::ExperienceCurve`, porque depende de la especie y no sólo del
    # nivel. Lo que había era `n³` para todo el mundo, que resultó ser exactamente
    # la curva `medium` del juego; dejar aquí una copia sería tener dos sitios
    # donde se decide lo mismo, y en cuanto se separen el nivel que muestra la
    # ficha dejará de ser el que calcula el combate.
    MAX_LEVEL = 100

    # Nivel con el que nace un Pokémon capturado. Su experiencia tiene que
    # corresponderse: creado con nivel 5 y experiencia 0, el primer combate lo
    # recalculaba a nivel 3 y el jugador veía a su Pokémon *bajar* de nivel.
    STARTING_LEVEL = 5

    # Experiencia que da derrotar a un rival, con la fórmula de gen 1.
    def experience_from(base_experience:, level:)
      [((base_experience.to_i * level.to_i) / 7.0).round, 1].max
    end

  end
end
