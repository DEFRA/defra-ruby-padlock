# frozen_string_literal: true

module DefraRuby
  module Padlock
    class UserResponse
      attr_reader :username, :user_id, :organisation, :first_name, :last_name

      def initialize(body)
        @username = body["username"]
        @user_id = body["userId"]
        @organisation = body["organisation"]
        @first_name = body["firstName"]
        @last_name = body["lastName"]
      end
    end
  end
end
