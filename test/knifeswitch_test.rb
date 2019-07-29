require 'test_helper'

class Knifeswitch::Test < ActiveSupport::TestCase
  class TestError < StandardError
  end
  class UnwatchedError < StandardError
  end

  def raise_error(circuit, error_type = TestError)
    assert_raise error_type, "Circuit should pass errors through" do
      circuit.run { raise error_type, "Should be raised" }
    end
  end

  simple_opts = {
    exceptions: [TestError],
    error_threshold: 1,
    error_timeout: 1
  }

  test 'Circuit opens and closes' do
    circuit = Knifeswitch::Circuit.new simple_opts

    assert !circuit.open?, "Circuit should start out closed"

    raise_error circuit

    assert circuit.open?, "Circuit should open up"
    sleep 0.1
    assert circuit.open?, "Circuit should remain open"
    sleep 0.9
    assert !circuit.open?, "Circuit should close after 1 second"
  end

  test 'Circuit ignores irrelevant errors' do
    circuit = Knifeswitch::Circuit.new simple_opts

    raise_error circuit, UnwatchedError

    assert !circuit.open?, "Circuit should not open up on unwatched error"
  end

  test "Circuits with different names don't collide" do
    circuit1 = Knifeswitch::Circuit.new simple_opts.merge(namespace: "c1")
    circuit2 = Knifeswitch::Circuit.new simple_opts.merge(namespace: "c2")

    raise_error circuit1

    assert circuit1.open?, "Circuit1 saw the error and should open up"
    assert !circuit2.open?, "Circuit2 did not see an error and should be closed"
  end

  test "Circuit does not execute body when open" do
    circuit = Knifeswitch::Circuit.new simple_opts

    raise_error circuit
    assert circuit.open?, "Circuit should be open after error"

    assert_raise Knifeswitch::CircuitOpen, "Should raise CircuitOpen when open" do
      circuit.run { raise TestError, "Should NOT be raised" }
    end
  end

  test "Circuit executes body when closed" do
    circuit = Knifeswitch::Circuit.new simple_opts

    test_val = "untouched"
    circuit.run { test_val = "touched" }
    assert_equal test_val, "touched", "Should be modified by run block"
  end

  test "Circuit resets counter when a block doesn't error out" do
    circuit = Knifeswitch::Circuit.new simple_opts.merge(error_threshold: 2)

    test_val = "untouched"

    # First error
    raise_error circuit

    circuit.run { test_val = "touched" }

    # Second error - shouldn't open the circuit since the last statement succeeded
    # and presumably reset the counter.
    raise_error circuit

    assert_equal test_val, "touched", "Should've modified test val"
    assert !circuit.open?, "Circuit should not open since counter was reset"
  end

  test "Circuit doesn't reset on close" do
    circuit = Knifeswitch::Circuit.new simple_opts.merge(error_threshold: 3)

    3.times { raise_error circuit }

    assert circuit.open?, "Circuit should open after 3 consecutive errors"
    sleep 1
    assert !circuit.open?, "Circuit should close after 1 second"

    raise_error circuit
    assert circuit.open?, "Circuit should open after an error when it just closed"
    sleep 1
  end

  test "Circuit counter advances from 0 to 1 on first error" do
    circuit = Knifeswitch::Circuit.new simple_opts.merge(error_threshold: 5)

    assert_equal circuit.counter, 0
    raise_error circuit
    assert_equal circuit.counter, 1
  end

  test "Circuit resets counter on unwatched error" do
    circuit = Knifeswitch::Circuit.new simple_opts.merge(error_threshold: 5)

    raise_error circuit
    assert_equal circuit.counter, 1

    raise_error circuit, UnwatchedError
    assert_equal circuit.counter, 0
  end
end
