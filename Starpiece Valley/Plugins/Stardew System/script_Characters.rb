#===============================================================================
#  NPC Data Setup
#===============================================================================

module GameData
  class NPC
    attr_reader :id, :name, :portrait, :sprite, :gifts, :dialog, :schedule
    DATA = {}
    DATA_FILENAME = "npcs.dat"
    PBS_FILENAME = "npcs.txt"

    def initialize(hash)
      @id = hash[:id]
      @name = hash[:name] || "Unnamed"
      @portrait = hash[:portrait]|| "???"
      @sprite = hash[:sprite]
      @gifts = hash[:gifts] || []  # Hash of gift items and their affection values
      dialog_data = hash[:dialog] || {}
      @dialog = {
        opener: dialog_data[:opener] || [],
        chat: dialog_data[:chat] || [],
        closer: dialog_data[:closer] || [],
        forms: dialog_data[:forms] || {}
      }
      @schedule = hash[:schedule] || {}  # Schedule data (day/time-based)
    end

    def self.register(hash)
      npc = self.new(hash)
      DATA[npc.id] = npc
    end

    def self.try_get(npc_id)
      return DATA[npc_id]
    end

    def self.each(&block)
      DATA.values.each(&block)
    end

    def self.compile
      npc_data = {}
      current_npc = nil
      current_section = nil
      current_form = :base

      File.open("PBS/npcs.txt", "rb") do |f|
        f.each_line do |line|
          line = line.chomp
          next if line.empty? || line.start_with?('#')

          # Section headers
          if line.start_with?('[')
            line = line[1..-2] # Remove brackets
            case line
            when /^NPC:(\w+)/
              current_npc = $1.to_sym
              npc_data[current_npc] = {
                id: current_npc,
                name: "",
                portrait: "",
                sprite: "",
                gifts: [],
                dialog: {
                  opener: [],
                  chat: [],
                  closer: [],
                  forms: {}
                }
              }
              current_section = nil
              current_form = :base
            when 'DIALOGUE'
              current_section = :dialogue
            when /^FORM:(\w+)/
              current_form = $1.to_sym
              npc_data[current_npc][:dialog][:forms][current_form] ||= {
                portrait: nil, # Form-specific portrait (optional)
                opener: [],
                chat: [],
                closer: []
              }
              current_section = :dialogue
            end
            next
          end

          next unless current_npc # Skip if no NPC defined

          # Property lines (outside DIALOGUE sections)
          if current_section != :dialogue && line.include?('=')
            key, value = line.split('=', 2).map(&:strip)
            case key.downcase
            when 'name'
              npc_data[current_npc][:name] = value
            when 'portrait'
              if current_form == :base
                npc_data[current_npc][:portrait] = value
              else
                npc_data[current_npc][:dialog][:forms][current_form][:portrait] = value
              end
            when 'sprite'
              npc_data[current_npc][:sprite] = value
            when 'favoritegifts'
              gifts = value.split(',')
              gifts = gifts.map { |g| g.strip.upcase }
              gifts.reject! { |g| g.empty? || g == '}' }
              npc_data[current_npc][:gifts] = gifts
            end
          # Dialogue lines
          elsif current_section == :dialogue
            target = current_form == :base ? npc_data[current_npc][:dialog] : npc_data[current_npc][:dialog][:forms][current_form]
            
            if line.start_with?('Open')
              target[:opener] << line.split('=', 2).last.strip.gsub('/PN', '{1}')
            elsif line.start_with?('Close')
              target[:closer] << line.split('=', 2).last.strip.gsub('/PN', '{1}')
            else # Chat line
              parts = line.split('|').map(&:strip)
              target[:chat] << {
                prompt: parts[0].split('=', 2).last,
                response: parts[1],
                affection: parts[2]&.include?('Affection=') ? parts[2].split('=').last.to_i : 0
              }
            end
          end
        end
      end

      save_data(npc_data.values, "Data/npcs.dat")
    end

    def self.parse_dialog_line(line, target_hash)
      if line.start_with?('Open')
        target_hash[:opener] << line.split('=', 2).last.strip.gsub('/PN', '{1}')
      elsif line.start_with?('Close')
        target_hash[:closer] << line.split('=', 2).last.strip.gsub('/PN', '{1}')
      else # Chat line
        parts = line.split('|').map(&:strip)
        target_hash[:chat] << {
          prompt: parts[0].split('=', 2).last,
          response: parts[1],
          affection: parts[2]&.include?('Affection=') ? parts[2].split('=').last.to_i : 0
        }
      end
    end

    def self.parse_property(key, value, npc_hash, form)
      case key.downcase
      when 'name'
        npc_hash[:name] = value
      when 'portrait'
        npc_hash[:portrait] = value
      when 'sprite'
        npc_hash[:sprite] = value
      when 'favoritegifts'
        npc_hash[:gifts] = value.split(',').map(&:strip)
      when 'conditions'
        npc_hash[:dialog][:forms][form][:conditions] = value
      end
    end

    def self.parse_schedule_line(line)
      time, rest = line.split('|', 2)
      entry = { time: time.strip.to_i }
      
      rest.split('|').each do |part|
        key, value = part.split('=', 2).map(&:strip)
        next if key.nil? || value.nil?
        
        key = key.downcase.to_sym
        entry[key] = case key
                     when :time then value.to_i
                     when :x, :y then value.to_i
                     when :map then value.to_sym
                     else value
                     end
      end
      
      entry
    end

    def self.load
      return unless safe_exists?("Data/npcs.dat")
      data = load_data("Data/npcs.dat")
      data.each do |npc|
        gifts = {}
        npc[:gifts].each { |g| gifts[g] = 5 } if npc[:gifts]

        register(
          id: npc[:id],
          name: npc[:name],
          portrait: npc[:portrait],
          sprite: npc[:sprite],
          dialog: npc[:dialog]
        )
      end
    end

    def self.safe_exists?(path)
      File.exist?(path) && !File.zero?(path)
    end
  end
end

# Load NPC data on game start
GameData::NPC.load

#===============================================================================
#  NPC Event Handler
#===============================================================================
def pbNPC
  interp = pbMapInterpreter
  event = interp.get_self

  # Initialize the NPC ID mapping if it doesn't exist
  $npc_event_to_id ||= {}

  # Get NPC ID from event's ID
  npc_id = $npc_event_to_id[event.id]
  unless npc_id
    pbMessage("No NPC assigned to this event!")
    return
  end

  # Load NPC data
  npc = GameData::NPC.try_get(npc_id)
  unless npc
    pbMessage("NPC data not found for #{npc_id}!")
    return
  end

  # Initialize NPC data if needed
  $PokemonGlobal.npc_data[npc_id] ||= { 
    affection: 0, 
    interactions: 0,
    gifts: []
  }
  data = $PokemonGlobal.npc_data[npc_id]

  # Handle interaction
  data[:interactions] += 1
  interaction = NPC_Interaction.new(npc_id)
  interaction.start
end

#===============================================================================
#  NPC Event Setup
#===============================================================================

def pbSpawnNPCs
  GameData::NPC.load if GameData::NPC::DATA.empty?
  $npc_event_to_id ||= {}  # Initialize mapping hash
  
  # Get player position as center point
  center_x = 41
  center_y = 51
  
  # Spawn NPCs in a spiral pattern around player
  spiral_pattern = [
    [1,0], [1,-1], [0,-1], [-1,-1], [-1,0], [-1,1], [0,1], [1,1]
  ]
  
  index = 0
  GameData::NPC.each do |npc|
    next unless npc.sprite && !npc.sprite.empty?
    
    # Calculate event ID (300 + index)
    event_id = 300 + index
    
    # Skip if event already exists
    next if $game_map.events[event_id]
    
    # Calculate position using spiral pattern
    spiral_x, spiral_y = spiral_pattern[index % spiral_pattern.size]
    x = center_x + spiral_x * 3  # 3 tiles apart
    y = center_y + spiral_y * 3
    
    # Find nearest passable tile
    5.times do |i|
      if $game_map.passable?(x, y, 0)
        break  # Position is good
      else
        # Try adjacent tiles
        x += [-1,1].sample
        y += [-1,1].sample
      end
    end
    
    # Spawn the NPC event
    pbSpawnEvent(
      event_id,
      x, y,
      npc.sprite,
      "pbNPC",
      npc.name
    )
    
    # Map event ID to NPC ID
    $npc_event_to_id[event_id] = npc.id
    index = index+1
  end
end

# Find nearest passable tile to target position
def find_passable_spawn(base_x, base_y, radius=5)
  # Check in expanding square pattern
  (0..radius).each do |r|
    (-r..r).each do |dx|
      (-r..r).each do |dy|     
        check_x = base_x + dx
        check_y = base_y + dy
        
        if $game_map.passable?(check_x, check_y, 0) &&
           !too_close_to_player?(check_x, check_y)
          return [check_x, check_y]
        end
      end
    end
  end
  nil
end

def pbDebugNPCData
  # Load data if needed
  GameData::NPC.load if GameData::NPC::DATA.empty?
  
  puts "===== NPC DEBUG ====="
  puts "Total NPCs: #{GameData::NPC::DATA.size}"
  puts ""
  
  GameData::NPC.each do |npc|
    puts "ID: #{npc.id}"
    puts "Name: #{npc.name}"
    
    # Sprite verification
    sprite_status = if npc.sprite
      pbResolveBitmap("Graphics/Characters/#{npc.sprite}") ? "FOUND" : "MISSING"
    else
      "NOT SET"
    end
    puts "Sprite: #{npc.sprite || 'N/A'} (#{sprite_status})"
    
    # Portrait verification
    portrait_status = if npc.portrait
      pbResolveBitmap("Graphics/Trainers/#{npc.portrait}") ? "FOUND" : "MISSING"
    else
      "NOT SET"
    end
    puts "Portrait: #{npc.portrait || 'N/A'} (#{portrait_status})"
    
    # Basic gift info
    puts "Favorite Gifts: #{npc.gifts.any? ? npc.gifts.join(', ') : 'None'}"
    
    # Simple dialog count
    puts "Dialogue: #{npc.dialog[:opener].size} openers, #{npc.dialog[:chat].size} chats"
    
    puts "------------------"
  end
end

def pbEraseAllNPCEvents
  # Get all NPC event IDs (300 + their index in GameData)
  npc_event_ids = GameData::NPC::DATA.keys.sort.map.with_index { |id, i| 300 + i + 1 }

  # Delete each NPC event from the current map
  npc_event_ids.each do |event_id|
    $game_map.events.delete(event_id)
  end

  # Refresh map to update sprites
  $game_map.need_refresh = true
end

def too_close_to_player?(x, y)
  ($game_player.x - x).abs < 8 && ($game_player.y - y).abs < 8
end

# Map setup
EventHandlers.add(:on_enter_map, :spawn_npcs, proc { pbSpawnNPCs })
EventHandlers.add(:on_leave_map, :erase_npcs, proc { pbEraseAllNPCEvents })

def pbDebugNPCSprites
  GameData::NPC.each do |npc|
    puts "#{npc.id}:"
    puts "  Sprite: #{npc.sprite || 'MISSING'}"
    puts "  Portrait: #{npc.portrait || 'MISSING'}"
    puts "  Sprite Exists: #{pbResolveBitmap("Graphics/Characters/#{npc.sprite}") ? 'YES' : 'NO'}"
    puts "  Portrait Exists: #{pbResolveBitmap("Graphics/Trainers/#{npc.portrait}") ? 'YES' : 'NO'}"
  end
end

#===============================================================================
#  Update Event Graphics
#===============================================================================
def pbUpdateNPCGraphics(event_id = nil)
  if event_id
    # Update a specific event
    event = $game_map.events[event_id]
    if event && event.name.downcase == "pbnpc"
      npc_id = $npc_event_to_id[event.id]
      if npc_id
        npc = GameData::NPC.try_get(npc_id)
        if npc && npc.sprite
          filename = "Graphics/Characters/" + npc.sprite
          if pbResolveBitmap(filename)
            event.character_name = npc.sprite
            event.refresh
          end
        end
      end
    end
  else
    # Update all NPC events on the current map
    events = $game_map.events.values
    npc_events = events.select { |e| e.id > 200 }
    npc_events.each do |event|
      npc_id = $npc_event_to_id[event.id]
      if npc_id
        npc = GameData::NPC.try_get(npc_id)
        if npc && npc.sprite
          filename = "Graphics/Characters/" + npc.sprite
          if pbResolveBitmap(filename)
            event.character_name = npc.sprite
            event.refresh
          end
        end
      end
    end
  end
end


#===============================================================================
#  Conversation System
#===============================================================================
class NPC_Interaction
  def initialize(npc_id)
    @npc = GameData::NPC.try_get(npc_id)
    @data = $PokemonGlobal.npc_data[npc_id] ||= { 
      affection: 100, 
      interactions: 0,
      gifts: []
    }
    @current_dialog = get_appropriate_dialog
  end

  def start
    return unless @npc
    Rf.new_portrait(@npc.portrait)
    pbMessage(_INTL("#{@npc.name}: #{select_opener}"))
    handle_chat_options
    pbMessage(_INTL("#{@npc.name}: #{select_closer}"))
    Rf.close_portrait  # Close the portrait after the conversation
  end

 private

  def get_appropriate_dialog
    # Check for form-specific dialog first (e.g., holidays)
    @npc.dialog[:forms].each do |form_id, form_data|
      if meets_form_conditions?(form_id)
        return form_data
      end
    end
    # Fall back to base dialog
    @npc.dialog
  end

  def meets_form_conditions?(form_id)
    case form_id
    when :holiday
      pbIsFestivalDay?
    when :rainy
      $game_screen.weather_type == :Rain
    else
      false
    end
  end

  def select_opener
    return "Hello!" if @npc.dialog[:opener].empty?
    
    opener = @npc.dialog[:opener].sample
    # Safely handle nil or malformed opener
    opener.is_a?(String) ? opener.gsub("{1}", "\\PN") : "Hello!"
  rescue
    "Hello!"
  end

  def select_closer
    return "Goodbye!" if @npc.dialog[:closer].empty?
    
    closer = @npc.dialog[:closer].sample
    closer.is_a?(String) ? closer.gsub("{1}", "\\PN") : "Goodbye!"
  rescue
    "Goodbye!"
  end

  def handle_chat_options
    return if @npc.dialog[:chat].empty?

    # Filter out invalid chat options
    valid_chats = @npc.dialog[:chat].select do |c| 
      c.is_a?(Hash) && c[:prompt] && !c[:prompt].empty?
    end
    
    commands = valid_chats.map { |c| c[:prompt] }
    commands.push("Exit")

    loop do
      choice = pbShowCommands(nil, commands, -1)
      break if choice == commands.length - 1
      
      chat = valid_chats[choice]
      response = chat[:response].to_s.gsub("{1}", "\\PN")
      pbMessage(_INTL("#{@npc.name}: #{response}"))
      update_affection(choice)
    end
  end

  def update_affection(choice)
    return unless @npc.dialog[:chat][choice].is_a?(Hash)
    
    affection_gain = @npc.dialog[:chat][choice][:affection].to_i
    @data[:affection] = [@data[:affection] + affection_gain, 100].min
  end
end

#===============================================================================
#  Global Data Handling
#===============================================================================
class PokemonGlobalMetadata
  attr_accessor :npc_data
  
  def npc_data
    @npc_data ||= {}
  end
end

#===============================================================================
#  Test Command
#===============================================================================
def pbTalkToNPC(npc_id)
  npc = GameData::NPC.try_get(npc_id)
  return if !npc
  Rf.new_portrait(npc_id)  # Use showGroup for single-NPC dialogue
  Rf.set_speaker(npc.name)
  pbMessage(_INTL("#{npc.name}: #{npc.opener.sample}"))
  Rf.close_portrait
end

#===============================================================================
#  Event Spawning System
#===============================================================================
# This script dynamically creates events on the map with a single page.
# The event's sprite, interaction script, and name are optional.
# Call pbForceMapRefresh after spawning events to ensure they are displayed.
#===============================================================================

def pbSpawnEvent(event_id, x, y, sprite = nil, script = nil, event_name = "OutdoorLight", movement_type = 3)
  # Create event object
  new_event = RPG::Event.new(x, y)
  new_event.id = event_id
  new_event.name = event_name  # Customize the event name

  # Create a single event page
  page = RPG::Event::Page.new
  page.graphic.character_name = sprite || ""  # Set the event's sprite (optional)
  page.graphic.direction = 2 # Face down by default
  page.trigger = 0 # Action button trigger
  page.move_type = movement_type
  page.move_speed = 3  # Normal speed
  page.move_frequency = 4  # High frequency

  # Add interaction command if a script is provided
  if script
    page.list = [
      RPG::EventCommand.new(355, 0, [script]), # Call the provided script
      RPG::EventCommand.new(0, 0, []) # Empty command as placeholder
    ]
  end

  # Add the page to the event
  new_event.pages = [page]

  # Create and position Game_Event
  game_event = Game_Event.new($game_map.map_id, new_event)
  game_event.moveto(x, y)

  # Add to map
  $game_map.events[event_id] = game_event

  # Refresh the event to apply changes
  $game_map.refresh
  puts "Event added to $game_map.events: #{$game_map.events.has_key?(event_id)}"
end


class PokemonGlobalMetadata
  attr_accessor :dynamic_event_ids

  def dynamic_event_ids
    @dynamic_event_ids ||= []
  end
end

def pbCreateNPCEvents
  # Get all NPCs from your data file
  npcs = GameData::NPC::DATA.values
  base_event_id = 300
  player_x = $game_player.x
  player_y = $game_player.y

  # Initialize dynamic_event_ids if it doesn't exist
  $PokemonGlobal.dynamic_event_ids ||= []

  npcs.each_with_index do |npc, index|
    # Calculate position around player (semi-circle pattern)
    angle = (index * 45) % 360  # 45 degree spacing
    x = player_x + (3 * Math.cos(angle * Math::PI / 180)).round
    y = player_y + (3 * Math.sin(angle * Math::PI / 180)).round

    # Assign NPC to event
    $npc_event_to_id ||= {}
    event_id = base_event_id + index
    $npc_event_to_id[event_id] = npc.id

    # Spawn the NPC event
    pbSpawnEvent(event_id, x, y, npc.sprite, "pbNPC", "NPC")

    # Add to global tracking
    $PokemonGlobal.dynamic_event_ids << event_id
  end

  # Refresh the map
  pbForceMapRefresh
end

def pbForceMapRefresh
  return unless $scene.is_a?(Scene_Map)
  
  # Dispose of the existing spriteset
  $scene.spriteset.dispose if $scene.spriteset

  # Create a new spriteset
  $scene.createSpritesets
end

EventHandlers.add(:on_leave_map, :remove_dynamic_npcs,
  proc { |_new_map_id|
    # Check if dynamic_event_ids exists and is not empty
    next if !$PokemonGlobal.dynamic_event_ids || $PokemonGlobal.dynamic_event_ids.empty?

    # Remove all dynamically created events
    $PokemonGlobal.dynamic_event_ids.each do |event_id|
      $game_map.events.delete(event_id)
    end

    # Clear the list of dynamic event IDs
    $PokemonGlobal.dynamic_event_ids.clear
  }
)