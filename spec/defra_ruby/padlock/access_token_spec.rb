# frozen_string_literal: true

RSpec.describe DefraRuby::Padlock::AccessToken do
  let(:token_url) { "https://apigateway.timeforstorm.com/StormWebServices/oauth/token" }

  describe ".fetch" do
    let(:expected_request) do
      a_request(:post, token_url).with(
        basic_auth: %w[test_username test_password],
        body: { "grant_type" => "client_credentials" },
        headers: { "Accept" => "application/json", "Content-Type" => "application/x-www-form-urlencoded" }
      )
    end

    before do
      stub_request(:post, token_url).to_return(status: 200, body: file_fixture("access_token_response.json"))
    end

    it "requests a token using the client credentials" do
      described_class.fetch

      expect(expected_request).to have_been_made.once
    end

    it "returns the access token" do
      expect(described_class.fetch).to eq("test-access-token")
    end

    context "when a token has already been fetched" do
      before { described_class.fetch }

      it "does not request another one" do
        described_class.fetch

        expect(a_request(:post, token_url)).to have_been_made.once
      end

      it "returns the same token" do
        expect(described_class.fetch).to eq("test-access-token")
      end
    end

    context "when the token has expired" do
      before do
        stub_request(:post, token_url).to_return(
          { status: 200, body: file_fixture("access_token_response.json") },
          { status: 200, body: { access_token: "second-access-token", expires_in: 3600 }.to_json }
        )

        described_class.fetch
        allow(Time).to receive(:now).and_return(Time.now + 3601)
      end

      it "requests a new one" do
        described_class.fetch

        expect(a_request(:post, token_url)).to have_been_made.twice
      end

      it "returns the new token" do
        expect(described_class.fetch).to eq("second-access-token")
      end
    end

    context "when the request fails" do
      before do
        stub_request(:post, token_url).to_return(status: 401, body: "synthetic error body")
      end

      let(:error) do
        described_class.fetch
      rescue DefraRuby::Padlock::ApiError => e
        e
      end

      it "raises an error with the status and the response body" do
        expect { described_class.fetch }.to raise_error(DefraRuby::Padlock::ApiError, /401.*synthetic error body/)
      end

      it "leaves the credentials out of the error message" do
        expect(error.message).not_to match(/test_username|test_password/)
      end
    end

    context "when Padlock responds with a redirect" do
      let(:redirect_url) { "https://elsewhere.example.com/oauth/token" }
      let(:error) do
        described_class.fetch
      rescue DefraRuby::Padlock::ApiError => e
        e
      end

      before do
        stub_request(:post, token_url).to_return(status: 303, headers: { "Location" => redirect_url })
        stub_request(:any, redirect_url).to_return(status: 200, body: file_fixture("access_token_response.json"))
      end

      it "raises an error" do
        expect { described_class.fetch }.to raise_error(DefraRuby::Padlock::ApiError, /303/)
      end

      it "does not send the credentials to the new address" do
        error

        expect(a_request(:any, redirect_url)).not_to have_been_made
      end
    end
  end
end
