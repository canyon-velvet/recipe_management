class Tag < ApplicationRecord
  include TranslatedName

  KINDS = %w[meal cuisine diet convenience].freeze

  has_many :recipe_tags, dependent: :destroy
  has_many :recipes, through: :recipe_tags

  enum :kind, KINDS.index_by(&:itself), validate: true

  validates :position, presence: true

  scope :ordered, -> { order(:position) }

  def self.kind_name(kind) = I18n.t(kind, scope: :tag_kinds)

  # [[kind name, [[tag name, value], ...]], ...] for grouped selects and grouped pickers.
  def self.grouped_by_kind(value: :id)
    ordered.group_by(&:kind).map { |kind, tags| [ kind_name(kind), tags.map { [ _1.name, _1.public_send(value) ] } ] }
  end
end
