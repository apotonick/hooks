require 'minitest/autorun'
require 'hooks'

Uber::Options::Value.class_eval do
  def to_sym
    @value
  end
end