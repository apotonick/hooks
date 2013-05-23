module Hooks
  class Hook
    def initialize(scope, callbacks, options, *args)
      @scope     = scope
      @callbacks = callbacks
      @options   = options || {}
      @args      = args
    end

    # The chain contains the return values of the executed callbacks.
    #
    # Example:
    #
    #   class Person
    #     define_hook :before_eating
    #
    #     before_eating :wash_hands
    #     before_eating :locate_food
    #     before_eating :sit_down
    #
    #     def wash_hands; :washed_hands; end
    #     def locate_food; :located_food; false; end
    #     def sit_down; :sat_down; end
    #   end
    #
    #   result = person.run_hook(:before_eating)
    #   result.chain #=> [:washed_hands, false, :sat_down]
    #
    # If <tt>:halts_on_falsey</tt> is enabled:
    #
    #   class Person
    #     define_hook :before_eating, :halts_on_falsey => true
    #     # ...
    #   end
    #
    #   result = person.run_hook(:before_eating)
    #   result.chain #=> [:washed_hands]
    def chain
      entries = []

      @callbacks.take_while do |callback|
        executed = execute_callback(@scope, callback, *@args)
        continue_execution?(@options, executed) && entries << executed
      end

      entries
    end

    # Returns true or false based on whether all callbacks
    # in the chain are successfully executed
    def halted?
      chain.count != @callbacks.count
    end

    def not_halted?
      !halted?
    end

    private

    def execute_callback(scope, callback, *args)
      if callback.kind_of?(Symbol)
        scope.send(callback, *args)
      else
        scope.instance_exec(*args, &callback)
      end
    end

    def continue_execution?(options, execution_result)
      options[:halts_on_falsey] ? execution_result : true
    end
  end
end
