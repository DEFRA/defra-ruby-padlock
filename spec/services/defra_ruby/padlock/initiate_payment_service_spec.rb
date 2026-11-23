# frozen_string_literal: true

RSpec.describe DefraRuby::Padlock::InitiatePaymentService do
  describe ".run" do
    let(:url) { "https://apigateway.timeforstorm.com/StormWebServices/InitiatePayment" }
    let(:body) do
      {
        userId: 123_456,
        lockInterface: "WEXTest",
        checkUserReadyForPayment: true,
        validateCardInformation: true,
        padlockData: { transactionAmount: { value: "15.67", readonly: true } }
      }
    end

    before do
      allow(DefraRuby::Padlock::AccessToken).to receive(:fetch).and_return("test-access-token")
      stub_request(:post, url).to_return(status: 201, body: "")
    end

    it "sends the body unchanged" do
      expected_json = body.to_json

      described_class.run(body: body)

      expect(a_request(:post, url).with(body: expected_json)).to have_been_made.once
    end

    it "returns true" do
      expect(described_class.run(body: body)).to be(true)
    end

    context "when the request fails" do
      before do
        stub_request(:post, url).to_return(status: 400, body: "synthetic error body")
      end

      it "raises an error" do
        expect { described_class.run(body: body) }.to raise_error(DefraRuby::Padlock::ApiError)
      end
    end
  end
end
