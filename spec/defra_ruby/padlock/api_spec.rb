# frozen_string_literal: true

RSpec.describe DefraRuby::Padlock::API do
  subject(:api) { described_class.new }

  before do
    allow(DefraRuby::Padlock::AccessToken).to receive(:fetch).and_return("test-access-token")
  end

  describe "#initiate_payment" do
    let(:url) { "https://apigateway.timeforstorm.com/StormWebServices/InitiatePayment" }
    let(:body) do
      { userId: 123_456, lockInterface: "WEXTest", padlockData: { oneTimeToken: { value: "secret-one-time-token" } } }
    end
    let(:expected_request) do
      a_request(:post, url).with(
        body: body.to_json,
        headers: {
          "Authorization" => "Bearer test-access-token",
          "Content-Type" => "application/json",
          "Accept" => "application/problem+json"
        }
      ) { |request| !request.headers.key?("Params") }
    end

    before do
      # Padlock responds with HTTP 201 and an empty body
      stub_request(:post, url).to_return(status: 201, body: "")
    end

    it "posts the body as JSON with the access token" do
      api.initiate_payment(body)

      expect(expected_request).to have_been_made.once
    end

    it "returns true" do
      expect(api.initiate_payment(body)).to be(true)
    end

    context "when the request fails" do
      before do
        # The real Padlock error format is not known, so this body is synthetic
        stub_request(:post, url).to_return(status: 400, body: "synthetic error body")
      end

      let(:error) do
        api.initiate_payment(body)
      rescue DefraRuby::Padlock::ApiError => e
        e
      end

      it "raises an error with the status and the response body" do
        expect { api.initiate_payment(body) }
          .to raise_error(DefraRuby::Padlock::ApiError, /POST.*InitiatePayment.*400.*synthetic error body/)
      end

      it "leaves the request body and the access token out of the error message" do
        expect(error.message).not_to match(/secret-one-time-token|test-access-token/)
      end
    end

    context "when the request times out" do
      before { stub_request(:post, url).to_timeout }

      it "raises an error with the method and the path" do
        expect { api.initiate_payment(body) }
          .to raise_error(DefraRuby::Padlock::ApiError, %r{POST /InitiatePayment.*Timed out})
      end
    end
  end

  describe "#get_payment" do
    let(:url) { "https://apigateway.timeforstorm.com/StormWebServices/Payments/testpaymentid0000000000002" }
    let(:expected_request) do
      a_request(:get, url).with(
        headers: { "Authorization" => "Bearer test-access-token", "Accept" => "application/json" }
      ) { |request| !request.headers.key?("Content-Type") && !request.headers.key?("Params") }
    end

    before do
      stub_request(:get, url).to_return(status: 200, body: file_fixture("get_payment_response.json"))
    end

    it "requests the payment with the access token" do
      api.get_payment("testpaymentid0000000000002")

      expect(expected_request).to have_been_made.once
    end

    it "returns a payment response" do
      expect(api.get_payment("testpaymentid0000000000002")).to be_a(DefraRuby::Padlock::PaymentResponse)
    end

    context "when the request fails" do
      before do
        stub_request(:get, url).to_return(status: 404, body: "synthetic error body")
      end

      it "raises an error with the status and the response body" do
        expect { api.get_payment("testpaymentid0000000000002") }
          .to raise_error(DefraRuby::Padlock::ApiError, /GET.*Payments.*404.*synthetic error body/)
      end
    end
  end

  describe "#get_user" do
    let(:url) { "https://apigateway.timeforstorm.com/StormWebServices/User" }
    let(:query) { { "username" => "test.agent+wex@example.gov.uk" } }
    let(:expected_request) do
      a_request(:get, url).with(
        query: query,
        headers: { "Authorization" => "Bearer test-access-token", "Accept" => "application/json" }
      ) { |request| !request.headers.key?("Content-Type") }
    end

    before do
      stub_request(:get, url).with(query: query)
                             .to_return(status: 200, body: file_fixture("get_user_response.json"))
    end

    it "requests the user by username with the access token" do
      api.get_user("test.agent+wex@example.gov.uk")

      expect(expected_request).to have_been_made.once
    end

    it "returns a user response" do
      expect(api.get_user("test.agent+wex@example.gov.uk")).to be_a(DefraRuby::Padlock::UserResponse)
    end

    it "returns the user details" do
      expect(api.get_user("test.agent+wex@example.gov.uk")).to have_attributes(
        username: "test.agent@example.gov.uk", user_id: 123_456, organisation: 1234,
        first_name: "Test", last_name: "Agent"
      )
    end

    context "when the user is not known to Padlock" do
      before do
        # Padlock's actual response for an unknown username, seen in manual testing
        stub_request(:get, url).with(query: query)
                               .to_return(status: 403, body: file_fixture("get_user_forbidden_response.json"))
      end

      let(:error) do
        api.get_user("test.agent+wex@example.gov.uk")
      rescue DefraRuby::Padlock::ApiError => e
        e
      end

      it "raises an error with the status and the response body" do
        expect { api.get_user("test.agent+wex@example.gov.uk") }
          .to raise_error(DefraRuby::Padlock::ApiError, %r{GET /User.*403 Forbidden.*"detail":"Forbidden"})
      end

      it "leaves the email address and the access token out of the error message" do
        expect(error.message).not_to match(/test\.agent|test-access-token/)
      end
    end

    context "when Padlock responds with a redirect" do
      let(:redirect_url) { "https://elsewhere.example.com/User" }
      let(:error) do
        api.get_user("test.agent+wex@example.gov.uk")
      rescue DefraRuby::Padlock::ApiError => e
        e
      end

      before do
        stub_request(:get, url).with(query: query).to_return(status: 302, headers: { "Location" => redirect_url })
        stub_request(:any, redirect_url).to_return(status: 200, body: file_fixture("get_user_response.json"))
      end

      it "raises an error" do
        expect { api.get_user("test.agent+wex@example.gov.uk") }
          .to raise_error(DefraRuby::Padlock::ApiError, /302/)
      end

      it "does not send the access token to the new address" do
        error

        expect(a_request(:any, redirect_url)).not_to have_been_made
      end
    end
  end
end
