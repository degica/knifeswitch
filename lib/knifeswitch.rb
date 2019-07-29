require 'knifeswitch/railtie'
require 'knifeswitch/circuit'

module Knifeswitch
  class Error < StandardError; end
  class CircuitOpen < Error; end
end
