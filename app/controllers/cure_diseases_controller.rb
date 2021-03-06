class CureDiseasesController < PlayerActionsController
  delegate :location, to: :current_player

  def create
    cure_marker.update!(cured: true, eradicated: game.eradicated?(color: color))
    game.increment!(:actions_taken)
    current_player.update!(cards_composite_ids: remaining_composite_ids)
    send_game_broadcast
  end

  private

  def create_error_message
    @create_error_message ||=
      begin
        if !current_player.at_research_station?
          I18n.t("player_actions.city_with_no_station", name: location.name)
        elsif !correct_number_of_cards?
          I18n.t("cure_diseases.wrong_number_of_cards")
        elsif cities.map(&:color).uniq.count != 1
          I18n.t("cure_diseases.not_the_same_color")
        elsif cure_marker.cured
          I18n.t("cure_diseases.already_cured")
        elsif !current_player.owns_cards?(cities)
          I18n.t("cure_diseases.player_must_own_cards")
        end
      end
  end

  def correct_number_of_cards?
    unique_city_staticids.count ==
      if current_player.scientist?
        4
      else
        5
      end
  end

  def cure_marker
    @cure_marker ||= game.cure_markers.find_by(color: color)
  end

  def cities
    @cities ||= City.find_from_staticids(unique_city_staticids) end

  def unique_city_staticids
    params[:city_staticids].uniq
  end

  def color
    @color ||= cities.first.color
  end

  def remaining_composite_ids
    current_player.cards_composite_ids - cities.map(&:composite_id)
  end
end
