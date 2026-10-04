# Starts an Import (GLOSSARY): checks the recipe link or pasted text, puts a Draft in the user's Draft box as
# Reading…, and queues ImportRecipeJob to read it in the background. The import form uses it, and so will the
# phone API.
class StartImportService
  # error: :blank, :invalid_link, :needs_claude, :already_saved (with the recipe) or :already_in_draft_box
  Result = Data.define(:draft, :error, :recipe) do
    def success? = error.nil?
  end

  def initialize(user:, url: nil, text: nil)
    @user = user
    @url = RecipeLink.normalize(url)
    @text = text.to_s.strip.presence
  end

  def call
    return failure(:blank) if @url.nil? && @text.nil?
    return failure(:needs_claude) if @text && !CleanRecipeService.available?

    recipe = @url && @user.recipes.find_by(source_url: @url)
    return failure(:already_saved, recipe: recipe) if recipe

    draft = draft_to_read
    return failure(:already_in_draft_box) unless draft
    # :taken means another request for the same link just won the race.
    unless draft.save
      return failure(draft.errors.of_kind?(:source_url, :taken) ? :already_in_draft_box : :invalid_link)
    end

    ImportRecipeJob.perform_later(draft)
    Result.new(draft: draft, error: nil, recipe: nil)
  rescue ActiveRecord::RecordNotUnique
    failure(:already_in_draft_box)
  end

  private

  # A failed draft for the same link is read again (typically with the recipe text pasted in); any other draft
  # for that link means it's already being imported.
  def draft_to_read
    existing = @url && @user.drafts.find_by(source_url: @url)
    return @user.drafts.new(source_url: @url, source_text: @text) unless existing
    return unless existing.failed?

    existing.tap { |draft| draft.assign_attributes(status: :reading, failure_reason: nil, source_text: @text, data: {}) }
  end

  def failure(error, recipe: nil) = Result.new(draft: nil, error: error, recipe: recipe)
end
