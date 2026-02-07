class CreateGroceryStoreTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :grocery_store_types do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :grocery_store_types, :name, unique: true
  end
end
