class Aisle < ApplicationRecord
  include TranslatedName

  DEFAULT_KEYS = %w[produce meat_seafood dairy_eggs bakery pantry spices_seasonings frozen beverages other].freeze

  belongs_to :user
  has_many :ingredients, dependent: :restrict_with_error

  validates :key, uniqueness: { scope: :user_id }
  validates :position, presence: true

  scope :ordered, -> { order(:position) }

  # Idempotent: gives the user any default aisle they don't have yet, in shopping order.
  def self.create_defaults_for(user)
    DEFAULT_KEYS.each.with_index(1) do |key, i|
      user.aisles.find_or_create_by!(key: key) { |aisle| aisle.position = i * 10 }
    end
  end
end
