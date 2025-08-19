# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Open_gemdocs is a Ruby gem that provides a command-line tool for opening Ruby gem documentation. It supports both local documentation (via Yard server) and online documentation (via gemdocs.org).

## Common Commands

### Development Setup
```bash
# Install dependencies
bundle install

# Setup development environment
bin/setup

# Open IRB console with gem loaded
bin/console
```

### Testing
```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/open_gemdocs_spec.rb

# Run tests via Rake
bundle exec rake spec
```

### Linting & Code Quality
```bash
# Run RuboCop for code linting
bundle exec rubocop

# Auto-fix RuboCop violations
bundle exec rubocop -a

# Run all checks (tests + linting)
bundle exec rake
```

### Building & Installation
```bash
# Build the gem
gem build open_gemdocs.gemspec

# Install locally for testing
gem install ./open_gemdocs-*.gem

# Build via Rake
bundle exec rake build

# Release new version (requires gem push permissions)
bundle exec rake release
```

### Local Testing of CLI
```bash
# Test the main executable
bundle exec exe/open-gem-docs rails

# Test with local documentation
bundle exec exe/open-gem-docs --local rails

# Test the local-only wrapper
bundle exec exe/open-local-docs rails
```

## Architecture

The gem follows a simple, focused architecture with three main components:

### Core Module Structure
- **`lib/open_gemdocs.rb`**: Main module that orchestrates between Browser and Yard classes based on user options
- **`lib/open_gemdocs/browser.rb`**: Handles opening online documentation from gemdocs.org, includes Gemfile.lock parsing for version detection
- **`lib/open_gemdocs/yard.rb`**: Manages local Yard server lifecycle (starting, stopping, checking status) and opens local documentation

### Key Implementation Details

1. **Version Detection**: The Browser class automatically detects gem versions from Gemfile.lock when no version is specified
2. **Server Management**: The Yard class manages a background Yard server process, checking if it's running and starting it if needed
3. **Platform Dependency**: Uses macOS `open` command - platform-specific implementation would be needed for Linux/Windows support
4. **Error Handling**: Custom `OpenGemdocs::Error` class for consistent error reporting

### CLI Entry Points
- **`exe/open-gem-docs`**: Full-featured CLI with option parsing (--local, --version, etc.)
- **`exe/open-local-docs`**: Convenience wrapper that always uses local documentation

## Important Considerations

- The gem is signed with a certificate in `certs/mrinterweb.pem` - ensure this is present when building releases
- Requires Ruby >= 3.1.0
- The test suite needs expansion - currently only has placeholder tests
- When modifying CLI behavior, update both executables if needed
- The Yard server runs on port 8808 by default