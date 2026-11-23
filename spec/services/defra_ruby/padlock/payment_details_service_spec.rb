# frozen_string_literal: true

RSpec.describe DefraRuby::Padlock::PaymentDetailsService do
  describe ".run" do
    subject(:response) { described_class.run(payment_id: "testpaymentid0000000000002") }

    before do
      allow(DefraRuby::Padlock::AccessToken).to receive(:fetch).and_return("test-access-token")

      stub_request(:get, "https://apigateway.timeforstorm.com/StormWebServices/Payments/testpaymentid0000000000002")
        .to_return(status: 200, body: file_fixture("get_payment_response.json"))
    end

    it "returns a payment response" do
      expect(response).to be_a(DefraRuby::Padlock::PaymentResponse)
    end

    it "returns the payment reference" do
      expect(response.payment_reference).to eq("testpaymentid0000000000002")
    end

    it "returns the payment attempts as Padlock sent them" do
      expect(response.results).to eq(JSON.parse(file_fixture("get_payment_response.json"))["results"])
    end
  end
end
