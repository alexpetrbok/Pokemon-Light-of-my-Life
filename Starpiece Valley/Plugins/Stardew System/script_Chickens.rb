VALID_CHICKENS = [
  # Chickens and Ducks
  :TORCHIC, :COMBUSKEN, :BLAZIKEN,        # Fried egg line
  :ROWLET, :DARTRIX, :DECIDUEYE,          # Green egg line
  :ROWLET_1, :DARTRIX_1, :DECIDUEYE_1,    # Green egg line
  :QUAXLY, :QUAXWELL, :QUAQUAVAL,         # Navy egg line
  :DUCKLETT, :SWANNA,                     # Blue egg line
  :PIDOVE, :TRANQUILL, :UNFEZANT, 	  # Plain egg line
  :PSYDUCK, :GOLDUCK,                     # Scrambled egg line
  :TYRUNT, :TYRANTRUM,                    # Stone egg line
  :GIRATINA, :GIRATINA_1,            	  # Void egg line
  
  # Bunnies
  :BUNEARY, :LOPUNNY,                     # Soft wool line
  :NIDORANfE, :NIDORINA, :NIDOQUEEN,       # Blue wool line
  :NIDORANmA, :NIDORINO, :NIDOKING,        # Purple wool line
  :SCORBUNNY, :RABOOT, :CINDERACE,        # Warm wool line
  :BUNNELBY, :DIGGERSBY,                  # Earthy wool line
  :WHISMUR, :LOUDRED, :EXPLOUD,           # Soundproof wool line
  :AZURILL, :MARILL, :AZUMARILL,          # Waterproof wool line 
  :MAGEARNA, 				  # Artificial wool line
  
  # Sheep
  :MAREEP, :FLAAFFY, :AMPHAROS,           # Yellow wool line
  :WOOLOO, :DUBWOOL,                      # Fluffy wool line
  :COTTONEE, :WHIMSICOTT,                 # Cotton wool line
  :SWIRLIX, :SLURPUFF,                    # Candy wool line
  
  # Cows and Goats
  :MILTANK,                               # Moo moo milk
  :SKIDDO, :GOGOAT,                       # Go go milk line
  :HAPPINY, :CHANSEY, :BLISSEY,		  # Softboiled Egg line
  :EXEGGCUTE, :EXEGGUTOR, :EXEGGUTOR_1,   # Coconut milk line
  
  # Pigs
  :SPOINK, :GRUMPIG,                      # Magic truffles line
  :TEPIG, :PIGNITE, :EMBOAR,              # Spicy truffles line
  :LECHONK, :OINKOLOGNE,                  # Tasty truffles line
  :SWINUB, :PILOSWINE, :MAMOSWINE         # Frozen truffles line
]


EVO_LINES = {
  # Chickens/Ducks
  :TORCHIC => [:FRIEDEGG, :Sunny, :Summer],
  :ROWLET => [:GREENEGG, :Clear, :Spring],
  :ROWLET_1 => [:GREENEGG, :Fog, :Fall], # Hisuian
  :QUAXLY => [:NAVYEGG, :Rain, :Spring],
  :DUCKLETT => [:BLUEEGG, :Rain, :Summer],
  :PIDOVE => [:PLAINEGG, :Clear, :Spring],
  :PSYDUCK => [:SCRAMBLEDEGG, :Rain, :Spring],
  :TYRUNT => [:STONEEGG, :Sunny, :Summer],
  :GIRATINA => [:VOIDEGG, :Fog, :Fall],
  
  # Bunnies
  :BUNEARY => [:SOFTWOOL, :Clear, :Spring],
  :NIDORANfE => [:BLUEWOOL, :Clear, :Summer],
  :NIDORANmA => [:PURPLEWOOL, :Clear, :Summer],
  :SCORBUNNY => [:WARMWOOL, :Sunny, :Summer],
  :BUNNELBY => [:EARTHYWOOL, :Clear, :Fall],
  :WHISMUR => [:SOUNDPROOFWOOL, :Clear, :Spring],
  :AZURILL => [:WATERPROOFWOOL, :Rain, :Spring],
  :MAGEARNA => [:ARTIFICIALWOOL, :Clear, :Spring],
  
  # Sheep
  :MAREEP => [:YELLOWWOOL, :Rain, :Spring],
  :WOOLOO => [:FLUFFYWOOL, :Clear, :Spring],
  :COTTONEE => [:COTTONWOOL, :Sunny, :Summer],
  :SWIRLIX => [:CANDYWOOL, :Clear, :Spring],
  
  # Cows/Goats
  :MILTANK => [:MOOMOOMILK, :Clear, :Summer],
  :SKIDDO => [:GOGOMILK, :Clear, :Spring],
  :HAPPINY => [:SOFTBOILEDEGG, :Clear, :Spring],
  :EXEGGCUTE => [:COCONUTMILK, :Sunny, :Summer],
  
  # Pigs
  :SPOINK => [:MAGICTRUFFLE, :Clear, :Spring],
  :TEPIG => [:SPICYTRUFFLE, :Sunny, :Summer],
  :LECHONK => [:TASTYTRUFFLE, :Clear, :Fall],
  :SWINUB => [:FROZENTRUFFLE, :Snow, :Winter]
}


# Helper method to get data for any Pokémon in an evolution line
def self.get_chicken_data(species)
  if GameData::Chicken::DATA.has_key?(species)
    return GameData::Chicken::DATA[species]
  end
  
  # Check if it's an evolution of a base form
  GameData::Chicken::DATA.each do |base_species, data|
    evolutions = GameData::Species.get(base_species).evolutions
    next unless evolutions
    evolutions.each do |evo|
      if species == evo[:species]
        return data
      end
    end
  end
  
  # Default if not found
  return [:PLAINEGG, :Clear, :Spring]
end


#===============================================================================
# Chicken Data and Functions
#===============================================================================
class ChickenData
  attr_accessor :species, :hunger, :happiness,:egg_count, :event_id
  attr_accessor :interacted_today, :went_outside, :egg_flag, :shiny
  attr_accessor :pokemon 

  def initialize(pkmn, event_id)
    @pokemon = pkmn
    @species = pkmn.species
    @shiny = pkmn.shiny?
    @happiness = pkmn.happiness || 70 # Use existing happiness if available
    @event_id = event_id
    @hunger = 100
    @egg_count = 0
    @interacted_today = false
    @went_outside = 0
    @egg_flag = false
  end

  def sprite_name
    prefix = @shiny ? "Followers Shiny/" : "Followers/"
    "#{prefix}#{@species.to_s}"
  end

  def update_hunger
    if @is_outside
      @hunger = 100 # Outdoor chickens always full
    else
      @hunger -= 20 # Indoor chickens lose hunger
      @hunger = [@hunger, 0].max
    end
  end

  def feed
    if $feed_count > 0
      @hunger = 100
      $feed_count -= 1
    else
      pbMessage("The auto-feeder is empty!")
    end
  end

  def produce_eggs
    return if @hunger <= 0
    @eggs_ready = 0
    # Base 50% chance for 1 egg
    @eggs_ready += 1 if rand(100) < 50
    # happiness bonus (+10% per 25 points)
    @eggs_ready += 1 if rand(100) < (@happiness / 25 * 10)
    # Season/weather bonus (+20% if conditions match)
    season = pbGetSeason
    weather = $game_screen.weather_type
    chicken_data = GameData::Chicken.get(@species)
    @eggs_ready += 1 if rand(100) < 75 && (chicken_data.season_pref == season || chicken_data.season_pref == :All)
    @eggs_ready += 1 if rand(100) < 75 && chicken_data.weather_pref == weather
    @eggs_ready = [@eggs_ready, 3].min
  end

  def daily_interaction(slot)# Daily interaction
    chicken = ChickenSlotManager.slots[slot]
    unless chicken.interacted_today
      chicken.happiness = [chicken.happiness + 10, 255].min
      chicken.interacted_today = true
      pbMessage("#{chicken.species} enjoyed the attention!")
    end
  end
end

#===============================================================================
# Chicken Data Compilation
#===============================================================================
module GameData
  class Chicken
    attr_reader :id, :item, :weather_pref, :season_pref


    DATA = {}
    EVOLUTION_LINES = {} # This will be populated with all evolutions

    def initialize(hash)
      @id = hash[:id]
      @item = hash[:item]
      @weather_pref = hash[:weather_pref]
      @season_pref = hash[:season_pref]
    end

    def self.load
      DATA.clear
      EVO_LINES.each do |base_species, data|
        next unless GameData::Species.exists?(base_species)
        # Register base form
        register_species(base_species, data)
        
        # Register all evolutions
        begin
          get_evolutions(base_species).each do |species|
            register_species(species, data)
          end
        rescue
          # If evolution lookup fails, just register base form
          register_species(base_species, data)
        end
      end
    end

    def self.register_species(species, data)
      return unless GameData::Species.exists?(species)
      DATA[species] = self.new({
        id: species,
        item: data[0],
        weather_pref: data[1],
        season_pref: data[2]
      })
    end


    def self.get_evolutions(species)
      species_data = GameData::Species.try_get(species)
      return [species] if species_data.nil? || !species_data.evolutions
      
      [species] + species_data.evolutions.map { |e| e[0]} #e[:species] }
    end

    def self.get(species)
      DATA[species] || self.new({
        id: species,
        item: :PLAINEGG,
        weather_pref: :Clear,
        season_pref: :Spring
      })
    end
  end
end

def pbInitializeChickenSlots
  $chicken_slots = []
  
  # Find all pbChicken events on current map
  chicken_events = $game_map.events.values.select { |e| 
    e.name.downcase.include?("pbchicken") 
  }.sort_by { |e| e.id }
  
  # Assign chickens to these events
  chicken_events.each do |event|
    species = GameData::Chicken::DATA.keys.sample
    $chicken_slots << ChickenData.new(species, event.id)
    event.character_name = "Followers/#{species.to_s.upcase}"
  end
end

def pbGetChickenBySlot(slot)
  # Ensure slot is within valid range (1-3)
  if slot < 1 || slot > 3
    pbMessage("Invalid slot number. Please use 1, 2, or 3.")
    return nil
  end

  # Get the chicken from the specified slot
  chicken = $chicken_slots[slot - 1] # Convert slot to zero-based index
  if chicken.nil?
    pbMessage("No chicken found in slot #{slot}.")
    return nil
  end

  return chicken
end

# Compile chicken data on game load
# Add to the very end of your script:
#$Events.on_start_game += proc {
#  GameData::Chicken.load
#}

# Global feed counter
$feed_count = 100

# Global chicken slots (max 3)
$chicken_slots = []

#===============================================================================
# Chicken Interaction Function
#===============================================================================
def pbChicken(slot)
  chicken = ChickenSlotManager.slots[slot]
  unless chicken
    pbMessage("This slot is empty!")
    return
  end

  if GameData::Chicken::DATA.has_key?(chicken.species)
    chicken.daily_interaction(slot) # Daily interaction
    pbCollectEggs(chicken) if chicken.egg_count > 0
  end

  loop do
    choices = [
      _INTL("Feed"),
      _INTL("Check Stats"),
      _INTL("Return to PC"),
      _INTL("Exit")
    ]
    choice = pbMessage("What to do with #{chicken.species}?", choices, -1)
    
    case choice
    when 0 # Feed
      chicken.hunger = 100
      pbMessage("#{chicken.species} happily eats the food!")
    when 1 # Check Stats
      pbCheckStats(chicken)
    when 2 # Return to PC
      pbReturnChickenToPC(slot)
      break
    else
      break
    end
  end
end

#===============================================================================
# Debug Functions 
#===============================================================================
def pbAddAllChickens
  added = 0
  box_qty = $PokemonStorage.maxPokemon(0)
  completed = true
  
  # Get all species from Chicken data (already includes evolutions)
  GameData::Chicken.each do |chicken|
    species = chicken.id
    
    # Skip if boxes are full
    if added >= Settings::NUM_STORAGE_BOXES * box_qty
      completed = false
      next
    end
    
    # Create the Pokémon
    pkmn = Pokemon.new(species, 20) # Level 20
    pkmn.happiness = 70 # Base happiness
    
    # Register in Pokédex (simplified version)
    $player.pokedex.register(species)
    $player.pokedex.set_owned(species)
    
    # Add to PC
    box = added / box_qty
    index = added % box_qty
    $PokemonStorage[box, index] = pkmn
    added += 1
  end
  
  # Feedback
  if added > 0
    pbMessage(_INTL("Added {1} chicken Pokémon to PC.", added))
    unless completed
      pbMessage(_INTL("Couldn't fit all chickens! Only {1} slots available.", 
                     Settings::NUM_STORAGE_BOXES * box_qty))
    end
  else
    pbMessage(_INTL("No chicken Pokémon were added."))
  end
end

def pbFillChickenSlots
  if GameData::Chicken::DATA.empty?
    pbMessage(_INTL("Chicken data not loaded!"))
    pbMessage(_INTL("Loaded species: #{GameData::Chicken::DATA.keys}")) # Debug output
    return
  end

  filled = 0
  ChickenSlotManager.slots.each_with_index do |slot, index|
    next if slot # Skip filled slots
    
    species = GameData::Chicken::DATA.keys.sample
    pkmn = Pokemon.new(species, 20)
    pkmn.happiness = 70 # Base happiness
    pkmn.shiny = true if (rand(100) < 10) # 10% chance to be shiny
    #pkmn.name = species.to_s # Ensure proper name
    #pkmn.happiness = rand(70..100)
    
    if ChickenSlotManager.add_pokemon(pkmn)
      chicken = ChickenSlotManager.slots[index]
      chicken.hunger = rand(50..100)
      chicken.egg_count = rand(0..3)
      filled += 1
    end
  end

  pbMessage(filled > 0 ? 
    _INTL("Filled {1} slots with random chickens.", filled) : 
    _INTL("All slots are full!"))
  $game_map.need_refresh = true
end

#===============================================================================
# Egg Functions
#===============================================================================
def pbProduceEggs
  $chicken_slots.each do |chicken|
    # Update hunger
    if chicken.went_outside >= 1
      chicken.hunger = 100 # Outdoor chickens always full
    else
      chicken.hunger -= 20 # Indoor chickens lose hunger
      chicken.hunger = [chicken.hunger, 0].max
    end

    # Produce eggs if conditions are met and egg_flag is false
    if !chicken.egg_flag && chicken.hunger > 50
      chicken.egg_count = 0
      # Base 50% chance for 1 egg
      chicken.egg_count += 1 if rand(100) < 50
      # happiness bonus (+10% per 25 points)
      chicken.egg_count += 1 if rand(100) < (chicken.happiness / 25 * 10)
      # Weather/season bonus (+20% if conditions match)
      if chicken.went_outside == 2 # Favorite weather/season
        chicken.egg_count += 1 if rand(100) < 20
      end
      chicken.egg_flag = true # Prevent continuous egg production
    end

    # Reset went_outside for the next day
    chicken.went_outside = 0
  end
  pbMessage("Eggs have been produced for all chickens!")
end

def pbCheckStats(chicken)
      status = "Species: #{chicken.species}\n"
      status += "Hunger: #{chicken.hunger}\n"
      status += "Happiness: #{chicken.happiness}\n"
      status += "Eggs Ready: #{chicken.egg_count}"
      pbMessage(status)
end

def pbCollectEggs(chicken = nil)
  if chicken
    # Collect eggs from a specific chicken
    if chicken.egg_count > 0
      item = GameData::Chicken.get(chicken.species).item
      $bag.add(item, chicken.egg_count)
      pbMessage("Collected #{chicken.egg_count} #{GameData::Item.get(item).name} from #{chicken.species}!")
      chicken.egg_count = 0 # Reset egg count
      chicken.egg_flag = false # Reset egg flag
    else
      pbMessage("No eggs to collect from #{chicken.species}.")
    end
  else
    # Collect eggs from all chickens
    total_eggs = 0
    $chicken_slots.each do |chicken|
      if chicken.egg_count > 0
        item = GameData::Chicken.get(chicken.species).item
        $bag.add(item, chicken.egg_count)
        total_eggs += chicken.egg_count
        chicken.egg_count = 0 # Reset egg count
        chicken.egg_flag = false # Reset egg flag
      end
    end
    if total_eggs > 0
      pbMessage("Collected #{total_eggs} eggs from all chickens!")
    else
      pbMessage("No eggs to collect.")
    end
  end
end

def pbUpdateChickenOutsideStatus
  $chicken_slots.each do |chicken|
    chicken_data = GameData::Chicken.get(chicken.species)
    season = pbGetSeason
    weather = $game_screen.weather_type

    if chicken_data.season_pref == season || chicken_data.season_pref == :All
      if chicken_data.weather_pref == weather
        chicken.went_outside = 2 # Favorite weather/season
      else
        chicken.went_outside = 1 # Went outside, but not favorite weather/season
      end
    else
      chicken.went_outside = 0 # Stayed inside
    end
  end
end

#===============================================================================
# Chicken Slot System with Event Spawning
#===============================================================================
module ChickenSlotManager
  INITIAL_SLOTS = 3
  BASE_EVENT_ID = 400

  @slots = Array.new(INITIAL_SLOTS) { nil }
  @unlocked_slots = []

  def self.slots
    @slots
  end

  def self.max_slots
    INITIAL_SLOTS + @unlocked_slots.size
  end

  def self.full?
    @slots.none?(&:nil?)
  end

  def self.add_pokemon(pkmn)
    empty_idx = @slots.index(nil)
    return false if empty_idx.nil?
   
    @slots[empty_idx] = ChickenData.new(pkmn, BASE_EVENT_ID + empty_idx)
    spawn_chicken_event(empty_idx, pkmn)
    return empty_idx
  end

  def self.spawn_chicken_event(slot_idx, pkmn)
    chicken_data = @slots[slot_idx]
    event_id = BASE_EVENT_ID + slot_idx
    x, y = get_chicken_coordinates(slot_idx)
    
    sprite_path = chicken_data.sprite_name
   
    if $game_map.events[event_id]
      event = $game_map.events[event_id]
      event.character_name = sprite_path
    else
      pbSpawnEvent(
        event_id,
        x, y,
        sprite_path,
        "pbChicken(#{slot_idx})",
        "Chicken_#{slot_idx}",
        1
      )
    end

    event = $game_map.events[event_id]
    event.character_name = sprite_path
    event.refresh

    $PokemonGlobal.dynamic_event_ids << event_id
    pbForceMapRefresh
  end

  def self.get_chicken_coordinates(slot_idx, indoor=false)
    # Replace with your actual coordinate system
    if indoor
      # Indoor coop positions
      case slot_idx
      when 0 then [57, 26]
      when 1 then [59, 26]
      when 2 then [58, 27]
      else [55 + (slot_idx * 3), 33]
      end
    else
      # Outdoor pasture positions
      case slot_idx
      when 0 then [57, 26]
      when 1 then [59, 26]
      when 2 then [58, 27]
      else [55 + (slot_idx * 4), 33]
      end
    end
  end

  def self.unlock_slot
    new_slot_id = max_slots
    @unlocked_slots << new_slot_id
    @slots.push(nil)
    return new_slot_id
  end
end

#===============================================================================
# Chicken Interaction
#===============================================================================
def pbChickenInteraction(slot_idx)
  chicken = ChickenSlotManager.slots[slot_idx]
  return pbMessage("This slot is empty!") if !chicken

  loop do
    choices = [
      _INTL("Check Stats"),
      _INTL("Collect Items"),
      _INTL("Return to PC"),
      _INTL("Cancel")
    ]
    choice = pbMessage(_INTL("What to do with {1}?", chicken.name), choices, -1)
    case choice
    when 0 then pbChickenStats(chicken)
    when 1 then pbCollectEggs(chicken)
    when 2 then pbReturnChickenToPC(slot_idx)
    else break
    end
  end
end


#===============================================================================
# PC Assignment UI
#===============================================================================
def pbAssignChickenFromPC
  if ChickenSlotManager.full?
    pbMessage("All chicken slots are full!")
    return false
  end

  pbFadeOutIn {
    scene = PokemonStorageScene.new
    screen = PokemonStorageScreen.new(scene, $PokemonStorage)
    ret = screen.pbChoosePokemon(
      proc { |pkmn| 
        next true # Allow selecting any Pokémon
      }
    ) 
    
    if ret
      box, index = ret
      pkmn = $PokemonStorage[box, index]
      if pkmn
        slot_idx = ChickenSlotManager.add_pokemon(pkmn)
        if slot_idx
          $PokemonStorage.pbDelete(box, index)
          if GameData::Chicken::DATA.has_key?(pkmn.species)
            pbMessage(_INTL("{1} was assigned to Chicken Slot {2}!", pkmn.name, slot_idx + 1))
          else
            pbMessage(_INTL("{1} was placed in slot {2} (won't produce items).", pkmn.name, slot_idx + 1))
          end
          return true
        end
      end
    end
  }
  return false
end

def pbChoosePokemonFromPC(filter_proc)
  scene = PokemonStorageScene.new
  screen = PokemonStorageScreen.new(scene, $PokemonStorage)
  screen.pbStartScreen(filter_proc)
end

def pbReturnChickenToPC(slot_idx)
  chicken_data = ChickenSlotManager.slots[slot_idx]
  return unless chicken_data
  
  pkmn = chicken_data.pokemon
  if pkmn
  
    $player.pokedex.set_seen(pkmn.species)
    $player.pokedex.set_owned(pkmn.species)
    if $PokemonStorage.pbStoreCaught(pkmn)
      pbMessage(_INTL("{1} was returned to PC.", pkmn.name))
      # Clean up slot
      ChickenSlotManager.slots[slot_idx] = nil
      $game_map.need_refresh = true
      pbEraseThisEvent
    else
      pbMessage(_INTL("No space in PC to return {1}!", pkmn.name))
      return
    end
  else
    pbMessage(_INTL("Empty Pokemon was Deleted."))
    # Clean up slot
    ChickenSlotManager.slots[slot_idx] = nil
    $game_map.need_refresh = true
    pbEraseThisEvent
  end

end