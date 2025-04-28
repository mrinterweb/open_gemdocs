# OpenGemdocs

This is a simple command line tool that helps open gem documentation. There are two documentation sources this gem supports.

1. local gems served with the yard gem via `yarn server --gems` or `yarn server --gemfile` accessible at http://localhost:8808.
2. [https://gemdocs.org](https://gemdocs.org) - a good ruby gem documentation host

* If ran from a directory with a Gemfile.lock, it will open the documentation for the version specified in Gemfile.lock. When using the online source, you can specify `--latest` or `--version` options.
* Defaults to open the latest version of the documentation if not `--local` or a `Gemfile.lock` is not found in the current directory.
* Can specify a version of the docs to view
* When ran with `--local`, it will either serve docs for all gems you have installed or the versions specified in your Gemfile.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add open_gemdocs
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install open_gemdocs
```

## Usage

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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mrinterweb/open_gemdocs.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
