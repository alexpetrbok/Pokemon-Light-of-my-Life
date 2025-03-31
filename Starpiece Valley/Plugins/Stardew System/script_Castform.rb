def pbCastformDebugTool
  # Main menu options
  options = [
    _INTL("Change Weather"),
    _INTL("Force Forecast Update"),
    _INTL("Change Season"),
    _INTL("Exit")
  ]
  
  loop do
    # Show the menu
    choice = pbShowCommands(nil, options, -1)
    break if choice == 3  # Exit

    case choice
    when 0  # Change Weather
      # List of weather options
      weather_options = [
        _INTL("Clear"),
        _INTL("Rain"),
        _INTL("Storm"),
        _INTL("Snow"),
        _INTL("Blizzard"),
        _INTL("Sandstorm"),
        _INTL("Heavy Rain"),
        _INTL("Sunny"),
        _INTL("Fog")
      ]
      # Ask the player to choose a weather type
      weather_choice = pbShowCommands(nil, weather_options, -1)
      if weather_choice >= 0
        # Map the choice to a weather symbol
        weather = [
          :None, :Rain, :Storm, :Snow, :Blizzard, :Sandstorm, :HeavyRain, :Sun, :Fog
        ][weather_choice]
        # Force the weather to change
        pbForceUpdateWeather
        pbMessage(_INTL("The weather has been changed to {1}.", weather_options[weather_choice]))
      end

    when 1  # Force Forecast Update
      # Ask the player to choose a zone
      zone_options = [
        _INTL("Zone 1: Farm, Lake, Swamp, Bug Meadows"),
        _INTL("Zone 2: Town, Lab, River Estuary"),
        _INTL("Zone 3: Mountain Path, Mines")
      ]
      zone_choice = pbShowCommands(nil, zone_options, -1)
      if zone_choice >= 0
        # Force a weather forecast update for the selected zone
        pbForceUpdateZoneWeather(zone_choice)
        pbMessage(_INTL("The weather forecast for {1} has been updated.", zone_options[zone_choice]))
      end

    when 2  # Advance to Season
      # List of season start options
      season_start_options = [
        _INTL("April (Spring)"),
        _INTL("July (Summer)"),
        _INTL("October (Autumn)"),
        _INTL("December (Winter)")
      ]
      # Ask the player to choose a season start
      season_start_choice = pbShowCommands(nil, season_start_options, -1)
      if season_start_choice >= 0
        # Map the choice to a month
        month = [4, 7, 10, 12][season_start_choice]
        # Advance to the 1st day of the selected month
        pbSetMonth(month)
        pbMessage(_INTL("The season has been changed to {1}.", season_start_options[season_start_choice]))
      end 

    end
  end
end

#===============================================================================
# Advance to Season
#===============================================================================
def pbSetMonth(month)
  # Get the current time
  now = pbGetTimeNow
  # Calculate the target time (1st day of the specified month at 6:00 AM)
  target_time = Time.local(now.year, month, 1, 6, 0)
  # If the target time is in the past, advance to the same month next year
  if target_time < now
    target_time = Time.local(now.year + 1, month, 1, 6, 0)
  end
  # Calculate the difference in seconds
  seconds_to_add = target_time - now
  # Add the seconds to advance to the target time
  UnrealTime.add_seconds(seconds_to_add)
  # Refresh the map to reflect the new season
  $game_map.need_refresh = true if $game_map
  PBDayNight.sheduleToneRefresh
end