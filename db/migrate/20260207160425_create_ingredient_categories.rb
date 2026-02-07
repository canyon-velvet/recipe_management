class CreateIngredientCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :ingredient_categories do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :ingredient_categories, :name, unique: true
  end
end
