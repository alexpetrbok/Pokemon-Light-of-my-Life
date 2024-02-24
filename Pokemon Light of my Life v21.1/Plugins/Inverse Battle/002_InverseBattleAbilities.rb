#===============================================================================
# INVERSER inverse type effectiveness
#===============================================================================
Battle::AbilityEffects::OnSwitchIn.add(:INVERSER,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplayPaused(_INTL("{1} reversed the type effectiveness!", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

#===============================================================================
# INVERSEYMAKER
#===============================================================================
Battle::AbilityEffects::OnSwitchIn.add(:INVERSEYMAKER,
  proc { |ability, battler, battle, switch_in|
    next if battle.field.effects[PBEffects::InverseRoom] != 0
    battle.pbShowAbilitySplash(battler)
	battle.field.effects[PBEffects::InverseRoom] = 5
    battle.pbDisplayPaused(_INTL("{1} reversed the dimensions!", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)