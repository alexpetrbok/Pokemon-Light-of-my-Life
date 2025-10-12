#===============================================================================
# Hidden move handlers
#===============================================================================
module HiddenMoveHandlers
  CanUseMove     = MoveHandlerHash.new
  ConfirmUseMove = MoveHandlerHash.new
  UseMove        = MoveHandlerHash.new

  def self.addCanUseMove(item, proc);     CanUseMove.add(item, proc);     end
  def self.addConfirmUseMove(item, proc); ConfirmUseMove.add(item, proc); end
  def self.addUseMove(item, proc);        UseMove.add(item, proc);        end

  def self.hasHandler(item)
    return !CanUseMove[item].nil? && !UseMove[item].nil?
  end

  # Returns whether move can be used
  def self.triggerCanUseMove(item, pokemon, showmsg)
    return false if !CanUseMove[item]
    return CanUseMove.trigger(item, pokemon, showmsg)
  end

  # Returns whether the player confirmed that they want to use the move
  def self.triggerConfirmUseMove(item, pokemon)
    return true if !ConfirmUseMove[item]
    return ConfirmUseMove.trigger(item, pokemon)
  end

  # Returns whether move was used
  def self.triggerUseMove(item, pokemon)
    return false if !UseMove[item]
    return UseMove.trigger(item, pokemon)
  end
end

#===============================================================================
#
#===============================================================================
def pbCanUseHiddenMove?(pkmn, move, showmsg = true)
  return HiddenMoveHandlers.triggerCanUseMove(move, pkmn, showmsg)
end

def pbConfirmUseHiddenMove(pokemon, move)
  return HiddenMoveHandlers.triggerConfirmUseMove(move, pokemon)
end

def pbUseHiddenMove(pokemon, move)
  return HiddenMoveHandlers.triggerUseMove(move, pokemon)
end

# Unused
def pbHiddenMoveEvent
  EventHandlers.trigger(:on_player_interact)
end

def pbCheckHiddenMoveBadge(badge = -1, showmsg = true)
  return true #if badge < 0   # No badge requirement
  return true if $DEBUG
  if (Settings::FIELD_MOVES_COUNT_BADGES) ? $player.badge_count >= badge : $player.badges[badge]
    return true
  end
  pbMessage(_INTL("Sorry, a new Badge is required.")) if showmsg
  return false
end

def _field_item_use(result)
  # Return codes: 0 = not used, 2 = close bag and used
  $game_temp.in_menu = false if $game_temp.respond_to?(:in_menu)
  result ? 2 : 0
end

#===============================================================================
# Hidden move animation
#===============================================================================
def pbHiddenMoveAnimation(pokemon)
  return false if !pokemon
  viewport = Viewport.new(0, 0, Graphics.width, 0)
  viewport.z = 99999
  # Set up sprites
  bg = Sprite.new(viewport)
  bg.bitmap = RPG::Cache.ui("Field move/bg")
  sprite = PokemonSprite.new(viewport)
  sprite.setOffset(PictureOrigin::CENTER)
  sprite.setPokemonBitmap(pokemon)
  sprite.x = Graphics.width + (sprite.bitmap.width / 2)
  sprite.y = bg.bitmap.height / 2
  sprite.z = 1
  sprite.visible = false
  strobebitmap = AnimatedBitmap.new("Graphics/UI/Field move/strobes")
  strobes = []
  strobes_start_x = []
  strobes_timers = []
  15.times do |i|
    strobe = BitmapSprite.new(52, 16, viewport)
    strobe.bitmap.blt(0, 0, strobebitmap.bitmap, Rect.new(0, (i % 2) * 16, 52, 16))
    strobe.z = (i.even? ? 2 : 0)
    strobe.visible = false
    strobes.push(strobe)
  end
  strobebitmap.dispose
  # Do the animation
  phase = 1
  timer_start = System.uptime
  loop do
    Graphics.update
    Input.update
    sprite.update
    case phase
    when 1   # Expand viewport height from zero to full
      viewport.rect.y = lerp(Graphics.height / 2, (Graphics.height - bg.bitmap.height) / 2,
                             0.25, timer_start, System.uptime)
      viewport.rect.height = Graphics.height - (viewport.rect.y * 2)
      bg.oy = (bg.bitmap.height - viewport.rect.height) / 2
      if viewport.rect.y == (Graphics.height - bg.bitmap.height) / 2
        phase = 2
        sprite.visible = true
        timer_start = System.uptime
      end
    when 2   # Slide Pokémon sprite in from right to centre
      sprite.x = lerp(Graphics.width + (sprite.bitmap.width / 2), Graphics.width / 2,
                      0.4, timer_start, System.uptime)
      if sprite.x == Graphics.width / 2
        phase = 3
        pokemon.play_cry
        timer_start = System.uptime
      end
    when 3   # Wait
      if System.uptime - timer_start >= 0.75
        phase = 4
        timer_start = System.uptime
      end
    when 4   # Slide Pokémon sprite off from centre to left
      sprite.x = lerp(Graphics.width / 2, -(sprite.bitmap.width / 2),
                      0.4, timer_start, System.uptime)
      if sprite.x == -(sprite.bitmap.width / 2)
        phase = 5
        sprite.visible = false
        timer_start = System.uptime
      end
    when 5   # Shrink viewport height from full to zero
      viewport.rect.y = lerp((Graphics.height - bg.bitmap.height) / 2, Graphics.height / 2,
                             0.25, timer_start, System.uptime)
      viewport.rect.height = Graphics.height - (viewport.rect.y * 2)
      bg.oy = (bg.bitmap.height - viewport.rect.height) / 2
      phase = 6 if viewport.rect.y == Graphics.height / 2
    end
    # Constantly stream the strobes across the screen
    strobes.each_with_index do |strobe, i|
      strobe.ox = strobe.viewport.rect.x
      strobe.oy = strobe.viewport.rect.y
      if !strobe.visible   # Initial placement of strobes
        randomY = 16 * (1 + rand((bg.bitmap.height / 16) - 2))
        strobe.y = randomY + ((Graphics.height - bg.bitmap.height) / 2)
        strobe.x = rand(Graphics.width)
        strobe.visible = true
        strobes_start_x[i] = strobe.x
        strobes_timers[i] = System.uptime
      elsif strobe.x < Graphics.width   # Move strobe right
        strobe.x = strobes_start_x[i] + lerp(0, Graphics.width * 2, 0.8, strobes_timers[i], System.uptime)
      else   # Strobe is off the screen, reposition it to the left of the screen
        randomY = 16 * (1 + rand((bg.bitmap.height / 16) - 2))
        strobe.y = randomY + ((Graphics.height - bg.bitmap.height) / 2)
        strobe.x = -strobe.bitmap.width - rand(Graphics.width / 4)
        strobes_start_x[i] = strobe.x
        strobes_timers[i] = System.uptime
      end
    end
    pbUpdateSceneMap
    break if phase == 6
  end
  sprite.dispose
  strobes.each { |strobe| strobe.dispose }
  strobes.clear
  bg.dispose
  viewport.dispose
  return true
end

#===============================================================================
# Cut
#===============================================================================
def pbCut
  move = :CUT
  movefinder = $player.get_pokemon_with_move(move)
  if (!pbCheckHiddenMoveBadge(Settings::BADGE_FOR_CUT, false) || (!$DEBUG && !movefinder)) && !$bag.has?(:CUTITEM)
    pbMessage(_INTL("This tree looks like it can be cut down."))
    return false
  end
  if pbConfirmMessage(_INTL("This tree looks like it can be cut down!\nWould you like to cut it?"))
    if !movefinder
      if !$player_energy.modify_energy(ENERGY_CUT)
        pbMessage(_INTL("You don't have enough energy to use that move."))
        return false
      end
    end

    $stats.cut_count += 1
    speciesname = (movefinder) ? movefinder.name : $player.name
    pbMessage(_INTL("{1} used {2}!", speciesname, GameData::Move.get(move).name))
    pbHiddenMoveAnimation(movefinder)

    qty = 0
    rand(1..5).times { qty += 1 if rand(100) < 50 }
    if qty > 3
      pbEncounter(:HeadbuttLow)
      $stats.headbutt_count += 1
    elsif qty > 0
      $bag.add(:WOOD, qty)
      pbShowItemDisplay(:WOOD, qty)
    else
      $bag.add(:WOOD, 2)
      pbShowItemDisplay(:WOOD, 2)
      $bag.add(:ORANBERRY, 1)
      pbShowItemDisplay(:ORANBERRY, 1)
    end
    return true
  end
  return false
end

ItemHandlers::UseInField.add(:CUTITEM, proc { |item| pbCut })

ItemHandlers::UseFromBag.add(:CUTITEM, proc { |item| 
  facingEvent = $game_player.pbFacingEvent 
  if !facingEvent || !facingEvent.name[/cuttree/i]
    pbMessage(_INTL("You can't use that here."))
    next 0
  end
  next 2 
})

HiddenMoveHandlers::CanUseMove.add(:CUT, proc { |move, pkmn, showmsg|
  next false if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_CUT, showmsg)
  facingEvent = $game_player.pbFacingEvent
  if !facingEvent || !facingEvent.name[/cuttree/i]
    pbMessage(_INTL("You can't use that here.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:CUT, proc { |move, pokemon|
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!", pokemon.name, GameData::Move.get(move).name))
  end
  $stats.cut_count += 1
  facingEvent = $game_player.pbFacingEvent
  pbSmashEvent(facingEvent) if facingEvent
  next true
})

def pbSmashEvent(event)
  return if !event
  if event.name[/cuttree/i]
    pbSEPlay("Cut")
  elsif event.name[/smashrock/i]
    pbSEPlay("Rock Smash")
  elsif event.name[/digspot/i]
    pbSEPlay("Rock Smash")
  end
  pbMoveRoute(event, [PBMoveRoute::WAIT, 2,
                      PBMoveRoute::TURN_LEFT, PBMoveRoute::WAIT, 2,
                      PBMoveRoute::TURN_RIGHT, PBMoveRoute::WAIT, 2,
                      PBMoveRoute::TURN_UP, PBMoveRoute::WAIT, 2])
  pbWait(0.4)
  event.erase
  $PokemonMap&.addErasedEvent(event.id)
end

#===============================================================================
# Dig
#===============================================================================
def pbUseDigFromItem
  # Mirror vanilla DIG UseMove (escape to last escape point)
  escape = ($PokemonGlobal.escapePoint rescue nil)
  facingEvent = $game_player.pbFacingEvent

  cave_dig = (!escape || escape == [] || !$game_player.can_map_transfer_with_follower?)
  item_dig = (facingEvent && facingEvent.name[/digspot/i])
  if !cave_dig && !item_dig
    pbMessage(_INTL("You can't use that here.")) 
    return false
  end

  if cave_dig 
    return false unless pbConfirmMessage(_INTL("Want to dig up items?")) if item_dig
  else
    mapname = pbGetMapNameFromId(escape[0])
    return false unless pbConfirmMessage(_INTL("Want to escape from here and return to {1}?", mapname)) if cave_dig
  end

  movefinder = $player.get_pokemon_with_move(:DIG)
  if !movefinder && $bag.has?(:DIGITEM)
    if !$player_energy.modify_energy(ENERGY_DIG)
      pbMessage(_INTL("You don't have enough energy to dig."))
      return false
    end
  end

  if item_dig
    pbDigSpot
  else
    pbMessage(_INTL("{1} started digging...", $player.name))
    pbFadeOutIn do
      $game_temp.player_new_map_id    = escape[0]
      $game_temp.player_new_x         = escape[1]
      $game_temp.player_new_y         = escape[2]
      $game_temp.player_new_direction = escape[3]
      pbDismountBike
      $scene.transfer_player
      $game_map.autoplay
      $game_map.refresh
    end
    pbEraseEscapePoint
  end
  true
end

def pbDigSpot
  facingEvent = $game_player.pbFacingEvent
  #return if !facingEvent || !facingEvent.name[/digspot/i]
  if !$bag.has?(:DIGITEM)
    pbMessage(_INTL("You can't dig that up."))
    return false
  end
  movefinder = $player.get_pokemon_with_move(:DIG)
  if pbConfirmMessage(_INTL("Want to dig up items?"))
    if movefinder
      pbHiddenMoveAnimation(movefinder)
      pbMessage(_INTL("{1} used {2}!", movefinder.name, :DIG))
    elsif $player_energy.modify_energy(ENERGY_DIG)
      pbMessage(_INTL("{1} used Dig!", $player.name))
    else
      pbMessage(_INTL("You don't have enough energy to dig."))
      return false
    end
    pbDigItems
    return true
  else
    return false
  end
end 

def pbDigItems
  facingEvent = $game_player.pbFacingEvent
  pbSEPlay("Dig")
  pbWait(0.5)
  qty = 0
  rand(1..10).times { qty += 1 if rand(100) < 20 }
  if qty > 6
    $bag.add(:NUGGET, 1)
    pbShowItemDisplay(:NUGGET, 1)
  elsif qty > 3
    $bag.add(:GEODE, 1)
    pbShowItemDisplay(:GEODE, 1)
  elsif qty > 0
    $bag.add(:ORE, qty)
    pbShowItemDisplay(:ORE, qty)
  else
    pbEncounter(:RockSmash)
  end
  $stats.dig_count += 1
  pbSmashEvent(facingEvent)
  return true
end

ItemHandlers::UseInField.add(:DIGITEM, proc { |item| pbUseDigFromItem })

ItemHandlers::UseFromBag.add(:DIGITEM, proc { |item| 
  escape = ($PokemonGlobal.escapePoint rescue nil)
  faceingEvent = $game_player.pbFacingEvent
  if !escape || escape == [] || faceingEvent&.name[/digspot/i] 
    pbMessage(_INTL("You can't use that here."))
    next 0
  end
  next 2 
})


HiddenMoveHandlers::CanUseMove.add(:DIG, proc { |move, pkmn, showmsg|
  escape = ($PokemonGlobal.escapePoint rescue nil)
  if !escape || escape == []
    pbMessage(_INTL("You can't use that here.")) if showmsg
    next false
  end
  if !$game_player.can_map_transfer_with_follower?
    pbMessage(_INTL("It can't be used when you have someone with you.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::ConfirmUseMove.add(:DIG, proc { |move, pkmn|
  escape = ($PokemonGlobal.escapePoint rescue nil)
  next false if !escape || escape == []
  mapname = pbGetMapNameFromId(escape[0])
  next pbConfirmMessage(_INTL("Want to escape from here and return to {1}?", mapname))
})

HiddenMoveHandlers::UseMove.add(:DIG, proc { |move, pokemon|
  escape = ($PokemonGlobal.escapePoint rescue nil)
  facingEvent = $game_player.pbFacingEvent
  if facingEvent && facingEvent.name[/digspot/i]
    pbDigSpot
    $stats.dig_count += 1
    next true
  elsif escape
    if !pbHiddenMoveAnimation(pokemon)
      pbMessage(_INTL("{1} used {2}!", pokemon.name, GameData::Move.get(move).name))
    end
    pbFadeOutIn do
      $game_temp.player_new_map_id    = escape[0]
      $game_temp.player_new_x         = escape[1]
      $game_temp.player_new_y         = escape[2]
      $game_temp.player_new_direction = escape[3]
      pbDismountBike
      $scene.transfer_player
      $game_map.autoplay
      $game_map.refresh
    end
    pbEraseEscapePoint
    $stats.dig_count += 1
    next true
  end
  next false
})

#===============================================================================
# Dive
#===============================================================================
def pbDive
  map_metadata = $game_map.metadata
  return false if !map_metadata || !map_metadata.dive_map_id
  move = :DIVE
  movefinder = $player.get_pokemon_with_move(move)
  if (!pbCheckHiddenMoveBadge(Settings::BADGE_FOR_DIVE, false) || (!$DEBUG && !movefinder)) && !$bag.has?(:DIVEITEM)
    pbMessage(_INTL("The sea is deep here. A Pokémon may be able to go underwater."))
    return false
  end
  if pbConfirmMessage(_INTL("The sea is deep here. Would you like to use Dive?"))
    speciesname = (movefinder) ? movefinder.name : $player.name
    pbMessage(_INTL("{1} used {2}!", speciesname, GameData::Move.get(move).name))
    pbHiddenMoveAnimation(movefinder)
    pbFadeOutIn do
      $game_temp.player_new_map_id    = map_metadata.dive_map_id
      $game_temp.player_new_x         = $game_player.x
      $game_temp.player_new_y         = $game_player.y
      $game_temp.player_new_direction = $game_player.direction
      $PokemonGlobal.surfing = false
      $PokemonGlobal.diving  = true
      $stats.dive_count += 1
      pbUpdateVehicle
      $scene.transfer_player(false)
      $game_map.autoplay
      $game_map.refresh
    end
    return true
  end
  return false
end

def pbSurfacing
  return if !$PokemonGlobal.diving
  surface_map_id = nil
  GameData::MapMetadata.each do |map_data|
    next if !map_data.dive_map_id || map_data.dive_map_id != $game_map.map_id
    surface_map_id = map_data.id
    break
  end
  return if !surface_map_id
  move = :DIVE
  movefinder = $player.get_pokemon_with_move(move)
  if (!pbCheckHiddenMoveBadge(Settings::BADGE_FOR_DIVE, false) || (!$DEBUG && !movefinder)) && !$bag.has?(:DIVEITEM)
    pbMessage(_INTL("Light is filtering down from above. A Pokémon may be able to surface here."))
    return false
  end
  if pbConfirmMessage(_INTL("Light is filtering down from above. Would you like to use Dive?"))
    speciesname = (movefinder) ? movefinder.name : $player.name
    pbMessage(_INTL("{1} used {2}!", speciesname, GameData::Move.get(move).name))
    pbHiddenMoveAnimation(movefinder)
    pbFadeOutIn do
      $game_temp.player_new_map_id    = surface_map_id
      $game_temp.player_new_x         = $game_player.x
      $game_temp.player_new_y         = $game_player.y
      $game_temp.player_new_direction = $game_player.direction
      $PokemonGlobal.surfing = true
      $PokemonGlobal.diving  = false
      pbUpdateVehicle
      $scene.transfer_player(false)
      surfbgm = GameData::Metadata.get.surf_BGM
      (surfbgm) ? pbBGMPlay(surfbgm) : $game_map.autoplayAsCue
      $game_map.refresh
    end
    return true
  end
  return false
end

ItemHandlers::UseInField.add(:DIVEITEM, proc { |item| 
  if $game_player.terrain_tag.can_dive
    pbDive
  elsif $PokemonGlobal.diving
    surface_map_id = nil
    GameData::MapMetadata.each do |map_data|
      next if !map_data.dive_map_id || map_data.dive_map_id != $game_map.map_id
      surface_map_id = map_data.id
      break
    end
    if surface_map_id &&
        $map_factory.getTerrainTag(surface_map_id, $game_player.x, $game_player.y).can_dive
      pbSurfacing
    end
  else
    pbMessage(_INTL("You can't use that here."))
    next false
  end
})
ItemHandlers::UseFromBag.add(:DIVEITEM, proc { |item| next 2 })

EventHandlers.add(:on_player_interact, :diving,
  proc {
    if $PokemonGlobal.diving
      surface_map_id = nil
      GameData::MapMetadata.each do |map_data|
        next if !map_data.dive_map_id || map_data.dive_map_id != $game_map.map_id
        surface_map_id = map_data.id
        break
      end
      if surface_map_id &&
         $map_factory.getTerrainTag(surface_map_id, $game_player.x, $game_player.y).can_dive
        pbSurfacing
      end
    elsif $game_player.terrain_tag.can_dive
      pbDive
    end
  }
)

HiddenMoveHandlers::CanUseMove.add(:DIVE, proc { |move, pkmn, showmsg|
  next false if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_DIVE, showmsg)
  if $PokemonGlobal.diving
    surface_map_id = nil
    GameData::MapMetadata.each do |map_data|
      next if !map_data.dive_map_id || map_data.dive_map_id != $game_map.map_id
      surface_map_id = map_data.id
      break
    end
    if !surface_map_id ||
       !$map_factory.getTerrainTag(surface_map_id, $game_player.x, $game_player.y).can_dive
      pbMessage(_INTL("You can't use that here.")) if showmsg
      next false
    end
  else
    if !$game_map.metadata&.dive_map_id
      pbMessage(_INTL("You can't use that here.")) if showmsg
      next false
    end
    if !$game_player.terrain_tag.can_dive
      pbMessage(_INTL("You can't use that here.")) if showmsg
      next false
    end
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:DIVE, proc { |move, pokemon|
  wasdiving = $PokemonGlobal.diving
  if $PokemonGlobal.diving
    dive_map_id = nil
    GameData::MapMetadata.each do |map_data|
      next if !map_data.dive_map_id || map_data.dive_map_id != $game_map.map_id
      dive_map_id = map_data.id
      break
    end
  else
    dive_map_id = $game_map.metadata&.dive_map_id
  end
  next false if !dive_map_id
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!", pokemon.name, GameData::Move.get(move).name))
  end
  pbFadeOutIn do
    $game_temp.player_new_map_id    = dive_map_id
    $game_temp.player_new_x         = $game_player.x
    $game_temp.player_new_y         = $game_player.y
    $game_temp.player_new_direction = $game_player.direction
    $PokemonGlobal.surfing = wasdiving
    $PokemonGlobal.diving  = !wasdiving
    pbUpdateVehicle
    $scene.transfer_player(false)
    $game_map.autoplay
    $game_map.refresh
  end
  next true
})

#===============================================================================
# Flash
#===============================================================================
def pbUseFlashFromItem
  # Mirror vanilla FLASH UseMove without needing a Pokémon argument
  return false if $PokemonGlobal.flashUsed
  #return false unless $game_map.metadata&.dark_map
  $game_temp.in_menu = false if $game_temp.respond_to?(:in_menu)
  darkness = $game_temp.darkness_sprite
  return false if !darkness || darkness.disposed?
  pbMessage(_INTL("{1} raised a lantern.", $player.name))
  $PokemonGlobal.flashUsed = true
  $stats.flash_count += 1 if $stats.respond_to?(:flash_count)
  duration = 0.7
  pbWait(duration) do |dt|
    darkness.radius = lerp(Settings::INITIAL_DARKNESS_CIRCLE, Settings::FLASH_CIRCLE_RADIUS, duration, dt)
  end
  darkness.radius = Settings::FLASH_CIRCLE_RADIUS
  true
end 

ItemHandlers::UseInField.add(:FLASHITEM, proc { |item| pbUseFlashFromItem })
ItemHandlers::UseFromBag.add(:FLASHITEM, proc { |item| next 2 })

HiddenMoveHandlers::CanUseMove.add(:FLASH, proc { |move, pkmn, showmsg|
  next false if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_FLASH, showmsg)
  if !$game_map.metadata&.dark_map
    pbMessage(_INTL("You can't use that here.")) if showmsg
    next false
  end
  if $PokemonGlobal.flashUsed
    pbMessage(_INTL("Flash is already being used.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:FLASH, proc { |move, pokemon|
  darkness = $game_temp.darkness_sprite
  next false if !darkness || darkness.disposed?
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!", pokemon.name, GameData::Move.get(move).name))
  end
  $PokemonGlobal.flashUsed = true
  $stats.flash_count += 1
  duration = 0.7
  pbWait(duration) do |delta_t|
    darkness.radius = lerp(darkness.radiusMin, darkness.radiusMax, duration, delta_t)
  end
  darkness.radius = darkness.radiusMax
  next true
})

#===============================================================================
# Fly
#===============================================================================
def pbCanFly?(pkmn = nil, show_messages = false)
  #return false if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_FLY, show_messages)
  return false if !$DEBUG && !pkmn && !$player.get_pokemon_with_move(:FLY)
  if !$game_player.can_map_transfer_with_follower?
    pbMessage(_INTL("It can't be used when you have someone with you.")) if show_messages
    return false
  end
  if !$game_map.metadata&.outdoor_map
    pbMessage(_INTL("You can't use that here.")) if show_messages
    return false
  end
  return true
end

ItemHandlers::UseFromBag.add(:FLYITEM, proc { |item| 
  if !$game_map.metadata&.outdoor_map
    pbMessage(_INTL("You can't use that here.")) 
    next 0
  end
  next 2 
})
ItemHandlers::UseInField.add(:FLYITEM, proc { |item|
  scene = PokemonRegionMap_Scene.new(-1, false)
  screen = PokemonRegionMapScreen.new(scene)
  ret = screen.pbStartFlyScreen
  if ret
    $game_temp.fly_destination = ret
  end
  pbFlyToNewLocation
})

def pbFlyToNewLocation(pkmn = nil, move = :FLY)
  return false if $game_temp.fly_destination.nil?
  pkmn = $player.get_pokemon_with_move(move) if !pkmn
  if !$DEBUG #&& !pkmn
    $game_temp.fly_destination = nil
    yield if block_given?
    return false
  end
  if !pkmn || !pbHiddenMoveAnimation(pkmn)
    name = pkmn&.name || $player.name
    pbMessage(_INTL("{1} used {2}!", name, GameData::Move.get(move).name))
  end
  $stats.fly_count += 1
  pbFadeOutIn do
    pbSEPlay("Fly")
    $game_temp.player_new_map_id    = $game_temp.fly_destination[0]
    $game_temp.player_new_x         = $game_temp.fly_destination[1]
    $game_temp.player_new_y         = $game_temp.fly_destination[2]
    $game_temp.player_new_direction = 2
    $game_temp.fly_destination = nil
    pbDismountBike
    $scene.transfer_player
    $game_map.autoplay
    $game_map.refresh
    yield if block_given?
    pbWait(0.25)
  end
  pbEraseEscapePoint
  return true
end

HiddenMoveHandlers::CanUseMove.add(:FLY, proc { |move, pkmn, showmsg|
  next pbCanFly?(pkmn, showmsg)
})

HiddenMoveHandlers::UseMove.add(:FLY, proc { |move, pkmn|
  if $game_temp.fly_destination.nil?
    pbMessage(_INTL("You can't use that here."))
    next false
  end
  pbFlyToNewLocation(pkmn)
  next true
})

#===============================================================================
# Headbutt
#===============================================================================
def pbHeadbuttEffect(event = nil)
  pbSEPlay("Headbutt")
  pbWait(1.0)
  event = $game_player.pbFacingEvent(true) if !event
  a = (event.x + (event.x / 24).floor + 1) * (event.y + (event.y / 24).floor + 1)
  a = (a * 2 / 5) % 10   # Even 2x as likely as odd, 0 is 1.5x as likely as odd
  b = $player.public_ID % 10   # Practically equal odds of each value
  chance = 1                 # ~50%
  if a == b                    # 10%
    chance = 8
  elsif a > b && (a - b).abs < 5   # ~30.3%
    chance = 5
  elsif a < b && (a - b).abs > 5   # ~9.7%
    chance = 5
  end
  if rand(10) >= chance
    pbMessage(_INTL("Nope. Nothing..."))
  else
    enctype = (chance == 1) ? :HeadbuttLow : :HeadbuttHigh
    if pbEncounter(enctype)
      $stats.headbutt_battles += 1
    else
      pbMessage(_INTL("Nope. Nothing..."))
    end
  end
end

def pbHeadbutt(event = nil)
  move = :HEADBUTT
  movefinder = $player.get_pokemon_with_move(move)
  if (!$DEBUG && !movefinder) && !$bag.has?(:HEADBUTTITEM)
    pbMessage(_INTL("A Pokémon could be in this tree. Maybe a Pokémon could shake it."))
    return false
  end
  if pbConfirmMessage(_INTL("A Pokémon could be in this tree. Would you like to use Headbutt?"))
    if !movefinder
      if !$player_energy.modify_energy(ENERGY_HEADBUTT)
        pbMessage(_INTL("You don't have enough energy to use that move."))
        return false
      end
    end
    $stats.headbutt_count += 1
    speciesname = (movefinder) ? movefinder.name : $player.name
    pbMessage(_INTL("{1} used {2}!", speciesname, GameData::Move.get(move).name))
    pbHiddenMoveAnimation(movefinder)
    pbHeadbuttEffect(event)
    return true
  end
  return false
end

ItemHandlers::UseInField.add(:HEADBUTTITEM, proc { |item| pbHeadbutt })
ItemHandlers::UseFromBag.add(:HEADBUTTITEM, proc { |item| 
  facingEvent = $game_player.pbFacingEvent 
  if !facingEvent || !facingEvent.name[/headbutttree/i] 
    pbMessage(_INTL("You can't use that here."))
    next 0
  end
  next 2
})


HiddenMoveHandlers::CanUseMove.add(:HEADBUTT, proc { |move, pkmn, showmsg|
  facingEvent = $game_player.pbFacingEvent
  if !facingEvent || !facingEvent.name[/headbutttree/i]
    pbMessage(_INTL("You can't use that here.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:HEADBUTT, proc { |move, pokemon|
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!", pokemon.name, GameData::Move.get(move).name))
  end
  $stats.headbutt_count += 1
  facingEvent = $game_player.pbFacingEvent
  pbHeadbuttEffect(facingEvent)
})

#===============================================================================
# Rock Smash
#===============================================================================
def pbRockSmashRandomEncounter
  if $PokemonEncounters.encounter_triggered?(:RockSmash, false, false)
    $stats.rock_smash_battles += 1
    pbEncounter(:RockSmash)
  end
end

def pbRockSmash
  move = :ROCKSMASH
  movefinder = $player.get_pokemon_with_move(move)
  if (!pbCheckHiddenMoveBadge(Settings::BADGE_FOR_ROCKSMASH, false) || (!$DEBUG && !movefinder)) && !$bag.has?(:ROCKSMASHITEM)
    pbMessage(_INTL("It's a rugged rock, but a Pokémon may be able to smash it."))
    return false
  end
  if pbConfirmMessage(_INTL("This rock seems breakable with a hidden move.\nWould you like to use Rock Smash?"))
    if !movefinder
      if !$player_energy.modify_energy(ENERGY_ROCKSMASH)
        pbMessage(_INTL("You don't have enough energy to use that move."))
        return false
      end
    end
    $stats.rock_smash_count += 1
    speciesname = (movefinder) ? movefinder.name : $player.name
    pbHiddenMoveAnimation(movefinder)
    pbMessage(_INTL("{1} used {2}!", speciesname, GameData::Move.get(move).name))
    pbRockSmashRandomEncounter
    qty = 0
    rand(1..5).times { qty += 1 if rand(100) < 30 }
    if qty > 3
      $bag.add(:GEODE, 1)
      pbShowItemDisplay(:GEODE, 1)
    elsif qty > 0
      $bag.add(:ORE, qty)
      pbShowItemDisplay(:ORE, qty)
    end
    return true
  end
  return false
end

ItemHandlers::UseInField.add(:ROCKSMASHITEM, proc { |item| pbRockSmash })
ItemHandlers::UseFromBag.add(:ROCKSMASHITEM, proc { |item| 
  facingEvent = $game_player.pbFacingEvent
  if !facingEvent || !facingEvent.name[/smashrock/i]
    pbMessage(_INTL("You can't use that here."))
    next 0
  end
  next 2 
})

HiddenMoveHandlers::CanUseMove.add(:ROCKSMASH, proc { |move, pkmn, showmsg|
  next false if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_ROCKSMASH, showmsg)
  facingEvent = $game_player.pbFacingEvent
  if !facingEvent || !facingEvent.name[/smashrock/i]
    pbMessage(_INTL("You can't use that here.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:ROCKSMASH, proc { |move, pokemon|
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!", pokemon.name, GameData::Move.get(move).name))
  end
  $stats.rock_smash_count += 1
  facingEvent = $game_player.pbFacingEvent
  if facingEvent
    pbSmashEvent(facingEvent)
    pbRockSmashRandomEncounter
  end
  next true
})

#===============================================================================
# Strength
#===============================================================================
def pbStrength
  if $PokemonMap.strengthUsed
    pbMessage(_INTL("Strength made it possible to move boulders around."))
    return false
  end
  move = :STRENGTH
  movefinder = $player.get_pokemon_with_move(move)
  if (!pbCheckHiddenMoveBadge(Settings::BADGE_FOR_STRENGTH, false) || (!$DEBUG && !movefinder)) && !$bag.has?(:STRENGTHITEM)
    pbMessage(_INTL("It's a big boulder, but a Pokémon may be able to push it aside."))
    return false
  end
  pbMessage(_INTL("It's a big boulder, but you may be able to push it aside with a hidden move.") + "\1")
  if pbConfirmMessage(_INTL("Would you like to use Strength?"))
    speciesname = (movefinder) ? movefinder.name : $player.name
    pbMessage(_INTL("{1} used {2}!", speciesname, GameData::Move.get(move).name))
    pbHiddenMoveAnimation(movefinder)
    pbMessage(_INTL("Strength made it possible to move boulders around!"))
    $PokemonMap.strengthUsed = true
    return true
  end
  return false
end

ItemHandlers::UseFromBag.add(:STRENGTHITEM, proc { |item|
  if $PokemonMap.strengthUsed
    pbMessage(_INTL("Strength is already being used.")) 
    next 0
  end
  next 2
})

ItemHandlers::UseFromBag.add(:STRENGTHITEM, proc { |item| 
  if $PokemonMap.strengthUsed
    pbMessage(_INTL("Strength is already being used."))
    next 0
  end
  next 2 
})
ItemHandlers::UseInField.add(:STRENGTHITEM, proc { |item| 
  if pbConfirmMessage(_INTL("Would you like to use Strength?"))
    pbMessage(_INTL("{1} used {2}!", $player.name, :STRENGTH))
    pbMessage(_INTL("Strength made it possible to move boulders around!"))
    $PokemonMap.strengthUsed = true
    next true
  end
  next false 
})



EventHandlers.add(:on_player_interact, :strength_event,
  proc {
    facingEvent = $game_player.pbFacingEvent
    pbStrength if facingEvent && facingEvent.name[/strengthboulder/i]
  }
)

HiddenMoveHandlers::CanUseMove.add(:STRENGTH, proc { |move, pkmn, showmsg|
  next false if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_STRENGTH, showmsg)
  if $PokemonMap.strengthUsed
    pbMessage(_INTL("Strength is already being used.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:STRENGTH, proc { |move, pokemon|
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!", pokemon.name, GameData::Move.get(move).name) + "\1")
  end
  pbMessage(_INTL("Strength made it possible to move boulders around!"))
  $PokemonMap.strengthUsed = true
  next true
})

#===============================================================================
# Surf
#===============================================================================
def pbSurf
  return false if !$game_player.can_ride_vehicle_with_follower?
  move = :SURF
  movefinder = $player.get_pokemon_with_move(move)
  if (!pbCheckHiddenMoveBadge(Settings::BADGE_FOR_SURF, false) || (!$DEBUG && !movefinder)) && !$bag.has?(:SURFITEM)
    return false
  end
  if pbConfirmMessage(_INTL("The water is a deep blue color... Would you like to use Surf on it?"))
    speciesname = (movefinder) ? movefinder.name : $player.name
    pbMessage(_INTL("{1} used {2}!", speciesname, GameData::Move.get(move).name))
    pbCancelVehicles
    pbHiddenMoveAnimation(movefinder)
    surfbgm = GameData::Metadata.get.surf_BGM
    pbCueBGM(surfbgm, 0.5) if surfbgm
    pbStartSurfing
    return true
  end
  return false
end

def pbStartSurfing
  pbCancelVehicles
  $PokemonEncounters.reset_step_count
  $PokemonGlobal.surfing = true
  $stats.surf_count += 1
  pbUpdateVehicle
  $game_temp.surf_base_coords = $map_factory.getFacingCoords($game_player.x, $game_player.y, $game_player.direction)
  $game_player.jumpForward
end

def pbEndSurf(_xOffset, _yOffset)
  return false if !$PokemonGlobal.surfing
  return false if $game_player.pbFacingTerrainTag.can_surf
  base_coords = [$game_player.x, $game_player.y]
  if $game_player.jumpForward
    $game_temp.surf_base_coords = base_coords
    $game_temp.ending_surf = true
    return true
  end
  return false
end

ItemHandlers::UseInField.add(:SURFITEM, proc { |item| pbSurf })
ItemHandlers::UseFromBag.add(:SURFITEM, proc { |item| 
  if $PokemonGlobal.surfing
    pbMessage(_INTL("You're already surfing.")) 
    next 0
  end
  if !$game_player.can_ride_vehicle_with_follower?
    pbMessage(_INTL("It can't be used when you have someone with you.")) 
    next 0
  end
  if $game_map.metadata&.always_bicycle
    pbMessage(_INTL("Let's enjoy cycling!")) 
    next 0
  end
  if !$game_player.pbFacingTerrainTag.can_surf_freely ||
     !$game_map.passable?($game_player.x, $game_player.y, $game_player.direction, $game_player)
    pbMessage(_INTL("No surfing here!")) 
    next 0
  end
  next 2 
})

EventHandlers.add(:on_player_interact, :start_surfing,
  proc {
    next if $PokemonGlobal.surfing
    next if $game_map.metadata&.always_bicycle
    next if !$game_player.pbFacingTerrainTag.can_surf_freely
    next if !$game_map.passable?($game_player.x, $game_player.y, $game_player.direction, $game_player)
    pbSurf
  }
)

# Do things after a jump to start/end surfing.
EventHandlers.add(:on_step_taken, :surf_jump,
  proc { |event|
    next if !$scene.is_a?(Scene_Map) || !event.is_a?(Game_Player)
    next if !$game_temp.surf_base_coords
    # Hide the temporary surf base graphic after jumping onto/off it
    $game_temp.surf_base_coords = nil
    # Finish up dismounting from surfing
    if $game_temp.ending_surf
      pbCancelVehicles
      $PokemonEncounters.reset_step_count
      $game_map.autoplayAsCue   # Play regular map BGM
      $game_temp.ending_surf = false
    end
  }
)

HiddenMoveHandlers::CanUseMove.add(:SURF, proc { |move, pkmn, showmsg|
  next false if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_SURF, showmsg)
  if $PokemonGlobal.surfing
    pbMessage(_INTL("You're already surfing.")) if showmsg
    next false
  end
  if !$game_player.can_ride_vehicle_with_follower?
    pbMessage(_INTL("It can't be used when you have someone with you.")) if showmsg
    next false
  end
  if $game_map.metadata&.always_bicycle
    pbMessage(_INTL("Let's enjoy cycling!")) if showmsg
    next false
  end
  if !$game_player.pbFacingTerrainTag.can_surf_freely ||
     !$game_map.passable?($game_player.x, $game_player.y, $game_player.direction, $game_player)
    pbMessage(_INTL("No surfing here!")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:SURF, proc { |move, pokemon|
  $game_temp.in_menu = false
  pbCancelVehicles
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!", pokemon.name, GameData::Move.get(move).name))
  end
  surfbgm = GameData::Metadata.get.surf_BGM
  pbCueBGM(surfbgm, 0.5) if surfbgm
  pbStartSurfing
  next true
})

#===============================================================================
# Sweet Scent
#===============================================================================
def pbSweetScent
  if $game_screen.weather_type != :None
    pbMessage(_INTL("The sweet scent faded for some reason..."))
    return
  end
  movefinder = $player.get_pokemon_with_move(:SWEETSCENT)
  if !movefinder
    if !$player_energy.modify_energy(ENERGY_SWEETSCENT)
      pbMessage(_INTL("You don't have enough energy to use that move."))
      return 
    end
  end
  viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  viewport.z = 99999
  viewport.color.red   = 255
  viewport.color.green = 32
  viewport.color.blue  = 32
  viewport.color.alpha -= 10
  pbSEPlay("Sweet Scent")
  start_alpha = viewport.color.alpha
  duration = 2.0
  fade_time = 0.4
  pbWait(duration) do |delta_t|
    if delta_t < duration / 2
      viewport.color.alpha = lerp(start_alpha, start_alpha + 128, fade_time, delta_t)
    else
      viewport.color.alpha = lerp(start_alpha + 128, start_alpha, fade_time, delta_t - duration + fade_time)
    end
  end
  viewport.dispose
  pbSEStop(0.5)
  enctype = $PokemonEncounters.encounter_type
  if !enctype || !$PokemonEncounters.encounter_possible_here? ||
     !pbEncounter(enctype, false)
    pbMessage(_INTL("There appears to be nothing here..."))
  end
end

ItemHandlers::UseInField.add(:SWEETSCENTITEM, proc { |item| pbSweetScent })
ItemHandlers::UseFromBag.add(:SWEETSCENTITEM, proc { |item| next 2 })

HiddenMoveHandlers::CanUseMove.add(:SWEETSCENT, proc { |move, pkmn, showmsg|
  next true
})

HiddenMoveHandlers::UseMove.add(:SWEETSCENT, proc { |move, pokemon|
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!", pokemon.name, GameData::Move.get(move).name))
  end
  pbSweetScent
  next true
})

#===============================================================================
# Teleport
#===============================================================================
def pbUseTeleportFromItem
  # Mirror vanilla TELEPORT UseMove without needing a Pokémon argument
  #return false unless $game_map.metadata&.outdoor_map
  healing = $PokemonGlobal.healingSpot
  healing = GameData::PlayerMetadata.get($player.character_ID)&.home if !healing
  healing = GameData::Metadata.get.home if !healing
  return false if !healing
  return false if !$game_player.can_map_transfer_with_follower?
  mapname = pbGetMapNameFromId(healing[0])
  return false unless pbConfirmMessage(_INTL("Want to return to the healing spot used last in {1}?", mapname))
  movefinder = $player.get_pokemon_with_move(:TELEPORT)
  if !movefinder
    if !$player_energy.modify_energy(ENERGY_TELEPORT)
      pbMessage(_INTL("You don't have enough energy to use that move."))
      return false
    end
  end
  pbMessage(_INTL("{1} focused the crystal...", $player.name))
  pbFadeOutIn do
    $game_temp.player_new_map_id    = healing[0]
    $game_temp.player_new_x         = healing[1]
    $game_temp.player_new_y         = healing[2]
    $game_temp.player_new_direction = 2
    pbDismountBike
    $scene.transfer_player
    $game_map.autoplay
    $game_map.refresh
  end
  pbEraseEscapePoint
  return true
end

ItemHandlers::UseInField.add(:TELEPORTITEM, proc { |item| pbUseTeleportFromItem })
ItemHandlers::UseFromBag.add(:TELEPORTITEM, proc { |item| 
  healing = $PokemonGlobal.healingSpot
  healing = GameData::PlayerMetadata.get($player.character_ID)&.home if !healing
  healing = GameData::Metadata.get.home if !healing
  next 0 if !healing
  #return 0 if !$game_player.can_map_transfer_with_follower?
  next 2
})

HiddenMoveHandlers::CanUseMove.add(:TELEPORT, proc { |move, pkmn, showmsg|
  if !$game_map.metadata&.outdoor_map
    pbMessage(_INTL("You can't use that here.")) if showmsg
    next false
  end
  healing = $PokemonGlobal.healingSpot
  healing = GameData::PlayerMetadata.get($player.character_ID)&.home if !healing
  healing = GameData::Metadata.get.home if !healing   # Home
  if !healing
    pbMessage(_INTL("You can't use that here.")) if showmsg
    next false
  end
  if !$game_player.can_map_transfer_with_follower?
    pbMessage(_INTL("It can't be used when you have someone with you.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::ConfirmUseMove.add(:TELEPORT, proc { |move, pkmn|
  healing = $PokemonGlobal.healingSpot
  healing = GameData::PlayerMetadata.get($player.character_ID)&.home if !healing
  healing = GameData::Metadata.get.home if !healing   # Home
  next false if !healing
  mapname = pbGetMapNameFromId(healing[0])
  next pbConfirmMessage(_INTL("Want to return to the healing spot used last in {1}?", mapname))
})

HiddenMoveHandlers::UseMove.add(:TELEPORT, proc { |move, pokemon|
  healing = $PokemonGlobal.healingSpot
  healing = GameData::PlayerMetadata.get($player.character_ID)&.home if !healing
  healing = GameData::Metadata.get.home if !healing   # Home
  next false if !healing
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!", pokemon.name, GameData::Move.get(move).name))
  end
  pbFadeOutIn do
    $game_temp.player_new_map_id    = healing[0]
    $game_temp.player_new_x         = healing[1]
    $game_temp.player_new_y         = healing[2]
    $game_temp.player_new_direction = 2
    pbDismountBike
    $scene.transfer_player
    $game_map.autoplay
    $game_map.refresh
  end
  pbEraseEscapePoint
  next true
})

#===============================================================================
# Waterfall
#===============================================================================
# Starts the ascending of a waterfall.
def pbAscendWaterfall
  return if $game_player.direction != 8   # Can't ascend if not facing up
  terrain = $game_player.pbFacingTerrainTag
  return if !terrain.waterfall && !terrain.waterfall_crest
  $stats.waterfall_count += 1
  $PokemonGlobal.ascending_waterfall = true
  $game_player.through = true
end

# Triggers after finishing each step while ascending/descending a waterfall.
def pbTraverseWaterfall
  if $game_player.direction == 2   # Facing down; descending
    terrain = $game_player.pbTerrainTag
    if ($DEBUG && Input.press?(Input::CTRL)) ||
       (!terrain.waterfall && !terrain.waterfall_crest)
      $PokemonGlobal.descending_waterfall = false
      $game_player.through = false
      return
    end
    $stats.waterfalls_descended += 1 if !$PokemonGlobal.descending_waterfall
    $PokemonGlobal.descending_waterfall = true
    $game_player.through = true
  elsif $PokemonGlobal.ascending_waterfall
    terrain = $game_player.pbTerrainTag
    if ($DEBUG && Input.press?(Input::CTRL)) ||
       (!terrain.waterfall && !terrain.waterfall_crest)
      $PokemonGlobal.ascending_waterfall = false
      $game_player.through = false
      return
    end
    $PokemonGlobal.ascending_waterfall = true
    $game_player.through = true
  end
end

def pbWaterfall
  move = :WATERFALL
  movefinder = $player.get_pokemon_with_move(move)
  if (!pbCheckHiddenMoveBadge(Settings::BADGE_FOR_WATERFALL, false) || (!$DEBUG && !movefinder)) && !$bag.has?(:WATERFALLITEM)
    pbMessage(_INTL("A wall of water is crashing down with a mighty roar."))
    return false
  end
  if pbConfirmMessage(_INTL("It's a large waterfall. Would you like to use Waterfall?"))
    speciesname = (movefinder) ? movefinder.name : $player.name
    pbMessage(_INTL("{1} used {2}!", speciesname, GameData::Move.get(move).name))
    pbHiddenMoveAnimation(movefinder)
    pbAscendWaterfall
    return true
  end
  return false
end

ItemHandlers::UseInField.add(:WATERFALLITEM, proc { |item| pbWaterfall })
ItemHandlers::UseFromBag.add(:WATERFALLITEM, proc { |item|
  terrain = $game_player.pbFacingTerrainTag
  if !terrain.waterfall && !terrain.waterfall_crest
    pbMessage(_INTL("You can't use that here."))
    next 0
  end
  next 2
})

EventHandlers.add(:on_player_interact, :waterfall,
  proc {
    terrain = $game_player.pbFacingTerrainTag
    if terrain.waterfall
      pbWaterfall
    elsif terrain.waterfall_crest
      pbMessage(_INTL("A wall of water is crashing down with a mighty roar."))
    end
  }
)

HiddenMoveHandlers::CanUseMove.add(:WATERFALL, proc { |move, pkmn, showmsg|
  next false if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_WATERFALL, showmsg)
  if !$game_player.pbFacingTerrainTag.waterfall
    pbMessage(_INTL("You can't use that here.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:WATERFALL, proc { |move, pokemon|
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!", pokemon.name, GameData::Move.get(move).name))
  end
  pbAscendWaterfall
  next true
})
