class Source < ApplicationRecord
  has_many :recipes, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  normalizes :name, with: ->(name) { name.strip }
end
