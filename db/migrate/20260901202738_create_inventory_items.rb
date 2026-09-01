# Bolas que tiene cada usuario.
#
# Una fila por tipo y usuario, con la cantidad, en lugar de una columna por
# objeto: añadir un objeto nuevo no debería exigir una migración.
class CreateInventoryItems < ActiveRecord::Migration[8.1]

  def change
    create_table :inventory_items do |t|
      t.references :user, null: false, foreign_key: true
      t.string :kind, null: false
      t.integer :quantity, null: false, default: 0

      t.timestamps
    end

    add_index :inventory_items, %i[user_id kind], unique: true
  end

end
