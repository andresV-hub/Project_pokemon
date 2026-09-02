module Pokemons
  # Suma experiencia a un Pokémon y aplica lo que se derive: subir de nivel y,
  # si toca, evolucionar.
  #
  # Devuelve un resumen de lo ocurrido para que la vista pueda contarlo, en lugar
  # de dejar que lo deduzca comparando estados.
  class GainExperience < BaseService

    def initialize(pokemon:, amount:)
      @pokemon = pokemon
      @amount = amount.to_i
    end

    def service_execute
      before = @pokemon.level
      @pokemon.experience = @pokemon.experience.to_i + @amount
      # `max` como red de seguridad: la experiencia sólo sube, así que el nivel
      # tampoco debería bajar nunca por mucho que se toquen los datos a mano.
      # Con la curva de su especie, no con la de todos. `max` sigue de red de
      # seguridad: si a un Pokémon antiguo se le asignara una curva más lenta que
      # la que tenía, su experiencia correspondería a un nivel más bajo y el
      # jugador lo vería *bajar* de nivel al ganar un combate.
      @pokemon.level = [ExperienceCurve.level_for(@pokemon.experience, @pokemon.growth_rate), before].max

      events = []
      events << { type: :level_up, from: before, to: @pokemon.level } if @pokemon.level > before

      evolution = @pokemon.level > before ? evolve_if_ready : nil
      events << { type: :evolution, into: evolution[:name] } if evolution

      @pokemon.save!

      # Los movimientos, después de guardar el nivel y la evolución: lo que se
      # aprende depende de las dos cosas, y de la especie nueva si ha evolucionado.
      events.concat(LearnMoves.execute(pokemon: @pokemon, from_level: before).value) if @pokemon.level > before
      ServiceResult.new(value: { pokemon: @pokemon, gained: @amount, events: events })
    end

    private

    # Evoluciona si la cadena tiene una forma siguiente cuyo nivel ya se alcanzó.
    # Sólo se mira el escalón inmediato: encadenar dos evoluciones de una vez
    # sería raro de leer y de contar.
    def evolve_if_ready
      chain = ::Pokeapi::FindEvolutionChain.execute(id: @pokemon.num_pokedex).value
      stages = EvolutionStages.execute(chain: chain).value
      return nil if stages.blank?

      current_stage = stages.index { |stage| stage.any? { |link| link[:id] == @pokemon.num_pokedex } }
      return nil if current_stage.nil?

      following = Array(stages[current_stage + 1]).find do |link|
        link[:min_level].present? && link[:min_level] <= @pokemon.level
      end
      return nil if following.nil?

      apply_evolution(following)
    end

    def apply_evolution(link)
      species = ::Pokeapi::FindPokemon.execute(id: link[:id]).value
      return nil if species.nil?

      stats = species.stat_list.index_by { |stat| stat[:key] }
      @pokemon.assign_attributes(
        name: species.name,
        num_pokedex: species.num_pokedex,
        image: @pokemon.shiny? ? species.image_shiny : species.image,
        type_of_pokemon: species.type_of_pokemon,
        hp: stats.dig('hp', :value),
        atack: stats.dig('attack', :value),
        defense: stats.dig('defense', :value),
        special_atack: stats.dig('special-attack', :value),
        special_defense: stats.dig('special-defense', :value),
        speed: stats.dig('speed', :value)
      )

      # El apodo sólo se actualiza si era el nombre de la especie: si el jugador
      # le puso uno propio, evolucionar no debe borrárselo.
      @pokemon.nickname = species.name if @pokemon.nickname == link_previous_name

      link
    end

    def link_previous_name
      @link_previous_name ||= @pokemon.name
    end

  end
end
