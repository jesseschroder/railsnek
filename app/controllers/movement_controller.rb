class MovementController < ApplicationController
  def create
    move = MovementProcessor.new(data: params)
    response = {
      move: move.food_move,
      shout: 'moving',
    }

     render json: response
  end
end
