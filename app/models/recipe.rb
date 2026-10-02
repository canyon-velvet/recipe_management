class Recipe < ApplicationRecord
  belongs_to :source
  belongs_to :user
  has_many :recipe_ingredients, dependent: :destroy
  has_many :ingredients, through: :recipe_ingredients
  has_many :steps, -> { order(:position) }, class_name: "RecipeStep", dependent: :destroy, inverse_of: :recipe
  has_many :recipe_tags, dependent: :destroy
  has_many :tags, -> { ordered }, through: :recipe_tags, after_add: :touch_if_persisted, after_remove: :touch_if_persisted
  has_many :meal_slot_recipes, dependent: :destroy
  has_many :meal_slots, through: :meal_slot_recipes

  validates :name, presence: true
  validate :must_have_steps
  validate :source_must_belong_to_user

  accepts_nested_attributes_for :recipe_ingredients, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :steps, allow_destroy: true,
                                        reject_if: ->(attributes) { attributes["id"].blank? && attributes["body"].blank? }

  # The form submits each step's position; renumber 1..n in that order so gaps or duplicates never persist.
  before_validation :renumber_steps

  scope :search_by_name, ->(query) { where("name ILIKE ?", "%#{query}%") if query.present? }
  scope :tagged, ->(tag_key) {
    where(id: RecipeTag.joins(:tag).where(tags: { key: tag_key }).select(:recipe_id)) if tag_key.present?
  }

  private

  def kept_steps
    steps.reject(&:marked_for_destruction?)
  end

  def must_have_steps
    errors.add(:steps, :blank) if kept_steps.empty?
  end

  def source_must_belong_to_user
    errors.add(:source, :invalid) if source && user && source.user_id != user_id
  end

  def renumber_steps
    kept_steps.each_with_index
              .sort_by { |step, index| [ step.position || Float::INFINITY, index ] }
              .each.with_index(1) { |(step, _), position| step.position = position }
  end

  # Tag changes only write recipe_tags rows, so bump updated_at to keep recently edited recipes on top.
  def touch_if_persisted(_tag)
    touch if persisted?
  end
end
