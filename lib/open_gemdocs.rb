# frozen_string_literal: true

require_relative 'open_gemdocs/version'
require_relative 'open_gemdocs/browser'
require_relative 'open_gemdocs/yard'

module OpenGemdocs
  class Error < StandardError; end
  
  # MCP components are loaded on-demand by the executable
  module MCP
    # Autoload MCP components to avoid loading them unless needed
    autoload :Server, 'open_gemdocs/mcp/server'
    autoload :Handlers, 'open_gemdocs/mcp/handlers'
    autoload :Tools, 'open_gemdocs/mcp/tools'
  end
end
