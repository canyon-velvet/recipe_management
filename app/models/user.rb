class User < ApplicationRecord
  has_secure_password

  has_many :recipes, dependent: :destroy
  has_many :meal_plans, dependent: :destroy
  has_many :sources, dependent: :destroy
  has_many :ingredients, dependent: :destroy
  has_many :aisles, dependent: :destroy
  has_many :drafts, dependent: :destroy

  validates :username, presence: true,
                       uniqueness: { case_sensitive: false },
                       length: { minimum: 2, maximum: 50 }
  validates :password, length: { minimum: 6 }, on: :create

  normalizes :username, with: ->(username) { username.strip }

  # Every user shops with the default aisles until they change them.
  after_create { Aisle.create_defaults_for(self) }

  def admin?
    admin
  end
end
