module Assistant
  module Tools
    # Something an agent can do while it writes a reply, such as searching the user's recipes. Claude reads the tool's
    # definition and asks for calls; RunAgentService runs them. Tools only ever see their user's data.
    #
    # A tool sets NAME and defines description, input_schema and execute(input). Any agent can use any tool.
    class Tool
      def initialize(user)
        @user = user
      end

      def name = self.class::NAME

      # How Claude sees the tool.
      def definition = { name: name, description: description, input_schema: input_schema }

      # Runs the tool with Claude's input (a Hash with symbol keys), returning its result for Claude. A call that
      # didn't work returns an :error instead of raising, so Claude can try again.
      def call(input)
        return { error: "The input isn't a JSON object." } unless input.is_a?(Hash)

        execute(input)
      end

      # What the panel shows while the tool runs, if anything, e.g. "Searching your recipes…".
      def activity = nil

      # Whether calling it ends the agent's turn and hands the conversation to another agent.
      def handoff? = false
    end
  end
end
