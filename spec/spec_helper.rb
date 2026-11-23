# frozen_string_literal: true

# Require and run our simplecov initializer as the very first thing we do,
# before the gem is loaded, so its files are included in the coverage report.
# This is as per its docs https://github.com/colszowka/simplecov#getting-started
require "./spec/support/simplecov"

require "webmock/rspec"
require "defra_ruby/padlock"

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories.
#
# We make an exception for simplecov because that will already have been
# required and run at the very top of spec_helper.rb
support_files = Dir["./spec/support/**/*.rb"].reject { |file| file == "./spec/support/simplecov.rb" }
support_files.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.include FixtureHelper

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    DefraRuby::Padlock.configure do |padlock_config|
      padlock_config.padlock_api_username = "test_username"
      padlock_config.padlock_api_password = "test_password"
      padlock_config.lock_interface = "WEXTest"
    end

    DefraRuby::Padlock::AccessToken.reset
  end
end
