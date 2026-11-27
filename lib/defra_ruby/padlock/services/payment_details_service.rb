# frozen_string_literal: true

module DefraRuby
  module Padlock
    class PaymentDetailsService < BaseService
      def run(payment_id:)
        DefraRuby::Padlock::API.new.get_payment(payment_id)
      end
    end
  end
end
