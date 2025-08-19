# frozen_string_literal: true

RSpec.describe OpenGemdocs do
  it "has a version number" do
    expect(OpenGemdocs::VERSION).not_to be nil
  end

  it "has MCP module" do
    expect(OpenGemdocs::MCP).to be_a(Module)
  end
end
