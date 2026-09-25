class Recipe < ApplicationRecord
  CATEGORIES = %w[
    beef pork poultry seafood vegan rice-noodles soup bakery dessert salad sandwich pasta sauce
  ].freeze

  belongs_to :source
  belongs_to :user
  has_many :recipe_ingredients, dependent: :destroy
  has_many :ingredients, through: :recipe_ingredients
  has_many :meal_slot_recipes, dependent: :destroy
  has_many :meal_slots, through: :meal_slot_recipes

  validates :name, presence: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :instructions, presence: true

  accepts_nested_attributes_for :recipe_ingredients, allow_destroy: true, reject_if: :all_blank

  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :search_by_name, ->(query) { where("name ILIKE ?", "%#{query}%") if query.present? }

  def self.category_options = CATEGORIES.map { |category| [ category_label(category), category ] }
  def self.category_label(category) = I18n.t(category, scope: :recipe_categories)

  def category_label = self.class.category_label(category)
end
