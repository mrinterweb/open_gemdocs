# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module OpenGemdocs
  module MCP
    class Tools
      def initialize
        # Ensure we can access the Yard module
        require_relative "../yard"
      end

      def list
        [
          {
            "name" => "search_gems",
            "description" => "Search for installed Ruby gems",
            "inputSchema" => {
              "type" => "object",
              "properties" => {
                "query" => {
                  "type" => "string",
                  "description" => "Search query for gem names (partial match supported)"
                }
              },
              "required" => ["query"]
            }
          },
          {
            "name" => "get_gem_info",
            "description" => "Get information about a specific gem including version and summary",
            "inputSchema" => {
              "type" => "object",
              "properties" => {
                "gem_name" => {
                  "type" => "string",
                  "description" => "Exact name of the gem"
                }
              },
              "required" => ["gem_name"]
            }
          },
          {
            "name" => "start_yard_server",
            "description" => "Start the Yard documentation server",
            "inputSchema" => {
              "type" => "object",
              "properties" => {}
            }
          },
          {
            "name" => "stop_yard_server",
            "description" => "Stop the Yard documentation server",
            "inputSchema" => {
              "type" => "object",
              "properties" => {}
            }
          },
          {
            "name" => "get_yard_server_status",
            "description" => "Check if the Yard documentation server is running",
            "inputSchema" => {
              "type" => "object",
              "properties" => {}
            }
          },
          {
            "name" => "get_gem_documentation_url",
            "description" => "Get the local documentation URL for a gem",
            "inputSchema" => {
              "type" => "object",
              "properties" => {
                "gem_name" => {
                  "type" => "string",
                  "description" => "Name of the gem"
                },
                "class_name" => {
                  "type" => "string",
                  "description" => "Optional: specific class or module name"
                }
              },
              "required" => ["gem_name"]
            }
          },
          {
            "name" => "fetch_gem_docs",
            "description" => "Fetch documentation content for a gem from the Yard server",
            "inputSchema" => {
              "type" => "object",
              "properties" => {
                "gem_name" => {
                  "type" => "string",
                  "description" => "Name of the gem"
                },
                "path" => {
                  "type" => "string",
                  "description" => 'Optional: specific documentation path (e.g., "ActiveRecord/Base")'
                }
              },
              "required" => ["gem_name"]
            }
          }
        ]
      end

      def call(tool_name, arguments)
        case tool_name
        when "search_gems"
          search_gems(arguments["query"])
        when "get_gem_info"
          get_gem_info(arguments["gem_name"])
        when "start_yard_server"
          start_yard_server
        when "stop_yard_server"
          stop_yard_server
        when "get_yard_server_status"
          get_yard_server_status
        when "get_gem_documentation_url"
          get_gem_documentation_url(arguments["gem_name"], arguments["class_name"])
        when "fetch_gem_docs"
          fetch_gem_docs(arguments["gem_name"], arguments["path"])
        else
          {
            "content" => [{
              "type" => "text",
              "text" => "Unknown tool: #{tool_name}"
            }],
            "isError" => true
          }
        end
      end

      private

      def search_gems(query)
        if query.nil? || query.empty?
          return { "content" => [{ "type" => "text", "text" => "Query cannot be empty" }],
                   "isError" => true }
        end

        gems = `gem list --local`.lines
                                 .map do |line|
                                   parts = line.strip.match(/^([^\s]+)\s+\(([^)]+)\)/)
                                   next unless parts

                                   { name: parts[1], versions: parts[2] }
                                 end
                                 .compact
                                 .select { |gem| gem[:name].downcase.include?(query.downcase) }

        if gems.empty?
          {
            "content" => [{
              "type" => "text",
              "text" => "No gems found matching '#{query}'"
            }]
          }
        else
          gem_list = gems.map { |g| "• #{g[:name]} (#{g[:versions]})" }.join("\n")
          {
            "content" => [{
              "type" => "text",
              "text" => "Found #{gems.count} gem(s):\n#{gem_list}"
            }]
          }
        end
      end

      def get_gem_info(gem_name)
        spec = Gem::Specification.find_by_name(gem_name)

        info = []
        info << "**#{spec.name}** v#{spec.version}"
        info << ""
        info << "**Summary:** #{spec.summary}" if spec.summary
        info << "**Description:** #{spec.description}" if spec.description && spec.description != spec.summary
        info << "**Homepage:** #{spec.homepage}" if spec.homepage
        info << "**License:** #{spec.license || spec.licenses.join(", ")}" if spec.license || spec.licenses.any?
        info << "**Authors:** #{spec.authors.join(", ")}" if spec.authors.any?

        {
          "content" => [{
            "type" => "text",
            "text" => info.join("\n")
          }]
        }
      rescue Gem::LoadError => e
        {
          "content" => [{
            "type" => "text",
            "text" => "Gem '#{gem_name}' not found: #{e.message}"
          }],
          "isError" => true
        }
      end

      def start_yard_server
        if OpenGemdocs::Yard.server_running?
          {
            "content" => [{
              "type" => "text",
              "text" => "Yard server is already running on port 8808"
            }]
          }
        else
          OpenGemdocs::Yard.start_yard_server
          sleep 2 # Give server time to start

          if OpenGemdocs::Yard.server_running?
            {
              "content" => [{
                "type" => "text",
                "text" => "Yard server started successfully on port 8808"
              }]
            }
          else
            {
              "content" => [{
                "type" => "text",
                "text" => "Failed to start Yard server"
              }],
              "isError" => true
            }
          end
        end
      end

      def stop_yard_server
        if OpenGemdocs::Yard.server_running?
          OpenGemdocs::Yard.stop_server
          {
            "content" => [{
              "type" => "text",
              "text" => "Yard server stopped successfully"
            }]
          }
        else
          {
            "content" => [{
              "type" => "text",
              "text" => "Yard server is not running"
            }]
          }
        end
      end

      def get_yard_server_status
        if OpenGemdocs::Yard.server_running?
          pids = OpenGemdocs::Yard.find_yard_pids
          {
            "content" => [{
              "type" => "text",
              "text" => "Yard server is running (PID: #{pids.join(", ")}) on port 8808"
            }]
          }
        else
          {
            "content" => [{
              "type" => "text",
              "text" => "Yard server is not running"
            }]
          }
        end
      end

      def get_gem_documentation_url(gem_name, class_name = nil)
        # Ensure server is running
        unless OpenGemdocs::Yard.server_running?
          OpenGemdocs::Yard.start_yard_server
          sleep 2
        end

        url = "http://localhost:8808/docs/#{gem_name}"
        url += "/#{class_name.gsub("::", "/")}" if class_name

        {
          "content" => [{
            "type" => "text",
            "text" => "Documentation URL: #{url}\n\nNote: The Yard server is running on port 8808"
          }]
        }
      end

      def fetch_gem_docs(gem_name, path = nil)
        # Ensure server is running
        unless OpenGemdocs::Yard.server_running?
          OpenGemdocs::Yard.start_yard_server
          sleep 2
        end

        url = "http://localhost:8808/docs/#{gem_name}"
        url += "/#{path.gsub("::", "/")}" if path

        begin
          uri = URI(url)
          response = Net::HTTP.get_response(uri)

          case response.code
          when "200"
            # Extract text content from HTML (basic extraction)
            body = response.body
            # Remove script and style tags
            body = body.gsub(%r{<script[^>]*>.*?</script>}m, "")
            body = body.gsub(%r{<style[^>]*>.*?</style>}m, "")
            # Extract title if present
            title = body.match(%r{<title>([^<]+)</title>}i)&.captures&.first || gem_name

            # Extract main content (yard uses #content div)
            content = if body.match(%r{<div id="content"[^>]*>(.*?)</div>}m)
                        body.match(%r{<div id="content"[^>]*>(.*?)</div>}m).captures.first
                      else
                        body
                      end

            # Basic HTML to text conversion
            content = content.gsub(/<[^>]+>/, " ")  # Remove HTML tags
            content = content.gsub(/\s+/, " ")      # Normalize whitespace
            content = content.strip

            # Truncate if too long
            content = "#{content[0..1997]}..." if content.length > 2000

            {
              "content" => [{
                "type" => "text",
                "text" => "**#{title}**\n\n#{content}\n\n[Full documentation: #{url}]"
              }]
            }
          when "202"
            {
              "content" => [{
                "type" => "text",
                "text" => "Documentation is being generated for '#{gem_name}'. This usually takes a few seconds.\n\nPlease try again shortly. The documentation will be available at: #{url}"
              }],
              "isError" => false
            }
          when "404"
            {
              "content" => [{
                "type" => "text",
                "text" => "Documentation not found for '#{gem_name}'. The gem might not be installed or the path '#{path}' might be incorrect."
              }],
              "isError" => true
            }
          else
            {
              "content" => [{
                "type" => "text",
                "text" => "Failed to fetch documentation (HTTP #{response.code}): #{response.message}"
              }],
              "isError" => true
            }
          end
        rescue StandardError => e
          {
            "content" => [{
              "type" => "text",
              "text" => "Error fetching documentation: #{e.message}"
            }],
            "isError" => true
          }
        end
      end
    end
  end
end
