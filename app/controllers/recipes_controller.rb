class RecipesController < ApplicationController
  before_action :set_recipe, only: [ :show, :edit, :update, :destroy ]
  before_action :set_form_data, only: [ :new, :create, :edit, :update ]

  def index
    recipes = Recipe.includes(:source)
                    .search_by_name(params[:q])
                    .by_category(params[:category])
                    .order(updated_at: :desc)
    @pagy, @recipes = pagy(recipes)
  end

  def search
    recipes = Recipe.where("name ILIKE ?", "%#{params[:q]}%")
                    .order(:name)
                    .limit(20)
    render json: recipes.map { |r| { id: r.id, name: r.name, category: Recipe::CATEGORIES[r.category] } }
  end

  def show
  end

  def new
    @recipe = Recipe.new
  end

  def create
    @recipe = current_user.recipes.build(recipe_params)

    if @recipe.save
      redirect_to recipe_path(@recipe), notice: "菜谱创建成功"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @recipe.update(recipe_params)
      redirect_to recipe_path(@recipe), notice: "菜谱更新成功"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @recipe.destroy
    redirect_to recipes_path, notice: "菜谱已删除"
  end

  private

  def set_recipe
    @recipe = Recipe.includes(:source, recipe_ingredients: :ingredient).find(params[:id])
  end

  def set_form_data
    @ingredient_categories = IngredientCategory.order(:name)
    @grocery_store_types = GroceryStoreType.order(:name)
  end

  def recipe_params
    params.require(:recipe).permit(
      :name, :category, :description, :instructions, :source_id,
      recipe_ingredients_attributes: [ :id, :ingredient_id, :quantity, :unit, :_destroy ]
    )
  end
end
