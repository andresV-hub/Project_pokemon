module Shop
  # Compra una unidad de un objeto.
  #
  # Cobro y entrega van en la misma transacción: si algo falla entre medias, el
  # usuario no puede quedarse sin dinero y sin objeto, ni al revés.
  class Buy < BaseService

    def initialize(user:, kind:, quantity: 1)
      @user = user
      @kind = kind.to_s
      @quantity = quantity.to_i
    end

    def service_execute
      return ServiceResult.new(error: :unknown_item) if Catalog.find(@kind).nil?
      return ServiceResult.new(error: :invalid_quantity) unless @quantity.positive?

      cost = Catalog.price(@kind) * @quantity
      return ServiceResult.new(error: :not_enough_money) if @user.money < cost

      item = nil
      ActiveRecord::Base.transaction do
        @user.decrement!(:money, cost)
        item = @user.inventory_items.find_or_create_by!(kind: @kind)
        item.increment!(:quantity, @quantity)
      end

      ServiceResult.new(value: item)
    end

  end
end
