# frozen_string_literal: true

RSpec.describe DefraRuby::Padlock::BuildPaymentRequestBodyService do
  describe ".run" do
    subject(:body) do
      described_class.run(
        user_id: 123_456,
        amount: 1567,
        payment_id: "testpaymentid0000000000001",
        one_time_token: "00000000-0000-0000-0000-000000000000",
        transaction_reference: "wex-test-transaction-001",
        description: "Payment for WEX000001 registration"
      )
    end

    let(:expected_body) do
      {
        userId: 123_456,
        lockInterface: "WEXTest",
        checkUserReadyForPayment: false,
        validateCardInformation: true,
        padlockData: {
          transactionAmount: { value: "15.67", readonly: true },
          reference: { value: "testpaymentid0000000000001", readonly: true },
          oneTimeToken: { value: "00000000-0000-0000-0000-000000000000" },
          TransactionReference: { value: "wex-test-transaction-001", readonly: true },
          Description: { value: "Payment for WEX000001 registration", readonly: true }
        }
      }
    end

    it "returns the InitiatePayment request body" do
      expect(body).to eq(expected_body)
    end

    it "does not make any requests" do
      body

      expect(a_request(:any, /.*/)).not_to have_been_made
    end
  end
end
