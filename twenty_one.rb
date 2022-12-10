class Card
  attr_reader :rank, :suit

  FACE_CARDS = ["jack", "queen", "king"]

  def initialize(rank, suit)
    @rank = rank
    @suit = suit
  end

  def value
    if FACE_CARDS.include?(rank)
      10
    elsif rank == "ace"
      11
    else
      rank.to_i
    end 
  end

  def to_s
    "#{rank}_of_#{suit}"
  end
end

class Deck
  RANKS = (2..10).to_a + ["jack", "queen", "king", "ace"]
  SUITS = ["clubs", "spades", "diamonds", "hearts"]

  def initialize
    generate_and_shuffle
  end

  def pop
    generate_and_shuffle if @cards.empty?
    @cards.pop
  end

  def to_s
    @cards.to_s
  end

  private

  def generate_and_shuffle
    @cards = SUITS.product(RANKS).map do |suit, rank|
      Card.new(rank, suit)
    end
    @cards.shuffle!
  end
end


class Player
  attr_reader :wallet, :name

  def initialize
    reset
    @name = nil
    @wallet = 0
  end

  def set_name(name)
    @name = name
  end

  def deal(card)
    @cards << card
  end

  def busted?
    total > 21
  end

  def total
    total = @cards.reduce(0) { |sum, card| sum + card.value }

    no_of_aces = @cards.select { |card| card.rank == "ace" }.size

    while no_of_aces > 0 && total > 21
      total -= 10
      no_of_aces -= 1
    end

    total
  end

  def show_cards
    @cards.map(&:to_s)
  end

  def add(amount)
    @wallet += amount
  end

  def reset
    @cards = []
  end
end

class Dealer < Player
  def show_initial_cards
    [@cards.first, "facedown"]
  end

  def must_hit?
    total < 17
  end
end

class TwentyOneGame
  attr_reader :player, :dealer, :deck, :player_turn, :bet

  def initialize
    @player = Player.new
    @dealer = Dealer.new
    @deck = Deck.new
    @player_turn = true
  end

  def reset_players
    player.reset
    dealer.reset
    @bet = nil
    @payout = nil
  end

  def cards_hash(facedown: false)
    cards = {}
    cards[:player] = { cards: player.show_cards, total: player.total }
    if facedown
      cards[:dealer] = { cards: dealer.show_initial_cards, total: nil }
    else
      cards[:dealer] = { cards: dealer.show_cards, total: dealer.total }
    end
    cards
  end

  def deal_initial_cards
    2.times do
      dealer.deal(deck.pop)
      player.deal(deck.pop)
    end
  end

  def hit(current_player)
    current_player.deal(deck.pop)
  end

  def dealer_must_hit?
    dealer.total < 17 && !player.busted?
  end

  def round_over_message
    if player.busted?
      {winner: "dealer", message: "Player busts! Dealer wins! Player loses #{bet}"}
    elsif dealer.busted?
      {winner: "player", message: "Dealer busts! Player wins #{bet}!"}
    elsif player.total > dealer.total
      {winner: "player", message: "Player wins #{bet}!"}
    elsif dealer.total > player.total
      {winner: "dealer", message: "Dealer wins! Player loses #{bet}" }
    else
      {winner: "push", message: "Push! The totals are equal"}
    end
  end

  def settle_bet
    return if @payout
    if round_over_message[:winner] == "player"
      player.add(@bet * 2)
    elsif round_over_message[:winner] == "push"
      player.add(@bet)
    end
    @payout = true
  end

  def game_over?
    player.busted? || dealer.busted? || dealer.total >= 17 || dealer.total > player.total
  end

  def validate_and_place_bet(amount)
    if player.wallet >= amount && amount > 0 && amount.to_s.to_i == amount
      @bet = amount.to_i
      place_bet
      nil
    else
      "Please enter a valid amount to bet"
    end
  end

  def place_bet
    player.add(-@bet) if @bet
  end

  def validate_and_set_name_amount(name, amount)
    if name.size < 1 || amount.to_i.to_s != amount
      "Please enter a valid name and a whole number!"
    else
      player.set_name(name)
      player.add(amount.to_i)
      nil
    end
  end
end

  # def display_cards_and_total(current_player)
  #   puts "#{current_player.class} has:"
  #   puts current_player.show_cards
  #   puts "For a total of #{current_player.total}"
  # end

  # def display_initial_cards
  #   puts "Dealer has:"
  #   puts dealer.show_initial_cards
  #   puts
  #   puts "Player has: "
  #   puts player.show_cards
  #   puts "For a total of #{player.total}"
  #   puts
  # end



  # def player_takes_turns
  #   player_choice = nil
  #   until player.busted? do
  #     puts "Would you like to stay(s) or hit(h)?"
  #     player_choice = gets.chomp
  #     break if player_choice.downcase.start_with?("s")
  #     player.deal(deck.pop)
  #     display_cards_and_total(player)
  #   end
  # end

  # def dealer_takes_turns
  #   while dealer.total < 17
  #     dealer.deal(deck.pop)
  #   end
  # end

  # def cards_hash(current_player, show_status: "normal")
  #   if show_status == "normal"
  #     { cards: current_player.show_cards, total: current_player.total }
  #   elsif show_status == "facedown"
  #     { cards: current_player.show_initial_cards, total: nil }
  #   end
  # end

  # def show_final_cards_and_result
  #   puts "======================="
  #   display_cards_and_total(player)
  #   puts
  #   display_cards_and_total(dealer)
  #   puts
  #   puts WINNING_LINE[winner]
  #   reset_players
  # # end

  # def winner
  #   if player.busted?
  #     :dealer
  #   elsif dealer.busted?
  #     :player
  #   elsif player.total > dealer.total
  #     :player
  #   elsif dealer.total > player.total
  #     :dealer
  #   else
  #     :tie
  #   end
  # end

# TwentyOneGame.new.play