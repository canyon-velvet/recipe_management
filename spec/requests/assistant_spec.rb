require "rails_helper"

RSpec.describe "Assistant panel", type: :request do
  let(:user) { create(:user) }
  let(:turbo_stream) { { "Accept" => "text/vnd.turbo-stream.html" } }

  def log_in = post(login_path, params: { username: user.username, password: "password" })

  context "with an Anthropic API key" do
    before do
      allow(CleanRecipeService).to receive(:available?).and_return(true)
      log_in
    end

    it "shows the ✦ button and the panel, closed until the cookie says it's open" do
      get recipes_path
      expect(response.body).to include('class="assistant-toggle"', 'id="assistant-panel"', 'aria-expanded="false"')
      expect(response.body).not_to include("assistant-open")

      cookies[:assistant_open] = "1"
      get recipes_path
      expect(response.body).to include("assistant-open", 'aria-expanded="true"')
    end

    it "adds the message and a pending reply to the user's conversation" do
      post assistant_messages_path, params: { message: { content: "Dinner for 4?" } }, headers: turbo_stream

      messages = user.current_conversation.messages
      expect(messages.map(&:role)).to eq %w[user assistant]
      expect(response.media_type).to eq "text/vnd.turbo-stream.html"
      expect(response.body).to include('target="assistant_messages"', "Dinner for 4?", "Thinking…",
                                       "message_#{messages.first.id}", "message_#{messages.last.id}")
    end

    it "rejects a blank message" do
      post assistant_messages_path, params: { message: { content: " " } }, headers: turbo_stream

      expect(response).to have_http_status(:unprocessable_content)
      expect(Message.count).to eq 0
    end

    it "starts a new chat and shows it empty" do
      user.current_conversation!.ask("Hello")

      post assistant_conversations_path, headers: turbo_stream

      expect(user.conversations.count).to eq 2
      expect(response.body).to include('action="replace" target="assistant_messages"')
      expect(response.body).not_to include("Hello")
    end
  end

  context "without an Anthropic API key" do
    before do
      allow(CleanRecipeService).to receive(:available?).and_return(false)
      log_in
    end

    it "leaves the assistant out" do
      get recipes_path
      expect(response.body).not_to include("assistant-toggle", "assistant-panel")

      post assistant_messages_path, params: { message: { content: "Hi" } }, headers: turbo_stream
      expect(response).to have_http_status(:not_found)
      post assistant_conversations_path, headers: turbo_stream
      expect(response).to have_http_status(:not_found)
    end
  end

  it "isn't there when logged out" do
    get login_path

    expect(response.body).not_to include("assistant-toggle", "assistant-panel")
    expect(Nokogiri::HTML(response.body).at_css("body")["data-controller"]).to be_nil
  end
end
