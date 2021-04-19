class AddFieldsToUser < ActiveRecord::Migration[5.2]
  def change
  	add_column :users, :name, :string, pressence: true
  	add_column :users, :last_name, :string
  	add_column :users, :phone, :integer
  end
end
