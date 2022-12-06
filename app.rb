require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"
require "redcarpet"

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

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

before do
  @game = session[:game]
end

get "/" do
  file = File.read("./data/rules.md")
  @rules = render_markdown(file)
  erb :home
end

get "/game/new" do
  reset_game

  erb :new_game
end

post "/game/player" do
  if @game.player.show_cards.empty?
    @game.deal_initial_cards
  end

  @cards = @game.cards_hash(facedown: true)

  erb :player, layout: :game_layout
end

post "/game/player/choice" do
  choice = params[:choice]
  @game.hit(@game.player) if choice == "hit"

  if choice == "stay" || @game.player.total == 21
    redirect "/game/result" if @game.game_over?
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
  @game.hit(@game.dealer)

  redirect "/game/result" if @game.game_over?

  @cards = @game.cards_hash(facedown: false)

  erb :dealer, layout: :game_layout
end

get "/game/result" do
  @cards = @game.cards_hash(facedown: false)
  @result = @game.round_over_message

  erb :result, layout: :game_layout
end