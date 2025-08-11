# ================== Settings ==================
SADDLE_SPEED      = 5            # Bike is usually 5; walk is 4
RIDING_SWITCH_ID  = 90           # Free switch to mark "Mounted"

# === Helper: return every species symbol for all forms of given bases. ===
def pbAllFormsOf(*base_ids)
  out = []
  base_ids = base_ids.flatten
  GameData::Species.each do |sp|
    sid = sp.id
    s   = sid.to_s
    base_ids.each do |b|
      bs = b.to_s
      if sid == b || s.start_with?("#{bs}_")
        out << sid
        break
      end
    end
  end
  return out.uniq
end

# === Big curated base list (maintainable) ===
RIDABLE_BASES = [
  # Horses / ride icons
  :PONYTA, :RAPIDASH, :MUDBRAY, :MUDSDALE, :SKIDDO, :GOGOAT, :WYRDEER, :GLASTRIER, :SPECTRIER,
  :ZEBSTRIKA, :BLITZLE, :KELDEO, :GIRAFARIG, :FARIGIRAF, :TAUROS, :STANTLER,
  # Eeveelutions
  :VAPOREON, :JOLTEON, :FLAREON, :ESPEON, :UMBREON, :LEAFEON, :GLACEON, :SYLVEON,
  # Large dogs / wolves
  :GROWLITHE, :ARCANINE, :HOUNDOUR, :HOUNDOOM, :ELECTRIKE, :MANECTRIC,
  :LILLIPUP, :HERDIER, :STOUTLAND, :ROCKRUFF, :LYCANROC, :YAMPER, :BOLTUND,
  :MASCHIFF, :MABOSSTIFF,
  # Bulky quadrupeds you listed (non-exhaustive but broad)
  #:NIDORANf, :NIDORINA, :NIDORANm, :NIDORINO,
  #:VULPIX, :NINETALES, :MEOWTH, :PERSIAN,
  :RHYHORN, :DONPHAN, :PHANPY, :MAMOSWINE, :PILOSWINE, :SWINUB, :BOUFFALANT,
  #:NUMEL, :CAMERUPT, :TORKOAL, :TROPIUS, :ABSOL, :WALREIN, :BEARTIC,
  #:HIPPOPOTAS, :HIPPOWDON, :BUZIEL, :FLOATZEL, :GLAMEOW, :PURUGLY, :STUNKY, :SKUNTANK,
  #:BASCULIN, :BASCULEGION, # if you use them as “land-ish” mounts in your world (optional)
  :DEERLING, :SAWSBUCK, :WOOLLOO, :DUBWOOL, :CUFANT, :COPPERAJAH, :APPLETUN, :AVALUGG,
  #:MAMOSWINE, :CLODSIRE,  # Ursaluna is great as a burly mount
  :CYCLIZAR, :URSALUNA, # your world might want the bike-dragon too
  # Legendaries / box mascots that are quadruped or close enough
  :RAIKOU, :ENTEI, :SUICUNE,
  :COBALION, :TERRAKION, :VIRIZION,
  :XERNEAS, :SOLGALEO, :ZACIAN, :ZAMAZENTA,
  :TINGLU, :CHIENPAO,
].uniq

# Expand to include *all* defined forms (e.g., :PONYTA_1) present in your PBS
MOUNT_ALLOWED_SPECIES = pbAllFormsOf(RIDABLE_BASES)

# ================== Checks ==================
def pbAnyRidable?
  $Trainer.party.any? { |p| p && !p.egg? && MOUNT_ALLOWED_SPECIES.include?(p.species) }
end

def pbSaddleOrBikeCheck
  # If you can ride OR you can bike, allow closing bag.
  return true if pbSaddleCheck
  return pbBikeCheck
end

def pbSaddleCheck
  return false if $PokemonGlobal.surfing
  return false if $game_system.menu_disabled
  # Respect all the same map rules as Bike (indoors, caves, “no bike” maps)
  return false unless pbBikeCheck
  return true if pbAnyRidable?
  return false
end

# ================== Mount / Dismount ==================
def pbMountSaddle
  return if $game_switches[RIDING_SWITCH_ID]
  # Speed like bike, separate flag from $PokemonGlobal.bicycle so both can coexist
  $game_switches[RIDING_SWITCH_ID] = true
  $game_player.move_speed = SADDLE_SPEED

  # Optional: Followers integration (show the mount up front)
  begin
    if defined?(FollowingPkmn)
      lead = $Trainer.party.find { |p| p && !p.egg? && MOUNT_ALLOWED_SPECIES.include?(p.species) }
      FollowingPkmn.set_lead(lead) if lead
    end
  rescue; end

  pbSEPlay("Bike get on") rescue nil
  pbMessage(_INTL("You mounted up."))
end

def pbDismountSaddle
  return unless $game_switches[RIDING_SWITCH_ID]
  $game_switches[RIDING_SWITCH_ID] = false
  $game_player.move_speed = 4
  pbSEPlay("Bike get off") rescue nil
  pbMessage(_INTL("You dismounted."))
end


# ================== UI text (like Bike "Use/Walk") ==================
ItemHandlers::UseText.add(:SADDLEITEM, proc { |item|
  if $game_switches[RIDING_SWITCH_ID]
    next _INTL("Dismount")
  else
    # Show "Ride" if a mount exists, otherwise mirror Bike "Use"
    next (pbAnyRidable?) ? _INTL("Ride") : (($PokemonGlobal.bicycle) ? _INTL("Walk") : _INTL("Use"))
  end
})

# ================== Bag use: close bag then act (like Bike) =========
ItemHandlers::UseFromBag.add(:SADDLEITEM, proc { |item|
  # Close the bag so we can mount OR bike
  next (pbSaddleOrBikeCheck) ? 2 : 0
})

# ================== Field use / Ready Menu ==========================
ItemHandlers::UseInField.add(:SADDLEITEM, proc { |item|
  # If already riding, dismount
  if $game_switches[RIDING_SWITCH_ID]
    pbDismountSaddle
    next true
  end

  # Try to mount a ridable follower first
  if pbSaddleCheck
    pbMountSaddle
    next true
  end

  # No mount? Fall back to Bike behaviour
  if pbBikeCheck
    if $PokemonGlobal.bicycle
      pbDismountBike
    else
      pbMountBike
    end
    next true
  end

  pbMessage(_INTL("You can’t ride here."))
  next false
})
