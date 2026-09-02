module Pokemons
  # Aprende los movimientos que corresponden al subir de nivel, y cuenta lo que ha
  # pasado.
  #
  # Antes no existía este paso: el repertorio se recalculaba entero en cada
  # combate a partir del nivel, y el que estaba guardado en el Pokémon se quedaba
  # con el que tenía al capturarlo. Es decir, había **dos repertorios distintos**:
  # la ficha de un Bulbasaur de nivel 30 enseñaba Tackle y Growl mientras el
  # combate peleaba con Razor Leaf. Y aprender un movimiento —que en los juegos es
  # un momento— aquí no ocurría, simplemente aparecía otro.
  #
  # Ahora el repertorio guardado es el único, y cambia sólo aquí.
  class LearnMoves < BaseService

    SLOTS = MoveSet::SLOTS

    def initialize(pokemon:, from_level:)
      @pokemon = pokemon
      @from_level = from_level.to_i
    end

    def service_execute
      nuevos = MoveSet.learned_between(num_pokedex: @pokemon.num_pokedex,
                                       from: @from_level, to: @pokemon.level)
      return ServiceResult.new(value: []) if nuevos.empty?

      eventos = nuevos.filter_map { |name| learn(name) }
      @pokemon.save! if eventos.any?

      ServiceResult.new(value: eventos)
    end

    private

    def learn(name)
      label = name.to_s.tr('-', ' ').capitalize
      return nil if known.any? { |sabido| same?(sabido, label) }

      if known.size < SLOTS
        write(known + [label])
        { type: :learned, move: label }
      else
        # Con los cuatro huecos llenos se olvida el más antiguo. En los juegos se
        # pregunta cuál; preguntarlo aquí significaría parar el combate con un
        # diálogo a mitad de turno, así que se resuelve como el juego cuando dices
        # que sí, y **se cuenta** cuál se ha perdido para que no sea una sorpresa.
        olvidado = known.first
        write(known.drop(1) + [label])
        { type: :replaced, move: label, forgot: olvidado }
      end
    end

    def known
      [@pokemon.atack0, @pokemon.atack1, @pokemon.atack2, @pokemon.atack3].compact_blank
    end

    # Los guardados de antes traen la etiqueta con mayúsculas y espacios, y los
    # nombres de la API vienen con guiones: se comparan normalizados para no
    # aprender dos veces el mismo movimiento.
    def same?(one, other)
      one.to_s.downcase.tr(' ', '-') == other.to_s.downcase.tr(' ', '-')
    end

    def write(lista)
      SLOTS.times { |index| @pokemon.public_send("atack#{index}=", lista[index]) }
    end

  end
end
