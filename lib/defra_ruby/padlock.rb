# frozen_string_literal: true

require "json"
require "rest-client"

require_relative "padlock/version"
require_relative "padlock/configuration"
require_relative "padlock/api_error"
require_relative "padlock/access_token"
require_relative "padlock/api"

require_relative "padlock/services/base_service"
require_relative "padlock/services/build_payment_request_body_service"
require_relative "padlock/services/initiate_payment_service"
require_relative "padlock/services/payment_details_service"
require_relative "padlock/services/user_details_service"

require_relative "padlock/responses/payment_response"
require_relative "padlock/responses/user_response"

module DefraRuby
  module Padlock
    class << self
      def configure
        yield(configuration)
      end

      def configuration
        @configuration ||= Configuration.new
      end
    end
  end
end
