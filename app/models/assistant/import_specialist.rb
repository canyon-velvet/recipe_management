module Assistant
  # The specialist that imports recipe links the user sends into their Draft box, and says how their imports are
  # going. Haiku is enough: it finds the links, calls a tool and reports back, with no judgment to make.
  class ImportSpecialist < Agent
    MODEL = "claude-haiku-4-5"
    NAME = "import"
    TITLE = "Import"
    # For the router's transfer tool: when to hand over.
    HANDLES = "imports recipe links into the user's Draft box and says how their imports are going. Use it when " \
              "they send a recipe link, or ask about an import or their Draft box"

    PROMPT = <<~PROMPT.freeze
      You are the Import specialist of the assistant in a home recipe app. You import recipe links the user sends
      into their Draft box, and tell them how their imports are going.

      Call import_recipe for each recipe link in the user's latest message, at most
      #{Tools::ImportRecipe::MAX_PER_REPLY}. An import is read in the background: when import_recipe says it
      started, say so and that they'll get a notification when it's ready to review in their Draft box. Never say
      an import started unless import_recipe said so. If the link is already a saved
      recipe, call show_recipes with it so it appears as a card. If it's already in the Draft box, or can't be
      imported, say so and why.

      You can only import links. If the user pasted a recipe's text instead, tell them to use Import recipe on All
      Recipes and choose "Paste text instead". If they ask how an import is going, call list_drafts.

      Keep replies to a sentence or two.
    PROMPT

    def system_prompt = "#{PROMPT}\n#{language_rule}\n"

    # It must act before it answers. Left to choose, Haiku said an import had started without starting it, and when
    # made to call some tool it checked the Draft box instead and claimed the recipe was saved. So a message with a
    # link always gets import_recipe; any other ("is it done?") gets a tool of its choice, in practice list_drafts.
    # Only the first call: after the tools' results it writes its reply. (Haiku 4.5 has no thinking here, so the
    # request may differ between calls.)
    def first_call_options
      if turn.links.any?
        { tool_choice: { type: :tool, name: Tools::ImportRecipe::NAME } }
      else
        { tool_choice: { type: :any } }
      end
    end

    private

    def build_tools
      [ Tools::ImportRecipe, Tools::ListDrafts, Tools::ShowRecipes ].map { |tool| tool.new(@user, turn) }
    end
  end
end
