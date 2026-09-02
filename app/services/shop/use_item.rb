module Shop
  # Usa un objeto de curación sobre un Pokémon.
  #
  # Sólo tiene sentido **dentro del combate**. Fuera, el Centro Pokémon cura a todo
  # el equipo gratis y siempre está a un clic en la barra, así que gastar una
  # poción fuera sería tirar el dinero. En el juego pasa lo mismo: las pociones
  # existen para el rato en que no puedes ir a un Centro.
  #
  # Devuelve cuánta vida ha recuperado, o un error si no queda ninguno o si el
  # objeto no puede aplicarse a ese Pokémon.
  class UseItem < BaseService

    def initialize(user:, kind:, pokemon:)
      @user = user
      @kind = kind.to_s
      @pokemon = pokemon
    end

    def service_execute
      return ServiceResult.new(error: :unknown_item) if Catalog.find(@kind).nil? || Catalog.ball?(@kind)

      item = @user.inventory_items.find_by(kind: @kind)
      return ServiceResult.new(error: :out_of_stock) if item.nil? || item.quantity < 1

      error = rejection
      return ServiceResult.new(error: error) if error

      restored = apply
      item.decrement!(:quantity)

      ServiceResult.new(value: restored)
    end

    private

    # Un Revive sólo sirve con un Pokémon debilitado y una poción sólo con uno que
    # siga en pie: en el juego no se pueden intercambiar, y dejar que se gasten en
    # balde sería castigar al jugador por un despiste de la interfaz.
    def rejection
      if Catalog.category(@kind) == :revive
        :not_fainted unless @pokemon.fainted?
      elsif @pokemon.fainted?
        :already_fainted
      elsif @pokemon.full_health?
        :already_full
      end
    end

    def apply
      if Catalog.category(@kind) == :revive
        @pokemon.heal!((@pokemon.max_hp / 2.0).ceil)
      else
        @pokemon.heal!(Catalog.heals(@kind))
      end
    end

  end
end
