# Reference data stores a stable `key`; the display name comes from the locale files,
# scoped by the model's plural name (e.g. `aisles.produce`). Models with a `name` column can
# instead hold a name the user typed, which wins over the translation and isn't translated.
module TranslatedName
  extend ActiveSupport::Concern

  included do
    validates :key, presence: true, unless: :nameable?
    validates :name, presence: true, if: -> { nameable? && key.blank? }
  end

  def name = custom_name? ? self[:name] : key && I18n.t(key, scope: model_name.plural)

  private

  def nameable? = has_attribute?(:name)
  def custom_name? = nameable? && self[:name].present?
end
