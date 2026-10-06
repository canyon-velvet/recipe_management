module Assistant
  # Sending a message from the panel: the user's message and the assistant's pending reply are added to the chat.
  class MessagesController < BaseController
    def create
      question, reply = current_user.current_conversation!.ask(params.dig(:message, :content))
      return head :unprocessable_entity unless reply

      render turbo_stream: turbo_stream.append("assistant_messages", partial: "assistant/messages/message",
                                                                     collection: [ question, reply ], as: :message)
    end
  end
end
