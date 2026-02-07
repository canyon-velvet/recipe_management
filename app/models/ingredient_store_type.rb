class IngredientStoreType < ApplicationRecord
  belongs_to :ingredient
  belongs_to :grocery_store_type

  validates :grocery_store_type_id, uniqueness: { scope: :ingredient_id }
end
