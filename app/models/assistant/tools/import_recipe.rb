module Assistant
  module Tools
    # Imports a recipe link the user sent into their Draft box (see StartImportService), where it's read in the
    # background; they get a notification when it's ready to review. Only links in the user's latest message can be
    # imported (see Turn), and only a few per reply, since each import can cost a Claude call.
    class ImportRecipe < Tool
      NAME = "import_recipe"
      MAX_PER_REPLY = 3

      class Input < Anthropic::BaseModel
        required :url, String, doc: "A recipe link from the user's latest message, as they wrote it."
      end

      def initialize(user, turn)
        super
        @imports = 0
      end

      def description
        "Import a recipe link the user sent into their Draft box. It's read in the background: the user gets a " \
          "notification when it's ready to review, or if it can't be read. At most #{MAX_PER_REPLY} links per " \
          "reply."
      end

      def activity = I18n.t("assistant.importing")

      private

      def execute(input)
        link = @turn.link_for(input[:url])
        return { error: "Only links in the user's latest message can be imported." } unless link
        return { error: "You can import at most #{MAX_PER_REPLY} links per reply." } if @imports >= MAX_PER_REPLY

        result = StartImportService.new(user: @user, url: link).call
        case result.error
        when nil then started(result.draft)
        when :already_saved then already_saved(result.recipe)
        when :already_in_draft_box then already_in_draft_box(link)
        else { result: "not_started", reason: I18n.t(result.error, scope: "imports.errors") }
        end
      end

      # Only imports that start count towards the limit: they're the ones that can cost a Claude call.
      def started(draft)
        @imports += 1
        { result: "started", draft: DraftSummary.of(draft) }
      end

      def already_in_draft_box(link)
        draft = @user.drafts.find_by(source_url: link)
        { result: "already_in_draft_box", draft: (DraftSummary.of(draft) if draft) }.compact
      end

      # The recipe can be shown as a card (see ShowRecipes).
      def already_saved(recipe)
        @turn.found([ recipe ])
        { result: "already_saved", recipe: { id: recipe.id, name: recipe.name } }
      end
    end
  end
end
