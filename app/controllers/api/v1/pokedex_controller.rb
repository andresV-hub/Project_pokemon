module Api
  module V1
    # Catálogo de la PokeAPI. La paginación se delega en los parámetros
    # `limit`/`offset` de la API externa, así que cada petición sólo descarga la
    # página solicitada.
    class PokedexController < BaseController

      def index
        @pokemons = ::Pokeapi::SearchPokemons.execute(page: page_param, per_page: per_page_param).value
        @descriptions = descriptions_for(@pokemons)
      end

      def show
        @pokemon = ::Pokeapi::FindPokemon.execute(id: params[:id]).value
        raise ActiveRecord::RecordNotFound, "Pokemon #{params[:id]} no encontrado" if @pokemon.nil?

        @description = ::Pokeapi::FindDescription.execute(id: params[:id]).value
      end

      private

      def descriptions_for(pokemons)
        pokemons.each_with_object({}) do |pokemon, descriptions|
          descriptions[pokemon.num_pokedex] = ::Pokeapi::FindDescription.execute(id: pokemon.num_pokedex).value
        end
      end

    end
  end
end
