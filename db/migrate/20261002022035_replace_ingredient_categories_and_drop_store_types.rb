# Replaces the Chinese-only ingredient categories with a fixed, aisle-ordered list keyed for i18n
# (display names live in the locale files), moves existing ingredients to the closest new category,
# and drops grocery store types: the grocery list is now grouped by ingredient category only.
class ReplaceIngredientCategoriesAndDropStoreTypes < ActiveRecord::Migration[8.1]
  class Category < ActiveRecord::Base
    self.table_name = "ingredient_categories"
  end

  class Ingredient < ActiveRecord::Base
    self.table_name = "ingredients"
  end

  CATEGORY_KEYS = %w[produce meat_seafood dairy_eggs bakery pantry spices_seasonings frozen beverages other].freeze

  OLD_CATEGORY_TO_KEY = {
    "香料" => "spices_seasonings",
    "油" => "pantry",
    "酒" => "spices_seasonings",
    "调料" => "spices_seasonings",
    "面粉" => "pantry",
    "熟食" => "other",
    "蛋奶" => "dairy_eggs",
    "谷物" => "pantry",
    "菇类" => "produce",
    "水果" => "produce",
    "蔬菜" => "produce",
    "肉类" => "meat_seafood"
  }.freeze

  def up
    replace_categories
    drop_table :ingredient_store_types
    drop_table :grocery_store_types
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def replace_categories
    add_column :ingredient_categories, :key, :string
    add_column :ingredient_categories, :position, :integer
    Category.reset_column_information

    old_categories = Category.all.to_a
    new_ids = CATEGORY_KEYS.each_with_index.to_h do |key, index|
      [ key, Category.create!(name: key, key: key, position: (index + 1) * 10).id ]
    end

    old_categories.each do |old|
      target_id = new_ids.fetch(OLD_CATEGORY_TO_KEY.fetch(old.name, "other"))
      Ingredient.where(ingredient_category_id: old.id).update_all(ingredient_category_id: target_id)
      old.destroy!
    end

    remove_index :ingredient_categories, :name
    remove_column :ingredient_categories, :name, :string
    change_column_null :ingredient_categories, :key, false
    change_column_null :ingredient_categories, :position, false
    add_index :ingredient_categories, :key, unique: true
    add_index :ingredient_categories, :position
  end
end
