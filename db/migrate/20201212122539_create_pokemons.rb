class CreatePokemons < ActiveRecord::Migration[5.2]
  def change
    create_table :pokemons do |t|
    	t.string :name
    	t.string :nickname
        t.integer :num_pokedex
    	t.integer :hp
    	t.integer :atack
    	t.integer :special_atack
    	t.integer :defense
    	t.integer :special_defense
    	t.integer :speed
    	t.text :description
    	t.string :atack0
    	t.string :atack1
    	t.string :atack2
    	t.string :atack3
    	t.references :user
        t.string :type_of_pokemon
        t.string :habitat
        t.integer :capture_rate
        t.integer :base_happiness
        t.text :image
    end
  end
end
