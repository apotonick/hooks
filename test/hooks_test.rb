require 'test_helper'

class HooksTest < MiniTest::Spec
  class TestClass
    include Hooks

    def executed
      @executed ||= [];
    end
  end


  describe "Hooks.define_hook" do
    let(:klass) do
      Class.new(TestClass) do
        define_hook :after_eight
      end
    end

    subject { klass.new }

    it "provide accessors to the stored callbacks" do
      assert_equal [], klass._after_eight_callbacks
      klass._after_eight_callbacks << :dine
      assert_equal [:dine], klass._after_eight_callbacks
    end

    it "respond to Class.callbacks_for_hook" do
      assert_equal [], klass.callbacks_for_hook(:after_eight)
      klass.after_eight :dine
      assert_equal [:dine], klass.callbacks_for_hook(:after_eight)
    end

    it "accept multiple hook names" do
      subject.class.define_hooks :before_ten, :after_ten
      assert_equal [], klass.callbacks_for_hook(:before_ten)
      assert_equal [], klass.callbacks_for_hook(:after_ten)
    end

    describe "creates a public writer for the hook that" do
      it "accepts method names" do
        klass.after_eight :dine
        assert_equal [:dine], klass._after_eight_callbacks
      end

      it "accepts blocks" do
        klass.after_eight do true; end
        assert klass._after_eight_callbacks.first.kind_of? Proc
      end

      it "be inherited" do
        klass.after_eight :dine
        subklass = Class.new(klass)

        assert_equal [:dine], subklass._after_eight_callbacks
      end
    end

    describe "Hooks#run_hook" do
      it "run without parameters" do
        subject.instance_eval do
          def a; executed << :a; nil; end
          def b; executed << :b; end

          self.class.after_eight :b
          self.class.after_eight :a
        end

        subject.run_hook(:after_eight)

        assert_equal [:b, :a], subject.executed
      end

      it "accept arbitrary parameters" do
        subject.instance_eval do
          def a(me, arg); executed << arg+1; end
        end
        subject.class.after_eight :a
        subject.class.after_eight lambda { |me, arg| me.executed << arg-1 }

        subject.run_hook(:after_eight, subject, 1)

        assert_equal [2, 0], subject.executed
      end

      it "execute block callbacks in instance context" do
        subject.class.after_eight { executed << :c }
        subject.run_hook(:after_eight)
        assert_equal [:c], subject.executed
      end

      it "returns all callbacks in order" do
        subject.class.after_eight { :dinner_out }
        subject.class.after_eight { :party_hard }
        subject.class.after_eight { :taxi_home }

        results = subject.run_hook(:after_eight)

        assert_equal [:dinner_out, :party_hard, :taxi_home], results.chain
        assert_equal false, results.halted?
        assert_equal true, results.not_halted?
      end

      describe "halts_on_falsey: true" do
        let(:klass) do
          Class.new(TestClass) do
            define_hook :after_eight, :halts_on_falsey => true
          end
        end

        [nil, false].each do |falsey|
          it "returns successful callbacks in order (with #{falsey.inspect})" do
            ordered = []

            subject.class.after_eight { :dinner_out }
            subject.class.after_eight { :party_hard; falsey }
            subject.class.after_eight { :taxi_home }

            results = subject.run_hook(:after_eight)

            assert_equal [:dinner_out], results.chain
            assert_equal true, results.halted?
          end
        end
      end

      describe "halts_on_falsey: false" do
        [nil, false].each do |falsey|
          it "returns all callbacks in order (with #{falsey.inspect})" do
            ordered = []

            subject.class.after_eight { :dinner_out }
            subject.class.after_eight { :party_hard; falsey }
            subject.class.after_eight { :taxi_home }

            results = subject.run_hook(:after_eight)

            assert_equal [:dinner_out, falsey, :taxi_home], results.chain
            assert_equal false, results.halted?
          end
        end
      end
    end

    describe "in class context" do
      it "run a callback block" do
        executed = []
        klass.after_eight do
          executed << :klass
        end
        klass.run_hook(:after_eight)

        assert_equal [:klass], executed
      end

      it "run a class methods" do
        executed = []
        klass.instance_eval do
          after_eight :have_dinner

          def have_dinner(executed)
            executed << :have_dinner
          end
        end
        klass.run_hook(:after_eight, executed)

        assert_equal [:have_dinner], executed
      end
    end
  end

  describe "Inheritance" do
    let (:klass) {
      Class.new(TestClass) do
        define_hook :after_eight

        after_eight :take_shower

        def take_shower
          executed << :take_shower
        end
      end
    }

    it "inherits the hook" do
      Class.new(klass) do
        after_eight :have_dinner

        def have_dinner
          executed << :have_dinner
        end
      end.new.class.callbacks_for_hook(:after_eight).must_equal [:take_shower, :have_dinner]
    end
  end
end
