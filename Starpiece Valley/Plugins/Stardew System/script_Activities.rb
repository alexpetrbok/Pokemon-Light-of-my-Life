#===============================================================================
# Starpiece Valley - NPC Activity: Fishing Together
# Minimal-touch helper that plugs into your NPC "Activities" choice.
# Works with Essentials v21.1 and More Rods (auto-picks best owned rod).
#===============================================================================
module SVActivities
  # --- CONFIG ---------------------------------------------------------------
  # Fill these with your real map IDs and coordinates (player stands facing water).
  SCENIC_FISHING_SPOTS = [
    { name: "River Bend",     map_id: 12,  x: 34, y: 20, dir: 2 },  # ↓
    { name: "Oceanside Dock",  map_id: 78,  x:  21, y: 27, dir: 2 },
    { name: "Farm Pond",     map_id: 42,  x: 41, y:  59, dir: 2 }   # ←
  ]

  SPOTS = [
    {
      name:  "River Bend",
      map:   12,
      player: { x: 34, y: 20, dir: 2 },
      npc:    { sprite: "NPC_Karlee", x: 33, y: 20, dir: 2, event_id: 7 } # reskin existing event 7
    },
    {
      name:  "Lakeside Dock",
      map:   41,
      player: { x: 8, y: 15, dir: 2 },
      npc:    { sprite: "NPC_Generic", x: 9, y: 15, dir: 4, create: true } # create a new event
    },
    {
      name:  "Sea Cliffs",
      map:   82,
      player: { x: 23, y: 3, dir: 3 },
      npc:    { sprite: "NPC_Generic", x: 22, y: 3, dir: 6, create: true }
    }
  ]

  # Energy cost for the whole outing
  ENERGY_COST_TOTAL = 8
  # Affection granted for doing the activity together
  AFFECTION_REWARD  = 20
  # If true, ask to return to original location at the end.
  PROMPT_RETURN     = true
  # Optional: name of an event on fishing maps used as the “spawn point” for the NPC.
  # If present, we temporarily re-sprite that event so the NPC is visibly there.
  # If nil or not found, we’ll still run the dialogue without a sprite.
  NPC_SPAWN_EVENT_NAME = "ACTIVITY_NPC_SPAWN"
  # --------------------------------------------------------------------------

  def self.fishing(npc, energy_cost = ENERGY_COST_TOTAL)
    # Energy check
    if !$player_energy || !$player_energy.respond_to?(:energy) || !$player_energy.respond_to?(:modify_energy)
      pbMessage(_INTL("Energy system not available."))
      return
    end
    if $player_energy.energy < energy_cost
      pbMessage(_INTL("You're too tired to go fishing right now."))
      return
    end

    # Pick a scenic spot
    idx = pbShowCommands(nil, SPOTS.map { |s| s[:name] }, -1)
    return if idx < 0
    spot = SPOTS[idx]

    # Snapshot origin
    origin = {
      map: $game_map.map_id, x: $game_player.x, y: $game_player.y, dir: $game_player.direction
    }

    # Go there
    transfer_player(spot[:map], spot[:player][:x], spot[:player][:y], spot[:player][:dir])

    # Spawn or reskin NPC
    # Prefer npc.overworld_sprite if provided by your NPC object; fallback to spot-config sprite
    sprite_name = (npc.respond_to?(:overworld_sprite) && npc.overworld_sprite) ? npc.overworld_sprite : spot[:npc][:sprite]
    cleanup = spawn_npc(spot[:map], spot[:npc], sprite_name)

    # Opening dialog (safe fallback)
    begin
      if npc.respond_to?(:talk)
        npc.talk(:fishing)
      else
        raise StandardError
      end
    rescue
      pbMessage(_INTL("{1}: Let's drop a line and relax a bit.", npc.respond_to?(:name) ? npc.name : "Friend"))
    end

    # 3 simple loops: fish → small time skip (ignore battle outcome)
    3.times do |i|
      rod = [:SUPERROD, :GOODROD, :OLDROD].find { |sym| $bag.has?(sym) }
      if rod
        ItemHandlers.triggerUseInField(rod)   # runs pbFishing and any battle; we don't branch on result
      else
        pbMessage(_INTL("You don't have a fishing rod..."))
        break
      end
      UnrealTime.add_hours(1) rescue nil
      
    end

    # Spend energy (no relationship state logic per your request)
    $player_energy.modify_energy(-energy_cost)

    # Clean up NPC appearance
    despawn_npc(cleanup)

    # Optional return
    if pbConfirmMessage(_INTL("Head back together?"))
      transfer_player(origin[:map], origin[:x], origin[:y], origin[:dir])
    end
  end

  # --- Internals ------------------------------------------------------------

  def self.transfer_player(map_id, x, y, dir)
    pbFadeOutIn do
      pbDismountBike
      $game_temp.player_new_map_id    = map_id
      $game_temp.player_new_x         = x
      $game_temp.player_new_y         = y
      $game_temp.player_new_direction = dir
      $scene.transfer_player
      $game_map.autoplay
      $game_map.refresh
    end
  end

  # Try several time APIs without forcing your project to change
  def self.advance_hours_safely(n)
    if defined?(UnrealTime) && UnrealTime.respond_to?(:add_hours)
      UnrealTime.add_hours(n)
    elsif defined?(GameTime) && GameTime.respond_to?(:advance_time)
      GameTime.advance_time(0, n, 0) # minutes, hours, days
    elsif Kernel.respond_to?(:pbTimePasses)
      pbTimePasses(n * 60) # minutes
    else
      # Last-resort: no-op (keeps compatibility)
    end
  end

  # Soft guard: allow late starts but warn if less than 'hours' until your 2am cutoff
  def self.time_budget_ok?(hours_needed)
    return true unless defined?(UnrealTime) && UnrealTime.respond_to?(:hour)
    cur_h = UnrealTime.hour
    # Treat 0..1 as post-midnight; assume day rolls/reset at 2am per your loop
    remaining = (cur_h <= 23 ? 24 - cur_h : 0)
    remaining >= hours_needed || cur_h < 1 # Allow after midnight if you want
  end

  # Energy hooks (graceful fallbacks)
  def self.current_energy
    if defined?(SV_Energy) && SV_Energy.respond_to?(:current)
      return SV_Energy.current
    end
    # Fallback: use game variable 50 as an example (change to your real one)
    return $game_variables[50] || 0
  end

  def self.enough_energy?(amt)
    current_energy >= amt
  end

  def self.spend_energy(amt)
    if defined?(SV_Energy) && SV_Energy.respond_to?(:add)
      SV_Energy.add(-amt)
    else
      $game_variables[50] = [0, current_energy - amt].max
    end
  end

  # Affection hooks (graceful fallbacks)
  def self.add_affection(npc, amt)
    if defined?(SV_Relationship) && SV_Relationship.respond_to?(:add_affection)
      SV_Relationship.add_affection(npc, amt)
    else
      # Fallback: do nothing or track via a hash on $PokemonGlobal
      $PokemonGlobal.stv_aff ||= {}
      key = npc_display_name(npc)
      $PokemonGlobal.stv_aff[key] = ($PokemonGlobal.stv_aff[key] || 0) + amt
    end
  end

  def self.npc_display_name(npc)
    npc.is_a?(Symbol) ? npc.to_s.capitalize : npc.to_s
  end

  # Use best owned rod by triggering its normal UseInField handler (so pbFishing runs normally)
  def self.perform_fishing_with_best_rod
    rod_item = best_owned_rod
    if rod_item
      # Ensure we’re facing water; if not, rotate toward it if the tile ahead isn’t fishable
      # (Assumes your scenic spots already face water; this is a safety net)
      # Then trigger the rod as if the player used it.
      result = ItemHandlers.triggerUseInField(rod_item)
      # In Essentials, returning 1 typically means the item was used; battle outcome is handled by the engine.
      return true if result == 1 # hooked & battled at least once in the flow
      # If the engine didn’t start a battle, we can’t perfectly infer bite/hook.
      # Return false to vary the chatter.
      return false
    else
      pbMessage(_INTL("You don’t have a fishing rod…"))
      return false
    end
  end

  # Prioritize your plugin’s highest-tier rods if present
  def self.best_owned_rod
    # Extend this list to match your More Rods items (highest -> lowest)
    # Example symbols; replace with your actual item IDs if different.
    candidate_rods = [
      :ELITE_ROD, :MASTER_ROD, :ULTRAROD, :SUPERROD, :GOODROD, :OLDROD
    ]
    candidate_rods.find { |sym| $bag.has?(sym) }
  end

  # ---- NPC spawn/despawn helpers ------------------------------------------
  # We “reskin” a designated event on the target map so it looks like the NPC.
  # Put a dummy event named ACTIVITY_NPC_SPAWN near the fishing tile on each map.
  def self.begin_spawn_npc_at_spawnpoint(npc_id_or_name)
    return nil unless NPC_SPAWN_EVENT_NAME
    spawn_event = get_event_by_name(NPC_SPAWN_EVENT_NAME)
    return nil unless spawn_event
    # Save original graphic to restore later
    spawn_event.__send__(:instance_variable_set, :@_sv_orig_page, {
      char_name: spawn_event.character_name,
      char_index: spawn_event.character_index,
      dir_fix: spawn_event.direction_fix
    })
    # Apply your NPC’s overworld sprite. Replace these two lines with your naming convention.
    # Example expects a charset per-NPC like "NPC_Karlee", index 0.
    npc_charset = npc_overworld_charset(npc_id_or_name)   # e.g., "NPC_Karlee"
    spawn_event.character_name  = npc_charset
    spawn_event.character_index = 0
    spawn_event.direction_fix   = false
    spawn_event.turn_toward_player
    spawn_event
  rescue
    nil
  end

  def self.end_spawn_npc(spawn_event)
    return unless spawn_event && (orig = spawn_event.instance_variable_get(:@_sv_orig_page))
    spawn_event.character_name  = orig[:char_name]
    spawn_event.character_index = orig[:char_index]
    spawn_event.direction_fix   = orig[:dir_fix]
  end

  def self.get_event_by_name(name)
    $game_map.events.values.find do |ev|
      next false unless ev.list && ev.name
      ev.name == name
    end
  end

  # Stub to map an NPC id/name to a charset filename.
  # Replace with your own lookup (NPC registry, metadata, etc.)
  def self.npc_overworld_charset(npc)
    base = npc.is_a?(Symbol) ? npc.to_s.capitalize : npc.to_s
    "NPC_#{base}"
  end
end
