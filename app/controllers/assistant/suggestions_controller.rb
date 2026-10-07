module Assistant
  # The buttons on a preference the assistant suggested (see Assistant::Tools::SuggestPreference): Save adds it to
  # the user's preferences, No thanks dismisses it. Either way the reply is re-rendered with the card's new state.
  class SuggestionsController < BaseController
    before_action :set_suggestion

    def save
      return head :unprocessable_entity unless SaveSuggestedPreferenceService.new(@message, @index).call

      render_reply
    end

    def dismiss
      @message.decide_suggestion!(@index, "dismissed") if @message.preference_suggestions[@index]["state"] == "pending"
      render_reply
    end

    private

    # Only the user's own replies, and only suggestions they have.
    def set_suggestion
      @message = current_user.conversation_messages.assistant.find(params[:message_id])
      @index = Integer(params[:id], exception: false)
      head :not_found unless @index&.between?(0, @message.preference_suggestions.size - 1)
    end

    def render_reply
      render turbo_stream: turbo_stream.replace(@message, partial: "assistant/messages/message",
                                                          locals: { message: @message })
    end
  end
end
