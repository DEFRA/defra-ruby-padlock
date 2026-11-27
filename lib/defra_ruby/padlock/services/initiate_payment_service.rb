# frozen_string_literal: true

module DefraRuby
  module Padlock
    class InitiatePaymentService < BaseService
      def run(body:)
        DefraRuby::Padlock::API.new.initiate_payment(body)
      end
    end
  end
end
