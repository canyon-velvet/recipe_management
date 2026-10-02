# Replaces the single recipe category with many-to-many tags (display names live in the locale files)
# and carries each recipe's old category over to the closest tag, where one exists.
class ReplaceRecipeCategoryWithTags < ActiveRecord::Migration[8.1]
  class Tag < ActiveRecord::Base
    self.table_name = "tags"
  end

  class Recipe < ActiveRecord::Base
    self.table_name = "recipes"
  end

  class RecipeTag < ActiveRecord::Base
    self.table_name = "recipe_tags"
  end

  TAGS = {
    "meal" => %w[breakfast lunch dinner snack dessert appetizer soup salad drink],
    "cuisine" => %w[chinese italian japanese mexican american],
    "diet" => %w[vegetarian vegan gluten_free],
    "convenience" => %w[quick kid_friendly make_ahead]
  }.freeze

  CATEGORY_TO_TAG = {
    "dessert" => "dessert",
    "soup" => "soup",
    "salad" => "salad",
    "vegan" => "vegetarian",
    "rice-noodles" => "chinese",
    "pasta" => "italian"
  }.freeze

  def up
    create_table :tags do |t|
      t.string :key, null: false
      t.string :kind, null: false
      t.integer :position, null: false
      t.timestamps
    end
    add_index :tags, :key, unique: true

    create_table :recipe_tags do |t|
      t.references :recipe, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      t.timestamps
    end
    add_index :recipe_tags, [ :recipe_id, :tag_id ], unique: true

    tag_ids = TAGS.flat_map { |kind, keys| keys.map { [ kind, _1 ] } }.each.with_index(1).to_h do |(kind, key), i|
      [ key, Tag.create!(key: key, kind: kind, position: i * 10).id ]
    end

    Recipe.find_each do |recipe|
      tag_key = CATEGORY_TO_TAG[recipe.category]
      RecipeTag.create!(recipe_id: recipe.id, tag_id: tag_ids.fetch(tag_key)) if tag_key
    end

    remove_index :recipes, :category
    remove_column :recipes, :category, :string
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
