module GameData
  class DailyClock
    attr_reader :game_day

    def initialize
      now = pbGetTimeNow
      @game_day = now.day
    end

    def update
      now = pbGetTimeNow


      $item_display.update if $item_display && $item_display.visible?

      # Check if the player is late (past 2 AM)
      pass_out if is_late?(now)
    end

    def daily_reset
      # Reset player energy
      $player_energy.reset_daily if $player_energy

      pbShowDayBanner

      pbCollectEggs
      # Advance the time to 6 AM
      UnrealTime.advance_to(06,00,00)

      NPCSystem.daily_schedule_update

      # Increment the day counter
      now = pbGetTimeNow
      @game_day = now.day
      if @game_day > 28
        if pbGetSeason == 3 # Winter -> Spring
          UnrealTime.add_days(92)
          $PokemonGlobal.encounter_version = 1
          UnrealTime.advance_to(06,00,00)

          now = pbGetTimeNow
          @game_day = now.day
          UnrealTime.advance_to(06,00,00) if @game_day > 1 #leap year fix
        elsif pbGetSeason == 2 # Autumn -> Winter
          UnrealTime.add_days(33)
          $PokemonGlobal.encounter_version = 4
          UnrealTime.advance_to(06,00,00)
        elsif pbGetSeason == 1 # Summer -> Autumn
          UnrealTime.add_days(64)
          $PokemonGlobal.encounter_version = 3
          UnrealTime.advance_to(06,00,00)
        elsif pbGetSeason == 0 # Spring -> Summer
          UnrealTime.add_days(63)
          $PokemonGlobal.encounter_version = 2
          UnrealTime.advance_to(06,00,00)
        end
      end
      now = pbGetTimeNow
      @game_day = now.day

      pbShowDayBanner
      
      # Call existing functions for berry production, egg collection, NPC affection, etc.
      pbProduceEggs

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
      elsif now.hour > 3
        # Player went to bed before midnight
        $player_energy.modify_daily(10)  # Bonus: Increase daily max by 10
      end
    end


    def pass_out
      # Transfer the player to bed
      pbFadeOutIn do
        $game_temp.player_new_map_id    = 82
        $game_temp.player_new_x         = 23
        $game_temp.player_new_y         = 3
        $game_temp.player_new_direction = 3
        pbDismountBike
        $scene.transfer_player
        $game_map.autoplay
        $game_map.refresh
        
        # Call the daily reset function
        daily_reset
      end
    end



  end
end

#===============================================================================
# * pbShowDayBanner: centered full-screen banner for Season/Day
#   show_seconds: how long to show (default ~1.5s)
#===============================================================================
def pbShowDayBanner(show_seconds = 2)
  vp = Viewport.new(0, 0, Graphics.width, Graphics.height)
  vp.z = 99999

  bg = Sprite.new(vp)
  bg.bitmap = Bitmap.new(Graphics.width, Graphics.height)
  bg.bitmap.fill_rect(bg.bitmap.rect, Color.new(0, 0, 0, 255)) # full black

  txt = Sprite.new(vp)
  txt.bitmap = Bitmap.new(Graphics.width, Graphics.height)
  bmp  = txt.bitmap
  font = bmp.font
  font.name  = "Pokemon System" rescue nil
  font.size  = 48
  font.bold  = true
  #font.outline = true

  season_str =   ["Spring", "Summer", "Fall", "Winter"][pbGetSeason] || "Unknown"
  day_str    = "Day #{game_day}"
  message    = "#{season_str} — #{day_str}"

  tw = bmp.text_size(message).width
  th = bmp.text_size(message).height
  x  = (Graphics.width  - tw) / 2
  y  = (Graphics.height - th) / 2
  bmp.draw_text(x, y, tw, th, message)

  # Hold for a bit (convert seconds to frames)
  (show_seconds * 60).to_i.times { Graphics.update }

ensure
  [txt, bg].each do |s|
    next unless s
    s.bitmap.dispose if s.bitmap && !s.bitmap.disposed?
    s.dispose
  end
  vp.dispose if vp
end


def pbInitialGameLoading

  # Load NPC data and dialog files
  GameData::NPC.load
  load_dialogs


  GameData::Chicken.load

end

