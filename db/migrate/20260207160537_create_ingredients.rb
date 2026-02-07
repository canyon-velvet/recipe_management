class CreateIngredients < ActiveRecord::Migration[8.1]
  def change
    create_table :ingredients do |t|
      t.string :name, null: false
      t.references :ingredient_category, null: false, foreign_key: true

      t.timestamps
    end
    add_index :ingredients, "LOWER(name)", unique: true, name: "index_ingredients_on_lowercase_name"
  end
end
