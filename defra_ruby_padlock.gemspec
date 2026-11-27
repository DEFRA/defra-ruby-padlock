# frozen_string_literal: true

require_relative "lib/defra_ruby/padlock/version"

Gem::Specification.new do |spec|
  spec.name = "defra_ruby_padlock"
  spec.version = DefraRuby::Padlock::VERSION
  spec.authors = ["Defra"]
  spec.email = ["leonid.brujev@defra.gov.uk"]
  spec.license = "The Open Government Licence (OGL) Version 3"

  spec.summary = "Ruby client for the Storm Padlock API"
  spec.homepage = "https://github.com/DEFRA/defra-ruby-padlock"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/DEFRA/defra-ruby-padlock"
  spec.metadata["changelog_uri"] = "https://github.com/DEFRA/defra-ruby-padlock/blob/main/CHANGELOG.md"

  # REST client
  spec.add_dependency "rest-client", "~> 2.1"

  spec.require_paths = ["lib"]

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.metadata["rubygems_mfa_required"] = "true"
end
