# frozen_string_literal: true

module OpenGemdocs
  class Browser
    attr_reader :gem_name, :version, :use_latest

    def initialize(gem_name:, version: nil, use_latest: false)
      @gem_name = gem_name
      raise ArgumentError, "Gem name is required" if gem_name.nil? || gem_name.empty?

      @version = version
      @use_latest = use_latest
    end

    def resolve_version
      return version if version

      if !use_latest && File.exist?("Gemfile.lock")
        @version = check_bundle_version
        if @version
          puts "Using version from Gemfile.lock: #{version}"
          return version
        end
      end

      @use_latest = true

      puts "No version specified, using latest version"
    end

    def open_browser
      resolve_version
      raise Error, "No version URL found" unless version_url

      version_str = version ? "@v#{version}" : ""
      latest_str = use_latest ? " (latest)" : ""
      puts "Fetching gem documentation for #{gem_name}#{version_str}#{latest_str}..."
      # open is a macOS command to open a URL in the default browser
      raise Error, "Could not resolve URL" if version_url.nil?

      `open "#{version_url.sub("production.", "")}"`
    end

    def version_url
      if use_latest
        version_data.last["url"]
      else
        version_data.detect { |row| row["version"] == version }&.fetch("url")
      end
    end

    def check_bundle_version
      `bundle show #{gem_name}`.strip.match(/#{gem_name}-([0-9.]+).*$/)&.[](1)
    end

    def version_data
      @version_data ||= begin
        uri = URI("https://gemdocs.org/gems/#{ARGV[0]}/versions.json")
        res = Net::HTTP.get_response(uri)
        raise Error, "HTTP request failed to uri: #{uri} -- #{res.code} #{res.message}" unless res.is_a?(Net::HTTPSuccess)

        JSON.parse(res.body)["versions"]
      end
    end
  end
end
