require 'rails_helper'

RSpec.describe DirectFlightsController, type: :request do
  include AuthHelper
  include ResponseHelpers

  let(:current_user) { Fabricate(:user, password: '12341234') }
  let(:game) { Fabricate(:game, owner: current_user) }
  let(:current_player) { current_user.players.find_by(game: game) }
  let(:player) { Fabricate(:player, game: game) }
  let(:user) { user.players.find_by(game: game) }
  let(:city) { WorldGraph.cities[10] }

  before(:each) do
    game.update(player_turn_ids: [current_player.id, player.id])
  end

  it "returns an error if no city card passed in" do
    trigger_post
    expect(error).to eq(I18n.t("player_actions.city_staticid"))
  end

  context "with valid request" do
    before(:each) do
      current_player.update!(cards_composite_ids: [city.composite_id])
    end

    it "creates a movement with the to location set to the card passed in" do
      trigger_post
      expect(Movement.last.to_city_staticid).to eq(city.staticid)
    end

    it "sets movement's from location to the player's current location" do
      trigger_post
      expect(Movement.last.from_city_staticid)
        .to eq(current_player.location_staticid)
    end

    it "sets the current player's location to the new location" do
      trigger_post
      expect(current_player.reload.location).to eq(city)
    end

    it "increments actions taken" do
      trigger_post
      expect(game.reload.actions_taken).to eq(1)
    end

    it "removes used player card from player's inventory" do
      trigger_post
      expect(current_player.reload.owns_card?(city)).to be(false)
    end
  end

  private

  def trigger_post(id: city.staticid)
    post "/games/#{game.id}/direct_flights", params: {
      city_staticid: id
    }.to_json, headers: headers
  end
end
