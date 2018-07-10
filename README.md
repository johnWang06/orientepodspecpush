# Orientepodspecpush

Tired of linting, checking, pushing your cocoapod spec? No more! Once you are satisified with your pod, simply increment and push the tag. No changes to .podspec required, the tooling will update this for you!

You can then publish your next version by running `orientepodspecpush --specRepo <reponame>`!

Thats it!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'orientepodspecpush'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install orientepodspecpush

## Usage

```sh
Options:
  -s, --specRepo=<s>     Name of the repo to push to. See pod repo list for available repos
  -w, --workspace=<s>    Path to cocoapod workspace
  -o, --sources=<s>      Comma delimited list of private repo sources to consider when linting private repo. Master is included by default so private repos can source master
  -p, --private          If set, assume the cocoapod is private and skip public checks
  -h, --help             Show this message
```

Note: The force flag is off by default. If set to true you will push with warnings.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/johnWang06/orientepodspecpush.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

