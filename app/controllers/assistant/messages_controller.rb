module Assistant
  # Sending a message from the panel: the user's message and the assistant's pending reply are added to the chat,
  # and WriteReplyJob streams the reply into it.
  class MessagesController < BaseController
    def create
      question, reply = current_user.current_conversation!.ask(params.expect(message: [ :content ])[:content])
      return head :unprocessable_entity unless reply

      WriteReplyJob.perform_later(reply, I18n.locale.to_s)

      render turbo_stream: turbo_stream.append("assistant_messages", partial: "assistant/messages/message",
                                                                     collection: [ question, reply ], as: :message)
    end
  end
end
