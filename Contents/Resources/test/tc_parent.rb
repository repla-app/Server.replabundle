#!/usr/bin/env ruby

require 'minitest/autorun'
require_relative '../lib/parent.rb'
require_relative 'lib/parent_delegate'
require_relative 'lib/test_constants'

# Test parent
class TestParent < Minitest::Test
  def test_parent
    delegate = ParentDelegate.new
    parent = Repla::Parent.new(delegate)
    delegate.add_process_line_block do |text|
      puts "text = #{text}"
    end
    parent.run_command(PRINT_VARIABLE_PATH, TEST_ENV)
  end
end
