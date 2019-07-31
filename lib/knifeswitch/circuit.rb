module Knifeswitch
  # Implements the "circuit breaker" pattern using a simple MySQL table.
  #
  # Example usage:
  #
  #   circuit = Knifeswitch::Circuit.new(
  #     namespace:       'some third-party',
  #     exceptions:      [Example::TimeoutError],
  #     error_threshold: 5,
  #     error_timeout:   30
  #   )
  #   response = circuit.run { client.request(...) }
  #
  # In this example, when a TimeoutError is raised within a circuit.run
  # block 5 times in a row, the circuit will "open" and further calls to
  # circuit.run will raise Knifeswitch::CircuitOpen instead of executing the
  # block. After 30 seconds, the circuit "closes" and circuit.run blocks
  # will be run again.
  #
  # Two circuits with the same namespace share the same counter and
  # open/closed state, as long as they're connected to the same database.
  #
  class Circuit
    attr_reader :namespace, :exceptions, :error_threshold, :error_timeout
    attr_accessor :callback

    # Options:
    #
    # namespace:       circuits in the same namespace share state
    # exceptions:      an array of error types that bump the counter
    # error_threshold: number of errors required to open the circuit
    # error_timeout:   seconds to keep the circuit open
    def initialize(
      namespace: 'default',
      exceptions: [Timeout::Error],
      error_threshold: 10,
      error_timeout: 60,
      callback: nil
    )
      @namespace       = namespace
      @exceptions      = exceptions
      @error_threshold = error_threshold
      @error_timeout   = error_timeout
      @callback        = callback
    end

    # Call this with a block to execute the contents of the block under
    # circuit breaker protection.
    #
    # Raises Knifeswitch::CircuitOpen when called while the circuit is open.
    def run
      if open?
        callback.try(:call, CircuitOpen.new)
        raise CircuitOpen
      end

      result = yield
      reset_counter!
      result
    rescue Exception => error
      if exceptions.any? { |watched| error.is_a?(watched) }
        increment_counter!
        callback.try(:call, error)
      else
        reset_counter!
      end

      raise error
    end

    # Queries the database to see if the circuit is open.
    #
    # The circuit opens when 'error_threshold' errors occur consecutively.
    # When the circuit is open, calls to `run` will raise CircuitOpen
    # instead of yielding.
    def open?
      result = sql(:select_value, %(
        SELECT COUNT(*) c FROM knifeswitch_counters
        WHERE name = ? AND closetime > ?
      ), namespace, DateTime.now)

      result > 0
    end

    # Retrieves the current counter value.
    def counter
      result = sql(:select_value, %(
        SELECT counter FROM knifeswitch_counters
        WHERE name = ?
      ), namespace)

      result || 0
    end

    # Increments counter and opens the circuit if it went
    # too high
    def increment_counter!
      # Increment the counter
      sql(:execute, %(
        INSERT INTO knifeswitch_counters (name,counter)
        VALUES (?, 1)
        ON DUPLICATE KEY UPDATE counter=counter+1
      ), namespace)

      # Possibly open the circuit
      sql(
        :execute,
        %(
          UPDATE knifeswitch_counters
          SET closetime = ?
          WHERE name = ? AND COUNTER >= ?
        ),
        DateTime.now + error_timeout.seconds,
        namespace, error_threshold
      )
    end

    # Sets the counter to zero
    def reset_counter!
      sql(:execute, %(
        INSERT INTO knifeswitch_counters (name,counter)
        VALUES (?, 0)
        ON DUPLICATE KEY UPDATE counter=0
      ), namespace)
    end

    private

    # Executes a SQL query with the given Connection method
    # (i.e. :execute, or :select_values)
    def sql(method, query, *args)
      query = ActiveRecord::Base.send(:sanitize_sql_array, [query] + args)

      ActiveRecord::Base.connection_pool.with_connection do |conn|
        conn.send(method, query)
      end
    end
  end
end
