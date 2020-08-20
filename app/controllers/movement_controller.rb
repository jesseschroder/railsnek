class MovementController < ApplicationController
  def create
    processor = Food::Processor.new(data: move_params)
    response = {
      move: processor.move,
      shout: 'moving',
    }

     render json: response
  end

  private

  def move_params
    params.permit!
  end
end
