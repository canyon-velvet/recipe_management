class GroceryListItem < ApplicationRecord
  belongs_to :grocery_list
  belongs_to :ingredient

  validates :ingredient_id, uniqueness: { scope: :grocery_list_id }
  validates :occurrence_count, numericality: { greater_than: 0 }

  scope :active, -> { where(in_pantry: false) }
  scope :in_pantry, -> { where(in_pantry: true) }
  scope :in_aisle_order, -> {
    includes(ingredient: :aisle).order("aisles.position", "ingredients.name")
  }
end
