class MealPlan < ApplicationRecord
  DAYS_OF_WEEK = %w[monday tuesday wednesday thursday friday saturday sunday].freeze
  MEAL_TYPES = %w[breakfast lunch dinner snack].freeze

  belongs_to :user
  has_many :meal_slots, dependent: :destroy
  has_one :grocery_list, dependent: :destroy

  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :start_date, uniqueness: { scope: :user_id, message: "already has a meal plan for this week" }
  validate :start_date_must_be_monday
  validate :end_date_must_be_sunday_after_start

  after_create :create_meal_slots
  after_create :create_grocery_list

  private

  def start_date_must_be_monday
    return if start_date.blank?
    errors.add(:start_date, "must be a Monday") unless start_date.monday?
  end

  def end_date_must_be_sunday_after_start
    return if start_date.blank? || end_date.blank?
    errors.add(:end_date, "must be the Sunday after start date") unless end_date == start_date + 6.days
  end

  def create_meal_slots
    DAYS_OF_WEEK.each_with_index do |_day, day_index|
      MEAL_TYPES.each_with_index do |_meal, meal_index|
        meal_slots.create!(day_of_week: day_index, meal_type: meal_index)
      end
    end
  end
end
