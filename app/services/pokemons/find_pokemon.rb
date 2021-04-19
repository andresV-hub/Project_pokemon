module Pokemons
  class FindPokemon < BaseService

    def initialize(id:)
      @id = id
    end

    def service_execute
    	::Base::Find.execute(klass: Pokemon,id: @id)
    end

  end
end