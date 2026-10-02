class Recipe < ApplicationRecord
  belongs_to :source
  belongs_to :user
  has_many :recipe_ingredients, dependent: :destroy
  has_many :ingredients, through: :recipe_ingredients
  has_many :recipe_tags, dependent: :destroy
  has_many :tags, -> { ordered }, through: :recipe_tags, after_add: :touch_if_persisted, after_remove: :touch_if_persisted
  has_many :meal_slot_recipes, dependent: :destroy
  has_many :meal_slots, through: :meal_slot_recipes

  validates :name, presence: true
  validates :instructions, presence: true

  accepts_nested_attributes_for :recipe_ingredients, allow_destroy: true, reject_if: :all_blank

  scope :search_by_name, ->(query) { where("name ILIKE ?", "%#{query}%") if query.present? }
  scope :tagged, ->(tag_key) {
    where(id: RecipeTag.joins(:tag).where(tags: { key: tag_key }).select(:recipe_id)) if tag_key.present?
  }

  private

  # Tag changes only write recipe_tags rows, so bump updated_at to keep recently edited recipes on top.
  def touch_if_persisted(_tag)
    touch if persisted?
  end
end
