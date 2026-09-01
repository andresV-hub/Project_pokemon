module Pokemons
  class Create < BaseService

    # Probabilidad de variocolor: 1 entre 512. El canon moderno es 1/4096, pero
    # en una aplicación donde se capturan decenas de Pokémon, y no miles, esa
    # cifra haría que la mecánica no llegara a notarse nunca.
    SHINY_ODDS = 512

  	def initialize(pokemon:, user:, description:, nickname:)
  		@pokemon = pokemon
  		@user = user
  		@description = description
  		@nickname = nickname
  	end

  	# Las estadísticas y los movimientos se leen del decorador, que los expone ya
  	# normalizados y **por clave**. Antes se cogían por posición del array de la
  	# PokeAPI (`stats(num: 2)`, `stats(num: 3)`), y las posiciones estaban
  	# cruzadas: la API devuelve `defense` en la 2 y `special-attack` en la 3, así
  	# que cada Pokémon capturado guardaba esas dos estadísticas intercambiadas.
  	# La migración FixSwappedDefenseAndSpecialAttack corrige los ya guardados.
  	def service_execute
      stats = @pokemon.stat_list.index_by { |stat| stat[:key] }
      moves = @pokemon.move_list
      shiny = shiny?

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
        shiny: shiny,
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
