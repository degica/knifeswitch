# Knifeswitch
Yet another circuit breaker gem. This one strives to be as small and simple as possible. It uses MySQL (through ActiveRecord) for distributed state.

## Usage
```ruby
# Instantiate circuit
circuit = Knifeswitch::Circuit.new(
  namespace:       'whatever',
  exceptions:      [TimeoutExceptionToCatch, Timeout::Error],
  error_threshold: 5,
  error_timeout:   60
)

response = circuit.run { client.request(...) }
# 'run' will raise Knifeswitch::CircuitOpen if its error_threshold has
# been exceeded. That is: when a timeout has occurred 5 times in a row.
#
# After the circuit opens, it will close back down after 60 seconds of
# rejecting requests (by raising Knifeswitch::CircuitOpen).
#
# When closed, it will just run the block like normal and return the result.
```

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'knifeswitch'
```

And then execute:
```bash
$ bundle
```

Finally, generate migrations:
```bash
$ rake knifeswitch:create_migrations
```

## Testing

### Have Docker installed?
``` bash
$ bin/dockertest
```

### Manually, without docker
You'll need to set up the test Rails app's database. Edit `test/dummy/config/database.yml` as you see fit, and run:

```bash
$ rake knifeswitch:create_migrations db:create db:migrate
```
inside of the `test/dummy` directory.

After that you can run:
```bash
$ bin/test
```
in the project root with no problem. If you end up changing the migration generation rake task, you'll have to clean up and re-run it manually.

## Limitations

To keep the gem simple, Knifeswitch depends on [Rails](https://github.com/rails/rails). Technically, it should be pretty simple to make Knifeswitch work without the Rails dependency, but for us since we use Rails it's easier to just keep it as is.

Knifeswitch also softly depends on MySQL, in that it uses MySQL's `ON DUPLICATE KEY UPDATE` syntax.
