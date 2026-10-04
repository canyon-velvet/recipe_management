# A recipe produced by an import that the user hasn't saved yet. It waits in the Draft box until the
# user reviews and saves it as a Recipe, or discards it.
#
# `data` is what the importer read, in this shape:
#   { "name" => "…", "description" => "…", "source_name" => "…",
#     "ingredients" => [{ "name" => "…", "quantity" => "…", "unit" => "…", "aisle_id" => 1 }],
#     "steps" => ["…"], "tags" => ["tag_key"] }
class Draft < ApplicationRecord
  belongs_to :user

  enum :status, { reading: "reading", ready: "ready", failed: "failed" }, validate: true

  validates :source_url, http_url: true, allow_blank: true
  validates :source_url, uniqueness: { scope: :user_id }, allow_nil: true
  validate :data_must_be_an_object

  normalizes :source_url, with: ->(url) { RecipeLink.normalize(url) }

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  def name = data["name"].to_s.strip.presence

  # The link passed validation, but Ruby's stricter URI parser can still reject a few such strings.
  def source_host
    URI.parse(source_url).host if source_url
  rescue URI::InvalidURIError
    nil
  end

  def title = name || source_host || source_url || I18n.t("drafts.pasted_text")

  # Unknown or missing reasons show the generic message.
  def failure_reason_key = failure_reason.presence || "generic"

  private

  def data_must_be_an_object
    errors.add(:data, :invalid) unless data.is_a?(Hash)
  end
end
