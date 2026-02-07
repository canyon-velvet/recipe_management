class CreateGroceryListItems < ActiveRecord::Migration[8.1]
  def change
    create_table :grocery_list_items do |t|
      t.references :grocery_list, null: false, foreign_key: true
      t.references :ingredient, null: false, foreign_key: true
      t.integer :occurrence_count, null: false, default: 1
      t.boolean :in_pantry, null: false, default: false

      t.timestamps
    end
    add_index :grocery_list_items, [:grocery_list_id, :ingredient_id], unique: true, name: "index_grocery_list_items_uniqueness"
  end
end
