# La tienda: convertir el dinero de los combates en bolas.
class ShopController < ApplicationController

	def show
		@items = ::Shop::Catalog::ITEMS
		@owned = current_user.inventory_items.index_by(&:kind)
	end

	def buy
		result = ::Shop::Buy.execute(user: current_user, kind: params[:kind])

		case result.error
		when :not_enough_money
			redirect_to user_shop_path(user_id: current_user.id),
				alert: "You can't afford that yet.", status: :see_other
		when :unknown_item, :invalid_quantity
			redirect_to user_shop_path(user_id: current_user.id),
				alert: 'That item does not exist.', status: :see_other
		else
			redirect_to user_shop_path(user_id: current_user.id),
				notice: "You bought a #{::Shop::Catalog.name(params[:kind])}.", status: :see_other
		end
	end

end
