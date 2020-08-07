class GameController < ApplicationController

  def create
    Game.create(game_params)
  end

  def destroy
    Game.delete(game_params)
  end

  private

  def game_params
    {
      online_id: params.dig(:game, :id),
      timeout: params.dig(:game, :timeout)
    }
  end
end
