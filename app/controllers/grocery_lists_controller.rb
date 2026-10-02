class GroceryListsController < ApplicationController
  def show
    @meal_plan = current_user.meal_plans.find(params[:meal_plan_id])
    @grocery_list = @meal_plan.grocery_list

    items = @grocery_list.grocery_list_items.in_aisle_order
    @active_groups = items.active.group_by { |item| item.ingredient.ingredient_category }
    @pantry_items = items.in_pantry
  end
end
