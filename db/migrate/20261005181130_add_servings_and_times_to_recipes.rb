# How many people a recipe serves and how long it takes, when its source says so. All optional.
class AddServingsAndTimesToRecipes < ActiveRecord::Migration[8.1]
  def change
    add_column :recipes, :servings, :integer
    add_column :recipes, :prep_minutes, :integer
    add_column :recipes, :cook_minutes, :integer
    add_column :recipes, :total_minutes, :integer

    add_check_constraint :recipes, "servings > 0", name: "recipes_servings_positive"
    add_check_constraint :recipes, "prep_minutes > 0", name: "recipes_prep_minutes_positive"
    add_check_constraint :recipes, "cook_minutes > 0", name: "recipes_cook_minutes_positive"
    add_check_constraint :recipes, "total_minutes > 0", name: "recipes_total_minutes_positive"
  end
end
