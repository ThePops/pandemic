class Games::GovernmentGrantsController < ApplicationController
  before_action :check_for_potential_create_errors, only: :create

  def create
    game.research_stations.create!(city_staticid: params[:city_staticid])
    current_player.update(cards_composite_ids: remaining_composite_ids)
    game.discarded_special_player_card_ids << government_grant.staticid
    game.save!
    send_game_broadcast
  end

  private

  def create_error_message
    @create_error_message ||=
      begin
        case
        when params[:city_staticid].nil?
          I18n.t("player_actions.city_staticid")
        when game.all_research_stations_used?
          I18n.t('research_stations.none_left')
        when research_station_already_exists?
          I18n.t("government_grant.alread_exists")
        when !current_player.owns_government_grant?
          I18n.t('player_actions.must_own_card')
        end
      end
  end

  def research_station_already_exists?
    game.research_stations.find_by(city_staticid: params[:city_staticid])
  end

  def remaining_composite_ids
    current_player.cards_composite_ids - [government_grant.composite_id]
  end

  def government_grant
    SpecialCard.events.find(&:government_grant?)
  end

  def send_game_broadcast
    payload = JSON.parse(ApplicationController.new.render_to_string(
      'games/show',
      locals: { game: StartedGameDecorator.new(game) }
    ))
    ActionCable.server.broadcast(
      "game_channel:#{game.id}",
      game_update: true,
      game: payload
    )
  end
end
