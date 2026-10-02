# Reference data stores a stable `key`; the display name comes from the locale files,
# scoped by the model's plural name (e.g. `aisles.produce`).
module TranslatedName
  extend ActiveSupport::Concern

  included do
    validates :key, presence: true, uniqueness: true
  end

  def name = I18n.t(key, scope: model_name.plural)
end
