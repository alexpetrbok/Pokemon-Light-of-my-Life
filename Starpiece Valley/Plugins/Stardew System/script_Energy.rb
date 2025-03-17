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
      @energy = [@energy + amount, 0].max
      @energy = [@energy, @daily].min
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
      $daily_clock.rest_bonus(@energy)
      @energy = @daily
    end
  end
end