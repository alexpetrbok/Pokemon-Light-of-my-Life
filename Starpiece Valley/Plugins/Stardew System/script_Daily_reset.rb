def is_late?()
  # Check if the current time is between 2 AM and 6 AM
  now = pbGetTimeNow
  now.hour == 2 && now.hour < 4
end

module GameData
  class DailyClock
    attr_reader :game_day, :hr_schedule

    UPDATE_LOOP_SWITCH_ID = 69
    FESTIVAL_SWITCH_ID = 70
    DOW_ORDER = [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday]

    SEASON_START_MONTHS = [4, 7, 10, 12]            # Apr, Jul, Oct, Dec
    SEASON_ENCOUNTER    = { 4 => 1, 7 => 2, 10 => 3, 12 => 4 }


    def initialize
      now = pbGetTimeNow
      @game_day = now.day
      @hr_schedule = now.hour
    end

    def update
      now = pbGetTimeNow


      $item_display.update if $item_display && $item_display.visible?

      # Check if the player is late (past 2 AM)

      update_schedule if now.hour != @hr_schedule

    end

    def daily_reset
      # Reset player energy
      $player_energy.reset_daily if $player_energy

      pbShowDayBanner

      pbCollectEggs
      # Advance the time to 6 AM
      UnrealTime.advance_to(06,00,00)

      NPCSystem.nightly_npc_update

      # Increment the day counter
      now = pbGetTimeNow
      if now.day < 1 || now.day > 28 || ![4,7,10,12].include?(now.mon)
        advance_to_next_season
        now = pbGetTimeNow
        $game_variables[71] = true
      end
      @game_day = now.day

      pbShowDayBanner
      
      # Call existing functions for berry production, egg collection, NPC affection, etc.
      pbProduceEggs
      produced = ChickenBreeding.nightly_breeding
      puts "🐣 Bred #{produced} new chicks overnight." if produced > 0
      $player.heal_party
      pbSetPokemonCenter

      pbForceUpdateWeather

      $game_variables[UPDATE_LOOP_SWITCH_ID] = true
    end

    def is_late?()
      # Check if the current time is between 2 AM and 6 AM
      now = pbGetTimeNow
      now.hour >= 2 && now.hour < 6
    end

    # 28‑day looped calendar (day 1 => :monday). Change anchor if you prefer a different start.
    def day_of_week
      idx = ((@game_day - 1) % 7)
      DOW_ORDER[idx]
    end

    def weekend?
      dow = day_of_week
      (dow == :saturday || dow == :sunday)
    end

    def season_symbol
      return nil unless defined?(pbGetSeason)
      case pbGetSeason
        when 0 then :spring
        when 1 then :summer
        when 2 then :autumn
        when 3 then :winter
        else nil
      end
    end
    
    # Festival resolution:
    def festival_today
      return nil unless defined?($game_switches) && $game_switches[FESTIVAL_SWITCH_ID]
      if defined?($game_variables)
        val = $game_variables[FESTIVAL_SWITCH_ID]
        return val.to_s.downcase.to_sym unless val.nil? || val == false || val == 0 || val == ""
      end
      :festival
    end

    # Call this ONCE per in‑game hour (and after big time jumps/fast travel if desired).
    def update_schedule
      now = pbGetTimeNow
      @hr_schedule = now.hour
      GameData::NPC.each do |npc|
        table = resolve_schedule_map(npc)
        next unless table
        new_state = active_state_for_hour(table)
        next unless new_state

        prev = npc.state
        if prev != new_state
          npc.state = new_state
          puts "🕒 [#{@hr_schedule}:00] #{npc.name}'s state changed: #{prev} → #{new_state}"
          # DEBUG: state changed — plug in your spawn/page toggles or move routes here.
          # e.g., NPCPages.apply_behavior(npc.id, new_state)
        end
      end
    end

    def active_state_for_hour(table)
      return nil if table.nil? || table.empty?
      hours = table.keys.grep(Integer).select { |h| h.between?(0, 23) }
      return nil if hours.empty?
      start = hours.select { |h| h <= @hr_schedule }.max
      start ||= hours.max
      table[start]
    end

    def resolve_schedule_map(npc)
      sched = npc.schedule || {}
      return nil if sched.empty?

      # 1) Festival
      if (fest = festival_today)
        block = sched[:festival]
        if block.is_a?(Hash)
          if block.values.all? { |v| v.is_a?(Symbol) }           # flat festival schedule
            return block
          elsif block[fest].is_a?(Hash)                          # named festival schedule
            return block[fest]
          end
        end
      end

      # 2) Day of Week
      dow = day_of_week
      return sched[dow] if sched[dow].is_a?(Hash)

      # 3) Season
      seas = season_symbol
      return sched[seas] if seas && sched[seas].is_a?(Hash)

      # 4) Weekday/Weekend
      if weekend?
        return sched[:weekend] if sched[:weekend].is_a?(Hash)
      else
        return sched[:weekday] if sched[:weekday].is_a?(Hash)
      end

      # 5) Default
      return sched[:default] if sched[:default].is_a?(Hash)

      nil
    end

    def advance_to_next_season
      now = pbGetTimeNow

      # If we're already in a season month, decide whether to snap to today 06:00 or the next season.
      if SEASON_START_MONTHS.include?(now.mon)
        today0600 = Time.new(now.year, now.mon, 1, 6, 0, 0)
        if now <= today0600
          target_month = now.mon
          target_year  = now.year
        else
          i = SEASON_START_MONTHS.index(now.mon)
          target_month = SEASON_START_MONTHS[(i + 1) % SEASON_START_MONTHS.length]
          target_year  = now.year + (i == SEASON_START_MONTHS.length - 1 ? 1 : 0)
        end
      else
        # Find the next season start month in this year, or wrap to April next year
        target_month = SEASON_START_MONTHS.find { |m| m > now.mon } || SEASON_START_MONTHS.first
        target_year  = (target_month > now.mon) ? now.year : now.year + 1
      end

      target = Time.new(target_year, target_month, 1, 6, 0, 0)
      delta  = (target - now).to_i
      UnrealTime.add_seconds(delta) if delta.positive?

      # Update the seasonal encounter version
      $PokemonGlobal.encounter_version = SEASON_ENCOUNTER[target_month]
      pbClearBerryTimeDelta()

      # Return the new time for convenience
      return pbGetTimeNow
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
  $player_energy = GameData::PlayerEnergy.new(100)
  $daily_clock = GameData::DailyClock.new
  
  # Load NPC data and dialog files
  GameData::NPC.load
  load_dialogs
  NPCSystem.seed_NPCs

  

  GameData::Chicken.load

end

def skip_hours(hours, mins = 0)
  now = pbGetTimeNow
  total_secs = (hours * 3600) + (mins * 60)

  # Advance by the number of seconds
  UnrealTime.add_seconds(total_secs)

  # Return new time if needed
  return pbGetTimeNow
end
# --- Helpers ---------------------------------------------------------------



# Transfer with safety (optionally invisible during the move)
def safe_transfer(map_id, x, y, dir = 2, invisible: false, autoplay: true)
  pbFadeOutIn do
    pbCancelVehicles
    Followers.clear
    pbDismountBike

    $game_player.transparent = true if invisible
    $game_temp.player_new_map_id    = map_id
    $game_temp.player_new_x         = x
    $game_temp.player_new_y         = y
    $game_temp.player_new_direction = dir

    $scene.transfer_player if $scene.is_a?(Scene_Map)
    $game_map.autoplay if autoplay
    $game_map.refresh

    $game_player.transparent = false if invisible
  end
end
