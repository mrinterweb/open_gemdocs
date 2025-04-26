# OpenGemdocs

This is a simple command line tool that helps open gem documentation on https://gemdocs.org.

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

For terminal use:

```bash
open_gemdocs --help
```

To see the available options.

If you pass in the name of a gem from a directory that contains a Gemfile.lock file, it will determine what version of the gem you are using when it opens the online documentation.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mrinterweb/open_gemdocs.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
