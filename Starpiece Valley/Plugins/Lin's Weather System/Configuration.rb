#===============================================================================
# * Weather System Configuration
#===============================================================================

module WeatherConfig
  # Set to false to use the Weather System.
  NO_WEATHER = false		# Default: false

  # Set to true to show the weather on the Town Map.
  SHOW_WEATHER_ON_MAP = true	# Default: true

  # Set to true to use the computer's time. Will not work without Unreal Time System.
  USE_REAL_TIME = true		# Default: true

  # Set to true to have the weather change at midnight.
  CHANGE_MIDNIGHT = false	# Default: true

  # Define the min and max amount of time (in hours) before the weather changes.
  # Set the same number to not randomize the amount of time before the weather changes.
  CHANGE_TIME_MIN = 8		# Default: 1
  CHANGE_TIME_MAX = 12		# Default: 4

  # Set to true to if you want to force the weather to change when interacting with certain events.
  # Use pbForceUpdateWeather in an event to update all zone weathers.
  # Use pbForceUpdateZoneWeather(zone) in an event to update the weather of a zone.
  FORCE_UPDATE = true		# Default: false

  # Set to true to have the outdoor maps change with seasons.
  # The map's appearance will update when leaving an indoor map.
  SEASON_CHANGE = true		# Default: false

  # Set to true if your game starts outdoors and want to show the season splash when going somewhere indoors.
  # Set to false if your game starts indoors and want to show the season splash when going somewhere outdoors.
  OUTDOOR = false		# Default: false

  # Array with the ID of outside tilesets that will change with seasons.
  OUTDOOR_TILESETS = [25]#[33, 42, 43, 48, 76, 77, 78, 79, 80, 81]

  # The difference between the ID of the tileset defined for an outdoor map and it's season version.
  # The difference has to be the same for any tileset defined in OUTDOOR_TILESETS.
  # Use the same season tileset as the default outdoor map tileset and define the diference for that season as 0.
  SPRING_TILESET = 0
  SUMMER_TILESET = 1
  AUTUMN_TILESET = 2
  WINTER_TILESET = 3


#===============================================================================
# * Weather Substitute
#===============================================================================
  # A hash with the ID of the maps that will have or not have certain weathers.
  # The ID of the weather has to be of the main one you want to change with WEATHER_SUBSTITUTE.
  # Use "exclude" to define a list of maps that will not use that weather when it's the main one.
  #     Any maps of a zone not added on the "exclude" list will use the main weather.
  # Use "include" to define a list of maps that will use that weather when it's the main one.
  #     Any maps of a zone not added on the "include" list will use the secondary weather.
  MAPS_SUBSTITUTE = {
	:Snow => ["exclude", 1, 4],
	:Blizzard => ["exclude", 1, 4],
    :Sandstorm => ["include", 5]
  }

  # The ID of the weathers that will substitute the main when appropiate (conditions defined in MAPS_SUBSTITUTE).
  # There has to be a hash (defined between {}) for each defined zone with weather to substitute.
  # Any weather not defined in the hash for a zone will use the main weather instead.
  WEATHER_SUBSTITUTE = [
	{:None => :None, :Rain => :Rain, :Storm => :Storm, :Snow => :Rain, :Blizzard => :Storm, :Sandstorm => :None, :HeavyRain => :HeavyRain, :Sun => :Sun, :Fog => :Fog},
	{:Snow => :Rain, :Blizzard => :Storm, :Sandstorm => :None},
	{:Snow => :Rain, :Blizzard => :HeavyRain}
  ]

#===============================================================================
# * Weather Names
#===============================================================================
  # A hash that contains the ID of weather and the name to display for each one.
  # Using .downcase will make them lowercase.
  def self.weather_names
    return {
	  :None			=> _INTL("None"),
	  :Rain			=> _INTL("Rain"),
	  :Storm		=> _INTL("Storm"),
	  :Snow			=> _INTL("Snow"),
	  :Blizzard		=> _INTL("Blizzard"),
	  :Sandstorm	=> _INTL("Sandstorm"),
	  :HeavyRain	=> _INTL("Heavy rain"),
	  :Sun			=> _INTL("Sun"),
	  :Fog			=> _INTL("Fog")
    }
  end
#===============================================================================
# * Zones Configuration
#===============================================================================
  # Arrays of id of the maps of each zone. Each array within the main array is a zone.
  # The maps within each zone will have the same weather at the same time.
  # Each zone may have a different weather than the others.
  ZONE_MAPS = [
    [42, 43, 77, 79],  # Zone 1: Farm, Lake, Swamp, Bug Meadows
    [48, 78, 76],       # Zone 2: Town, Lab, River Estuary
    [80, 81]            # Zone 3: Mountain Path, Mines
  ]
#===============================================================================
# * Map Display
#===============================================================================
  # Array of hashes to get each map's position in the Town Map. Each hash corresponds to a zone in ZONE_MAPS.
  # In "Map Name" you have to put the name the Town Map displays for that point.
  # In Map ID you have to put the ID of the map the name corresponds to, like in ZONE_MAPS.
  MAPS_POSITIONS = [
    #{"Map Name" => Map ID},
    {"Lappet Town" => 2, "Route 1" => 5},
    {"Cedolan City" => 7},
    {"Route 2" => 21}
  ]

  # A hash for the plugin to display the proper weather image on the map.
  # They have to be on Graphics/Pictures/Weather (in 20+) or Graphics/UI/Weather (in 21+).
  WEATHER_IMAGE = {
    :Rain => "mapRain",
    :Storm => "mapStorm",
    :Snow => "mapSnow",
    :Blizzard => "mapBlizzard",
    :Sandstorm => "mapSand",
    :HeavyRain => "mapRain",
    :Sun => "mapSun",
    :Fog => "mapFog"
  }
#===============================================================================
# * Season Probability Configuration
#===============================================================================
  # Arrays of probability of weather for each zone in the different seasons.
  # Each array within the main array corresponds to a zone in ZONE_MAPS.
  # Put 0 to weather you don't want if you define a probability after it.
  # If your game doesn't use seasons, edit the probabilities of one season and copy it to the others.

  # Probability of weather in spring.
  # Order: None, Rain, Storm, Snow, Blizzard, Sandstorm, HeavyRain, Sun/Sunny, Fog
  ZONE_WEATHER_SPRING = [
    [30, 40, 5, 0, 0, 0, 10, 15, 0],  # Zone 1
    [20, 30, 10, 0, 0, 0, 5, 20, 15],  # Zone 2
    [20, 20, 10, 10, 0, 0, 5, 15, 20]  # Zone 3
  ]

  # Probability of weather in summer.
  # Order: None, Rain, Storm, Snow, Blizzard, Sandstorm, HeavyRain, Sun/Sunny, Fog
  ZONE_WEATHER_SUMMER = [
    [20, 30, 10, 0, 0, 0, 5, 35, 0],   # Zone 1
    [10, 20, 20, 0, 0, 0, 10, 30, 10], # Zone 2
    [10, 10, 20, 0, 0, 0, 10, 40, 10]  # Zone 3
  ]

  # Probability of weather in autumn.
  # Order: None, Rain, Storm, Snow, Blizzard, Sandstorm, HeavyRain, Sun/Sunny, Fog
  ZONE_WEATHER_AUTUMN = [
    [40, 20, 5, 0, 0, 0, 5, 10, 20],   # Zone 1
    [30, 20, 10, 0, 0, 0, 5, 15, 20],  # Zone 2
    [20, 10, 10, 10, 0, 0, 5, 15, 30]  # Zone 3
  ]

  # Probability of weather in winter.
  # Order: None, Rain, Storm, Snow, Blizzard, Sandstorm, HeavyRain, Sun/Sunny, Fog
  ZONE_WEATHER_WINTER = [
    [30, 10, 0, 30, 5, 0, 0, 10, 15],  # Zone 1
    [20, 10, 5, 20, 0, 0, 0, 10, 35],  # Zone 2
    [10, 5, 0, 40, 20, 0, 0, 5, 20]    # Zone 3
  ]
end