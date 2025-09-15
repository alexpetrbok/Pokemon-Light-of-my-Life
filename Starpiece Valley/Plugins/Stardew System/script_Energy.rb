ENERGY_PLANT   = -1
ENERGY_WATER   = -1
ENERGY_WEEDS   = -2
ENERGY_PESTS   = -5
ENERGY_HARVEST = -2
ENERGY_DIGBERRY= -3
ENERGY_MULCH   = -2   

ENERGY_CUT        = -4
ENERGY_ROCKSMASH  = -6
ENERGY_STRENGTH   = -8
ENERGY_HEADBUTT   = -3  
ENERGY_SURF      = -4
ENERGY_DIVE      = -2
ENERGY_FLASH     = -1
ENERGY_FLY       = -15
ENERGY_DIG       = -5
ENERGY_TELEPORT  = -5
ENERGY_WATERFALL = -10
ENERGY_SWEETSCENT= -3


module GameData
  class PlayerEnergy
    attr_reader :energy, :daily, :max

    def initialize(max_energy = 100)
      @max = max_energy         # The player's overall maximum energy (can increase over time)
      @daily = max_energy       # The player's maximum energy for the current day
      @energy = @daily          # The player's current energy
    end

    # Modify energy (positive or negative value)
    def modify_energy(amount)
      if amount < @energy
        @energy = [@energy + amount, 0].max
        @energy = [@energy, @daily].min
        return true
      else
        return false
      end
    end

    # Modify daily max (positive or negative value)
    def modify_daily(amount)
      @daily = [@daily + amount, 0].max
      @energy = [@energy, @daily].min  # Ensure energy doesn't exceed the new daily max
    end

    # Modify max energy (positive or negative value)
    def modify_max(amount)
      @max = [@max + amount, 0].max
      @daily = [@daily, @max].min      # Ensure daily max doesn't exceed the new max
      @energy = [@energy, @daily].min  # Ensure energy doesn't exceed the new daily max
    end

    # Reset daily max to max (to be called at the start of each day)
    def reset_daily
      @daily = @max
      rest_bonus()
      @energy = @daily
    end

    def rest_bonus()
      now = pbGetTimeNow

      if now.hour == 5 
        if @energy > 10
          # Player passed out with energy left
          @daily = @daily -25  
      	else
          # Player passed out with no energy left
          @daily = @daily -50  
	      end
      elsif now.hour < 3
        # Player went to bed after midnight
        @daily = @daily -5
      elsif now.hour < 6
        # Player went to bed before midnight
        @daily = @daily +10
      end
    end
  end
end