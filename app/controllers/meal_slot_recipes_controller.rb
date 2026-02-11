class MealSlotRecipesController < ApplicationController
  before_action :set_meal_slot, only: [:create]
  before_action :set_meal_slot_recipe, only: [:destroy, :update]

  def create
    @meal_slot_recipe = @meal_slot.meal_slot_recipes.build(
      recipe_id: params.dig(:meal_slot_recipe, :recipe_id),
      add_to_grocery_list: false
    )

    if @meal_slot_recipe.save
      SyncGroceryListService.new(@meal_slot.meal_plan).call
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.update(
          "meal_slot_#{@meal_slot.id}",
          partial: "meal_plans/meal_slot_cell",
          locals: { meal_slot: @meal_slot.reload }
        )}
      end
    else
      head :unprocessable_entity
    end
  end

  def destroy
    meal_slot = @meal_slot_recipe.meal_slot
    @meal_slot_recipe.destroy
    SyncGroceryListService.new(meal_slot.meal_plan).call

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update(
        "meal_slot_#{meal_slot.id}",
        partial: "meal_plans/meal_slot_cell",
        locals: { meal_slot: meal_slot.reload }
      )}
    end
  end

  def update
    @meal_slot_recipe.update(add_to_grocery_list: params.dig(:meal_slot_recipe, :add_to_grocery_list))
    meal_plan = @meal_slot_recipe.meal_slot.meal_plan

    # Find all meal_slot_recipes with the same recipe in this meal plan and sync them
    linked = MealSlotRecipe.joins(:meal_slot)
                           .where(meal_slots: { meal_plan_id: meal_plan.id })
                           .where(recipe_id: @meal_slot_recipe.recipe_id)

    linked.update_all(add_to_grocery_list: @meal_slot_recipe.add_to_grocery_list)
    SyncGroceryListService.new(meal_plan).call

    # Collect unique slot IDs to avoid duplicate stream replacements
    slot_ids = linked.pluck(:meal_slot_id).uniq
    slots = MealSlot.includes(meal_slot_recipes: :recipe).where(id: slot_ids)

    streams = slots.map do |slot|
      turbo_stream.update(
        "meal_slot_#{slot.id}",
        partial: "meal_plans/meal_slot_cell",
        locals: { meal_slot: slot }
      )
    end

    respond_to do |format|
      format.turbo_stream { render turbo_stream: streams }
    end
  end

  private

  def set_meal_slot
    @meal_slot = MealSlot.find(params[:meal_slot_id])
    authorize_meal_plan!(@meal_slot.meal_plan)
  end

  def set_meal_slot_recipe
    @meal_slot_recipe = MealSlotRecipe.includes(meal_slot: :meal_plan).find(params[:id])
    authorize_meal_plan!(@meal_slot_recipe.meal_slot.meal_plan)
  end

  def authorize_meal_plan!(meal_plan)
    redirect_to meal_plans_path, alert: "无权操作" unless meal_plan.user_id == current_user.id
  end
end
