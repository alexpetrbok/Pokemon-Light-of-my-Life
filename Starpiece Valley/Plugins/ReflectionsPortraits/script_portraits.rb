module Rf
  # Default settings
  @@name_window_skin = RfSettings::DEFAULT_WINDOW_SKIN
  @@outline_colour = RfSettings::DEFAULT_OUTLINE_COLOR
  GRAY_OUTLINE = Color.new(150, 150, 150) # Gray outline for non-main characters

  # Get the current portrait outline color
  def self.portrait_outline_color
    @@outline_colour
  end

  # Set the portrait outline color
  def self.portrait_outline_color=(color)
    @@outline_colour = color
  end

  # Show a group of 1-4 characters with layered positioning
  def self.new_portrait(*characters)
    return if characters.empty? || !$scene.is_a?(Scene_Map)
    close_portrait  # Close all existing portraits

    # Main speaker (right-aligned)
    main_char = characters[0]
    main_portrait = $scene.spritesetGlobal.newPortrait(main_char, 1)
    main_sprite = main_portrait.instance_variable_get(:@sprite)
    main_sprite.zoom_x = 2.0
    main_sprite.zoom_y = 2.0
    main_sprite.opacity = 0
    main_portrait.target_y = Graphics.height - 40  # <-- Set target Y position
    main_portrait.target_x = Graphics.width + 60  # <-- Set target X position

    if main_portrait.instance_variable_get(:@outline)
      main_outline = main_portrait.instance_variable_get(:@outline)
      main_outline.color = Rf.portrait_outline_color  # <-- White outline for main speake
      main_outline.x = main_sprite.x - 4  # <-- Align outline with main sprite
      main_outline.y = main_sprite.y - 4  # <-- Align outline with main sprite
    end 

    #Rf.set_speaker(main_char.to_s)  # Set NPC1 as the speaker

    # Secondary characters (left-aligned with mirroring)
    secondary_chars = characters[1..3]
    secondary_chars.each_with_index do |char, idx|
      next unless char
      portrait = $scene.spritesetGlobal.newPortrait(char, 0)
      sprite = portrait.instance_variable_get(:@sprite)
      outline = portrait.instance_variable_get(:@outline)

      portrait.target_x = -60 + (idx * 80)  # <-- Staggered left-to-right
      portrait.target_y = Graphics.height - 40  # <-- Keep at the bottom
      sprite.mirror = true
      sprite.z = 300 - idx
      sprite.opacity = 0

      # Fix outline alignment
      if outline
        outline.mirror = true
        outline.zoom_x = 2.0
        outline.zoom_y = 2.0
        outline.x = sprite.x - 4  # Compensate for 1px border
        outline.y = sprite.y - 4  # Compensate for 1px border
        outline.color = GRAY_OUTLINE
      end
    end
  end

  # Close all active portraits
  def self.close_portrait
    return unless $scene.is_a?(Scene_Map)
    $scene.spritesetGlobal.close_portraits
    Rf.clear_speaker
  end

  # Disable player portrait for the next showCommands
  def self.no_player_portrait
    $game_temp.player_portrait_disabled = true
  end

  # Set the speaker name for dialogue
  def self.set_speaker(name)
    $game_temp.speaker = name
  end

  # Clear the speaker name
  def self.clear_speaker
    $game_temp.speaker = nil
  end
end

#===============================================================================
#  RfDialoguePortrait Class (Updated for Scaling and Mirroring)
#===============================================================================
class RfDialoguePortrait
  #attr_reader :state
  #attr_reader :portrait
  attr_accessor :state 
  attr_accessor :speaker 
  attr_accessor :target_x, :target_y  

  def initialize(portrait, align = 0, viewport = nil)
    @align = align
    @sprite = Sprite.new(viewport)
    @sprite.bitmap = Bitmap.new("Graphics/Trainers/#{portrait}")
    @sprite.ox = @sprite.bitmap.width * (align % 2)
    @sprite.oy = @sprite.bitmap.height
    @sprite.x = align > 0 ? Graphics.width + 128 : -128
    @sprite.y = Graphics.height
    @sprite.opacity = 0
    @sprite.zoom_x = 2.0
    @sprite.zoom_y = 2.0

    # Set target positions
    @target_x = align > 0 ? Graphics.width - 128 : 160  # <-- Adjust as needed
    @target_y = Graphics.height - 80  # <-- Keep at the bottom

    if RfSettings::OUTLINE
      @outline = @sprite.create_outline_sprite
      @outline.color = Rf.portrait_outline_color
      @outline.opacity = 0
      @outline.zoom_x = 2.0 # <-- Match outline scaling
      @outline.zoom_y = 2.0 # <-- Match outline scaling
    end

    @state = :opening
    @state_change = System.uptime
    @disposed = false
  rescue
    @sprite.bitmap = nil
  end

  # Update portrait state (opening, active, closing)
  def update
    return if @disposed
    case @state
    when :opening then openAnimation
    when :active then mainUpdate
    when :closing then closeAnimation
    else raise "Invalid dialogue portrait state"
    end
  end
  
  def openAnimation
    @sprite.opacity = lerp(0, 255, 0.25, @state_change, System.uptime)
    @outline&.opacity = lerp(0, 255, 0.25, @state_change, System.uptime)
    @sprite.x = lerp(@sprite.x, @target_x, 0.25, @state_change, System.uptime) 
    @sprite.y = lerp(@sprite.y, @target_y, 0.25, @state_change, System.uptime)  
    @outline&.x = lerp(@outline.x, @target_x - 4, 0.25, @state_change, System.uptime)  
    @outline&.y = lerp(@outline.y, @target_y - 4, 0.25, @state_change, System.uptime)  
    @state = :active if @sprite.x == @target_x && @sprite.y == @target_y  
  end

  def mainUpdate
    self.state = :closing if !pbMapInterpreterRunning? && PORTRAITS_AUTO_CLOSE_ON_EVENT_END
    # lip flaps would go here, however these are currently not implemented
  end

  def closeAnimation
    return if @disposed
    @sprite.opacity = lerp(255, 0, 0.25, @state_change, System.uptime)
    @outline&.opacity = lerp(255, 0, 0.25, @state_change, System.uptime)

    if @align > 0
      # Move right-aligned sprites off the right side of the screen
      @sprite.x = lerp(@sprite.x, Graphics.width + 128, 0.25, @state_change, System.uptime)
      @outline&.x = lerp(@outline.x, Graphics.width + 126, 0.25, @state_change, System.uptime)
    else
      # Move left-aligned sprites off the left side of the screen
      @sprite.x = lerp(@sprite.x, -128, 0.25, @state_change, System.uptime)
      @outline&.x = lerp(@outline.x, -130, 0.25, @state_change, System.uptime)
    end

    dispose if @sprite.x <= -128 || @sprite.x >= Graphics.width + 128
  end

  # Dispose of the portrait
  def dispose
    @sprite.bitmap&.dispose
    @sprite.dispose
    @outline&.dispose
    @disposed = true
  end

  def disposed?
    return @disposed
  end
end

class Spriteset_Global
  alias rf_portraits_init initialize
  alias rf_portraits_update update

  attr_accessor :activePortraits

  def initialize
    rf_portraits_init
    @activePortraits = []  # Initialize as an empty array
  end

  def newPortrait(portrait, align = 0)
    @activePortraits ||= []  # Ensure @activePortraits is always an array
    portrait_sprite = RfDialoguePortrait.new(portrait, align, @@viewport2)
    @activePortraits << portrait_sprite  # Add new portrait to the array
    portrait_sprite
  end

  def update
    rf_portraits_update
    @activePortraits&.each(&:update)  # Safely update all active portraits
  end

  def close_portraits
    return unless @activePortraits
    @activePortraits.each do |portrait|
      portrait.dispose # <-- FORCE DISPOSE IMMEDIATELY
    end
    @activePortraits.clear # <-- CLEAR ARRAY
  end

  def self.viewport
    return @@viewport2
  end
end


class Game_Temp
  attr_accessor :speaker # Add this line
  attr_accessor :player_portrait_disabled # Optional: If you use this elsewhere
end

