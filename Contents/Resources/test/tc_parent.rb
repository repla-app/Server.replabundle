#!/usr/bin/env ruby

require 'minitest/autorun'
require_relative '../lib/parent.rb'
require_relative 'lib/parent_delegate'
require_relative 'lib/test_setup'

# Test parent
class TestParent < Minitest::Test
  TEST_OUTPUT_COUNT = 40
  def test_parent
    (1..2).each do |i|
      delegate = ParentDelegate.new
      restore = Repla::Test::Helper.add_env(TEST_ENV)
      parent = Repla::Server::Parent.new(PRINT_VARIABLE_PATH, delegate)
      test_output_count = TEST_OUTPUT_COUNT
      output_count = 0
      test_error_count = TEST_OUTPUT_COUNT
      error_count = 0
      (1..test_output_count).each do |_|
        delegate.add_process_output_block do |text|
          text.chomp!
          assert_equal(TEST_ENV_VALUE, text)
          output_count += 1
        end
        next unless i == 1

        delegate.add_process_output_block do |text|
          text.chomp!
          assert_equal(TEST_ENV_VALUE_TWO, text)
          error_count += 1
        end
      end
      if i == 2
        (1..test_error_count).each do |_|
          delegate.add_process_error_block do |text|
            text.chomp!
            assert_equal(TEST_ENV_VALUE_TWO, text)
            error_count += 1
          end
        end
      end
      if i == 1
        parent.run
      else
        parent.run_open3
      end
      Repla::Test.block_until do
        output_count == test_output_count && error_count == test_error_count
      end
      assert_equal(test_output_count, output_count)
      assert_equal(test_error_count, error_count)
      Repla::Test::Helper.remove_env(TEST_ENV, restore)
    end
  end

  def test_parent_real_env
    (1..2).each do |i|
      delegate = ParentDelegate.new
      argument_output = 'the first line'
      command = "#{PRINT_VARIABLE_NO_ERROR_PATH} #{argument_output}"
      restore = Repla::Test::Helper.add_env(TEST_REAL_ENV)
      parent = Repla::Server::Parent.new(command, delegate)
      test_output_count = TEST_OUTPUT_COUNT
      argument_output_success = false
      delegate.add_process_output_block do |text|
        text.chomp!
        assert_equal(argument_output, text)
        argument_output_success = true
      end

      output_count = 0
      (1..test_output_count).each do |_|
        delegate.add_process_output_block do |text|
          text.chomp!
          assert_equal(TEST_REAL_VALUE, text)
          output_count += 1
        end
      end
      error_called = false
      delegate.add_process_error_block do |_text|
        error_called = true
      end
      if i == 1
        parent.run
      else
        parent.run_open3
      end
      Repla::Test.block_until do
        output_count == test_output_count && argument_output_success
      end
      refute(error_called)
      assert_equal(test_output_count, output_count)
      Repla::Test::Helper.remove_env(TEST_REAL_ENV, restore)
    end
  end

  def test_escape_file
    with_escape = File.read(TEST_ESCAPE_FILE)
    result = Repla::Server::Parent.remove_escape(with_escape)
    without_escape = `sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" < #{TEST_ESCAPE_FILE}`
    assert_equal(without_escape, result)
  end

  def test_escape_file2
    with_escape = File.read(TEST_ESCAPE_FILE2)
    result = Repla::Server::Parent.remove_escape(with_escape)
    without_escape = `sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" < #{TEST_ESCAPE_FILE2}`
    assert_equal(without_escape, result)
  end

  def test_escape_file3
    with_escape = File.read(TEST_ESCAPE_FILE3)
    result = Repla::Server::Parent.remove_escape(with_escape)
    without_escape = `sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" < #{TEST_ESCAPE_FILE3}`
    assert_equal(without_escape, result)
  end

  def test_escape_file4
    with_escape = File.read(TEST_ESCAPE_FILE4)
    result = Repla::Server::Parent.remove_escape(with_escape)
    without_esc = `sed "s,\x1B\[\??[0-9;]*[a-zA-Z],,g" < #{TEST_ESCAPE_FILE4}`
    assert_equal(without_esc, result)
  end

  def test_escape1
    with_escape = "\e[2J\e[3J\e[H\e[32mCompiled successfully!\e[39m"
    result = Repla::Server::Parent.remove_escape(with_escape)
    without_escape = 'Compiled successfully!'
    assert_equal(without_escape, result)
  end

  def test_escape2
    with_escape = "\e[32m[I 18:52:18.709 NotebookApp]\e(B\e[m The Jupyter"
    result = Repla::Server::Parent.remove_escape(with_escape)
    without_escape = '[I 18:52:18.709 NotebookApp] The Jupyter'
    assert_equal(without_escape, result)
  end

  def test_escape3
    with_escape = "\e[0m\e[2K\e[1m0% compiling"
    result = Repla::Server::Parent.remove_escape(with_escape)
    without_escape = '0% compiling'
    assert_equal(without_escape, result)
  end

  def test_escape4
    with_escape = "\e[?25l\e[?25l\e[?25l\e[?25l⠋"\
    'open and validate gatsby-configs'
    result = Repla::Server::Parent.remove_escape(with_escape)
    without_escape = '⠋open and validate gatsby-configs'
    assert_equal(without_escape, result)
  end
end
