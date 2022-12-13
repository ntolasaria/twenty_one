ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../app"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def admin_session
    { "rack.session" => { player: "admin" } }
  end

  def session
    last_request.env["rack.session"]
  end

  def test_homepage
    get "/"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "Game Rules"
  end

  def test_login_page_without_active_session
    get "/login"

    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(<label for="name">Please)
  end

  def test_login_with_valid_name
    post "/login", { name: "admin" }, { "rack.session" => {game: TwentyOneGame.new} }

    assert_equal 302, last_response.status
    assert_equal "admin", session[:player]

    get last_response["Location"]

    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(<label for="amount">Please enter the amount to buyin:)
  end

  def test_login_with_invalid_name
    post "/login", { name: "   " }, { "rack.session" => {game: TwentyOneGame.new} }

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Please enter a valid name!"
  end

  def test_buyin_with_active_login
    get "/buyin", {}, { "rack.session" => {game: TwentyOneGame.new, player: "admin"} }

    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(<label for="amount">Please enter the amount to buyin:)
  end

  def test_buyin_without_active_login
    get "/buyin", {}, { "rack.session" => {game: TwentyOneGame.new} }

    assert_equal 302, last_response.status
    
    get last_response["Location"]

    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(<label for="name">Please enter your name:</label>)
  end

  def test_buyin_with_valid_amount
    post "/buyin", { amount: 1000 }, { "rack.session" => {game: TwentyOneGame.new, player: "admin"} }

    assert_equal 302, last_response.status

    get last_response["Location"]

    assert_equal 200, last_response.status
    assert_includes last_response.body, "wallet: 1000"
  end
end
