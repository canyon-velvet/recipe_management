class RecipesController < ApplicationController
  def index
    @recipes = Recipe.includes(:source).search_by_name(params[:query]).by_category(params[:category])
  end
end
