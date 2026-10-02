class Aisle < ApplicationRecord
  include TranslatedName

  has_many :ingredients, dependent: :restrict_with_error

  validates :position, presence: true

  scope :ordered, -> { order(:position) }
end
