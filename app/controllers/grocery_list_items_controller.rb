class GroceryListItemsController < ApplicationController
  before_action :set_item

  def update
    @item.update!(in_pantry: params[:in_pantry])

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream_for_toggle }
    end
  end

  private

  def set_item
    @item = GroceryListItem.includes(ingredient: [:ingredient_category, :grocery_store_types], grocery_list: :meal_plan).find(params[:id])
    meal_plan = @item.grocery_list.meal_plan
    redirect_to meal_plans_path, alert: "无权操作" unless meal_plan.user_id == current_user.id
  end

  def turbo_stream_for_toggle
    if @item.in_pantry?
      # Remove from active list, append to pantry list
      [
        turbo_stream.remove("grocery_item_#{@item.id}"),
        turbo_stream.append("pantry_items", partial: "grocery_lists/grocery_item", locals: { item: @item })
      ]
    else
      # Remove from pantry list — full page reload needed to place in correct group
      turbo_stream.remove("grocery_item_#{@item.id}")
    end
  end
end
