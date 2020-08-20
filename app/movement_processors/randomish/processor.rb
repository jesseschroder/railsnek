module Randomish
  class Processor < BaseMovementProcessor
    MAX_TURNS = 220

    def move
      choose_random_move
    end

    private

    def choose_random_move
      return 'up' if turn > MAX_TURNS

      10.times do
        move = MOVEMENTS.sample
        case move
          when 'up'
            next if move_bad?({ 'x' => head['x'], 'y' => head['y'] + 1 })
            return 'up'
          when 'down'
            next if move_bad?({ 'x' => head['x'], 'y' => head['y'] - 1 })
            return 'down'
          when 'left'
            next if move_bad?({ 'x' => head['x'] - 1, 'y' => head['y']})
            return 'left'
          when 'right'
            next if move_bad?({ 'x' => head['x'] + 1, 'y' => head['y']})
            return 'right'
        end
      end
      emergency_move
    end
  end
end
