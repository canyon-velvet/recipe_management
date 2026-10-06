# A small fact about what a user eats, such as "vegetarian" (diet) or "peanuts" (avoid). The assistant reads them when
# it recommends recipes: "avoid" is strict (never recommend a recipe with it), the rest are soft preferences.
class Preference < ApplicationRecord
  CATEGORIES = %w[diet likes dislikes avoid household].freeze

  belongs_to :user

  enum :category, CATEGORIES.index_by(&:itself), validate: true

  normalizes :value, with: ->(value) { value.squish }

  validates :value, presence: true, length: { maximum: 100 }
  validates :value, uniqueness: { scope: [ :user_id, :category ], case_sensitive: false }
  validate :one_household, if: :household?

  scope :ordered, -> { order(:created_at, :id) }

  # Like save, but when two requests add the same fact at once and the unique index stops the second, it gets the
  # usual "already listed" error instead of an exception.
  def save_once
    save
  rescue ActiveRecord::RecordNotUnique
    valid?
    errors.add(:value, :taken) if errors.empty? # the other row was removed again before the re-check
    false
  end

  private

  # A household is one fact, e.g. "4 people".
  def one_household
    errors.add(:base, :household_taken) if user && user.preferences.household.where.not(id: id).exists?
  end
end
