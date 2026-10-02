# Aisles and ingredients become per user (see docs/adr/0001). Every user gets their own copy of the
# aisles. Each ingredient goes to the users whose recipes or grocery lists use it, copied when several
# do; an unused ingredient was visible to everyone, so every user gets a copy. Each ingredient then
# points at its owner's aisle with the same key.
class AddUserToAislesAndIngredients < ActiveRecord::Migration[8.1]
  class Aisle < ActiveRecord::Base
    self.table_name = "aisles"
  end

  class Ingredient < ActiveRecord::Base
    self.table_name = "ingredients"
  end

  class User < ActiveRecord::Base
    self.table_name = "users"
  end

  class RecipeIngredient < ActiveRecord::Base
    self.table_name = "recipe_ingredients"
  end

  class GroceryListItem < ActiveRecord::Base
    self.table_name = "grocery_list_items"
  end

  def up
    add_reference :aisles, :user, foreign_key: true
    add_reference :ingredients, :user, foreign_key: true
    remove_index :aisles, :key
    remove_index :aisles, :position
    remove_index :ingredients, name: "index_ingredients_on_lowercase_name"
    [ Aisle, Ingredient ].each(&:reset_column_information)

    user_ids = User.order(:id).pluck(:id)
    copy_aisles_to(user_ids)
    assign_ingredients(user_ids)

    change_column_null :aisles, :user_id, false
    change_column_null :ingredients, :user_id, false
    add_index :aisles, [ :user_id, :key ], unique: true
    add_index :aisles, [ :user_id, :position ]
    add_index :ingredients, "user_id, lower((name)::text)", unique: true, name: "index_ingredients_on_user_id_and_lowercase_name"
  end

  # Rolling back would have to merge each user's copies, losing whose ingredient and aisle was whose.
  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def copy_aisles_to(user_ids)
    originals = Aisle.where(user_id: nil).order(:position).to_a
    user_ids.each do |user_id|
      originals.each do |aisle|
        Aisle.create!(aisle.attributes.except("id", "created_at", "updated_at").merge("user_id" => user_id))
      end
    end
  end

  def assign_ingredients(user_ids)
    Ingredient.where(user_id: nil).find_each do |ingredient|
      owner_ids = ingredient_users(ingredient.id).presence || user_ids
      owner_ids.each do |user_id|
        owned = Ingredient.create!(ingredient.attributes.except("id", "created_at", "updated_at")
                                             .merge("user_id" => user_id, "aisle_id" => own_aisle_id(ingredient.aisle_id, user_id)))
        repoint(ingredient.id, owned.id, user_id)
      end
    end

    Ingredient.where(user_id: nil).delete_all
    Aisle.where(user_id: nil).delete_all
  end

  def ingredient_users(ingredient_id)
    from_recipes = RecipeIngredient.joins("JOIN recipes ON recipes.id = recipe_ingredients.recipe_id")
                                   .where(ingredient_id: ingredient_id).distinct.pluck("recipes.user_id")
    from_lists = GroceryListItem.joins("JOIN grocery_lists ON grocery_lists.id = grocery_list_items.grocery_list_id")
                                .joins("JOIN meal_plans ON meal_plans.id = grocery_lists.meal_plan_id")
                                .where(ingredient_id: ingredient_id).distinct.pluck("meal_plans.user_id")
    (from_recipes + from_lists).uniq
  end

  def own_aisle_id(shared_aisle_id, user_id)
    key = Aisle.where(id: shared_aisle_id).pick(:key)
    Aisle.where(user_id: user_id, key: key).pick(:id)
  end

  def repoint(old_ingredient_id, new_ingredient_id, user_id)
    RecipeIngredient.where(ingredient_id: old_ingredient_id)
                    .where("recipe_id IN (SELECT id FROM recipes WHERE user_id = ?)", user_id)
                    .update_all(ingredient_id: new_ingredient_id)
    GroceryListItem.where(ingredient_id: old_ingredient_id)
                   .where("grocery_list_id IN (SELECT grocery_lists.id FROM grocery_lists " \
                          "JOIN meal_plans ON meal_plans.id = grocery_lists.meal_plan_id WHERE meal_plans.user_id = ?)", user_id)
                   .update_all(ingredient_id: new_ingredient_id)
  end
end
