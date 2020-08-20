class BaseMovementProcessor

  def move
    raise NotImplementedError
  end










  #todo
  # add check if bad spot is tail (will be free next move)

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

  # private

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
      other_heads.any? { |head| head['head'] == m.last }
    end
  end

  def move_bad?(move)
    my_body_locations = me['body'].map(&:to_h)

    return true if occupied_spots.include?(move)
    return true if outside_board?(move)
    return true if dead_end?(move)
    false
  end

  def dead_end?(move)
    my_body_locations = me['body'].map(&:to_h)
    move_options = next_locations_from_location(location: move)

    move_options.reject! { |l| l['x'] == -1 }

    move_options.reject! { |l| l['x'] == board['width'] }

    move_options.reject! { |l| l['y'] == -1 }

    move_options.reject! { |l| l['y'] == board['height'] }


    (move_options - my_body_locations).empty?
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

  def occupied_spots
    snakes.each_with_object([]) do |snake, arr|
      snake['body'].each { |b| arr << b }
    end
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
end
