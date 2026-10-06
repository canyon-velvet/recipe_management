module Assistant
  # One of the assistant's agents: the router or a specialist. An agent is a definition: which model it runs on, its
  # instructions and its tools. RunAgentService runs it for a reply.
  #
  # An agent sets MODEL and NAME (recorded on the steps and the reply it writes) and defines system_prompt and
  # build_tools; request_options adds anything else its model takes.
  class Agent
    # Plenty for a chat answer; a reply that hits it is cut off rather than failing.
    MAX_TOKENS = 8_000

    def initialize(user)
      @user = user
    end

    def model = self.class::MODEL

    def name = self.class::NAME

    # Made once per reply: a tool can keep what it was asked, such as the recipes to show.
    def tools = @tools ||= build_tools

    # What the tools have found during this reply, shared between them.
    def turn = @turn ||= Turn.new

    def tool(name) = tools.find { |tool| tool.name == name }

    # What every request for this agent sends, apart from the conversation.
    def request
      { model: model, max_tokens: MAX_TOKENS, system_: system_prompt, tools: tools.map(&:definition),
        **request_options }
    end

    # The recipes the agent chose to show as cards under its reply, with why: { recipe id => reason }.
    def shown_cards = tools.grep(Tools::ShowRecipes).map(&:cards).reduce({}, :merge)

    private

    # Ends every agent's instructions, after the user's data, so recipes and ingredients written in another language
    # don't pull the reply into it. The app's language (the job runs in the user's locale) settles any doubt.
    def language_rule
      "Write your reply in the language of the user's latest message, even when their recipes, ingredients or " \
        "earlier replies are in another language; keep recipe names as they are. If you can't tell its language, " \
        "use #{I18n.t('locale_name')}, the app's language."
    end

    def request_options = {}
  end
end
