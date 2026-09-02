module Pokemons
  # Los modificadores de estadística que duran lo que dura el combate.
  #
  # Growl baja el ataque del rival, Swords Dance sube el propio. En los juegos eso
  # no se guarda como un número nuevo sino como un **escalón** de −6 a +6 sobre la
  # estadística de base, y se pierde al acabar el combate. Aquí igual: los
  # escalones viven en la sesión del encuentro y no tocan la base de datos.
  #
  # Es lo que hace que un movimiento sin potencia pueda ganar un combate.
  module StatStages

    module_function

    LIMIT = 6

    # Multiplicador de primera generación: `(2 + n) / 2` hacia arriba y
    # `2 / (2 - n)` hacia abajo. Un escalón de +2 es el doble; uno de −2, la
    # mitad. Simétrico y sin sorpresas.
    def multiplier(stage)
      stage = stage.to_i.clamp(-LIMIT, LIMIT)

      stage.negative? ? 2.0 / (2 - stage) : (2 + stage) / 2.0
    end

    def apply(value, stage)
      [(value.to_i * multiplier(stage)).round, 1].max
    end

    # Suma un escalón respetando el tope. Devuelve el valor nuevo y si llegó a
    # moverse, porque «no puede bajar más» es algo que el combate cuenta.
    def add(current, change)
      updated = (current.to_i + change.to_i).clamp(-LIMIT, LIMIT)

      [updated, updated != current.to_i]
    end

    # Cómo se cuenta el cambio. Dos escalones son «sharply», como en el juego.
    def message(stat, change)
      stat = stat.to_s.tr('-', ' ')
      direction = change.positive? ? 'rose' : 'fell'
      intensity = change.abs >= 2 ? ' sharply' : ''

      "#{stat}#{intensity} #{direction}!"
    end

  end
end
