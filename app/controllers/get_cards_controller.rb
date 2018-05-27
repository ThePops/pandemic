class GetCardsController < PlayerActionsController
  include ShareKnowledge
  delegate :location, to: :current_player

  def create
    current_player.share_cards.create!(
      to_player: current_player,
      from_player: other_player,
      accepted: false,
      city_staticid: player_card.staticid
    )
  end

  private

  def create_error_message
    @create_error_message ||=
      begin
        if other_player.location != current_player.location
          I18n.t("share_cards.not_the_same_location")
        elsif !allowed_to_share_knowledge?
          I18n.t("player_actions.not_a_researcher")
        elsif !player_card
          I18n.t("share_cards.not_an_owner")
        end
      end
  end

  def other_player
    @other_player ||= game.players.find_by(id: params[:player_id])
  end

  def player_card
    return other_location if other_player.owns_card?(other_location)
    return location if other_player.owns_card?(location)
  end

  def other_location
    City.find(params[:city_staticid])
  end
end
