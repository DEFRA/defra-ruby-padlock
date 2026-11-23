# frozen_string_literal: true

module DefraRuby
  module Padlock
    class API
      def access_token
        response = execute(
          method: :post,
          path: "/oauth/token",
          payload: { grant_type: "client_credentials" },
          user: configuration.padlock_api_username,
          password: configuration.padlock_api_password,
          headers: { accept: :json }
        )

        JSON.parse(response.body)
      end

      # rubocop:disable-next Naming/PredicateMethod
      def initiate_payment(body)
        # Padlock responds with HTTP 201 and an empty body
        send_request(method: :post, path: "/InitiatePayment", payload: body.to_json, accept: "application/problem+json")

        true
      end

      def get_payment(payment_id)
        response = send_request(method: :get, path: "/Payments/#{payment_id}", accept: :json)

        DefraRuby::Padlock::PaymentResponse.new(JSON.parse(response.body))
      end

      def get_user(username)
        response = send_request(method: :get, path: "/User", accept: :json, params: { username: username })

        DefraRuby::Padlock::UserResponse.new(JSON.parse(response.body))
      end

      private

      def send_request(method:, path:, accept:, payload: nil, params: nil)
        headers = { accept: accept, authorization: "Bearer #{DefraRuby::Padlock::AccessToken.fetch}" }
        headers[:content_type] = :json if payload
        # rest-client takes the query string parameters from the :params header
        headers[:params] = params if params

        execute(method: method, path: path, payload: payload, headers: headers)
      end

      # The request payload is deliberately left out of the error message as it
      # can contain the GovPay one-time token.
      #
      # Redirects are not followed, as rest-client would send the credentials or
      # access token on to the new address. A redirect is raised as an ApiError.
      def execute(method:, path:, **)
        RestClient::Request.execute(
          method: method, url: "#{configuration.padlock_url}#{path}", max_redirects: 0, **
        )
      rescue RestClient::Exception => e
        raise ApiError,
              "Error sending request to Padlock (#{method.to_s.upcase} #{path}): #{e.message}, " \
              "response body: #{e.response&.body}"
      end

      def configuration
        DefraRuby::Padlock.configuration
      end
    end
  end
end
