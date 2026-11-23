# frozen_string_literal: true

module DefraRuby
  module Padlock
    class PaymentResponse
      attr_reader :payment_reference, :results

      def initialize(body)
        @payment_reference = body["paymentReference"]
        @results = body["results"]
      end
    end
  end
end
