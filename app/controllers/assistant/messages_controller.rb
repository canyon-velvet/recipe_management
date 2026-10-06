module Assistant
  # Sending a message from the panel: the user's message and the assistant's pending reply are added to the chat,
  # and WriteReplyJob streams the reply into it.
  class MessagesController < BaseController
    def create
      return render_limit_notice if current_user.assistant_limit_reached?

      question, reply = current_user.current_conversation!.ask(params.expect(message: [ :content ])[:content])
      return head :unprocessable_entity unless reply

      WriteReplyJob.perform_later(reply, I18n.locale.to_s)
      render turbo_stream: turbo_stream.append("assistant_messages", partial: "assistant/messages/message",
                                                                     collection: [ question, reply ], as: :message)
    end

    private

    # Over the daily limit nothing is saved or sent to Claude. The notice is shown in the chat, and the 429 keeps
    # what was typed in the box.
    def render_limit_notice
      render turbo_stream: turbo_stream.append("assistant_messages", partial: "assistant/messages/limit_notice"),
             status: :too_many_requests
    end
  end
end
