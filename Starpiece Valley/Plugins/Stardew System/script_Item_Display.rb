#===============================================================================
# Item Display System
#===============================================================================

# Single-line function to display the item sprite and text

def pbShowItemDisplay(item, quantity)
  $item_display = ItemDisplaySprite.new(item, quantity)
end



class ItemDisplaySprite
  def initialize(item, quantity, viewport = nil)
    @viewport = viewport || Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999  # Ensure it's drawn above everything else

    # Create item sprite
    @item_sprite = Sprite.new(@viewport)
    @item_sprite.bitmap = Bitmap.new("Graphics/Items/#{item}")  # Load item sprite
    @item_sprite.zoom_x = 0.75  # Scale down 50%
    @item_sprite.zoom_y = 0.75  # Scale down 50%
    @item_sprite.x = Graphics.width - 142  # Upper right-hand side
    @item_sprite.y = 112  # Position underneath the EXP bar
    @item_sprite.z = 1

    # Create text sprite for item name and quantity (scaled down 50%)
    @text_sprite = BitmapSprite.new(Graphics.width, 32, @viewport)
    @text_sprite.zoom_x = 0.75  # Scale down 50%
    @text_sprite.zoom_y = 0.75  # Scale down 50%
    @text_sprite.x = Graphics.width - 110  # Position next to the item sprite
    @text_sprite.y = 122  # Position underneath the EXP bar
    @text_sprite.z = 2
    pbSetSystemFont(@text_sprite.bitmap)

    # Set text
    itemname = (quantity > 1) ? GameData::Item.get(item).portion_name_plural : GameData::Item.get(item).portion_name
    text = _INTL("{1} x{2}", itemname, quantity)
    @text_sprite.bitmap.clear
    pbDrawTextPositions(@text_sprite.bitmap, [[text, 0, 0, :left, Color.new(255, 255, 255), Color.new(0, 0, 0)]])

    # Initialize animation variables
    @start_time = System.uptime
    @fade_in_duration = 0.5  # Fade in duration in seconds
    @stay_duration = 2.0     # Stay visible duration in seconds
    @fade_out_duration = 0.5 # Fade out duration in seconds
    @total_duration = @fade_in_duration + @stay_duration + @fade_out_duration
    @item_sprite.opacity = 0
    @text_sprite.opacity = 0
    @visible = true
  end

  def update
    return unless @visible

    # Calculate elapsed time since the animation started
    elapsed_time = System.uptime - @start_time

    # Determine the current phase of the animation
    if elapsed_time < @fade_in_duration
      # Phase 1: Fade in
      progress = elapsed_time / @fade_in_duration
      opacity = 0 + (255 * progress)
    elsif elapsed_time < @fade_in_duration + @stay_duration
      # Phase 2: Stay visible
      opacity = 255
    else
      # Phase 3: Fade out
      progress = (elapsed_time - @fade_in_duration - @stay_duration) / @fade_out_duration
      opacity = 255 - (255 * progress)
    end

    # Slide up
    @item_sprite.y = 112 - (32 * elapsed_time/@total_duration)  
    @text_sprite.y = 122 - (32 * elapsed_time/@total_duration) 

    # Fade in/out
    @item_sprite.opacity = opacity
    @text_sprite.opacity = opacity
                                                                                                                                                                                                                                                                                                                                                                                                                                         
    # End animation after total duration
    if elapsed_time >= @total_duration
      @visible = false
      dispose
    end
  end

  def dispose
    @item_sprite.dispose
    @text_sprite.dispose
    @viewport.dispose
  end

  def visible?
    @visible
  end
end

