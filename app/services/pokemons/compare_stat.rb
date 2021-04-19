module Pokemons
  class CompareStat < BaseService

    def initialize(my_stat:,your_stat:)
      @my_stat = my_stat
      @your_stat = your_stat
    end

    def service_execute
      @my_stat - @your_stat
    end

  end
end