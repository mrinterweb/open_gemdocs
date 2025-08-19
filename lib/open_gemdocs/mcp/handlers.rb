# frozen_string_literal: true

require_relative "tools"

module OpenGemdocs
  module MCP
    class Handlers
      def initialize
        @tools = Tools.new
      end

      def handle(request)
        method = request["method"]
        id = request["id"]

        case method
        when "initialize"
          handle_initialize(id)
        when "initialized"
          # Client notification, no response needed
          nil
        when "tools/list"
          handle_tools_list(id)
        when "tools/call"
          handle_tool_call(id, request["params"])
        when "ping"
          { "jsonrpc" => "2.0", "id" => id, "result" => {} }
        else
          error_response(id, -32_601, "Method not found: #{method}")
        end
      end

      private

      def handle_initialize(id)
        {
          "jsonrpc" => "2.0",
          "id" => id,
          "result" => {
            "protocolVersion" => "2024-11-05",
            "capabilities" => {
              "tools" => {},
              "resources" => {}
            },
            "serverInfo" => {
              "name" => "open_gemdocs_mcp",
              "version" => OpenGemdocs::VERSION
            }
          }
        }
      end

      def handle_tools_list(id)
        {
          "jsonrpc" => "2.0",
          "id" => id,
          "result" => {
            "tools" => @tools.list
          }
        }
      end

      def handle_tool_call(id, params)
        tool_name = params["name"]
        arguments = params["arguments"] || {}

        begin
          result = @tools.call(tool_name, arguments)

          {
            "jsonrpc" => "2.0",
            "id" => id,
            "result" => result
          }
        rescue StandardError => e
          error_response(id, -32_603, "Tool execution error: #{e.message}")
        end
      end

      def error_response(id, code, message)
        {
          "jsonrpc" => "2.0",
          "id" => id,
          "error" => {
            "code" => code,
            "message" => message
          }
        }
      end
    end
  end
end
