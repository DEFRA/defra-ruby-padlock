# frozen_string_literal: true

RSpec.describe DefraRuby::Padlock::UserDetailsService do
  describe ".run" do
    subject(:response) { described_class.run(email: "test.agent@example.gov.uk") }

    before do
      allow(DefraRuby::Padlock::AccessToken).to receive(:fetch).and_return("test-access-token")

      stub_request(:get, "https://apigateway.timeforstorm.com/StormWebServices/User")
        .with(query: { "username" => "test.agent@example.gov.uk" })
        .to_return(status: 200, body: file_fixture("get_user_response.json"))
    end

    it "returns a user response" do
      expect(response).to be_a(DefraRuby::Padlock::UserResponse)
    end

    it "returns the Storm user ID" do
      expect(response.user_id).to eq(123_456)
    end
  end
end
