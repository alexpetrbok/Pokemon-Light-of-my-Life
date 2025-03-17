#===============================================================================
#  NPC Data Setup
#===============================================================================
module GameData
  class NPC
    attr_reader :id, :name, :portrait, :gifts, :opener, :chat, :closer, :schedule, :sprite
    DATA = {}
    DATA_FILENAME = "npcs.dat"
    PBS_FILENAME = "npcs.txt"

    def initialize(hash)
      @id = hash[:id]
      @name = hash[:name]
      @portrait = hash[:portrait]
      @sprite = hash[:sprite]
      @gifts = hash[:gifts] || {}  # Hash of gift items and their affection values
      @opener = hash[:opener] || []
      @chat = hash[:chat] || []
      @closer = hash[:closer] || []
      @schedule = hash[:schedule] || {}  # Schedule data (day/time-based)
    end

    def self.register(hash)
      npc = self.new(hash)
      DATA[npc.id] = npc
    end

    def self.try_get(npc_id)
      return DATA[npc_id]
    end

    # Compile data from PBS/npcs.txt
    def self.compile
      data = []
      pbs_path = "PBS/#{PBS_FILENAME}"
      if FileTest.exist?(pbs_path)
        File.open(pbs_path, "rb") do |f|
          file_data = f.read
          # Parse the file as a Ruby array of hashes
          eval(file_data).each do |npc_hash|
            data.push(npc_hash)
          end
        end
      else
        raise "PBS file not found: #{pbs_path}"
      end
      save_data(data, "Data/#{DATA_FILENAME}")
    end

    # Load data from Data/npcs.dat
    def self.load
      if FileTest.exist?("Data/#{DATA_FILENAME}")
        @data = load_data("Data/#{DATA_FILENAME}")
        @data.each { |npc| register(npc) }
      else
        compile  # Automatically compile if data file doesn't exist
      end
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
def pbSetupNPCEvents
  # Get all events named "NPC" on the current map
  events = $game_map.events.values
  npc_events = events.select { |e| e.name.downcase == "npc" }

  # Sort NPC events by their ID (lowest to highest)
  npc_events.sort_by! { |e| e.id }

  # Get all NPCs from GameData::NPC
  npcs = GameData::NPC::DATA.values
  npcs.sort_by! { |npc| npc.id.to_s }

  # Assign NPCs to events in order
  $npc_event_to_id = {}  # Global hash to map event IDs to NPC IDs
  npc_events.each_with_index do |event, index|
    npc = npcs[index]
    if npc
      # Set event properties
      event.character_name = npc.sprite if npc.sprite
      #event.move_type = (npc.schedule.empty?) ? 1 : 0 # Stationary if no schedule

      # Map event ID to NPC ID
      $npc_event_to_id[event.id] = npc.id

      # Turn on self-switch A to make the NPC visible
      $game_self_switches[[$game_map.map_id, event.id, 'A']] = true
    else
      # Turn off self-switch A to hide the NPC
      $game_self_switches[[$game_map.map_id, event.id, 'A']] = false
    end
  end
  pbUpdateNPCGraphics
end


#===============================================================================
#  Update Event Graphics
#===============================================================================
def pbUpdateNPCGraphics(event_id = nil)
  if event_id
    # Update a specific event
    event = $game_map.events[event_id]
    if event && event.name.downcase == "npc"
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
    npc_events = events.select { |e| e.name.downcase == "npc" }
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
#  Map Load Hook (Using Essentials' EventHandlers)
#===============================================================================
EventHandlers.add(:on_enter_map, :setup_npc_events,
  proc { |_old_map_id|
    # Set up NPC events whenever the player enters a new map
    pbSetupNPCEvents
  }
)


#===============================================================================
#  Conversation System
#===============================================================================
class NPC_Interaction
  def initialize(npc_id)
    @npc = GameData::NPC.try_get(npc_id)
    @data = $PokemonGlobal.npc_data[npc_id] ||= { affection: 0, gifts_received: [] }
  end

  def start
    return unless @npc
    show_portrait
    pbMessage(_INTL("#{@npc.name}: #{select_opener}"))
    handle_chat_options
    pbMessage(_INTL("#{@npc.name}: #{select_closer}"))
    Rf.close_portrait  # Close the portrait after the conversation
  end

  private

  def show_portrait
    Rf.new_portrait(@npc.portrait)  # Open the NPC's portrait
  end

  def select_opener
    (@npc.opener.sample || "Hello!").gsub("{1}", "\\PN")
  end

  def select_closer
    (@npc.closer.sample || "Goodbye!").gsub("{1}", "\\PN")
  end

  def handle_chat_options
    commands = []
    @npc.chat.each { |c| commands.push(c[:prompt]) }
    commands.push("Exit")
    
    loop do
      choice = pbShowCommands(nil, commands, -1)
      break if choice == commands.length - 1
      
      response = @npc.chat[choice][:response].gsub("{1}", "\\PN")
      pbMessage(_INTL("#{@npc.name}: #{response}"))
      update_affection(choice)
    end
  end

  def update_affection(choice)
    @data[:affection] += @npc.chat[choice][:affection] || 0
    @data[:affection] = [@data[:affection], 100].min
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