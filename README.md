# vanilli-ruby
Ruby bindings for use with [vanilli](https://github.com/mixradio/vanilli).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'vanilli-ruby'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install vanilli-ruby

## Usage
Two classes are provided `VanilliServer` and `VanilliClient`.

### VanilliClient
This class provides a client API for interacting with a running vanilli server. The API has
deliberately been kept as close as possible to the canonical javascript API with a few "rubifications"
(snake case on method names for example). However, the API is close enough that providing extra
documentation here is counter-productive - please see the [javascript documentation](https://github.com/mixradio/vanilli/wiki/API).

Instantiating the client is straightforward:

```ruby
require 'vanilli/client'

vanilli = VanilliClient.new()

vanilli.stub(...)
#etc.
```

### VanilliServer
Of course, to be able to make use of the client one needs a vanilli server running to connect to. This
can be achieved in a number of ways:

* Start vanilli via its CLI
```sh
npm install -g vanilli
vanilli --port 9000
```

* Start vanilli from javascript
i.e. use the javascript API perhaps from some grunt/gulp/npm based task.

* Use VanilliServer provided with this ruby gem
This just acts as a wrapper around the vanilli CLI. Therefore you *MUST* have vanilli installed to your
path for this to work. Once installed, start something like this:

```ruby
vanilli_server = VanilliServer.new(port: 9000,
                                  log_level: "debug",
                                  static_root: "/your/web/app/assets",
                                  static_include: ['**/*.html', '**/*.js', '**/*.css*', '/robots.txt'])
                .start
```
