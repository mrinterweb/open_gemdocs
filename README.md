# OpenGemdocs

This gem makes accessing ruby gem documentation easy for users with a CLI tool and AI agents with a MCP server.

There are two documentation sources this gem supports.

1. local gems served with the yard gem via `yard server --gems` or `yard server --gemfile` accessible at http://localhost:8808.
2. [https://gemdocs.org](https://gemdocs.org) - a good ruby gem documentation host

* If ran from a directory with a Gemfile.lock, it will open the documentation for the version specified in Gemfile.lock. When using the online source, you can specify `--latest` or `--version` options.
* Defaults to open the latest version of the documentation if not `--local` or a `Gemfile.lock` is not found in the current directory.
* Can specify a version of the docs to view
* When ran with `--local`, it will either serve docs for all gems you have installed or the versions specified in your Gemfile.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add open_gemdocs --group development
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install open_gemdocs
```

## CLI Usage

Currently, this only works on Macs because of the `open` command. It opens the documentation for a gem in your default web browser.

To see the available options.
```bash
open-gem-docs --help
```

### Example usage
If you are in a directory with a Gemfile.lock, it will open the documentation for the version of the gem you are using unless you specify `--latest` or `--version` options.

If you are not in a directory with a Gemfile.lock, it will open the latest version of the documentation.
```bash
open-gem-docs rspec
```
(Assuming you are in a directory with a Gemfile.lock, it will open the rspec docs for the version you are using.)

Open a specific version (regardless of what is in your Gemfile.lock)
```bash
open-gem-docs -v 3.12.0 rspec
```

Open the latest version of the documentation
```bash
open-gem-docs --latest rspec
```

To use a local documentation server. Run the following command from a directory where Gemfile.lock exists. This will serves the documentation for your currently installed gems.
```bash
open-gem-docs --local
```

You can also jump directly to a local doc gem page:
```bash
open-gem-docs --local rspec
```

If you prefer the `--local` option to be the default, you can use the `open-local-docs` command instead of `open-gem-docs`.
Example using the `open-local-docs` command:

```bash
open-local-docs rspec
```

## Process Gem documentation sources

Pre-processing the gem docs makes lookups faster.

Change directory to a repository with a `Gemfile.lock` and run the following command:

```
document-bundle
```

## MCP Server

The gem includes an MCP (Model Context Protocol) server that allows AI assistants to programmatically access Ruby gem documentation. The MCP server manages a local Yard documentation server and provides tools for searching and retrieving gem documentation.

### Starting the MCP Server

```bash
open-gem-docs-mcp
```

By default, the server runs on port 6789. You can specify a different port:

```bash
open-gem-docs-mcp --port 8080
```

### Available MCP Tools

The MCP server provides the following tools:

- **search_gems** - Search for installed Ruby gems by name
- **get_gem_info** - Get detailed information about a specific gem
- **start_yard_server** - Start the Yard documentation server
- **stop_yard_server** - Stop the Yard documentation server
- **get_yard_server_status** - Check if the Yard server is running
- **get_gem_documentation_url** - Get the local documentation URL for a gem
- **fetch_gem_docs** - Fetch documentation content from the Yard server

### Using with Claude Code

```
claude mcp add open-gem-docs -- open-gem-docs-mcp-stdio
```

### Using with Claude Desktop

To use the MCP server with Claude Desktop, add the following to your Claude Desktop configuration:

```json
{
  "mcpServers": {
    "open_gemdocs": {
      "command": "open-gem-docs-mcp",
      "args": ["--port", "6789"]
    }
  }
}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mrinterweb/open_gemdocs.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
