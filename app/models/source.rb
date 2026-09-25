class Source < ApplicationRecord
  has_many :recipes, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true

  normalizes :name, with: ->(name) { name.strip }
end
