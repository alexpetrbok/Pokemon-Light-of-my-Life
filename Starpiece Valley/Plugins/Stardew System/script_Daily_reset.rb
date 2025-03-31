module GameData
  class DailyClock
    attr_reader :game_day

    def initialize
      @game_day = 1  # Start at Day 1
    end

    def update
      now = pbGetTimeNow


      $item_display.update if $item_display && $item_display.visible?

      # Check if the player is late (past 2 AM)
      if is_late?(now)
        pass_out
      end
    end

    def daily_reset
      # Reset player energy
      $player_energy.reset_daily if $player_energy

      # Advance the time to 6 AM
      UnrealTime.advance_to(06,00,00)

      # Increment the day counter
      now = pbGetTimeNow
      @game_day = now.day

      # Call existing functions for berry production, egg collection, NPC affection, etc.
      

    end

    def is_late?(now)
      # Check if the current time is between 2 AM and 6 AM
      now.hour >= 2 && now.hour < 6
    end

    def rest_bonus(energy)
      now = pbGetTimeNow

      if is_late?(now) 
        if energy > 10
          # Player passed out with energy left
          $player_energy.modify_daily(-10)  
      	else
          # Player passed out with no energy left
          $player_energy.modify_daily(-20)  
	end
      elsif now.hour > 2
        # Player went to bed before midnight
        $player_energy.modify_daily(10)  # Bonus: Increase daily max by 10
      end
    end


    def pass_out
      # Transfer the player to bed
      
      # Call the daily reset function
      daily_reset
    end

  end
end

#===============================================================================
#  A* Pathfinding
#===============================================================================
class AStarPathfinder
  def initialize(map_id)
    @map_id = map_id
    @map = $game_map
  end

  def find_path(start_x, start_y, goal_x, goal_y)
    open_set = [[start_x, start_y]]
    came_from = {}
    g_score = { [start_x, start_y] => 0 }
    f_score = { [start_x, start_y] => heuristic(start_x, start_y, goal_x, goal_y) }

    while !open_set.empty?
      current = open_set.min_by { |node| f_score[node] || Float::INFINITY }
      if current == [goal_x, goal_y]
        return reconstruct_path(came_from, current)
      end

      open_set.delete(current)
      neighbors(current[0], current[1]).each do |neighbor|
        tentative_g_score = g_score[current] + 1
        if tentative_g_score < (g_score[neighbor] || Float::INFINITY)
          came_from[neighbor] = current
          g_score[neighbor] = tentative_g_score
          f_score[neighbor] = tentative_g_score + heuristic(neighbor[0], neighbor[1], goal_x, goal_y)
          open_set << neighbor unless open_set.include?(neighbor)
        end
      end
    end

    return nil  # No path found
  end

  def heuristic(x1, y1, x2, y2)
    (x1 - x2).abs + (y1 - y2).abs
  end

  def neighbors(x, y)
    neighbors = []
    [[-1, 0], [1, 0], [0, -1], [0, 1]].each do |dx, dy|
      nx = x + dx
      ny = y + dy
      if @map.passable?(nx, ny, 0) && !$game_player.at_coordinate?(nx, ny)
        neighbors << [nx, ny]
      end
    end
    neighbors
  end

  def reconstruct_path(came_from, current)
    path = [current]
    while came_from.key?(current)
      current = came_from[current]
      path.unshift(current)
    end
    path
  end
end

def find_short_path(start_x, start_y, goal_x, goal_y, max_steps = 5)
  pathfinder = AStarPathfinder.new($game_map.map_id)
  full_path = pathfinder.find_path(start_x, start_y, goal_x, goal_y)
  return nil if full_path.nil? || full_path.empty?

  # Exclude the player's position from the path
  full_path.reject! { |x, y| $game_player.at_coordinate?(x, y) }

  # Return only the next `max_steps` steps
  full_path[0..max_steps]
end

def pbSetMoveRoute(event, commands, wait = false)
  return if event.nil? || !event.is_a?(Game_Event)

  # Ensure the move route has valid commands
  if commands.nil? || commands.empty?
    puts "No valid move commands for event #{event.id}"
    return
  end

  # Create a new move route
  move_route = RPG::MoveRoute.new
  move_route.repeat = false  # Don't repeat the move route
  move_route.skippable = true  # Don't allow skipping
  move_route.list = commands

  # Set the move route for the event
  event.force_move_route(move_route)

  # Wait for the move route to complete if specified
  #Fiber.yield while event.move_route_forcing if wait
end

def pbPathToMoveCommands(path)
  commands = []
  return commands if path.nil? || path.size < 2

  (0...path.size - 1).each do |i|
    current_x, current_y = path[i]
    next_x, next_y = path[i + 1]

    if next_x > current_x
      commands.push(RPG::MoveCommand.new(6))  # Move right
    elsif next_x < current_x
      commands.push(RPG::MoveCommand.new(4))  # Move left
    elsif next_y > current_y
      commands.push(RPG::MoveCommand.new(2))  # Move down
    elsif next_y < current_y
      commands.push(RPG::MoveCommand.new(8))  # Move up
    end
  end

  # Add a "Wait" command at the end to prevent the NPC from moving too fast
  commands.push(RPG::MoveCommand.new(15, [10]))  # Wait for 10 frames

  commands
end

#===============================================================================
#  NPC Movement Control
#===============================================================================
def pbMoveNPCToDoor(npc_event, door_x, door_y)
  return if npc_event.nil? || !npc_event.is_a?(Game_Event)

  # Get the NPC's current position
  current_x = npc_event.x
  current_y = npc_event.y

  # If the NPC is already at the door, make them disappear
  if current_x == door_x && current_y == door_y
    npc_event.erase if npc_event.exist?
    return
  end

  # Find a short path to the door (next 5 steps)
  short_path = find_short_path(current_x, current_y, door_x, door_y)

  if short_path
    # Convert the path to move commands
    move_commands = pbPathToMoveCommands(short_path)

    # Create a new move route
    move_route = RPG::MoveRoute.new
    move_route.repeat = false  # Don't repeat the move route
    move_route.skippable = false  # Allow skipping
    move_route.list = move_commands

    # Set the move route for the NPC
    npc_event.force_move_route(move_route)
  else
    puts "No path found for NPC #{npc_event.id} to the door."
  end
end

#===============================================================================
#  Parallel Process Update Loop
#===============================================================================
def pbUpdateNPCMovements
  # Define the door position
  door_x = 26
  door_y = 27

  # Get all NPC events
  npc_events = $game_map.events.values.select { |e| e.name.downcase == "npc" }

  # Move each NPC toward the door
  npc_events.each do |npc_event|
    unless npc_event.move_route_forcing
      pbMoveNPCToDoor(npc_event, door_x, door_y)
    end
  end
end