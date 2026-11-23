# frozen_string_literal: true

module DefraRuby
  module Padlock
    # Looks up a Storm user by their email address, which is their Storm username
    class UserDetailsService < BaseService
      def run(email:)
        DefraRuby::Padlock::API.new.get_user(email)
      end
    end
  end
end
