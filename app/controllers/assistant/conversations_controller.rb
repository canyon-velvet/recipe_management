module Assistant
  # "New chat": the panel switches to a fresh conversation.
  class ConversationsController < BaseController
    def create
      conversation = current_user.start_conversation
      render turbo_stream: turbo_stream.replace("assistant_messages", partial: "assistant/conversations/messages",
                                                                      locals: { conversation: conversation })
    end
  end
end
