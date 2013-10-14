require 'test_helper'

class InstanceHooksTest < MiniTest::Spec
  class TestClass
    include Hooks

    def executed
      @executed ||= [];
    end
  end



end
