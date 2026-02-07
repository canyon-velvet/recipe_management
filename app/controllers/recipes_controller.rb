class RecipesController < ApplicationController
  before_action :set_recipe, only: [:show]

  def index
    recipes = Recipe.includes(:source)
                    .search_by_name(params[:q])
                    .by_category(params[:category])
                    .order(updated_at: :desc)
    @pagy, @recipes = pagy(recipes)
  end

  def show
  end

  private

  def set_recipe
    @recipe = Recipe.includes(:source, recipe_ingredients: :ingredient).find(params[:id])
  end
end
