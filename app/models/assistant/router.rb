module Assistant
  # The agent that reads each message first. It answers general and cooking questions itself, and hands the rest to
  # a specialist with that specialist's transfer tool. Follow-ups stay with the specialist that wrote the last reply.
  class Router < Agent
    MODEL = "claude-haiku-4-5"
    NAME = "router"
    # Adding a specialist here gives the router its transfer tool. A specialist sets TITLE and HANDLES (when to hand
    # over) for it, and its NAME must be one of Message's agents (with the messages_agent_known check constraint).
    SPECIALISTS = [ RecommendSpecialist, ImportSpecialist ].freeze

    PROMPT = <<~PROMPT.freeze
      You are the assistant in a home recipe app. The user collects recipes, plans the week's meals, and gets a
      grocery list from the plan. Help with cooking: what to make, techniques, substitutions, timings, and how to use
      this app.

      Keep answers short and practical; use Markdown lists when they help.

      When one of your transfer tools fits what the user wants, call it without writing anything first: that
      specialist will answer. You can't see the user's saved recipes yourself, so never claim a recipe is in their
      collection.

      When the user tells you a lasting fact about what they eat or who they cook for (a diet, an allergy, a
      dislike, their household), call suggest_preference so they can save it with a click.

      Apart from what your tools do, you can't take actions in the app yet, such as saving a recipe or changing a
      meal plan. Never say you did; point the user to the app instead.
    PROMPT

    # last_agent: who wrote the conversation's last reply, e.g. "recommend".
    def initialize(user, last_agent: nil)
      super(user)
      @last_agent = last_agent
    end

    # The instructions, when to call each transfer tool, and which specialist to keep follow-ups with.
    def system_prompt
      handoffs = SPECIALISTS.map { |specialist| "- transfer_to_#{specialist::NAME}: the #{specialist::TITLE} " \
                                                "specialist #{specialist::HANDLES}." }
      prompt = "#{PROMPT}\nYour transfer tools:\n#{handoffs.join("\n")}\n"
      pinned = SPECIALISTS.find { |specialist| specialist::NAME == @last_agent }
      if pinned
        prompt += "\nThe last reply in this chat came from the #{pinned::TITLE} specialist. If the user's latest " \
                  "message follows up on it (for example \"anything quicker?\" or \"how spicy is the second " \
                  "one?\"), call transfer_to_#{pinned::NAME}.\n"
      end
      "#{prompt}\n#{language_rule}\n"
    end

    # The specialist the router handed the conversation to in this response, if any.
    def handoff(response)
      names = response.content.select { |block| block.type == :tool_use }.map(&:name)
      tools.find { |tool| tool.handoff? && names.include?(tool.name) }&.specialist
    end

    private

    def build_tools
      SPECIALISTS.map { |specialist| Tools::Transfer.new(specialist) } + [ Tools::SuggestPreference.new(@user, turn) ]
    end
  end
end
