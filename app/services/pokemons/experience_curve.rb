module Pokemons
  # Cuánta experiencia cuesta cada nivel, según la curva de la especie.
  #
  # Antes lo decidía `LevelStats` con `n³` para todo el mundo. Resulta que `n³` es
  # exactamente la curva `medium` del juego, así que no estaba mal: estaba
  # incompleto. Las seis curvas reales cambian bastante el ritmo —un Bulbasaur
  # `medium-slow` llega a nivel 20 con 5.460 puntos y un Snorlax `slow` necesita
  # 10.000—, y eso es progresión de verdad y no una constante elegida a ojo.
  #
  # == Por qué hay un respaldo
  #
  # Si la API no responde, se vuelve a `n³`. Es la curva `medium` calculada a mano,
  # así que el respaldo no es una invención: es el mismo número que devolvería la
  # API para la curva más común. Un combate no debe quedarse a medias porque
  # pokeapi.co tarde en contestar.
  module ExperienceCurve

    # Curva por defecto, y la que se aplica a los Pokémon que no tienen ninguna
    # guardada: es la que estaban usando todos antes de este cambio.
    DEFAULT = 'medium'.freeze

    MAX_LEVEL = 100

    module_function

    def experience_for(level, rate = DEFAULT)
      level = level.to_i.clamp(1, MAX_LEVEL)
      table = table_for(rate)

      table&.fetch(level, nil) || level**3
    end

    def level_for(experience, rate = DEFAULT)
      experience = experience.to_i
      table = table_for(rate)
      return Math.cbrt(experience).floor.clamp(1, MAX_LEVEL) if table.nil?

      # El nivel más alto cuyo coste ya se ha pagado.
      level = table.select { |_, cost| cost <= experience }.keys.max

      (level || 1).clamp(1, MAX_LEVEL)
    end

    def table_for(rate)
      ::Pokeapi::FindGrowthRate.execute(name: rate.presence || DEFAULT).value
    end

  end
end
