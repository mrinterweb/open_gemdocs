# frozen_string_literal: true

module OpenGemdocs
  module Yard
    extend self

    SERVER_COMMAND = 'yard server --daemon'

    def browse_gem(gem_name)
      if server_running?
        puts "Yard server is already running. Opening browser..."
        system("open http://localhost:8808/docs/#{gem_name}")
      else
        puts "Starting Yard server in the background..."
        start_yard_server
        sleep 2 # Give the server some time to start
        system("open http://localhost:8808/docs/#{gem_name}")
      end
      puts "  When you're done, remember to stop the server with `open-gem-docs --stop`"
    end

    def start_yard_server
      if File.exist?('Gemfile.lock')
        `#{SERVER_COMMAND} --gemfile`
      else
        `#{SERVER_COMMAND} --gems`
      end
    end

    def server_running? = find_yard_pids.any?

    def find_yard_pids
      # Find pids bound to port 8808
      `lsof -i TCP:8808 | grep -E "^ruby.*:8808"`.strip.split("\n").map { |line| line.split(/\s+/)[1] }
    end

    def stop_server
      yard_pids = find_yard_pids
      if yard_pids.any?
        puts "Stopping Yard server processes: #{yard_pids.join(', ')}"
        `kill #{yard_pids.join(' ')}`
        puts "Yard server processes stopped."
      else
        puts "No Yard server processes found to stop"
      end
    end
  end
end
