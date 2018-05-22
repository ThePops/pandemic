require 'rails_helper'

RSpec.describe CreateMovement do

  let(:game) { Fabricate(:game) }
  let(:user) { game.owner }
  let(:player) { game.players.find_by(user: user) }

  before(:each) do
    CreateMovement.new(game: game, player: player, from: "1", to: "2").call
  end

  it "sets from_city_staticid" do
    expect(Movement.last.from_city_staticid).to eq('1')
  end

  it "sets to_city_staticid" do
    expect(Movement.last.to_city_staticid).to eq('2')
  end

  it "sets player_id" do
    expect(Movement.last.player_id).to eq(player.id)
  end
end
