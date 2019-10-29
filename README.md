# Knifeswitch

![knifeswitch](https://user-images.githubusercontent.com/2793160/67077729-c908dd80-f1ca-11e9-96c7-5b1c8b792254.jpg)

Yet another circuit breaker gem. This one strives to be as small and simple as possible. In the effort to remain simple, it currently only supports Rails with MySQL.

## Usage
```ruby
# Instantiate circuit
circuit = Knifeswitch::Circuit.new(
  namespace:       'whatever',
  exceptions:      [TimeoutExceptionToCatch, Timeout::Error],
  error_threshold: 5, # Open circuit after 5 consecutive errors
  error_timeout:   60 # Stay open for 60 seconds
)

response = circuit.run { client.request(...) }
# 'run' will raise Knifeswitch::CircuitOpen if its error_threshold has
# been exceeded: after a watched exception has been raised 5 times.
# 
# The error threshold counter is shared among all Knifeswitch::Circuit
# instances with the same namespace. The counters are stored in the db,
# so the state is fully distributed among all your workers/webservers.
#
# After the circuit opens, it will close back down after 60 seconds of
# rejecting requests (by raising Knifeswitch::CircuitOpen).
#
# When closed, it will just run the block like normal and return the result.
```

### Disabling

To "disable" knifeswitch globally, set the environment variable `KNIFESWITCH=OFF`.
This makes all calls to `Knifeswitch::Circuit#run` yield unconditionally.

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
$ cd test/dummy && rake knifeswitch:create_migrations db:create db:migrate
```

After that you can run:
```bash
$ bin/test
```
in the project root with no problem. If you end up changing the migration generation rake task, you'll have to manually remove the old migration from the dummy app.

## Limitations

To keep the gem simple, Knifeswitch depends on [Rails](https://github.com/rails/rails). Technically, it should be pretty simple to make Knifeswitch work without the Rails dependency, but for us since we use Rails it's easier to just keep it as is.

Knifeswitch softly depends on MySQL because it uses MySQL's `ON DUPLICATE KEY UPDATE` syntax.
