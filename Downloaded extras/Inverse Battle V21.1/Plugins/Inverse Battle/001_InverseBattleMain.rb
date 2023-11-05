module PBEffects
  InverseRoom     = 913
end

class Battle::ActiveField
  attr_accessor :effects
  attr_accessor :defaultWeather
  attr_accessor :weather
  attr_accessor :weatherDuration
  attr_accessor :defaultTerrain
  attr_accessor :terrain
  attr_accessor :terrainDuration

  def initialize
    @effects = []
    @effects[PBEffects::AmuletCoin]      = false
    @effects[PBEffects::FairyLock]       = 0
    @effects[PBEffects::FusionBolt]      = false
    @effects[PBEffects::FusionFlare]     = false
    @effects[PBEffects::Gravity]         = 0
    @effects[PBEffects::HappyHour]       = false
    @effects[PBEffects::IonDeluge]       = false
    @effects[PBEffects::MagicRoom]       = 0
    @effects[PBEffects::MudSportField]   = 0
    @effects[PBEffects::PayDay]          = 0
    @effects[PBEffects::TrickRoom]       = 0
    @effects[PBEffects::WaterSportField] = 0
    @effects[PBEffects::WonderRoom]      = 0
	@effects[PBEffects::InverseRoom]     = 0
    @defaultWeather  = :None
    @weather         = :None
    @weatherDuration = 0
    @defaultTerrain  = :None
    @terrain         = :None
    @terrainDuration = 0
  end
end

class Battle::Move
  #=============================================================================
  # Type effectiveness calculation
  #=============================================================================
  def pbCalcTypeModSingle(moveType, defType, user, target)
    ret = Effectiveness.calculate(moveType, defType)
    if Effectiveness.ineffective_type?(moveType, defType)
	  if battle.pbCheckGlobalAbility(:INVERSER) || battle.field.effects[PBEffects::InverseRoom] > 0 # inverse battle 0→2
	     ret = Effectiveness::SUPER_EFFECTIVE_MULTIPLIER
	  end	 
      # Ring Target
      if target.hasActiveItem?(:RINGTARGET)
        ret = Effectiveness::NORMAL_EFFECTIVE_MULTIPLIER
      end
      # Foresight
      if (user.hasActiveAbility?(:SCRAPPY) || target.effects[PBEffects::Foresight]) &&
         defType == :GHOST
        ret = Effectiveness::NORMAL_EFFECTIVE_MULTIPLIER
      end
      # Miracle Eye
      if target.effects[PBEffects::MiracleEye] && defType == :DARK
        ret = Effectiveness::NORMAL_EFFECTIVE_MULTIPLIER
      end
    elsif Effectiveness.super_effective_type?(moveType, defType)
	  if battle.pbCheckGlobalAbility(:INVERSER) || battle.field.effects[PBEffects::InverseRoom] > 0  # inverse battle 2→0.5
	     ret = Effectiveness::NOT_VERY_EFFECTIVE_MULTIPLIER
	  end	 
      # Delta Stream's Weather
      if target.effectiveWeather == :StrongWinds && defType == :FLYING
        ret = Effectiveness::NORMAL_EFFECTIVE_MULTIPLIER
      end
    elsif Effectiveness.not_very_effective_type?(moveType, defType)
	  if battle.pbCheckGlobalAbility(:INVERSER) || battle.field.effects[PBEffects::InverseRoom] > 0  # inverse battle 0.5→2
	     ret = Effectiveness::SUPER_EFFECTIVE_MULTIPLIER
	  end	      
    end
    # Grounded Flying-type Pokémon become susceptible to Ground moves
    if !target.airborne? && defType == :FLYING && moveType == :GROUND
      ret = Effectiveness::NORMAL_EFFECTIVE_MULTIPLIER
    end
    return ret
  end
end

class Battle
  def pbEOREndFieldEffects(priority)
    # Trick Room
    pbEORCountDownFieldEffect(PBEffects::TrickRoom,
                              _INTL("The twisted dimensions returned to normal!"))
    # Gravity
    pbEORCountDownFieldEffect(PBEffects::Gravity,
                              _INTL("Gravity returned to normal!"))
    # Water Sport
    pbEORCountDownFieldEffect(PBEffects::WaterSportField,
                              _INTL("The effects of Water Sport have faded."))
    # Mud Sport
    pbEORCountDownFieldEffect(PBEffects::MudSportField,
                              _INTL("The effects of Mud Sport have faded."))
    # Wonder Room
    pbEORCountDownFieldEffect(PBEffects::WonderRoom,
                              _INTL("Wonder Room wore off, and Defense and Sp. Def stats returned to normal!"))
	# Inverse Room
    pbEORCountDownFieldEffect(PBEffects::InverseRoom,
                              _INTL("Inverse Room wore off, the type effectiveness returned to normal!"))						  
    # Magic Room
    pbEORCountDownFieldEffect(PBEffects::MagicRoom,
                              _INTL("Magic Room wore off, and held items' effects returned to normal!"))
  end
end  