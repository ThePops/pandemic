class ShuttleFlightChecker
  prepend SimpleCommand

  attr_reader :player, :city_staticid
  def initialize(player:, city_staticid:)
    @player = player
    @city_staticid = city_staticid
  end

  def call
    return false unless player.has_actions_left?
    return false if player.location == location
    player.owns_card?(location)
  end

  private

  def location
    City.find(city_staticid)
  end
end
