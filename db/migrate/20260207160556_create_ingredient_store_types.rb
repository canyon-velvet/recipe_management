class CreateIngredientStoreTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :ingredient_store_types do |t|
      t.references :ingredient, null: false, foreign_key: true
      t.references :grocery_store_type, null: false, foreign_key: true

      t.timestamps
    end
    add_index :ingredient_store_types, [:ingredient_id, :grocery_store_type_id], unique: true, name: "index_ingredient_store_types_uniqueness"
  end
end
