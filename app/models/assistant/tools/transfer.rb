module Assistant
  module Tools
    # The router's hand-off to a specialist, e.g. transfer_to_recommend. Calling it ends the router's turn, and the
    # specialist writes the reply instead (see WriteReplyService).
    class Transfer < Tool
      attr_reader :specialist

      def initialize(specialist)
        super(nil, nil)
        @specialist = specialist
      end

      def name = "transfer_to_#{specialist::NAME}"

      def description = "Hand the conversation to the #{specialist::TITLE} specialist, which #{specialist::HANDLES}."

      # A hand-off takes no input.
      class Input < Anthropic::BaseModel
      end

      def handoff? = true

      private

      def execute(_input) = {}
    end
  end
end
