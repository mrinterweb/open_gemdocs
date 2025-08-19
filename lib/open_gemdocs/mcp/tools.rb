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
        require_relative "../yard_json_formatter"
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
            "description" => "Get the local documentation URL for a gem (Note: Use fetch_gem_docs instead to get actual documentation content)",
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
            "description" => "Fetch structured documentation content for a gem or specific class/module. Returns formatted documentation with methods, attributes, parameters, and examples. Use this instead of fetching URLs directly.",
            "inputSchema" => {
              "type" => "object",
              "properties" => {
                "gem_name" => {
                  "type" => "string",
                  "description" => "Name of the gem"
                },
                "path" => {
                  "type" => "string",
                  "description" => 'Optional: specific class or module path (e.g., "FactoryBot::Trait" or "ActiveRecord::Base")'
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
          current_dir = Dir.pwd
          yard_dir = OpenGemdocs::Yard.yard_server_directory

          if yard_dir && yard_dir != current_dir
            # Yard is running in a different directory
            {
              "content" => [{
                "type" => "text",
                "text" => "Yard server is running in a different directory:\n" \
                          "Running in: #{yard_dir}\n" \
                          "Current dir: #{current_dir}\n\n" \
                          "The server is serving gems from '#{yard_dir}'.\n" \
                          "To serve gems from the current directory, stop the server first with 'stop_yard_server' tool."
              }]
            }
          else
            {
              "content" => [{
                "type" => "text",
                "text" => "Yard server is already running on port 8808"
              }]
            }
          end
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
          yard_dir = OpenGemdocs::Yard.yard_server_directory
          current_dir = Dir.pwd

          status = "Yard server is running (PID: #{pids.join(", ")}) on port 8808"
          status += "\nServing from: #{yard_dir}" if yard_dir

          if yard_dir && yard_dir != current_dir
            status += "\nCurrent directory: #{current_dir}"
            status += "\n\nNote: The server is serving gems from a different directory."
          end

          {
            "content" => [{
              "type" => "text",
              "text" => status
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
        
        path_hint = class_name || "the gem overview"

        {
          "content" => [{
            "type" => "text",
            "text" => "Documentation URL: #{url}\n\n" \
                     "**Tip:** Instead of fetching this URL directly, use the `fetch_gem_docs` tool with:\n" \
                     "- gem_name: \"#{gem_name}\"\n" \
                     "- path: \"#{class_name}\" (if you want specific class documentation)\n\n" \
                     "This will give you structured documentation for #{path_hint}."
          }]
        }
      end

      def fetch_gem_docs(gem_name, path = nil)
        # Use the YardJsonFormatter to get structured documentation
        result = OpenGemdocs::YardJsonFormatter.format_gem_docs(gem_name, path)

        if result[:error]
          {
            "content" => [{
              "type" => "text",
              "text" => result[:error]
            }],
            "isError" => true
          }
        else
          # Format the JSON result into readable text
          formatted_text = format_json_docs(result, gem_name, path)

          {
            "content" => [{
              "type" => "text",
              "text" => formatted_text
            }]
          }
        end
      end

      def format_json_docs(data, gem_name, path)
        lines = []

        if path
          # Specific object documentation
          obj = data
          lines << "# #{obj[:path]}"
          lines << ""
          lines << "**Type:** #{obj[:type]}"
          lines << "**Namespace:** #{obj[:namespace]}" if obj[:namespace]
          lines << ""

          if obj[:docstring]
            lines << "## Description"
            lines << obj[:docstring]
            lines << ""
          end

          if obj[:superclass]
            lines << "**Inherits from:** #{obj[:superclass]}"
            lines << ""
          end

          if obj[:includes] && obj[:includes].any?
            lines << "**Includes:** #{obj[:includes].join(", ")}"
            lines << ""
          end

          if obj[:parameters] && obj[:parameters].any?
            lines << "## Parameters"
            obj[:parameters].each do |param|
              default = param[:default] ? " = #{param[:default]}" : ""
              lines << "- `#{param[:name]}#{default}`"
            end
            lines << ""
          end

          if obj[:methods] && obj[:methods].any?
            lines << "## Methods"

            # Group methods by visibility
            %w[public protected private].each do |visibility|
              visible_methods = obj[:methods].select { |m| m[:visibility] == visibility }
              next if visible_methods.empty?

              lines << ""
              lines << "### #{visibility.capitalize} Methods"
              visible_methods.each do |method|
                return_info = method[:return_type] ? " → #{method[:return_type].join(", ")}" : ""
                lines << "- `#{method[:signature]}`#{return_info}"
                lines << "  #{method[:docstring]}" if method[:docstring]
              end
            end
            lines << ""
          end

          if obj[:attributes] && obj[:attributes].any?
            lines << "## Attributes"
            obj[:attributes].each do |attr|
              access = []
              access << "read" if attr[:read]
              access << "write" if attr[:write]
              lines << "- `#{attr[:name]}` (#{access.join("/")})"
              lines << "  #{attr[:docstring]}" if attr[:docstring] && !attr[:docstring].empty?
            end
            lines << ""
          end

          if obj[:tags] && obj[:tags].any?
            examples = obj[:tags].select { |t| t[:tag_name] == "example" }
            if examples.any?
              lines << "## Examples"
              examples.each do |example|
                lines << "```ruby"
                lines << example[:text]
                lines << "```"
              end
              lines << ""
            end
          end
        else
          # Gem overview documentation
          lines << "# #{gem_name}"

          if data[:summary]
            lines << ""
            lines << "**Version:** #{data[:summary][:version]}" if data[:summary][:version]
            lines << "**Homepage:** #{data[:summary][:homepage]}" if data[:summary][:homepage]
            lines << ""
            lines << data[:summary][:description] if data[:summary][:description]
            lines << ""
          end

          if data[:namespaces] && data[:namespaces].any?
            lines << "## Top-level Namespaces"
            data[:namespaces].each do |ns|
              lines << "- `#{ns[:path]}` (#{ns[:type]})"
            end
            lines << ""
          end

          if data[:classes] && data[:classes].any?
            lines << "## Classes"
            data[:classes].each do |cls|
              super_info = cls[:superclass] ? " < #{cls[:superclass]}" : ""
              lines << "- `#{cls[:path]}#{super_info}` (#{cls[:methods_count]} methods)"
              lines << "  #{cls[:docstring][0..100]}..." if cls[:docstring]
            end
            lines << ""
          end

          if data[:modules] && data[:modules].any?
            lines << "## Modules"
            data[:modules].each do |mod|
              lines << "- `#{mod[:path]}` (#{mod[:methods_count]} methods)"
              lines << "  #{mod[:docstring][0..100]}..." if mod[:docstring]
            end
            lines << ""
          end
        end

        lines.join("\n")
      end
    end
  end
end
