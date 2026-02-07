class MealSlot < ApplicationRecord
  belongs_to :meal_plan
  has_many :meal_slot_recipes, dependent: :destroy
  has_many :recipes, through: :meal_slot_recipes

  enum :day_of_week, MealPlan::DAYS_OF_WEEK.each_with_index.to_h, prefix: true
  enum :meal_type, MealPlan::MEAL_TYPES.each_with_index.to_h, prefix: true

  validates :day_of_week, presence: true
  validates :meal_type, presence: true
  validates :meal_type, uniqueness: { scope: [:meal_plan_id, :day_of_week] }
end
