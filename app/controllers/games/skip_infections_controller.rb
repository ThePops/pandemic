class Games::SkipInfectionsController < ApplicationController
  before_action :check_for_potential_create_errors, only: :create

  def create
    game.skip_infections = true
    game.discarded_special_player_card_ids << event.staticid
    game.save!
    current_player.update!(cards_composite_ids: remaining_cards)
  end

  private

  def check_for_potential_create_errors
    render json: { error: create_error_message } if create_error_message
  end

  def create_error_message
    if !current_player.events.include?(event)
      I18n.t("player_actions.must_own_card")
    end
  end

  def event
    @event ||= SpecialCard.events.find(&:one_quiet_night?)
  end

  def current_player
    @current_player ||= current_user.players.find_by(game: game)
  end

  def game
    @game ||= current_user.games.find_by(id: params[:game_id])
  end

  def remaining_cards
    current_player.cards_composite_ids - [event.composite_id]
  end
end