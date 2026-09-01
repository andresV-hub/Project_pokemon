module Api
  module V1
    # Pokémon capturados por el usuario autenticado. La paginación se resuelve
    # en SQL con Kaminari y viaja al cliente en el bloque `meta`.
    class PokemonsController < BaseController

      def index
        @pokemons = ::Pokemons::SearchByUser.execute(user_id: current_user.id)
          .order(:num_pokedex, :id)
          .page(page_param)
          .per(per_page_param)
      end

      def show
        @pokemon = current_user.pokemon.find(params[:id])
      end

    end
  end
end
