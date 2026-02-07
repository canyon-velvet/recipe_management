class MealSlotRecipe < ApplicationRecord
  belongs_to :meal_slot
  belongs_to :recipe

  scope :for_grocery_list, -> { where(add_to_grocery_list: true) }
end
