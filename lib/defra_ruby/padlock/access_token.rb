# frozen_string_literal: true

module DefraRuby
  module Padlock
    # Holds the Padlock access token in memory and requests a new one once it has expired
    class AccessToken
      class << self
        def fetch
          cached = @cached
          cached = request_token if cached.nil? || Time.now >= cached[:expires_at]

          cached[:token]
        end

        def reset
          @cached = nil
        end

        private

        # The token and its expiry are stored together so another thread never sees one without the other
        def request_token
          requested_at = Time.now
          response = DefraRuby::Padlock::API.new.access_token

          @cached = { token: response["access_token"], expires_at: requested_at + response["expires_in"] }
        end
      end
    end
  end
end
