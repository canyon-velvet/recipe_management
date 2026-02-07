class GroceryStoreType < ApplicationRecord
  has_many :ingredient_store_types, dependent: :destroy
  has_many :ingredients, through: :ingredient_store_types

  validates :name, presence: true, uniqueness: true
end
