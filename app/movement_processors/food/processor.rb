module Food
  class Processor < BaseMovementProcessor

    def move
      moves = build_moves_to_food

      safe_moves = moves.reject { |m| move_bad?(m.last) }
      kill_moves = moves_to_kill(safe_moves)
      bad_ideas = (safe_moves + kill_moves).uniq.each_with_object([]) do |move, array|
        array << move if not_great_idea(move)
      end

      Rails.logger.info '---------------SAFE---------------'
      Rails.logger.info safe_moves
      Rails.logger.info '---------------kill---------------'
      Rails.logger.info kill_moves
      Rails.logger.info '---------------bad---------------'
      Rails.logger.info bad_ideas

      # kill_moves.each { |km| return km.first unless move_bad?(km.last) }
      (safe_moves - bad_ideas).each { |sm| return sm.first unless move_bad?(sm.last) }
      bad_ideas.each { |bm| return bm.first unless move_bad?(bm.last) }

      emergency_move
    end

    private

    def build_moves_to_food
      x_move = higher_or_lower(target: closest_food['x'], head: head['x'])
      y_move = higher_or_lower(target: closest_food['y'], head: head['y'])
      x_direction = X_DIRECTIONS.dig(x_move) || 'right'
      y_direction = Y_DIRECTIONS.dig(y_move) || 'up'
      x_opposite = X_OPPOSITE.dig(x_direction)
      y_opposite = Y_OPPOSITE.dig(y_direction)

      moves =[]

      if x_move != 0
        moves << [x_direction, { 'x' => (head['x'] + x_move), 'y' => head['y'] }]
        if y_move != 0
          moves << [y_direction, { 'x' => head['x'], 'y' => (head['y'] + y_move) }]
          moves << [x_opposite, { 'x' => (head['x'] - x_move), 'y' => head['y'] }]
          moves << [y_opposite, { 'x' => head['x'], 'y' => (head['y'] - y_move) }]
        else
          moves << [x_opposite, { 'x' => (head['x'] - x_move), 'y' => head['y'] }]
          moves << [y_direction, { 'x' => head['x'], 'y' => (head['y'] + 1) }]
          moves << [y_opposite, { 'x' => head['x'], 'y' => (head['y'] - 1) }]
        end
      else
        moves << [y_direction, { 'x' => head['x'], 'y' => (head['y'] + y_move) }]
        moves << [y_opposite, { 'x' => head['x'], 'y' => (head['y'] - y_move) }]
        moves << [x_direction, { 'x' => (head['x'] + 1), 'y' => head['y'] }]
        moves << [x_opposite, { 'x' => (head['x'] - 1), 'y' => head['y'] }]
      end
      moves
    end

    def closest_food
      food_distance = food.each_with_object([]) do |fud, arr|
        x_dist = (fud['x'] - head['x']).abs
        y_dist = (fud['y'] - head['y']).abs

        arr << x_dist + y_dist
      end
      food[food_distance.each_with_index.min.last]
    end
  end
end
