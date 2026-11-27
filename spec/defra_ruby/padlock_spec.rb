# frozen_string_literal: true

RSpec.describe DefraRuby::Padlock do
  it "has a version number" do
    expect(DefraRuby::Padlock::VERSION).not_to be_nil
  end

  describe ".configure" do
    it "sets the configuration values" do
      described_class.configure { |config| config.lock_interface = "AnotherInterface" }

      expect(described_class.configuration.lock_interface).to eq("AnotherInterface")
    end
  end

  describe ".configuration" do
    it "defaults the Padlock URL" do
      expect(described_class.configuration.padlock_url).to eq("https://apigateway.timeforstorm.com/StormWebServices")
    end
  end
end
