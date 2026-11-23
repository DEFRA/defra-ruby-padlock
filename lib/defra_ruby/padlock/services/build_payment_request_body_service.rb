# frozen_string_literal: true

module DefraRuby
  module Padlock
    # Builds the request body for InitiatePaymentService. The amount is in pence.
    class BuildPaymentRequestBodyService < BaseService
      # rubocop:disable-next Metrics/ParameterLists
      def run(user_id:, amount:, payment_id:, one_time_token:, transaction_reference:, description:)
        {
          userId: user_id,
          lockInterface: DefraRuby::Padlock.configuration.lock_interface,
          checkUserReadyForPayment: false,
          validateCardInformation: true,
          padlockData: {
            transactionAmount: { value: amount_in_pounds(amount), readonly: true },
            reference: { value: payment_id, readonly: true },
            oneTimeToken: { value: one_time_token },
            TransactionReference: { value: transaction_reference, readonly: true },
            Description: { value: description, readonly: true }
          }
        }
      end

      private

      def amount_in_pounds(amount)
        format("%.2f", amount / 100.0)
      end
    end
  end
end
