# frozen_string_literal: true

require "spec_helper"
require "open_gemdocs/mcp/handlers"
require "open_gemdocs/mcp/tools"

RSpec.describe OpenGemdocs::MCP::Handlers do
  let(:handlers) { described_class.new }

  describe "#handle" do
    context "with initialize request" do
      let(:request) do
        {
          "jsonrpc" => "2.0",
          "id" => 1,
          "method" => "initialize",
          "params" => { "protocolVersion" => "2024-11-05" }
        }
      end

      it "returns server capabilities" do
        response = handlers.handle(request)

        expect(response).to include(
          "jsonrpc" => "2.0",
          "id" => 1
        )
        expect(response["result"]).to include(
          "protocolVersion" => "2024-11-05",
          "capabilities" => hash_including("tools", "resources"),
          "serverInfo" => hash_including("name" => "open_gemdocs_mcp")
        )
      end
    end

    context "with tools/list request" do
      let(:request) do
        {
          "jsonrpc" => "2.0",
          "id" => 2,
          "method" => "tools/list"
        }
      end

      it "returns available tools" do
        response = handlers.handle(request)

        expect(response).to include(
          "jsonrpc" => "2.0",
          "id" => 2
        )

        tools = response.dig("result", "tools")
        expect(tools).to be_an(Array)
        expect(tools).not_to be_empty

        # Check for expected tools
        tool_names = tools.map { |t| t["name"] }
        expect(tool_names).to include(
          "search_gems",
          "get_gem_info",
          "start_yard_server",
          "stop_yard_server"
        )
      end
    end

    context "with tools/call request" do
      let(:request) do
        {
          "jsonrpc" => "2.0",
          "id" => 3,
          "method" => "tools/call",
          "params" => {
            "name" => "search_gems",
            "arguments" => { "query" => "rspec" }
          }
        }
      end

      it "executes the requested tool" do
        response = handlers.handle(request)

        expect(response).to include(
          "jsonrpc" => "2.0",
          "id" => 3
        )
        expect(response["result"]).to include("content")
      end
    end

    context "with unknown method" do
      let(:request) do
        {
          "jsonrpc" => "2.0",
          "id" => 4,
          "method" => "unknown/method"
        }
      end

      it "returns method not found error" do
        response = handlers.handle(request)

        expect(response).to include(
          "jsonrpc" => "2.0",
          "id" => 4
        )
        expect(response["error"]).to include(
          "code" => -32_601,
          "message" => match(/Method not found/)
        )
      end
    end

    context "with ping request" do
      let(:request) do
        {
          "jsonrpc" => "2.0",
          "id" => 5,
          "method" => "ping"
        }
      end

      it "returns empty result" do
        response = handlers.handle(request)

        expect(response).to eq({
                                 "jsonrpc" => "2.0",
                                 "id" => 5,
                                 "result" => {}
                               })
      end
    end
  end
end
