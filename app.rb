require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

require_relative "twenty_one"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

def reset_game
  if session[:game]
    session[:game].reset_players
  else
    session[:game] = TwentyOneGame.new
  end
end

def logged_in?
  @game.player.name
end

def require_login
  redirect "/login" unless logged_in?
end

before do
  @game = session[:game]
end

get "/" do
  @rules = File.readlines("./data/rules.txt")
  reset_game

  erb :home
end

get "/login" do
  if logged_in?
    erb :buyin
  else
    erb :login
  end
end

post "/login" do
  name = params[:name].strip
  error = @game.validate_and_set_name(name)
  if error
    session[:error] = error
    erb :login
  else
    redirect "/buyin"
  end
end

get "/buyin" do
  erb :buyin
end

post "/buyin" do
  amount = params[:amount]
  error = @game.validate_and_buyin(amount)
  if error
    session[:error] = error
    erb :buyin
  else
    redirect "/game/new"
  end
end

get "/game/new" do
  reset_game

  erb :new_game
end

post "/game" do
  require_login

  bet = params[:bet].to_i
  error = @game.validate_and_place_bet(bet)
  if error
    session[:error] = error
    erb :new_game
  else
    redirect "/game"
  end
end

get "/game" do
  require_login

  if @game.player.show_cards.empty?
    @game.deal_initial_cards
  end

  @cards = @game.cards_hash(facedown: true)

  erb :player, layout: :game_layout
end

post "/game/player" do
  require_login

  choice = params[:choice]
  @game.hit(@game.player) if choice == "hit"

  if choice == "stay" || @game.player.total == 21
    @cards = @game.cards_hash(facedown: false)
    erb :dealer, layout: :game_layout
  elsif @game.player.busted?
    redirect "/game/result"
  else
    @cards = @game.cards_hash(facedown: true)
    erb :player, layout: :game_layout
  end
end

post "/game/dealer" do
  require_login

  @game.hit(@game.dealer) unless @game.game_over?

  redirect "/game/result" if @game.game_over?

  @cards = @game.cards_hash(facedown: false)

  erb :dealer, layout: :game_layout
end

get "/game/result" do
  require_login

  @cards = @game.cards_hash(facedown: false)
  @result = @game.round_over_message
  @game.settle_bet

  erb :result, layout: :game_layout
end

post "/logout" do
  session.clear
  reset_game
  redirect "/login"
end
