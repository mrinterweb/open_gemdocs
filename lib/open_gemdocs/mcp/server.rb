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
          begin
            body = JSON.parse(req.body)
            response = @handlers.handle(body)

            res.content_type = "application/json"
            res.body = JSON.generate(response)
            res.status = 200
          rescue JSON::ParserError => e
            res.content_type = "application/json"
            res.body = JSON.generate({
                                       jsonrpc: "2.0",
                                       error: {
                                         code: -32_700,
                                         message: "Parse error",
                                         data: e.message
                                       }
                                     })
            res.status = 200
          rescue StandardError => e
            res.content_type = "application/json"
            res.body = JSON.generate({
                                       jsonrpc: "2.0",
                                       error: {
                                         code: -32_603,
                                         message: "Internal error",
                                         data: e.message
                                       }
                                     })
            res.status = 200
          end
        else
          res.status = 405
          res.body = "Method not allowed"
        end
      end
    end
  end
end
