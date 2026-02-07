class IngredientCategory < ApplicationRecord
  has_many :ingredients, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
end
