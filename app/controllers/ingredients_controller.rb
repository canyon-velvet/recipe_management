class IngredientsController < ApplicationController
  def search
    ingredients = Ingredient.where("name ILIKE ?", "%#{params[:q]}%")
                            .order(:name)
                            .limit(20)
    render json: ingredients.map { |i| { id: i.id, name: i.name } }
  end

  def create
    ingredient = Ingredient.new(ingredient_params)

    if ingredient.save
      render json: { id: ingredient.id, name: ingredient.name }, status: :created
    else
      render json: { errors: ingredient.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def ingredient_params
    params.require(:ingredient).permit(:name, :ingredient_category_id, grocery_store_type_ids: [])
  end
end
