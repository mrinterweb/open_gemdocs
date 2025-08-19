# frozen_string_literal: true

require "webrick"
require "json"

module OpenGemdocs
  module MCP
    class Server
      attr_reader :port

      def initialize(port: 6789)
        @port = port
        @handlers = Handlers.new
      end

      def start
        server = WEBrick::HTTPServer.new(
          Port: @port,
          Logger: WEBrick::Log.new($stderr, WEBrick::Log::INFO),
          AccessLog: []
        )

        server.mount_proc "/" do |req, res|
          handle_request(req, res)
        end

        trap("INT") do
          puts "\nShutting down MCP server..."
          OpenGemdocs::Yard.stop_server
          server.shutdown
        end

        puts "MCP server started on port #{@port}"
        puts "Press Ctrl+C to stop"
        server.start
      end

      private

      def handle_request(req, res)
        if req.request_method == "POST"
          handle_post_request(req, res)
        else
          res.status = 405
          res.body = "Method not allowed"
        end
      end

      def handle_post_request(req, res)
        body = JSON.parse(req.body)
        response = @handlers.handle(body)
        send_json_response(res, response)
      rescue JSON::ParserError => e
        send_json_error(res, -32_700, "Parse error", e.message)
      rescue StandardError => e
        send_json_error(res, -32_603, "Internal error", e.message)
      end

      def send_json_response(res, response)
        res.content_type = "application/json"
        res.body = JSON.generate(response)
        res.status = 200
      end

      def send_json_error(res, code, message, data)
        send_json_response(res, {
                             jsonrpc: "2.0",
                             error: {
                               code: code,
                               message: message,
                               data: data
                             }
                           })
      end
    end
  end
end
