module Encounters
  # Sortea un rival de fuerza comparable a la del Pokémon que lo va a combatir.
  #
  # Sortear entre los 151 sin más parecía lo natural, pero a un inicial le tocaba
  # Dragonite uno de cada tres encuentros: medido, ganaba entre el 16% y el 30%
  # de los combates. Con esa proporción los entrenadores casi nunca pagan y la
  # economía del juego no arranca.
  #
  # El emparejamiento usa el total de estadísticas base, que es la medida honesta
  # de lo fuerte que es una especie, y deja un margen por encima para que el
  # combate no esté ganado de antemano.
  class DrawOpponent < BaseService

    # Cuánto más fuerte puede ser el rival. Por encima de esto, se vuelve a
    # sortear.
    STRENGTH_MARGIN = 1.15

    # Intentos antes de rendirse y aceptar el último candidato: la alternativa
    # sería buscar sin fin si el jugador lleva algo muy débil.
    MAX_DRAWS = 6

    def initialize(reference_total:)
      @limit = reference_total * STRENGTH_MARGIN
    end

    def service_execute
      candidate = nil

      MAX_DRAWS.times do
        candidate = ::Pokeapi::FindPokemon.execute(id: rand(1..::Pokeapi::SearchPokemons::POKEDEX_LIMIT)).value
        next if candidate.nil?
        break if self.class.base_total(candidate) <= @limit
      end

      ServiceResult.new(value: candidate)
    end

    # Suma de las seis estadísticas base.
    def self.base_total(pokemon)
      pokemon.stat_list.sum { |stat| stat[:value].to_i }
    end

  end
end
