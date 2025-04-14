module GameData
  class DailyClock
    attr_reader :game_day

    def initialize
      @game_day = 1  # Start at Day 1
    end

    def update
      now = pbGetTimeNow


      $item_display.update if $item_display && $item_display.visible?

      # Check if the player is late (past 2 AM)
      if is_late?(now)
        pass_out
      end
    end

    def daily_reset
      # Reset player energy
      $player_energy.reset_daily if $player_energy

      # Advance the time to 6 AM
      UnrealTime.advance_to(06,00,00)

      # Increment the day counter
      now = pbGetTimeNow
      @game_day = now.day

      # Call existing functions for berry production, egg collection, NPC affection, etc.
      

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
      elsif now.hour > 2
        # Player went to bed before midnight
        $player_energy.modify_daily(10)  # Bonus: Increase daily max by 10
      end
    end


    def pass_out
      # Transfer the player to bed
      
      # Call the daily reset function
      daily_reset
    end

  end
end




