module Assistant
  module Tools
    # The user's newest drafts and how their imports are going, for questions like "is my import done?".
    class ListDrafts < Tool
      NAME = "list_drafts"
      LIMIT = 10

      class Input < Anthropic::BaseModel
      end

      def description
        "List the user's newest drafts (at most #{LIMIT}): imported recipes waiting in their Draft box, each still " \
          "being read, ready to review, or failed with the reason. A draft leaves the list once it's saved as a " \
          "recipe or discarded."
      end

      def activity = I18n.t("assistant.checking_drafts")

      private

      def execute(_input)
        { drafts: @user.drafts.newest_first.limit(LIMIT).map { |draft| DraftSummary.of(draft) } }
      end
    end
  end
end
