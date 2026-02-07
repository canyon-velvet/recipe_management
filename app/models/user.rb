class User < ApplicationRecord
  has_secure_password

  has_many :recipes, dependent: :destroy
  has_many :meal_plans, dependent: :destroy

  validates :username, presence: true,
                       uniqueness: { case_sensitive: false },
                       length: { minimum: 2, maximum: 50 }
  validates :password, length: { minimum: 6 }, on: :create

  normalizes :username, with: ->(username) { username.strip }

  def admin?
    admin
  end
end
