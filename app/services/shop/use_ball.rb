module Shop
  # Gasta una bola del inventario. Devuelve error si no queda ninguna, para que
  # quien la use no tenga que comprobarlo antes.
  class UseBall < BaseService

    def initialize(user:, kind:)
      @user = user
      @kind = kind.to_s
    end

    def service_execute
      item = @user.inventory_items.find_by(kind: @kind)
      return ServiceResult.new(error: :out_of_stock) if item.nil? || item.quantity < 1

      item.decrement!(:quantity)
      ServiceResult.new(value: item)
    end

  end
end
