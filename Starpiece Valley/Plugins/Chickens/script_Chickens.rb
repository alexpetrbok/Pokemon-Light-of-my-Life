#===============================================================================
# Chicken Data and Functions
#===============================================================================
class ChickenData
  attr_accessor :species, :hunger, :affection, :eggs_ready, :event_id
  attr_accessor :days_since_last_interaction, :daily_affection_change 
  attr_accessor :egg_count, :went_outside, :egg_flag

  def initialize(species, event_id)
    @species = species
    @event_id = event_id
    @hunger = 100
    @affection = 70
    @days_since_last_interaction = 0
    @daily_affection_change = 0
    @egg_count = 0
    @went_outside = 0
    @egg_flag = false
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
      @affection += 10
    else
      pbMessage("The auto-feeder is empty!")
    end
  end

  def produce_eggs
    return if @hunger <= 0
    @eggs_ready = 0
    # Base 50% chance for 1 egg
    @eggs_ready += 1 if rand(100) < 50
    # Affection bonus (+10% per 25 points)
    @eggs_ready += 1 if rand(100) < (@affection / 25 * 10)
    # Season/weather bonus (+20% if conditions match)
    season = pbGetSeason
    weather = $game_screen.weather_type
    chicken_data = GameData::Chicken.get(@species)
    @eggs_ready += 1 if rand(100) < 20 && (chicken_data.season_pref == season || chicken_data.season_pref == :All)
    @eggs_ready += 1 if rand(100) < 20 && chicken_data.weather_pref == weather
    @eggs_ready = [@eggs_ready, 3].min
  end
end

#===============================================================================
# Chicken Data Compilation
#===============================================================================
module GameData
  class Chicken
    attr_reader :id, :item, :weather_pref, :season_pref

    DATA = {}

    def initialize(hash)
      @id = hash[:id]
      @item = hash[:item]
      @weather_pref = hash[:weather_pref]
      @season_pref = hash[:season_pref]
    end

    def self.load
      DATA.clear
      # Read from PBS/chickens.txt
      File.open("PBS/chickens.txt", "rb") do |f|
        f.each_line do |line|
          next if line.strip.empty?
          species, item, weather_pref, season_pref = line.strip.split(",")
          DATA[species.to_sym] = self.new({
            id: species.to_sym,
            item: item.to_sym,
            weather_pref: weather_pref.to_sym,
            season_pref: season_pref.to_sym
          })
        end
      end
    end

    def self.get(species)
      return DATA[species] if DATA.has_key?(species)
      raise "Unknown chicken species: #{species}"
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
GameData::Chicken.load

# Global feed counter
$feed_count = 100

# Global chicken slots (max 3)
$chicken_slots = []

#===============================================================================
# Chicken Interaction Function
#===============================================================================
def pbChicken
  interp = pbMapInterpreter
  this_event = interp.get_self
  chicken_data = $chicken_slots.find { |chicken| chicken.event_id == this_event.id }

  unless chicken_data
    pbMessage("Error: No chicken assigned to this event!")
    return
  end

  # Collect eggs
  if chicken_data.egg_count > 0
    pbCollectEggs(chicken_data)
  end

  # Interaction menu
  choices = [
    _INTL("Feed"),
    _INTL("Pet"),
    _INTL("Check Stats"),
    _INTL("Exit")
  ]
  loop do
    choice = pbMessage("What to do with the #{chicken_data.species}?", choices, -1)
    case choice
    when 0 # Feed
      chicken_data.hunger = 100
      chicken_data.affection += 5
      pbMessage("#{chicken_data.species} looks happy!")
    when 1 # Pet
      chicken_data.affection += 10
      pbMessage("#{chicken_data.species} loves the attention!")
    when 2 # Check Stats
      status = "Species: #{chicken_data.species}\n"
      status += "Hunger: #{chicken_data.hunger}\n"
      status += "Affection: #{chicken_data.affection}\n"
      status += "Eggs Ready: #{chicken_data.egg_count}"
      pbMessage(status)
    else
      break
    end
  end
end

#===============================================================================
# Debug Functions 
#===============================================================================
def pbUpdateChickenSprites
  $chicken_slots.each do |chicken|
    event = $game_map.events[chicken.event_id]
    next unless event
    event.character_name = "Followers/#{chicken.species.to_s.upcase}"
  end
  pbMessage("Sprites forcefully updated!")
end

def pbAddChickens
  # Clear existing assignments
  $chicken_slots.clear
  
  # Reassign all chickens
  pbInitializeChickenSlots
  pbMessage("Chickens reassigned to all pbChicken events!")
end

#===============================================================================
# Egg Production Function
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
      # Affection bonus (+10% per 25 points)
      chicken.egg_count += 1 if rand(100) < (chicken.affection / 25 * 10)
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

#===============================================================================
# Egg Collection Function
#===============================================================================
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