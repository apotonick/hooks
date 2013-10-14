module Hooks
  class HookSet < Hash
    def [](name)
      super(name.to_sym)
    end

    def []=(name, values)
      super(name.to_sym, values)
    end

    def clone
      super.tap do |cloned|
        each { |name, callbacks| cloned[name] = callbacks.clone }
      end
    end
  end
end
