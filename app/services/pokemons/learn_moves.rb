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
      return nil if same?(@pokemon.pending_move, label)

      if known.size < SLOTS
        write(known + [label])
        { type: :learned, move: label }
      else
        # Con los cuatro huecos llenos, el juego pregunta cuál olvidar, así que
        # aquí también: el movimiento queda **pendiente** y la elección se resuelve
        # en su propia pantalla al salir del combate.
        #
        # Sólo uno a la vez. Si se subieran varios niveles de golpe y llegaran dos,
        # encolarlos obligaría a una cola en la base de datos para un caso que en
        # la práctica no ocurre: se gana un nivel por combate.
        return nil if @pokemon.pending_move.present?

        @pokemon.pending_move = label
        { type: :pending, move: label }
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
