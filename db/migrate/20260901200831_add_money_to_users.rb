# Saldo del entrenador. Se gana ganando combates y se gastará en la tienda.
#
# Entero: la moneda del juego no tiene decimales, y con céntimos habría que
# preocuparse por el redondeo sin ganar nada a cambio.
class AddMoneyToUsers < ActiveRecord::Migration[8.1]

  def change
    add_column :users, :money, :integer, default: 0, null: false
  end

end
