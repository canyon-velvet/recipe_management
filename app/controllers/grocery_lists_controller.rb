class GroceryListsController < ApplicationController
  def show
    @meal_plan = current_user.meal_plans.find(params[:meal_plan_id])
    @grocery_list = @meal_plan.grocery_list

    items = @grocery_list.grocery_list_items
              .includes(ingredient: [:ingredient_category, :grocery_store_types])
              .order("ingredients.name")

    @active_grouped = group_by_store_and_category(items.active)
    @pantry_items = items.in_pantry
  end

  private

  def group_by_store_and_category(items)
    grouped = {}

    items.each do |item|
      store_name = item.ingredient.grocery_store_types.first&.name || "未分类商店"
      category_name = item.ingredient.ingredient_category&.name || "未分类"

      grouped[store_name] ||= {}
      grouped[store_name][category_name] ||= []
      grouped[store_name][category_name] << item
    end

    grouped
  end
end
