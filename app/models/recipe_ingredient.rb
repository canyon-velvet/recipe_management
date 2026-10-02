class RecipeIngredient < ApplicationRecord
  belongs_to :recipe
  belongs_to :ingredient

  validates :ingredient_id, uniqueness: { scope: :recipe_id }
  validate :ingredient_must_belong_to_recipe_owner

  private

  def ingredient_must_belong_to_recipe_owner
    errors.add(:ingredient, :invalid) if ingredient && recipe && ingredient.user_id != recipe.user_id
  end
end
