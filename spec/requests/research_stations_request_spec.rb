require 'rails_helper'

RSpec.describe ResearchStationsController, type: :request do
  include AuthHelper
  include ResponseHelpers

  let(:current_user) { Fabricate(:user, password: '12341234') }
  let(:game) { Fabricate(:game, owner: current_user) }
  let(:current_player) { current_user.players.find_by(game: game) }
  let(:player) { Fabricate(:player, game: game) }
  let(:user) { user.players.find_by(game: game) }

  before(:each) do
    # We must assign a role other than Operations Expert.
    current_player.update!(role: Player.roles.keys[1,5].sample)
    game.update(player_turn_ids: [current_player.id, player.id])
  end

  it "returns no reserach stations left to be placed error" do
    6.times { Fabricate(:research_station, game: game) }
    trigger_post
    expect(error).to eq(I18n.t('research_stations.none_left'))
  end

  it "returns error if the player doesn't own the current location" do
    current_player.update!(cards_composite_ids: [])
    trigger_post
    expect(error).to eq(I18n.t('player_actions.must_own_card'))
  end

  it "creates a research station at the current location" do
    trigger_post
    expect(body['city_staticid'])
      .to eq(current_player.location.staticid)
  end

  it "increments actions taken" do
    trigger_post
    expect(game.reload.actions_taken).to eq(1)
  end

  it "removes card from player's inventory" do
    composite_id = current_player.location.composite_id
    trigger_post
    expect(current_player.reload.cards_composite_ids.include?(composite_id))
      .to be(false)
  end


  context "when player is an operations expert" do
    before(:each) do
      current_player.update!(role: Player.roles.keys.first)
    end

    it "doesn't return must own card error if player is an operations expert" do
      current_player.update!(cards_composite_ids: [])
      trigger_post
      expect(error).to be_nil
    end

    it "doesn't remove cards from the current player's inventory" do
      composite_id = current_player.location.composite_id
      current_player.update!(cards_composite_ids: [composite_id])
      trigger_post
      expect(current_player.reload.cards_composite_ids.include?(composite_id))
        .to be(true)
    end
  end

  context "when government grant used" do
    let(:grant) { SpecialCard.events.find(&:government_grant?) }
    let(:city) { WorldGraph.cities[25] }

    before(:each) do
      current_player.update!(cards_composite_ids: [grant.composite_id])
    end

    it "removes the player card even if the player is an operations expert" do
      current_player.update!(role: Player.roles.keys.first)
      trigger_post(city_staticid: city.staticid)
      composite_ids = current_player.reload.cards_composite_ids
      expect(composite_ids.include?(grant.composite_id)).to be(false)
    end

    it "doesn't remove the current location card" do
      current_player.cards_composite_ids << current_player.location.composite_id
      current_player.save!
      trigger_post(city_staticid: city.staticid)
      composite_ids = current_player.reload.cards_composite_ids
      expect(composite_ids.include?(current_player.location.composite_id))
        .to be(true)
    end

    it "doesn't increment actions taken" do
      trigger_post(city_staticid: city.staticid)
      expect(game.reload.actions_taken).to eq(0)
    end

    it "creates a research station" do
      trigger_post(city_staticid: city.staticid)
      expect(game.research_stations.count).to eq(1)
    end

    it "adds the event card to the discarded cards pile" do
      trigger_post(city_staticid: city.staticid)
      discarded_ids = game.reload.discarded_special_player_card_ids
      expect(discarded_ids.include?(grant.staticid)).to be(true)
    end
  end

  private

  def trigger_post(city_staticid: nil)
    post "/games/#{game.id}/research_stations", params: {
      city_staticid: city_staticid
    }.to_json, headers: headers
  end
end
