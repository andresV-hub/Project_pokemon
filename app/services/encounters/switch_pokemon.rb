module Encounters
  # Cambiar de Pokémon por decisión propia, y no porque el tuyo se haya caído.
  #
  # Es la jugada más básica del juego —sacar al de tipo Agua contra el de Fuego— y
  # hasta ahora no se podía hacer: el equipo era una cola de reservas y el único
  # relevo era el forzado. Con los estados y los escalones ya en el combate, quién
  # está en el campo importa de verdad.
  #
  # **Cambiar gasta el turno**, como en los juegos. Sin ese coste la decisión sería
  # siempre «cambia al que mejor le venga», y dejaría de ser una decisión.
  class SwitchPokemon < BaseService

    def initialize(state:, user:, pokemon_id:)
      @state = state.dup
      @user = user
      @pokemon_id = pokemon_id
    end

    def service_execute
      target = @user.pokemon.in_party.find_by(id: @pokemon_id)

      return ServiceResult.new(error: :not_in_party) if target.nil?
      return ServiceResult.new(error: :already_out) if target.id == @state['trainer_pokemon_id']
      return ServiceResult.new(error: :fainted) if target.fainted?

      leaving = @user.pokemon.find_by(id: @state['trainer_pokemon_id'])
      SendOut.call(@state, target)

      # Se cuentan los dos movimientos: quién vuelve y quién sale. Con una sola
      # línea, en un combate largo no se sabe a quién se acaba de retirar.
      @state['log'] = [
        leaving ? "#{leaving.nickname}, come back!" : nil,
        "Go, #{target.nickname}!"
      ].compact

      ServiceResult.new(value: @state)
    end

  end
end
