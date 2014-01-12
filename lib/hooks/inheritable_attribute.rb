module Hooks
  module InheritableAttribute
    # Creates an inheritable attribute with accessors in the singleton class. Derived classes inherit the
    # attributes. This is especially helpful with arrays or hashes that are extended in the inheritance
    # chain. Note that you have to initialize the inheritable attribute.
    #
    # Example:
    #
    #   class Cat
    #     inheritable_attr :drinks
    #     self.drinks = ["Becks"]
    #
    #   class Garfield < Cat
    #     self.drinks << "Fireman's 4"
    #
    # and then, later
    #
    #   Cat.drinks      #=> ["Becks"]
    #   Garfield.drinks #=> ["Becks", "Fireman's 4"]
    def inheritable_attr(name)
      instance_eval %Q{
        def #{name}=(v)
          @#{name} = v
        end

        def #{name}
          @#{name} ||= InheritableAttribute.inherit_for(self, :#{name})
        end
      }
    end

    def self.inherit_for(klass, name)
      return unless klass.superclass.respond_to?(name) and value = klass.superclass.send(name)
      value.clone # only do this once.
    end
  end
end
