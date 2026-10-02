class RecipesController < ApplicationController
  before_action :set_recipe, only: [ :show, :edit, :update, :destroy ]
  before_action :set_form_data, only: [ :new, :create, :edit, :update ]

  def index
    recipes = current_user.recipes.includes(:source, :tags)
                          .search_by_name(params[:q])
                          .tagged(params[:tag])
                          .order(updated_at: :desc)
    @pagy, @recipes = pagy(recipes)
  end

  def search
    recipes = current_user.recipes.includes(:tags).search_by_name(params[:q]).order(:name).limit(20)
    render json: recipes.map { |r| { id: r.id, name: r.name, tags: r.tags.map(&:name) } }
  end

  def show
  end

  def new
    @recipe = Recipe.new
  end

  def create
    @recipe = current_user.recipes.build(recipe_params)

    if @recipe.save
      redirect_to recipe_path(@recipe), notice: t("flash.recipe_created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @recipe.update(recipe_params)
      redirect_to recipe_path(@recipe), notice: t("flash.recipe_updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @recipe.destroy
    redirect_to recipes_path, notice: t("flash.recipe_deleted")
  end

  private

  def set_recipe
    @recipe = current_user.recipes.includes(:source, :tags, recipe_ingredients: :ingredient).find(params[:id])
  end

  def set_form_data
    @ingredient_categories = IngredientCategory.ordered
  end

  def recipe_params
    params.require(:recipe).permit(
      :name, :description, :instructions, :source_id, tag_ids: [],
      recipe_ingredients_attributes: [ :id, :ingredient_id, :quantity, :unit, :_destroy ]
    )
  end
end
