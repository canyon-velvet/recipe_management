class RenameIngredientCategoriesToAisles < ActiveRecord::Migration[8.1]
  def change
    rename_table :ingredient_categories, :aisles
    rename_column :ingredients, :ingredient_category_id, :aisle_id
  end
end
