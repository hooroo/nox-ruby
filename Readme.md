# Nox-Ruby

For use with [Nox](http://github.com/hooroo/nox) and Ruby on Rails.

## Installation

Add to your Gemfile:

```ruby
gem 'nox', :github => "hooroo/nox-ruby"
```

Create an initializer:

```ruby
if Rails.env.development?
  require 'nox/net/http'
end
```

And finally, create a `nox.yml` file in your `/config` directory that configures how your application will interact with Nox.

```yml
shared: &SHARED
  ignore:
    -
      host: "204.93.223.138" # New relic
    -
      host: "airbrake.io" # Airbrake
    -
      host: "googleapis.com"
    -
      host: "maps.googleapis.com"

development:
  <<: *SHARED
  host: localhost
  port: 7654
```

## Development

Clone down the repo, and start hacking. There are no tests.
