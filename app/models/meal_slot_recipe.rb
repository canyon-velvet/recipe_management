class MealSlotRecipe < ApplicationRecord
  belongs_to :meal_slot
  belongs_to :recipe

  validates :recipe_id, uniqueness: { scope: :meal_slot_id, message: :already_in_slot }

  scope :for_grocery_list, -> { where(add_to_grocery_list: true) }
end
