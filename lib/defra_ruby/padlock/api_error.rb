# frozen_string_literal: true

module DefraRuby
  module Padlock
    # Custom error class to handle Padlock API errors
    class ApiError < StandardError
      def initialize(msg = "Padlock API error")
        super
      end
    end
  end
end
