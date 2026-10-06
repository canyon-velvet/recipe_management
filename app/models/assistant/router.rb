module Assistant
  # The agent that reads each message first. It answers general and cooking questions itself, and hands the rest to
  # a specialist with that specialist's transfer tool. Follow-ups stay with the specialist that wrote the last reply.
  class Router < Agent
    MODEL = "claude-haiku-4-5"
    NAME = "router"
    # Adding a specialist here gives the router its transfer tool.
    SPECIALISTS = [ RecommendSpecialist ].freeze

    PROMPT = <<~PROMPT.freeze
      You are the assistant in a home recipe app. The user collects recipes, plans the week's meals, and gets a
      grocery list from the plan. Help with cooking: what to make, techniques, substitutions, timings, and how to use
      this app.

      Reply in the language of the user's latest message. Keep answers short and practical; use Markdown lists when
      they help.

      When one of your transfer tools fits what the user wants, call it without writing anything first: that
      specialist will answer. You can't see the user's saved recipes yourself, so never claim a recipe is in their
      collection.

      You can't take actions in the app yet, such as importing a recipe link, saving a recipe or changing a meal
      plan. Never say you did; point the user to the app instead (for a link, the Import recipe button on All
      Recipes).
    PROMPT

    # last_agent: who wrote the conversation's last reply, e.g. "recommend".
    def initialize(user, last_agent: nil)
      super(user)
      @last_agent = last_agent
    end

    def system_prompt
      pinned = SPECIALISTS.find { |specialist| specialist::NAME == @last_agent }
      return PROMPT unless pinned

      "#{PROMPT}\nThe last reply in this chat came from the #{pinned::TITLE} specialist. If the user's latest " \
        "message follows up on it (for example \"anything quicker?\" or \"what about the second one?\"), call " \
        "transfer_to_#{pinned::NAME}.\n"
    end

    # The specialist the router handed the conversation to in this response, if any.
    def handoff(response)
      names = response.content.select { |block| block.type == :tool_use }.map(&:name)
      tools.find { |tool| tool.handoff? && names.include?(tool.name) }&.specialist
    end

    private

    def build_tools = SPECIALISTS.map { |specialist| Tools::Transfer.new(specialist) }
  end
end
