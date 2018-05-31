class Player < ApplicationRecord
  enum role: {
    operations_expert: 0,
    contingency_planer: 1,
    medic: 2,
    researcher: 3,
    quarantine_specialist: 4,
    dispatcher: 5,
    scientist: 6
  }

  has_many :special_cards
  has_many :movements
  belongs_to :game
  belongs_to :user
  has_many :city_offers_made, foreign_key: "from_player_id",
    class_name: "ShareCard"
  has_many :city_offers_received, foreign_key: "to_player_id",
    class_name: "ShareCard"
  has_many :share_cards, foreign_key: "creator_id"
  has_many :operations_expert_actions
  has_many :movement_proposals
  has_many :created_movement_proposals, foreign_key: "creator_id",
    class_name: "MovementProposal"

  scope :ordered_desc_by_game_creation, -> do
    includes(game: :owner).order(created_at: :desc)
  end

  def location
    City.find(location_staticid)
  end

  def has_too_many_cards?
    PlayerCard.city_cards(cards_composite_ids).count > 7
  end

  def owns_card?(card)
    cards_composite_ids.include?(card&.composite_id)
  end

  def player_cards
    cards_composite_ids.map do |id|
      PlayerCard.find_by_composite_id(id)
    end
  end

  def events
    player_cards.select { |card| card.is_a?(SpecialCard) }
  end

  def cities
    player_cards.select { |card| card.is_a?(City) }
  end
end
