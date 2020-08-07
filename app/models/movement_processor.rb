class MovementProcessor
  MOVEMENTS = %w(up down left right)
  X_DIRECTIONS = {
    1 => 'right',
    -1 => 'left',
  }
  Y_DIRECTIONS = {
    1 => 'up',
    -1 => 'down',
  }
  X_OPPOSITE = {
    'right' => 'left',
    'left' => 'right',
  }
  Y_OPPOSITE = {
    'up' => 'down',
    'down' => 'up',
  }

  attr_reader :data

  def initialize(data:)
    @data = data
    @bad_ideas = []
  end

  def random_move
    random_mover
  end

  def food_move
    moves = build_moves_to_food

    safe_moves = moves.reject { |m| move_bad?(m.last) }
    kill_moves = moves_to_kill(safe_moves)
    bad_ideas = (safe_moves + kill_moves).uniq.each_with_object([]) do |move, array|
      array << move if not_great_idea(move)
    end

    kill_moves.each { |km| return km.first unless move_bad?(km.last) }
    safe_moves.each { |sm| return sm.first unless move_bad?(sm.last) }
    bad_ideas.each { |bm| return bm.first unless move_bad?(bm.last) }

    emergency_move
  end

  def moves_to_kill(moves, recursive: false)
    kills = moves.each_with_object([]) do |move, array|
      other_heads.each do |head|
        next unless head['head'] == move.last
        next unless head['length'] < me['length']
        array << move
      end
    end

    return kills if recursive

    moves.each do |move|
      next_moves = possible_moves_from_location(location: move.last)
      kills.concat(moves_to_kill(next_moves, recursive: true))
    end
  end

  def survival
    if me['length'] < 5
      food_move
    else
      random_move
    end
  end

  private

  def game
    @game ||= Game.where(id: params.dig('game', 'id'))
  end

  def snakes
    @snakes ||= data.dig('board', 'snakes')
  end

  def me
    @me ||= data.dig('you')
  end

  def food
    @food ||= data.dig('board', 'food')
  end

  def turn
    @turn ||= data.dig('turn')
  end

  def head
    @head ||= me['head']
  end

  def board
    @board ||= data.dig('board')
  end

  def other_heads
    @other_heads ||= snakes.each_with_object([]) { |s, a| a << s unless s['id'] == me['id'] }
  end

  def possible_moves_from_location(location:)
    [
      [ 'right', { 'x' => location['x'] + 1, 'y' => location['y'] } ],
      [ 'left', { 'x' => location['x'] - 1, 'y' => location['y'] } ],
      [ 'up', { 'x' => location['x'], 'y' => location['y'] + 1 } ],
      [ 'down', { 'x' => location['x'], 'y' => location['y'] - 1 } ],
    ]
  end

  def next_locations_from_location(location:)
    [
      { 'x' => location['x'] + 1, 'y' => location['y'] },
      { 'x' => location['x'] - 1, 'y' => location['y'] },
      { 'x' => location['x'], 'y' => location['y'] + 1 },
      { 'x' => location['x'], 'y' => location['y'] - 1 },
    ]
  end

  def not_great_idea(move)
    possible_moves = possible_moves_from_location(location: move.last)
    possible_moves.any? do |m|
      other_heads.any? { |head| head['head'] == m }
    end
  end

  def move_bad?(move)
    return true if occupied_spots.include?(move)
    return true if outside_board?(move)
    return true if (next_locations_from_location(location: move) - me['body']).empty?
    false
  end

  def emergency_move
    possibilities = [
      [ 'right', { 'x' => head['x'] + 1, 'y' => head['y'] } ],
      [ 'left', { 'x' => head['x'] - 1, 'y' => head['y'] } ],
      [ 'up', { 'x' => head['x'], 'y' => head['y'] + 1 } ],
      [ 'down', { 'x' => head['x'], 'y' => head['y'] - 1 } ],
    ]

    possibilities.each do |move|
      next if occupied_spots.include?(move.last)
      next if outside_board?(move.last)
      return move.first
    end
    Rails.logger.info 'time to die'
    'up'
  end

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

  def outside_board?(move)
    return true if move['x'] < 0 || move['x'] == board['width'] || move['y'] < 0 || move['y'] == board['height']
    false
  end

  def higher_or_lower(target:, head:)
    difference = target - head
    case
      when difference > 0
        1
      when difference < 0
        -1
      else
        0
    end
  end

  def random_mover
    return 'up' if turn > 220

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

  def occupied_spots
    snakes.each_with_object([]) do |snake, arr|
      snake['body'].each { |b| arr << b }
    end
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
