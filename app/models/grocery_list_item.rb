class GroceryListItem < ApplicationRecord
  belongs_to :grocery_list
  belongs_to :ingredient

  validates :ingredient_id, uniqueness: { scope: :grocery_list_id }
  validates :occurrence_count, numericality: { greater_than: 0 }

  scope :active, -> { where(in_pantry: false) }
  scope :in_pantry, -> { where(in_pantry: true) }
  scope :by_store_type, ->(store_type_id) {
    joins(ingredient: :ingredient_store_types)
      .where(ingredient_store_types: { grocery_store_type_id: store_type_id })
  }
end
