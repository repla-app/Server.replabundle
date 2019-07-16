#!/System/Library/Frameworks/Ruby.framework/Versions/2.3/usr/bin/ruby

require 'minitest/autorun'
require_relative 'lib/test_setup'
require Repla::Test::LOG_HELPER_FILE
require_relative '../lib/parent_logger'
require_relative '../lib/parent'

# Test parent logger class
class TestParentLoggerClass < Minitest::Test
  def test_url_from_line
    good_url = 'http://www.example.com'
    line_with_good_url = "Here is a URL #{good_url}"
    url = Repla::Server::ParentLogger.url_from_line(line_with_good_url)
    assert_equal(good_url, url)

    local_url = 'http://127.0.0.1'
    line_with_local_url = "#{local_url} is a local URL"
    url = Repla::Server::ParentLogger.url_from_line(line_with_local_url)
    assert_equal(local_url, url)

    line_with_no_url = 'This line doesn\'t have any URLs'
    url = Repla::Server::ParentLogger.url_from_line(line_with_no_url)
    assert_nil(url)

    local_url_with_port = 'http://127.0.0.1:5000'
    line_with_local_url_with_port = "Here is a URL #{local_url_with_port}"
    url = Repla::Server::ParentLogger.url_from_line(
      line_with_local_url_with_port
    )
    assert_equal(local_url_with_port, url)

    real_example_url = 'http://127.0.0.1:4000/'
    line_with_real_example_url = "Server address: #{real_example_url}"
    url = Repla::Server::ParentLogger.url_from_line(line_with_real_example_url)
    assert_equal(real_example_url, url)

    real_example_url_two = 'http://localhost:8888/?token=dd9490c690046'
    line_with_real_example_url_two = "Server address: #{real_example_url_two}"
    url = Repla::Server::ParentLogger.url_from_line(
      line_with_real_example_url_two
    )
    assert_equal(real_example_url_two, url)

    rails_token = 'tcp://localhost:3000'
    rails_url = 'http://localhost:3000'
    line_with_rails_token = "Server address: #{rails_token}"
    url = Repla::Server::ParentLogger.url_from_line(line_with_rails_token)
    assert_equal(rails_url, url)
  end

  def test_port_url_from_line
    port_token = 'Port 3131'
    port_url = 'http://localhost:3131'
    line_with_port_token = "Server address: #{port_token}"
    url = Repla::Server::ParentLogger.url_from_line(line_with_port_token)
    assert_equal(port_url, url)

    port_token = 'port: 3131'
    port_url = 'http://localhost:3131'
    line_with_port_token = "Server address: #{port_token}"
    url = Repla::Server::ParentLogger.url_from_line(line_with_port_token)
    assert_equal(port_url, url)

    port_token = 'PORT=3131'
    port_url = 'http://localhost:3131'
    line_with_port_token = "Server address: #{port_token}"
    url = Repla::Server::ParentLogger.url_from_line(line_with_port_token)
    assert_equal(port_url, url)

    port_token = 'port  3131'
    port_url = 'http://localhost:3131'
    line_with_port_token = "Server address: #{port_token}"
    url = Repla::Server::ParentLogger.url_from_line(line_with_port_token)
    assert_equal(port_url, url)
  end

  def test_get_url
    test_url = 'http://localhost:8888'

    url = Repla::Server::ParentLogger.get_url(nil, 8888)
    assert_equal(test_url, url)

    test_url = 'http://127.0.0.1:8888'

    url = Repla::Server::ParentLogger.get_url('http://127.0.0.1', 8888)
    assert_equal(test_url, url)

    test_url = 'www.example.com:8888'

    url = Repla::Server::ParentLogger.get_url('www.example.com', 8888)
    assert_equal(test_url, url)

    test_url = 'https://example.com:8888'
    url = Repla::Server::ParentLogger.get_url('https://example.com', 8888)
    assert_equal(test_url, url)
  end

  def test_find_string
    text = 'The string is somewhere'

    test_index = 14
    string = 'some'
    index = Repla::Server::ParentLogger.find_string(text, string)
    assert_equal(test_index, index)
    found = Repla::Server::ParentLogger.string_found?(text, string)
    assert(found)

    string = 'Tnone'
    index = Repla::Server::ParentLogger.find_string(text, string)
    assert_nil(index)
    found = Repla::Server::ParentLogger.string_found?(text, string)
    refute(found)

    test_index = 0
    string = 'T'
    index = Repla::Server::ParentLogger.find_string(text, string)
    assert_equal(test_index, index)
    found = Repla::Server::ParentLogger.string_found?(text, string)
    assert(found)
  end
end

# Test parent logger
class TestParentLoggerURL < Minitest::Test
  def test_multiple_urls
    mock_view = Repla::Test::MockView.new
    parent_logger = Repla::Server::ParentLogger.new(Repla::Test::MockLogger.new,
                                                    mock_view,
                                                    TEST_DELAY_OPTIONS_ZERO)
    real_example_url = 'http://127.0.0.1:4000/'
    line_with_real_example_url = "Server address: #{real_example_url}"
    parent_logger.process_output(line_with_real_example_url)
    assert(mock_view.called)
    local_url_with_port = 'http://127.0.0.1:5000'
    line_with_local_url_with_port = "Here is a URL #{local_url_with_port}"
    parent_logger.process_output(line_with_local_url_with_port)
    assert(!mock_view.failed)
  end

  def test_delay_long
    mock_view = Repla::Test::MockView.new
    parent_logger = Repla::Server::ParentLogger.new(Repla::Test::MockLogger.new,
                                                    mock_view,
                                                    TEST_DELAY_OPTIONS_LONG)
    real_example_url = 'http://127.0.0.1:4000/'
    line_with_real_example_url = "Server address: #{real_example_url}"
    parent_logger.process_output(line_with_real_example_url)
    assert(!mock_view.called)
    Repla::Test.block_until { mock_view.called }
    assert(mock_view.called)
    now = Time.now.to_i
    elapsed = now - mock_view.timestamp
    assert(elapsed => TEST_DELAY_LENGTH_LONG)
  end

  def test_delay_default
    mock_view = Repla::Test::MockView.new
    parent_logger = Repla::Server::ParentLogger.new(Repla::Test::MockLogger.new,
                                                    mock_view)
    real_example_url = 'http://127.0.0.1:4000/'
    line_with_real_example_url = "Server address: #{real_example_url}"
    parent_logger.process_output(line_with_real_example_url)
    assert(!mock_view.called)
    Repla::Test.block_until_with_timeout(4, 0.2) { mock_view.called }
    assert(mock_view.called)
    now = Time.now.to_f
    elapsed = now - mock_view.timestamp
    assert(elapsed => TEST_DELAY_LENGTH_DEFAULT)
    # This assert isn't reliable
    # assert(elapsed < TEST_DELAY_LENGTH_LONG)
  end
end

# Test parent logger options
class TestParentLoggerURLOptionsSingle < Minitest::Test
  def test_string
    options = { url_string: 'wait for this string' }
    parent_logger = Repla::Server::ParentLogger.new(Repla::Test::MockLogger.new,
                                                    Repla::Test::MockView.new,
                                                    options)
    good_url = 'http://www.example.com'
    line_with_good_url = "Here is a URL #{good_url}"
    url = parent_logger.url_from_line(line_with_good_url)
    assert_nil(url)
    url = parent_logger.url_from_line(line_with_good_url)
    assert_nil(url)
    line_with_good_url_after_string = "wait for this string#{good_url}"
    url = parent_logger.url_from_line(line_with_good_url_after_string)
    assert_equal(good_url, url)
  end

  def test_url
    good_url = 'http://www.example.com'
    options = { url: good_url }
    parent_logger = Repla::Server::ParentLogger.new(Repla::Test::MockLogger.new,
                                                    Repla::Test::MockView.new,
                                                    options)
    line_with_no_url = 'A line with no URL'
    url = parent_logger.url_from_line(line_with_no_url)
    assert_equal(good_url, url)
  end

  def test_port
    port = 5000
    local_url_with_port = "http://localhost:#{port}"
    options = { port: port }
    parent_logger = Repla::Server::ParentLogger.new(Repla::Test::MockLogger.new,
                                                    Repla::Test::MockView.new,
                                                    options)
    line_with_no_url = 'A line with no URL'
    url = parent_logger.url_from_line(line_with_no_url)
    assert_equal(local_url_with_port, url)
  end
end

# Test parent logger options multiple
class TestParentLoggerOptionsMultiple < Minitest::Test
  def test_string_new_line
    string = 'wait for this string'
    options = { url_string: string }
    parent_logger = Repla::Server::ParentLogger.new(Repla::Test::MockLogger.new,
                                                    Repla::Test::MockView.new,
                                                    options)
    good_url = 'http://www.example.com'
    line_with_good_url = "Here is a URL #{good_url}"
    url = parent_logger.url_from_line(line_with_good_url)
    assert_nil(url)
    line_with_string = "the string will appear #{string}"
    url = parent_logger.url_from_line(line_with_string)
    assert_nil(url)
    line_with_good_url = "A different string #{good_url}"
    url = parent_logger.url_from_line(line_with_good_url)
    assert_equal(good_url, url)
  end

  def test_url_and_port
    port = 5000
    good_url = 'http://www.example.com'
    good_url_with_port = "#{good_url}:#{port}"
    options = { port: port, url: good_url }
    parent_logger = Repla::Server::ParentLogger.new(Repla::Test::MockLogger.new,
                                                    Repla::Test::MockView.new,
                                                    options)
    line_with_no_url = 'A line with no URL'
    url = parent_logger.url_from_line(line_with_no_url)
    assert_equal(good_url_with_port, url)
  end

  def test_url_string
    good_url = 'http://www.example.com'
    different_url = 'http://localhost'
    options = { url_string: 'wait for this string', url: good_url }
    parent_logger = Repla::Server::ParentLogger.new(Repla::Test::MockLogger.new,
                                                    Repla::Test::MockView.new,
                                                    options)
    line_with_no_url = 'A line with no URL'
    url = parent_logger.url_from_line(line_with_no_url)
    assert_nil(url)
    url = parent_logger.url_from_line(line_with_no_url)
    assert_nil(url)

    line_with_different_url_after_string = 'wait for this string'\
      "#{different_url}"
    url = parent_logger.url_from_line(line_with_different_url_after_string)
    assert_equal(good_url, url)
  end

  def test_port_string
    port = 5000
    options = { url_string: 'wait for this string', port: port }
    local_url_with_port = "http://localhost:#{port}"
    different_url = 'http://www.example.com'
    parent_logger = Repla::Server::ParentLogger.new(Repla::Test::MockLogger.new,
                                                    Repla::Test::MockView.new,
                                                    options)
    line_with_no_url = 'A line with no URL'
    url = parent_logger.url_from_line(line_with_no_url)
    assert_nil(url)
    line_with_different_url_after_string = 'wait for this string'\
      "#{different_url}"
    url = parent_logger.url_from_line(line_with_different_url_after_string)
    assert_equal(local_url_with_port, url)
  end

  def test_url_port_string
    string = 'wait for this string'
    port = 5000
    good_url = 'http://www.example.com'
    different_url = 'http://localhost'
    good_url_with_port = "#{good_url}:#{port}"
    # Add whitespace to assure it's stripped properly
    options = { port: "    #{port}     ",
                url: "    #{good_url}    ",
                url_string: string }
    parent_logger = Repla::Server::ParentLogger.new(Repla::Test::MockLogger.new,
                                                    Repla::Test::MockView.new,
                                                    options)
    line_with_no_url = 'A line with no URL'
    url = parent_logger.url_from_line(line_with_no_url)
    assert_nil(url)
    line_with_different_url_after_string = 'wait for this string'\
      "#{different_url}"
    url = parent_logger.url_from_line(line_with_different_url_after_string)
    assert_equal(good_url_with_port, url)
  end
end

# Test logger
class TestLogger < Minitest::Test
  def setup
    @logger = Repla::Logger.new
    @view = Repla::View.new(@logger.window_id)
    @parent_logger = Repla::Server::ParentLogger.new(@logger, @view)
    @logger.show
    @test_log_helper = Repla::Test::LogHelper.new(@logger.window_id,
                                                  @logger.view_id)
  end

  def teardown
    @view.close
  end

  def test_logging
    # Message
    message = TEST_ENV_VALUE
    @parent_logger.process_output(message)
    last = nil
    Repla::Test.block_until do
      last = @test_log_helper.last_log_message
      last == message
    end
    assert_equal(message, last)
    test_class = @test_log_helper.last_log_class
    assert_equal('message', test_class)

    # Error
    error = TEST_ENV_VALUE_TWO
    refute_equal(message, error)
    @parent_logger.process_error(error)
    last = nil
    Repla::Test.block_until do
      last = @test_log_helper.last_log_message
      last == error
    end
    assert_equal(error, last)
    test_class = @test_log_helper.last_log_class
    assert_equal('error', test_class)
  end
end

# Test server
class TestServer < Minitest::Test
  def setup
    logger = Repla::Logger.new
    @view = Repla::View.new(logger.window_id)
    @parent_logger = Repla::Server::ParentLogger.new(logger, @view)
    logger.show
    @restore = Repla::Test::Helper.add_env(TEST_SERVER_ENV)
    @parent = Repla::Server::Parent.new(SERVER_COMMAND_DEFAULT_PATH,
                                        @parent_logger)
    Thread.new do
      @parent.run
    end
    sleep Repla::Test::TEST_PAUSE_TIME
  end

  def teardown
    Repla::Test::Helper.remove_env(TEST_SERVER_ENV, @restore)
    @view.close
    @parent.stop
  end

  def test_server
    javascript = File.read(Repla::Test::TITLE_JAVASCRIPT_FILE)
    result = nil
    Repla::Test.block_until do
      @view.load_url(Repla::Test::INDEX_HTML_URL, should_clear_cache: true)
      result = @view.do_javascript(javascript)
      result == Repla::Test::INDEX_HTML_TITLE
    end
    assert_equal(result, Repla::Test::INDEX_HTML_TITLE)
  end
end

# Test server path
class TestServerPathAndArg < Minitest::Test
  def setup
    logger = Repla::Logger.new
    @view = Repla::View.new(logger.window_id)
    @parent_logger = Repla::Server::ParentLogger.new(logger, @view)
    logger.show
    @restore = Repla::Test::Helper.add_env(TEST_SERVER_COMMAND_PATH_ENV)
    @parent = Repla::Server::Parent.new(SERVER_COMMAND_DEFAULT_ROOT,
                                        @parent_logger)
    Thread.new do
      @parent.run
    end
    sleep Repla::Test::TEST_PAUSE_TIME
  end

  def teardown
    Repla::Test::Helper.remove_env(TEST_SERVER_COMMAND_PATH_ENV, @restore)
    @view.close
    @parent.stop
  end

  def test_server_path_and_arg
    javascript = File.read(Repla::Test::TITLE_JAVASCRIPT_FILE)

    result = nil
    Repla::Test.block_until do
      @view.load_url(Repla::Test::INDEX_HTML_URL, should_clear_cache: true)
      result = @view.do_javascript(javascript)
      result == Repla::Test::INDEX_HTML_TITLE
    end
    assert_equal(result, Repla::Test::INDEX_HTML_TITLE)
  end
end
