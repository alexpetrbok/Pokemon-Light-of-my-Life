#-------------------------------------------------------------------------------
# Safari Hud component
#-------------------------------------------------------------------------------
class VPM_SafariHud < Component
  def start_component(viewport, menu)
    super(viewport, menu)
    @sprites["overlay"]    = BitmapSprite.new(Graphics.width / 2, 96, viewport)
    @sprites["overlay"].ox = @sprites["overlay"].bitmap.width
    @sprites["overlay"].x  = Graphics.width
    @base_color = $PokemonSystem.from_current_menu_theme(MENU_TEXTCOLOR, Color.new(248, 248, 248))
    @shdw_color = $PokemonSystem.from_current_menu_theme(MENU_TEXTOUTLINE, Color.new(48, 48, 48))
  end

  def should_draw?; return pbInSafari?; end

  def refresh
    text = _INTL("Balls: {1}",pbSafariState.ballcount)
    text2 = (Settings::SAFARI_STEPS > 0) ? _INTL("Steps: {1}/{2}", pbSafariState.steps, Settings::SAFARI_STEPS) : ""
    @sprites["overlay"].bitmap.clear
    pbSetSystemFont(@sprites["overlay"].bitmap)
    pbDrawTextPositions(@sprites["overlay"].bitmap, [
      [text, (Graphics.width / 2) - 8, 12, 1, @base_color, @shdw_color],
      [text2, (Graphics.width / 2) - 8, 44, 1, @base_color, @shdw_color]
    ])
  end
end

#-------------------------------------------------------------------------------
# Bug Contest Hud component
#-------------------------------------------------------------------------------
class VPM_BugContestHud < Component
  def start_component(viewport, menu)
    super(viewport, menu)
    @sprites["overlay"]    = BitmapSprite.new(Graphics.width / 2, 96, viewport)
    @sprites["overlay"].ox = @sprites["overlay"].bitmap.width
    @sprites["overlay"].x  = Graphics.width
    @base_color = $PokemonSystem.from_current_menu_theme(MENU_TEXTCOLOR, Color.new(248, 248, 248))
    @shdw_color = $PokemonSystem.from_current_menu_theme(MENU_TEXTOUTLINE, Color.new(48, 48, 48))
  end

  def should_draw?; return pbInBugContest?; end

  def refresh
    if pbBugContestState.lastPokemon
      text  =  _INTL("Caught: {1}", pbBugContestState.lastPokemon.speciesName)
      text2 =  _INTL("Level: {1}", pbBugContestState.lastPokemon.level)
      text3 =  _INTL("Balls: {1}", pbBugContestState.ballcount)
    else
      text = _INTL("Caught: None")
      text2 = _INTL("Balls: {1}", pbBugContestState.ballcount)
      text3 = ""
    end
    @sprites["overlay"].bitmap.clear
    pbSetSystemFont(@sprites["overlay"].bitmap)
    pbDrawTextPositions(@sprites["overlay"].bitmap, [
      [text, (Graphics.width / 2) - 8, 12, 1, @base_color, @shdw_color],
      [text2, (Graphics.width / 2) - 8, 44, 1, @base_color, @shdw_color],
      [text3, 248, 76, 1, @base_color, @shdw_color]
    ])
  end
end

#-------------------------------------------------------------------------------
# Pokemon Party Hud component
#-------------------------------------------------------------------------------
class VPM_PokemonPartyHud < Component
  def start_component(viewport, menu)
    super(viewport, menu)
    # Overlay stuff
    @sprites["overlay"]   = BitmapSprite.new(Graphics.width, Graphics.height / 2, @viewport)
    @sprites["overlay"].y = (Graphics.height / 2)
    @info_bar_bmp = RPG::Cache.load_bitmap(MENU_FILE_PATH, "overlay_info")
    @hp_bar_bmp   = RPG::Cache.load_bitmap(MENU_FILE_PATH, "overlay_hp")
    @exp_bar_bmp  = RPG::Cache.load_bitmap(MENU_FILE_PATH, "overlay_exp")
    @status_bmp   = RPG::Cache.load_bitmap(MENU_FILE_PATH, "overlay_status")
    @item_bmp     = RPG::Cache.load_bitmap(MENU_FILE_PATH, "overlay_item")
    @shiny_bmp    = RPG::Cache.load_bitmap(MENU_FILE_PATH, "overlay_shiny")
  end

  def should_draw?; return $player.party_count > 0; end

  def refresh
    # Iterate through all the player's Pokémon
    @sprites["overlay"].bitmap.clear
    Settings::MAX_PARTY_SIZE.times do |i|
      next if !@sprites["pokemon_#{i}"]
      @sprites["pokemon_#{i}"].dispose
      @sprites["pokemon_#{i}"] = nil
      @sprites.delete("pokemon_#{i}")
    end
    $player.party.each_with_index do |pokemon, i|
      next if !pokemon.is_a?(Pokemon)
      spacing = (Graphics.width / 8) * i
      # Pokémon Icon
      @sprites["pokemon_#{i}"] = PokemonIconSprite.new(pokemon, @viewport) if !@sprites["pokemon#{i}"] || @sprites["pokemon#{i}"].disposed?
      @sprites["pokemon_#{i}"].x = spacing + (Graphics.width / 8)
      @sprites["pokemon_#{i}"].y = Graphics.height - 164
      @sprites["pokemon_#{i}"].y += Graphics.height / 2 if @menu.hidden && !@menu.start_up
      @sprites["pokemon_#{i}"].z = -2
      next if pokemon.egg?
      # Information Overlay
      @sprites["overlay"].bitmap.blt(spacing + (Graphics.width / 8) + 16, (Graphics.height / 2) - 102,
                          @info_bar_bmp, Rect.new(0, 0, @info_bar_bmp.width, @info_bar_bmp.height))
      # Health
      if pokemon.hp > 0
        w = (pokemon.hp * 32 * 1.0) / pokemon.totalhp
        w = 1 if w < 1
        w = ((w / 2).round) * 2
        hpzone = 0
        hpzone = 1 if pokemon.hp <= (pokemon.totalhp/2).floor
        hpzone = 2 if pokemon.hp <= (pokemon.totalhp/4).floor
        hprect = Rect.new(0, hpzone * 4, w, 4)
        @sprites["overlay"].bitmap.blt(spacing + (Graphics.width/8) + 18, (Graphics.height / 2) - 100, @hp_bar_bmp, hprect)
      end
      # EXP
      if pokemon.exp > 0
        minexp = pokemon.growth_rate.minimum_exp_for_level(pokemon.level)
        currentexp = minexp-pokemon.exp
        maxexp = minexp-pokemon.growth_rate.minimum_exp_for_level(pokemon.level + 1)
        w = (currentexp * 24 * 1.0)/maxexp
        w = 1 if w < 1.0
        w = 0 if w.is_a?(Float) && w.nan?
        w = ((w / 2).round) * 2 if w > 0 # I heard Pokémon Beekeeper was good
        exprect = Rect.new(0, 0, w, 2)
        @sprites["overlay"].bitmap.blt(spacing + (Graphics.width / 8) + 22, (Graphics.height / 2) - 94, @exp_bar_bmp, exprect)
      end
      # Item Icon
      if pokemon.hasItem?
        @sprites["overlay"].bitmap.blt(spacing + (Graphics.width / 8) + 52, (Graphics.height / 2) - 116,
        @item_bmp,Rect.new(0, 0, @item_bmp.width, @item_bmp.height))
      end
      # Status
      status = 0
      if pokemon.fainted?
        status = GameData::Status.count - 1
      elsif pokemon.status != :NONE
        status = GameData::Status.get(pokemon.status).icon_position
      elsif pokemon.pokerusStage == 1
        status = GameData::Status.count
      end
      if status > 0
        statusrect = Rect.new(0, 8 * status, 8, 8)
        @sprites["overlay"].bitmap.blt(spacing + (Graphics.width/8) + 48, (Graphics.height / 2) - 106, @status_bmp, statusrect)
      end
      # Shiny Icon
      if pokemon.shiny?
        @sprites["overlay"].bitmap.blt(spacing + (Graphics.width / 8) + 52, (Graphics.height / 2) - 142,
                          @shiny_bmp,Rect.new(0, 0, @shiny_bmp.width, @shiny_bmp.height))
      end
    end
  end

  def dispose
    super
    @info_bar_bmp.dispose
    @hp_bar_bmp.dispose
    @exp_bar_bmp.dispose
    @status_bmp.dispose
    @item_bmp .dispose
    @shiny_bmp.dispose
  end
end

#-------------------------------------------------------------------------------
# Date and Time Hud component
#-------------------------------------------------------------------------------
class VPM_DateAndTimeHud < Component
  def initialize
    super
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}

    # Create text overlay
    @sprites["overlay"] = Sprite.new(@viewport)
    @sprites["overlay"].bitmap = Bitmap.new(Graphics.width, 64)
    @sprites["overlay"].z = 1
    pbSetSystemFont(@sprites["overlay"].bitmap)

    # Load season icons
    @season_icons = {
      0 => "Graphics/UI/Overlay/Seasons/Spring", # Spring
      1 => "Graphics/UI/Overlay/Seasons/Summer", # Summer
      2 => "Graphics/UI/Overlay/Seasons/Fall",   # Fall
      3 => "Graphics/UI/Overlay/Seasons/Winter"  # Winter
    }

    # Load weather icons
    @weather_icons = {
      0 => "Graphics/UI/Overlay/Weather/Clear",      # Clear
      1 => "Graphics/UI/Overlay/Weather/Rain",       # Rain
      2 => "Graphics/UI/Overlay/Weather/Storm",      # Storm
      3 => "Graphics/UI/Overlay/Weather/Snow",       # Snow
      4 => "Graphics/UI/Overlay/Weather/Blizzard",   # Blizzard
      5 => "Graphics/UI/Overlay/Weather/Sandstorm",  # Sandstorm
      6 => "Graphics/UI/Overlay/Weather/HeavyRain",  # HeavyRain
      7 => "Graphics/UI/Overlay/Weather/Sun"         # Sun
    }

    # Create colored bars sprite (for green, yellow, red portions)
    @sprites["energy_colors"] = Sprite.new(@viewport)
    @sprites["energy_colors"].bitmap = Bitmap.new(100, 4)  
    @sprites["energy_colors"].x = Graphics.width - 107
    @sprites["energy_colors"].y = 72 
    @sprites["energy_colors"].z = 3
    @sprites["energy_colors"].visible = true

    # Create energy bar
    @sprites["energy_bar"] = IconSprite.new(Graphics.width - 111, 70, @viewport)
    @sprites["energy_bar"].setBitmap("Graphics/UI/VPM/energy_bar") 
    @sprites["energy_bar"].z = 999
    @sprites["energy_bar"].visible = true

    # Initialize related custom scripts
    $player_energy = GameData::PlayerEnergy.new(100) if !$player_energy
    $daily_clock = GameData::DailyClock.new if !$daily_clock

    # Show by default
    show
  end

  def should_draw?
    return true # Always show the overlay in the pause menu
  end

  def refresh
    unless @sprites["overlay"]
      @sprites["overlay"] = Sprite.new(@viewport)
      @sprites["overlay"].bitmap = Bitmap.new(Graphics.width, 64)
      @sprites["overlay"].z = 1
      pbSetSystemFont(@sprites["overlay"].bitmap)
    end

    # Update time
    $daily_clock.update
    $item_display.update if $item_display && $item_display.visible?
    now = pbGetTimeNow
    time_text = now.strftime("%I:%M %p").sub(/^0/, '') # Remove leading zero

    # Update day of the month
    #day_text = _INTL("Day: {1}", now.day)
    day_text = _INTL("Day: {1}", $daily_clock.game_day)

    # Update season
    season = pbGetSeason
    season_icon = @season_icons[season]

    # Update weather (default to Clear if not found)
    weather_type = $game_screen.weather_type
    weather_icon = @weather_icons[weather_type] || @weather_icons[0] # Default to Clear (0)

    # Draw text and icons
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base_color = Color.new(255, 255, 255) # White text
    shadow_color = Color.new(0, 0, 0)     # Black shadow

    # Adjust font size and position (moved 50px to the right)
    overlay.font.size = 24
    pbDrawTextPositions(overlay, [
      [time_text, 462, 10, :right, base_color, shadow_color], # Right-aligned at x=462
      [day_text, 462, 42, :right, base_color, shadow_color]   # Right-aligned at x=462
    ])

    # Draw season icon
    if season_icon && pbResolveBitmap(season_icon)
      @sprites["season"] ||= IconSprite.new(470, 36, @viewport)
      @sprites["season"].setBitmap(season_icon)
      @sprites["season"].z = 2
    end

    # Draw weather icon
    if weather_icon && pbResolveBitmap(weather_icon)
      @sprites["weather"] ||= IconSprite.new(470, 0, @viewport)
      @sprites["weather"].setBitmap(weather_icon)
      @sprites["weather"].z = 2
    end

    # Refresh energy bar
    refresh_energy_bar
  end

  def refresh_energy_bar
    return unless $player_energy

    unless @sprites["energy_bar"] && @sprites["energy_colors"]
      @sprites["energy_colors"] = Sprite.new(@viewport)
      @sprites["energy_colors"].bitmap = Bitmap.new(100, 4)  
      @sprites["energy_colors"].x = Graphics.width - 107
      @sprites["energy_colors"].y = 72 
      @sprites["energy_colors"].z = 3

      @sprites["energy_bar"] = IconSprite.new(Graphics.width - 111, 70, @viewport)
      @sprites["energy_bar"].setBitmap("Graphics/UI/VPM/energy_bar")  
      @sprites["energy_bar"].z = 999
      @sprites["energy_bar"].visible = true
    end

    # Clear the colored bars bitmap
    energy_colors = @sprites["energy_colors"].bitmap
    energy_colors.clear

    # Calculate the width of each portion
    max_width = 100
    
    # Determine the ratio based on daily and max
    if $player_energy.daily <= $player_energy.max
      # When daily <= max, show energy/max ratio
      energy_fraction = $player_energy.energy.to_f / $player_energy.max
    else
      # When daily > max, show energy/daily ratio
      energy_fraction = $player_energy.energy.to_f / $player_energy.daily
    end

    # Draw the red portion (if daily is less than max)
    if $player_energy.daily < $player_energy.max
      red_width = (1 - ($player_energy.daily.to_f / $player_energy.max)) * max_width
      energy_colors.fill_rect(max_width - red_width, 0, red_width, energy_colors.height, Color.new(255, 0, 0))  # Red
    end

    # Draw the green portion (normal energy)
    green_width = energy_fraction * max_width
    energy_colors.fill_rect(0, 0, green_width, energy_colors.height, Color.new(0, 255, 0))  # Green

    # Draw the yellow portion (if daily is greater than max)
    if $player_energy.daily > $player_energy.max
      yellow_width = (($player_energy.daily.to_f / $player_energy.max) - 1) * max_width
      energy_colors.fill_rect(max_width - yellow_width, 0, yellow_width, energy_colors.height, Color.new(255, 255, 0))  # Yellow
    end

    # Log a debug message if the energy bar graphic is missing
    unless pbResolveBitmap("Graphics/UI/VPM/energy_bar")
      p "Energy bar graphic not found at Graphics/UI/VPM/energy_bar. Drawing colored lines instead."
    end
  end

  def show
    @sprites.each { |key, sprite| sprite.visible = true }
    update # Force an immediate update when shown
  end

  def hide
    @sprites.each { |key, sprite| sprite.visible = false }
  end

  def visible?
    @sprites["overlay"].visible
  end

  def dispose
    @sprites.each { |key, sprite| sprite.dispose }
    @viewport.dispose
  end

  # Background update method
  def self.update_overlay
    $date_time_overlay ||= VPM_DateAndTimeHud.new
    $date_time_overlay.refresh
  end
end

# Global accessor
$date_time_overlay = nil

# Toggle overlay visibility (with optional true/false argument)
def pbToggleDateTimeOverlay(visible = nil)
  $date_time_overlay ||= VPM_DateAndTimeHud.new
  if visible.nil?
    $date_time_overlay.visible? ? $date_time_overlay.hide : $date_time_overlay.show
  else
    visible ? $date_time_overlay.show : $date_time_overlay.hide
  end
end

# Manually update overlay
def pbUpdateDateTimeOverlay
  VPM_DateAndTimeHud.update_overlay
end


#-------------------------------------------------------------------------------
# New Quesst Message Hud component
#-------------------------------------------------------------------------------
class VPM_NewQuestHud < Component
  def initialize
    @counter = 0
  end

  def start_component(viewport, menu)
    super(viewport, menu)
    @sprites["overlay"]    = BitmapSprite.new(Graphics.width / 2, 32, viewport)
    @sprites["overlay"].ox = @sprites["overlay"].bitmap.width
    @sprites["overlay"].x  = Graphics.width
    @sprites["overlay"].y  = 96
    @sprites["overlay"].oy = 32
    @base_color = $PokemonSystem.from_current_menu_theme(MENU_TEXTCOLOR, Color.new(248, 248, 248))
    @shdw_color = $PokemonSystem.from_current_menu_theme(MENU_TEXTOUTLINE, Color.new(48, 48, 48))
  end

  def should_draw?
    return false if !defined?(hasAnyQuests?)
    return false if !$PokemonGlobal
    return false if !$PokemonGlobal.respond_to?(:quests)
    return $PokemonGlobal.quests.active_quests.any? { |quest| quest.respond_to?(:new) && quest.new }
  end

  def update
    super
    @counter += 1
    if @counter > Graphics.frame_rate / 2
      @sprites["overlay"].y += 1 if @counter % (Graphics.frame_rate / 8) == 0
    else
      @sprites["overlay"].y -= 1 if @counter % (Graphics.frame_rate / 8) == 0
    end
    @counter = 0 if @counter >= Graphics.frame_rate
  end

  def refresh
    quest_count = $PokemonGlobal.quests.active_quests.count { |quest| quest.respond_to?(:new) && quest.new }
    @sprites["overlay"].bitmap.clear
    if quest_count > 0
      if quest_count == 1
        text = _INTL("You have {1} new quest!",quest_count)
      else
        text = _INTL("You have {1} new quests!",quest_count)
      end
      pbSetSmallFont(@sprites["overlay"].bitmap)
      pbDrawTextPositions(@sprites["overlay"].bitmap, [[text, (Graphics.width / 2) - 8, 12, 1, @base_color, @shdw_color]])
    end
  end
end
