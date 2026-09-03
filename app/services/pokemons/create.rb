module Pokemons
  class Create < BaseService

    # Probabilidad de variocolor: 1 entre 512. El canon moderno es 1/4096, pero
    # en una aplicación donde se capturan decenas de Pokémon, y no miles, esa
    # cifra haría que la mecánica no llegara a notarse nunca.
    SHINY_ODDS = 512

  	# `level` es el nivel con el que se captura. Por defecto el de inicio, que es
  	# lo que valía cuando todos los encuentros salían escalados al jugador; desde
  	# que cada zona tiene los niveles del juego, un Hypno cazado a nivel 50 en la
  	# Cueva Celeste llegaba al PC **como nivel 5**.
  	def initialize(pokemon:, user:, description:, nickname:, level: nil)
  		@pokemon = pokemon
  		@user = user
  		@description = description
  		@nickname = nickname
  		@level = (level.presence || LevelStats::STARTING_LEVEL).to_i
  	end

  	# Las estadísticas y los movimientos se leen del decorador, que los expone ya
  	# normalizados y **por clave**. Antes se cogían por posición del array de la
  	# PokeAPI (`stats(num: 2)`, `stats(num: 3)`), y las posiciones estaban
  	# cruzadas: la API devuelve `defense` en la 2 y `special-attack` en la 3, así
  	# que cada Pokémon capturado guardaba esas dos estadísticas intercambiadas.
  	# La migración FixSwappedDefenseAndSpecialAttack corrige los ya guardados.
  	def service_execute
      stats = @pokemon.stat_list.index_by { |stat| stat[:key] }
      # Los que sabe a su nivel inicial, no los cuatro primeros del array.
      moves = MoveSet.execute(raw_pokemon: @pokemon.object,
                              level: @level).value.map { |move| move['label'] }
      shiny = shiny?
      # Los DV se sortean una vez, al aparecer, y ya no cambian: son lo que hace
      # que este Pikachu no sea igual que el siguiente.
      dv = DeterminantValues.random

      pokemon = Pokemon.new(
       	name: @pokemon.name,
        nickname: @nickname,
        hp: stats.dig('hp', :value),
        atack: stats.dig('attack', :value),
        special_atack: stats.dig('special-attack', :value),
        defense: stats.dig('defense', :value),
        special_defense: stats.dig('special-defense', :value),
        speed: stats.dig('speed', :value),
        description: @description.description,
        atack0: moves[0],
        atack1: moves[1],
        atack2: moves[2],
        atack3: moves[3],
        user: @user,
        type_of_pokemon: @pokemon.type_of_pokemon,
        habitat: @description.habitat,
        capture_rate: @description.capture_rate,
        base_happiness: @description.base_happiness,
        num_pokedex: @pokemon.num_pokedex,
        level: @level,
        growth_rate: @description.growth_rate,
        # La experiencia tiene que corresponder al nivel y a **su** curva: con la
        # experiencia de otra curva, el primer combate lo recalcularía a un nivel
        # distinto del que se ve al capturarlo.
        experience: ExperienceCurve.experience_for(@level, @description.growth_rate),
        shiny: shiny,
        ability: @pokemon.ability,
        dv_attack: dv['attack'],
        dv_defense: dv['defense'],
        dv_speed: dv['speed'],
        dv_special: dv['special'],
        # El sprite se congela en la captura: si salió variocolor, lo que se
        # guarda es la variante shiny y la ficha ya no depende de la marca.
        image: shiny ? @pokemon.image_shiny : @pokemon.image
      )
      pokemon.save!
    end

    private

    # Aislado en su propio método para poder fijarlo en las pruebas sin tocar el
    # resto del servicio.
    def shiny?
      rand(SHINY_ODDS).zero?
    end

  end
end
