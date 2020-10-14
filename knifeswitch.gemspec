$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "knifeswitch/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name          = "knifeswitch"
  spec.version       = Knifeswitch::VERSION
  spec.authors       = ["Nigel Baillie"]
  spec.email         = ["nbaillie@degica.com"]

  spec.summary       = %q{Simple implementation of the circuit breaker pattern.}
  spec.description   = %q{Implements the circuit breaker pattern using MySQL as a datastore.
https://martinfowler.com/bliki/CircuitBreaker.html}
  spec.homepage      = "https://github.com/degica/knifeswitch"
  spec.license       = "MIT"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", ">= 5.2", "< 6.1"

  spec.add_development_dependency "mysql2"
end
