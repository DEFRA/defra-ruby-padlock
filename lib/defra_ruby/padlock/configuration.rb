# frozen_string_literal: true

module DefraRuby
  module Padlock
    class Configuration
      attr_accessor :padlock_api_username, :padlock_api_password, :lock_interface, :padlock_url

      def initialize
        @padlock_url = "https://apigateway.timeforstorm.com/StormWebServices"
      end
    end
  end
end
