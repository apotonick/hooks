require "hooks/hook"
require "hooks/hook_set"

# Example:
#
#   class CatWidget < Apotomo::Widget
#     define_hooks :before_dinner, :after_dinner
#
# Now you can add callbacks to your hook in class instance.
#
#   cat.before_dinner :wash_paws
#   cat.after_dinner { puts "Ice cream!" }
#   cat.after_dinner :have_a_desert   # => refers to CatWidget#have_a_desert
#
# Running the callbacks happens on instances. It will run the block and #have_a_desert from above.
#
#   cat.run_hook :after_dinner
module InstanceHooks
  def self.included(base)
    base.class_eval do
      extend ClassMethods
    end
  end

  module ClassMethods
    def _hook_names
      @_hook_names ||= {}
    end

    def define_hooks(*names)
      options = extract_options!(names)

      names.each do |name|
        setup_hook(name, options)
      end
    end
    alias_method :define_hook, :define_hooks

  private
    def setup_hook(name, options)
      _hook_names[name.to_sym] = options
      define_hook_writer(name)
    end

    def define_hook_writer(name)
      class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
        def #{name}(method=nil, &block)
          self._hooks[:#{name}] << (block || method)
        end
      RUBY_EVAL
    end

    def extract_options!(args)
      args.last.is_a?(Hash) ? args.pop : {}
    end
  end

  def _hooks
    return @_hooks if @_hooks
    @_hooks = Hooks::HookSet.new
    self.class._hook_names.each{|name, options| @_hooks[name] = Hooks::Hook.new(options) }
    @_hooks
  end

  def callbacks_for_hook(name)
    _hooks[name]
  end

  # Runs the callbacks (method/block) for the specified hook +name+. Additional arguments will
  # be passed to the callback.
  #
  # Example:
  #
  #   cat.run_hook :after_dinner, "i want ice cream!"
  #
  # will invoke the callbacks like
  #
  #   desert("i want ice cream!")
  #   block.call("i want ice cream!")
  def run_hook(name, *args)
    raise "Unknown hook: #{name}" unless self.class._hook_names.keys.include?(name)
    _hooks[name].run(self, *args)
  end

end
