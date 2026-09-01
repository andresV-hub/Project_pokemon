# Da las bolas iniciales a las cuentas que ya existían.
#
# El inventario se concede al registrarse, así que quien se hubiera dado de alta
# antes se quedaba a cero: sin bolas no se puede capturar nada, y sin dinero
# tampoco comprarlas. La cuenta quedaba encallada.
class GrantStartingBallsToExistingUsers < ActiveRecord::Migration[8.1]

  # Modelos mínimos y aislados: la migración no debe depender de las clases de la
  # aplicación, que pueden cambiar.
  class MigrationUser < ActiveRecord::Base
    self.table_name = 'users'
  end

  class MigrationInventoryItem < ActiveRecord::Base
    self.table_name = 'inventory_items'
  end

  def up
    kind = ::Shop::Catalog::STARTING_KIND
    quantity = ::Shop::Catalog::STARTING_QUANTITY
    given = 0

    MigrationUser.find_each do |user|
      next if MigrationInventoryItem.exists?(user_id: user.id, kind: kind)

      MigrationInventoryItem.create!(user_id: user.id, kind: kind, quantity: quantity)
      given += 1
    end

    say "#{quantity} #{kind} entregadas a #{given} usuarios"
  end

  # Sólo se retira lo que esta migración pudo dar, y únicamente si sigue intacto:
  # si el usuario ya gastó o compró bolas, ese inventario es suyo.
  def down
    MigrationInventoryItem.where(kind: ::Shop::Catalog::STARTING_KIND,
                                 quantity: ::Shop::Catalog::STARTING_QUANTITY).delete_all
  end

end
