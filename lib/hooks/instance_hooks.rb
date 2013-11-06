module Hooks
  module InstanceHooks
    include ClassMethods

    def _hooks
      @_hooks ||= self.class._hooks.clone # TODO: generify that with representable_attrs.
    end

    def run_hook(name, *args)
      run_hook_for(name, self, *args)
    end
  end
end