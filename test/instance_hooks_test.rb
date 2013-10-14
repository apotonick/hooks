require 'test_helper'
require 'instance_hooks'

class InstanceHooksTest < MiniTest::Spec
  class TestClass
    include InstanceHooks

    define_hook :after_eight
    define_hooks :before_one, 'after_one', :before_ten, :after_ten

    def executed
      @executed ||= [];
    end
  end

    describe "InstanceHooks.define_hook" do
      let(:klass) do
        TestClass
      end

      subject { klass.new }

      it "keeps definition names" do
        assert_equal(
          {:after_ten=>{}, :after_eight=>{}, :before_one=>{}, :after_one=>{}, :before_ten=>{}},
          klass._hook_names
        )
      end

      it "accept multiple hook names, symbolizes strings when defining a hook" do
        assert_equal [], subject.callbacks_for_hook(:before_one)
        assert_equal [], subject.callbacks_for_hook(:after_one)
        assert_equal [], subject.callbacks_for_hook('after_one')
        assert_equal [], subject.callbacks_for_hook(:before_ten)
        assert_equal [], subject.callbacks_for_hook(:after_ten)
      end

      describe "creates a public writer for the hook that" do
        it "accepts method names" do
          subject.after_eight :dine
          assert_equal [:dine], subject._hooks[:after_eight]
        end

        it "accepts blocks" do
          subject.after_eight do true; end
          assert subject._hooks[:after_eight].first.kind_of? Proc
        end

      end

      describe "Hooks#run_hook" do
        it "run without parameters" do
          subject.instance_eval do
            def a; executed << :a; nil; end
            def b; executed << :b; end

          end
          subject.after_eight :b
          subject.after_eight :a

          subject.run_hook(:after_eight)

          assert_equal [:b, :a], subject.executed
        end

        it "returns empty Results when no callbacks defined" do
          subject.run_hook(:after_eight).must_equal Hooks::Hook::Results.new
        end

        it "accept arbitrary parameters" do
          subject.instance_eval do
            def a(me, arg); executed << arg+1; end
          end
          subject.after_eight :a
          subject.after_eight lambda { |me, arg| me.executed << arg-1 }

          subject.run_hook(:after_eight, subject, 1)

          assert_equal [2, 0], subject.executed
        end

        it "returns all callbacks in order" do
          subject.after_eight { :dinner_out }
          subject.after_eight { :party_hard }
          subject.after_eight { :taxi_home }

          results = subject.run_hook(:after_eight)

          assert_equal [:dinner_out, :party_hard, :taxi_home], results
          assert_equal false, results.halted?
          assert_equal true, results.not_halted?
        end

      end
    end

end
