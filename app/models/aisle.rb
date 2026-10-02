class Aisle < ApplicationRecord
  include TranslatedName

  DEFAULT_KEYS = %w[produce meat_seafood dairy_eggs bakery pantry spices_seasonings frozen beverages other].freeze

  belongs_to :user
  has_many :ingredients, dependent: :restrict_with_error

  validates :key, uniqueness: { scope: :user_id }, allow_nil: true
  validates :name, uniqueness: { scope: :user_id, case_sensitive: false }, if: :custom_name?
  validate :name_must_differ_from_default_aisles, if: :custom_name?
  validates :position, presence: true

  normalizes :name, with: ->(name) { name.strip }

  scope :ordered, -> { order(:position) }

  # Idempotent: gives the user any default aisle they don't have yet, in shopping order.
  def self.create_defaults_for(user)
    DEFAULT_KEYS.each.with_index(1) do |key, i|
      user.aisles.find_or_create_by!(key: key) { |aisle| aisle.position = i * 10 }
    end
  end

  # A new aisle goes just before Other, which stays the catch-all at the end of the list.
  def self.add_before_other(user, name)
    transaction do
      position = user.aisles.find_by(key: "other")&.position || (user.aisles.maximum(:position).to_i + 10)
      aisle = user.aisles.new(name: name, position: position)
      user.aisles.where(position: position..).update_all("position = position + 10") if aisle.valid?
      aisle.save
      aisle
    end
  end

  private

  # Default aisles keep their name in the locale files, so the uniqueness index can't see it.
  def name_must_differ_from_default_aisles
    keys = user.aisles.where.not(key: nil).pluck(:key)
    labels = I18n.available_locales.flat_map { |locale| keys.map { |key| I18n.t(key, scope: :aisles, locale: locale) } }
    errors.add(:name, :taken) if labels.any? { |label| label.casecmp?(self[:name]) }
  end
end
