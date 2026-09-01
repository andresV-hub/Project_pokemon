module Pokemons
  # Mueve un Pokémon del PC al equipo, al primer hueco libre.
  class AddToParty < BaseService

    def initialize(pokemon:)
      @pokemon = pokemon
    end

    def service_execute
      return ServiceResult.new(value: @pokemon) if @pokemon.in_party?

      slot = free_slot
      return ServiceResult.new(error: :party_full) if slot.nil?

      @pokemon.update!(party_position: slot)
      ServiceResult.new(value: @pokemon)
    rescue ActiveRecord::RecordNotUnique
      # Dos peticiones simultáneas pidiendo el mismo hueco: el índice único de la
      # tabla es lo que impide que dos Pokémon acaben en la misma posición.
      ServiceResult.new(error: :slot_taken)
    end

    private

    def free_slot
      ocupados = @pokemon.user.pokemon.in_party.pluck(:party_position)
      (Pokemon::PARTY_SLOTS.to_a - ocupados).min
    end

  end
end
