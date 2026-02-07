class Ingredient < ApplicationRecord
  belongs_to :ingredient_category
  has_many :recipe_ingredients, dependent: :restrict_with_error
  has_many :recipes, through: :recipe_ingredients
  has_many :ingredient_store_types, dependent: :destroy
  has_many :grocery_store_types, through: :ingredient_store_types
  has_many :grocery_list_items, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  normalizes :name, with: ->(name) { name.strip }

  scope :alphabetical, -> { order(:name) }
end
