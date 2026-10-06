require "rails_helper"

RSpec.describe WriteReplyJob do
  it "writes the reply in the user's language" do
    reply = create(:conversation).ask("Hi").last
    service = instance_double(WriteReplyService)
    allow(WriteReplyService).to receive(:new).with(reply).and_return(service)
    allow(service).to receive(:call) { expect(I18n.locale).to eq :"zh-CN" }

    described_class.perform_now(reply, "zh-CN")

    expect(service).to have_received(:call)
  end
end
