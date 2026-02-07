class Recipe < ApplicationRecord
  CATEGORIES = {
    "beef" => "牛肉",
    "pork" => "猪肉",
    "poultry" => "禽肉",
    "seafood" => "海鲜",
    "vegan" => "素食",
    "chinese_carbs" => "中式主食",
    "soup" => "汤",
    "bakery" => "烘焙",
    "dessert" => "甜点",
    "salad" => "沙拉",
    "sandwich" => "三明治",
    "pasta" => "意面",
    "sauce" => "酱料"
  }.freeze

  belongs_to :source
  belongs_to :user
  has_many :recipe_ingredients, dependent: :destroy
  has_many :ingredients, through: :recipe_ingredients
  has_many :meal_slot_recipes, dependent: :destroy
  has_many :meal_slots, through: :meal_slot_recipes

  validates :name, presence: true
  validates :category, presence: true, inclusion: { in: CATEGORIES.keys }
  validates :instructions, presence: true

  accepts_nested_attributes_for :recipe_ingredients, allow_destroy: true, reject_if: :all_blank

  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :search_by_name, ->(query) { where("name ILIKE ?", "%#{query}%") if query.present? }
end
