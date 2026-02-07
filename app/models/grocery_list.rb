class GroceryList < ApplicationRecord
  belongs_to :meal_plan
  has_many :grocery_list_items, dependent: :destroy

  def user
    meal_plan.user
  end
end
