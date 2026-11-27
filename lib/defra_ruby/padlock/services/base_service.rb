# frozen_string_literal: true

module DefraRuby
  module Padlock
    class BaseService
      def self.run(attrs = {})
        new.run(**attrs)
      end
    end
  end
end
