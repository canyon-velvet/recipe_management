class Source < ApplicationRecord
  belongs_to :user
  has_many :recipes, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :user_id, case_sensitive: false }
  validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true

  normalizes :name, with: ->(name) { name.strip }
end
