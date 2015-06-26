require 'test_helper'

class HookTest < MiniTest::Spec
  subject { Hooks::Hook.new({}) }

  it "exposes array behaviour for callbacks" do
    subject << :play_music
    subject << :drink_beer

    subject.to_a.map(&:to_sym).must_equal [:play_music, :drink_beer]
  end

  it "evals the procs in the context of its argument" do
    subject << proc { self }
    obj = Object.new
    subject.run(obj).must_equal [obj]
  end

  describe "the scope option" do
   it "passes the callback and the scope as arguments and evaluates on the returned scope" do
      obj = Object.new
      hook = Hooks::Hook.new(scope: lambda { |callback, scope| [[callback], [scope]] })
      hook << :flatten
      hook.run(obj = Object.new).must_equal [[hook.last, obj]]
    end
    it "uses a plain object as a static scope" do
      scope = Object.new
      hook = Hooks::Hook.new(scope: scope)
      hook << lambda { self }
      hook.run(Object.new).must_equal [scope]
    end
    it "evaluates procs in their definition context if nil is returned" do
      hook = Hooks::Hook.new(scope: lambda { |callback, scope| scope if !callback.proc? })
      hook << lambda { self }
      hook.run(Object.new).must_equal [self]
    end
  end
end

class ResultsTest < MiniTest::Spec
  subject { Hooks::Hook::Results.new }

  describe "#halted?" do
    it "defaults to false" do
      subject.halted?.must_equal false
    end

    it "responds to #halted!" do
      subject.halted!
      subject.halted?.must_equal true
    end

    it "responds to #not_halted?" do
      subject.not_halted?.must_equal true
    end
  end
end
