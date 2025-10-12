def load_dialogs
  
  # ============================================
  # ENGINEER Isaac — Dialog & Menus
  # Notes:
  # - Affection range: 0..1000
  #   Milestones used here: 250 (warming), 500 (trust/vision), 800 (legacy/intimacy)
  # - Relationship state is treated as an additional layer like state/season.
  #   Possible values (overlay sets below): :single, :dating_player, :dating_spouse, :married_player, :married_spouse
  # - Default section must stay job-neutral.
  # - Use "\n" for multi-line responses (no leading hyphens).
  # - Script hooks are placeholders you can wire to real functions.
  # ============================================

  GameData::NPC.set_dialog(:ENGINEER, {
    # ---------------------------
    # Neutral, appears in any talk
    # ---------------------------
    default: {
      opener: [
        { text: "Oh, hey. Good timing." },
        { text: "I was just thinking about something and forgot the world existed." },
        { text: "Quiet helps me hear myself think. Glad you dropped by." }
      ],
      chat: [
        { prompt: "You doing okay?", response: "Mostly. People are part of the system too.\nWe fail, recover, and get replaced poorly. I plan around that." },
        { prompt: "What keeps you going?", response: "Small wins. A steady hum. Someone noticing the work matters." , condition: -> { NPCSystem.affection(:ENGINEER) >= 250 } },
        { prompt: "What do you actually want?", response: "A grid that keeps the town safe long after I’m gone.\nPower, water, heat… stable enough to be boring." , condition: -> { NPCSystem.affection(:ENGINEER) >= 500 } }
      ],
      closer: [
        { text: "Thanks for checking in." },
        { text: "Take care. Systems need their operators rested too." },
        { text: "Come by if you need anything." }
      ]
    },

    # ---------------------------
    # Work — Powerplant & Upgrades
    # ---------------------------
    work: {
      opener: [
        { text: "Watch your step. Some of these lines run at two hundred bar." },
        { text: "Everything here balances water, heat, and air.\nIf one drifts, the others catch it." },
        { text: "Bronzor are a degree off. I’ll nudge the reflector array after this." }
      ],
      chat: [
        { prompt: "How does this plant work?", response: "Bronzor reflect sunlight as a Fresnel field.\nSlugma ferries heat into the sand and rock TES.\nRolycoly spins up with Steam Engine when we boil.\nSandshrew chills the LAES tanks.\nPoison-types keep the sewers digesting.\nAll of it ties together with pipes and patience." },
        { prompt: "Wastewater and sewers?", response: "Sewers are veins for pipes, wires, and flow.\nPoison-types eat sludge like digestors. We polish the rest at the plant." },
        { prompt: "District heating and cooling?", response: "TES feeds hot loops in winter and cool loops when we spare the cold.\nIt’s just comfort by circulation." },
        { prompt: "Berry fields solar?", response: "Vertical bifacial panels in Lily’s rows.\nShade the berries, harvest the light. Win-win." },
        { prompt: "Do you need help here?", response: "Sometimes. Humans are failure points, including me.\nDesign with that in mind and the system survives." , condition: -> { NPCSystem.affection(:ENGINEER) >= 500 } },
        { prompt: "What happens if you’re gone?", response: "Then the plant should still breathe on its own.\nThat’s the point." , condition: -> { NPCSystem.affection(:ENGINEER) >= 800 } }
      ],
      shop: [
        { prompt: "Exosuit Fitting (Strength)", response: "Compressed-air assist. Push boulders without wrecking your back.", :script => -> { pbGiveExosuitStrength() } },
        { prompt: "PokéEgg Collector",          response: "Buffer eggs, hatch on your schedule. Robyn gets a breather.",    :script => -> { pbBuyEggCollector() } },
        { prompt: "Farm Upgrades",               response: "Greenhouse, Autowater, and statue kits. Pick your path.",       :script => -> { pbShopPowerplantUpgrades() } }
      ],
      activity: [
        { prompt: "Tour the Plant",  response: "I’ll walk you through the loops. It’s louder than it looks." },
        { prompt: "Prototype Test",  response: "Hold this valve steady and don’t flinch.\nIf the gauge jumps, let go." , condition: -> { NPCSystem.affection(:ENGINEER) >= 600 } }
      ],
      closer: [
        { text: "Flow’s steady. That’ll do." },
        { text: "I’ll tweak mirror alignment after I log these readings." },
        { text: "Thanks for the company." , condition: -> { NPCSystem.affection(:ENGINEER) >= 250 } }
      ]
    },

    # ---------------------------
    # Leisure — away from consoles
    # ---------------------------
    leisure: {
      opener: [
        { text: "Strange being off the floor. Feels… light." },
        { text: "Sandshrew insisted on a walk. He wins most arguments." },
        { text: "For once, I’m listening to the river instead of measuring it." }
      ],
      chat: [
        { prompt: "What relaxes you?", response: "Quiet paths. Even better if I leave the tools behind." },
        { prompt: "Your big dream again?", response: "A plant that doesn’t need a hero.\nResilient enough that any one person can step away." , condition: -> { NPCSystem.affection(:ENGINEER) >= 500 } },
        { prompt: "Need anything?", response: "Ore and parts keep statues happy. Curiosity keeps me going." , condition: -> { NPCSystem.affection(:ENGINEER) >= 250 } }
      ],
      activity: [
        { prompt: "Inspect the Greenhouse", response: "Check root temps and valve timing. Bulbasaur statue should be re-seeding." },
        { prompt: "Statue Maintenance",     response: "Swap upgrade cores. Squirtle handles pressure, Charmander scares pests." }
      ],
      date: [
        { prompt: "Night Watch at the Plant", response: "Turbines hum like a heartbeat. It helps me think." , condition: -> { NPCSystem.relationship_state?(:ENGINEER, :dating_player) } },
        { prompt: "Hot Spring Break",         response: "Even I can stop moving for a bit. Don’t quote me." , condition: -> { NPCSystem.relationship_state?(:ENGINEER, :dating_player) } }
      ],
      closer: [
        { text: "I’ll head back before the alarms miss me." },
        { text: "This helped. Thanks." , condition: -> { NPCSystem.affection(:ENGINEER) >= 500 } },
        { text: "You make the noise fade out." , condition: -> { NPCSystem.relationship_state?(:ENGINEER, :dating_player) } }
      ]
    },

    # ---------------------------
    # Seasonal flavor overlays
    # ---------------------------
    spring: {
      opener: [
        { text: "Thaw’s good for flow. Bad for leaky joints." },
        { text: "Soil wakes up. Lily’s panels will help shade the sprouts." },
        { text: "Storm season tests our drains. We pass, or we learn." }
      ],
      chat: [
        { prompt: "Spring work?", response: "Pipe checks, sewer clears, and mirror calibration.\nEverything stretches a little this time of year." }
      ],
      closer: [
        { text: "Call if a line whistles. That sound means trouble." }
      ]
    },
    summer: {
      opener: [
        { text: "Cooling is harder than heating. The loops run hot all day." },
        { text: "Rolycoly loves it. Steam Engine sings in this weather." },
        { text: "Slugma barely slows down. Good for the TES." }
      ],
      chat: [
        { prompt: "Summer tip?", response: "Don’t touch the collector pipes.\nOr do, once. You won’t do it twice." }
      ],
      closer: [
        { text: "Stay hydrated. People overheat faster than machines." }
      ]
    },
    autumn: {
      opener: [
        { text: "Air’s crisp. Compression efficiencies climb." },
        { text: "Leaves clog inlets. Pretty, then annoying." },
        { text: "Good season to extend district loops." }
      ],
      chat: [
        { prompt: "Autumn projects?", response: "Swaps and upgrades. Panels in the berry rows if Lily’s ready." }
      ],
      closer: [
        { text: "I’ll be cataloging parts if you need me." }
      ]
    },
    winter: {
      opener: [
        { text: "Frozen valves keep me humble." },
        { text: "Sandshrew patrols the LAES tanks like an artist." },
        { text: "If we hold through winter, the rest feels easy." }
      ],
      chat: [
        { prompt: "Winter routine?", response: "Heat tracing, backup lines, and patience.\nComfort by circulation, like always." }
      ],
      closer: [
        { text: "Warm up when you can. Cold is a slow thief." }
      ]
    },

    # ---------------------------
    # Relationship overlays
    # These merge like state/season. Use helper:
    # NPCSystem.relationship_state?(:ENGINEER, :state_symbol)
    # ---------------------------
    single: {
      opener: [
        { text: "Most nights it’s me and the consoles. It’s fine." },
        { text: "I live here more than I should, probably." },
        { text: "If it’s working, I don’t notice the hours." }
      ],
      chat: [
        { prompt: "Ever lonely?", response: "Sometimes. Systems hum back. People are… trickier." , condition: -> { NPCSystem.affection(:ENGINEER) >= 250 } },
        { prompt: "Why no partner?", response: "I won’t promise what I can’t keep.\nStability first, then anything else." }
      ],
      closer: [
        { text: "I’ll be here. That’s sort of the point." },
        { text: "Thanks for stopping by." }
      ]
    },

    dating_player: {
      opener: [
        { text: "You always show up right before I forget to eat." },
        { text: "I saved you a quiet minute. Best thing I can offer." },
        { text: "Funny how the plant hums softer when you’re around." }
      ],
      chat: [
        { prompt: "What do I mean to you?", response: "You’re proof I don’t have to be the only moving part.\nThat changes how I design… and how I breathe." , condition: -> { NPCSystem.affection(:ENGINEER) >= 500 } },
        { prompt: "Your dream for us?", response: "A home with warm floors from the TES loop.\nLights that never flicker. Work we’re proud of." , condition: -> { NPCSystem.affection(:ENGINEER) >= 800 } },
        { prompt: "About Robyn?", response: "We help each other. I build gear like the Snag Machine and ranger kits.\nShe clears the powerplant and sewers when the wilds push in." }
      ],
      date: [
        { prompt: "Night Watch Together", response: "Let’s listen to the turbines and say nothing for a while." }
      ],
      closer: [
        { text: "Get some rest. I’ll finish the checks." },
        { text: "I’ll walk you out. Habit, I guess." },
        { text: "You make the future feel maintainable." }
      ]
    },

    dating_spouse: {
      opener: [
        { text: "I’m glad Robyn has someone steady.\nShe deserves the kind of calm I can’t always give." },
        { text: "We sync schedules so the Ranger calls never leave gaps." },
        { text: "Good people are rare. I plan around keeping them." }
      ],
      chat: [
        { prompt: "How are you and Robyn?", response: "Better as a team every season.\nI build snag and field kits. She keeps the wilds from swallowing the plant." },
        { prompt: "Need anything from me?", response: "If you see sewer grates blocked, kick them clear.\nSaves me a night crawl later." }
      ],
      closer: [
        { text: "Tell Robyn the south loop is stable now." },
        { text: "Thanks for bridging gaps I can’t." }
      ]
    },

    married_player: {
      opener: [
        { text: "I tied a spare loop into the house.\nWarm floors. Quiet nights." },
        { text: "I moved a small console home.\nI’ll try to look at you more than the gauges." },
        { text: "Home is a system too. I like how ours runs." }
      ],
      chat: [
        { prompt: "What’s next for us?", response: "Statues to max, greenhouse tuned, then Lily’s panels.\nAfter that, maybe I finally let the plant run without me for a week." },
        { prompt: "Robyn okay with it?", response: "She cheered. Said she’d cover my calls.\nI owe her a dozen filter swaps." }
      ],
      closer: [
        { text: "Let’s go home. The grid can hum without me tonight." },
        { text: "I logged out early. That’s new." }
      ]
    },

    married_spouse: {
      opener: [
        { text: "Robyn and I are in a good rhythm.\nShe pulls me out of the plant when it’s time to breathe." },
        { text: "I promised her two full days off the floor this month." },
        { text: "We’re installing emergency kits in the café too." }
      ],
      chat: [
        { prompt: "How’s the partnership?", response: "Solid. She keeps me human, I keep the lights friendly.\nWe both sleep better for it." },
        { prompt: "Anything I can do?", response: "Keep catching Shadow Pokémon before they reach town lines.\nEvery rescue takes pressure off the grid." }
      ],
      closer: [
        { text: "Tell Robyn I’ll swing by with a new purifier head." },
        { text: "Thanks. This helps more than you think." }
      ]
    }
  })


  # ============================================
  # POKECAFE Robyn — Dialog & Menus
  # Notes:
  # - Affection range: 0..1000
  #   Key milestones: 250 (trust), 500 (personal dreams), 800 (deep connection)
  # - Relationship states overlay like state/season:
  #   :single, :dating_player, :dating_spouse, :married_player, :married_spouse
  # - Default state = job-neutral (not referencing café/ranger work).
  # - Robyn runs the Pokécafé + daycare, does ranger field rescues, purifies Shadow Pokémon.
  # - Robyn and Isaac support each other: she clears Pokémon from plant/sewers, he builds Snag Machine + ranger gear.
  # ============================================

  GameData::NPC.set_dialog(:POKECAFE, {
    # ---------------------------
    # Default (any state)
    # ---------------------------
    default: {
      opener: [
        { text: "Good to see you. How’s your team holding up?" },
        { text: "You caught me between thoughts. Always nice to reset." },
        { text: "Thanks for stopping in. I forget to look up sometimes." }
      ],
      chat: [
        { prompt: "How are you feeling?", response: "I keep moving, but… I should rest more often.\nDon’t tell anyone I said that." },
        { prompt: "Why did you start this?", response: "I saw too many Pokémon without care.\nThe café became my way to change that." },
        { prompt: "What’s your dream?", response: "A full rescue shelter with staff to help.\nNo Pokémon left behind." , condition: -> { NPCSystem.affection(:POKECAFE) >= 500 } }
      ],
      closer: [
        { text: "Take care of yourself too, not just your Pokémon." },
        { text: "Come back whenever you need me." },
        { text: "Thanks for checking in. It means more than you think." }
      ]
    },

    # ---------------------------
    # Work — Pokécafé / Ranger / Purification
    # ---------------------------
    work: {
      opener: [
        { text: "Welcome to the café. Your partners are safe here." },
        { text: "Shadow cases take patience. I’ll do what I can." },
        { text: "I was just finishing a training cycle. Need anything?" }
      ],
      chat: [
        { prompt: "How do you purify Shadows?", response: "Gentle care. Treats, massages, time.\nKindness breaks through, piece by piece.", script: -> { $player.seen_purify_chamber = true } },
        { prompt: "What’s for sale?", response: "Homemade treats, items for training, and ranger kits Isaac builds." },
        { prompt: "Any help out there?", response: "I answer field calls when Shadow Pokémon appear.\nSometimes I could use backup." },
        { prompt: "Do you rest?", response: "Rarely. But if you were here, maybe I’d close early." , condition: -> { NPCSystem.affection(:POKECAFE) >= 250 } },
        { prompt: "About Isaac?", response: "He keeps the grid alive. I keep the wilds from taking it back.\nWe cover each other." }
      ],
      shop: [
        { prompt: "Friendship Treats", response: "Made fresh. They ease bonds and soften shadows.", :script => -> { pbShopPokecafe() } },
        { prompt: "Pokémon Massage",  response: "Which one needs some affection?" },
        { prompt: "Shadow Purification", response: "Leave them with me. I’ll help them heal." , :script => -> { pbRelicStone() } }
      ],
      activity: [
        { prompt: "Field Rescue Call", response: "There’s a sighting nearby. Want to come?" , condition: -> { NPCSystem.affection(:POKECAFE) >= 500 } }
      ],
      closer: [
        { text: "Come back soon. The door’s always open." },
        { text: "Your Pokémon will always have a safe place here." },
        { text: "Thanks for lending me your time." }
      ]
    },

    # ---------------------------
    # Leisure — outside the café
    # ---------------------------
    leisure: {
      opener: [
        { text: "Strange not being behind the counter, isn’t it?" },
        { text: "I needed fresh air after a long shift." },
        { text: "For once, no customers. Just quiet." }
      ],
      chat: [
        { prompt: "How do you relax?", response: "Fishing clears my head.\nThe water doesn’t ask anything of me." },
        { prompt: "What about autumn?", response: "I walk the Haunted Woods.\nIt’s eerie, but I find peace there." },
        { prompt: "Do you have long-term plans?", response: "A bigger shelter. Trained staff.\nSomething that lasts." , condition: -> { NPCSystem.affection(:POKECAFE) >= 500 } }
      ],
      activity: [
        { prompt: "Fishing Trip", response: "Bring bait, I’ll bring patience." , condition: -> { NPCSystem.season?(:spring) || NPCSystem.season?(:summer) } },
        { prompt: "Haunted Walk", response: "The woods teach resilience.\nWant to see?" , condition: -> { NPCSystem.season?(:autumn) } },
        { prompt: "Hot Springs", response: "Winter’s harsh. The springs help me breathe again." , condition: -> { NPCSystem.season?(:winter) } }
      ],
      date: [
        { prompt: "Evening Walk", response: "That sounds nice.\nI don’t get asked that often." , condition: -> { NPCSystem.relationship_state?(:POKECAFE, :dating_player) } },
        { prompt: "Café After Hours", response: "Lights low, cocoa warm… just us." , condition: -> { NPCSystem.relationship_state?(:POKECAFE, :dating_player) } }
      ],
      closer: [
        { text: "I should get back soon. But this was good." },
        { text: "Thanks for pulling me away from work." },
        { text: "I’d do this again, anytime." , condition: -> { NPCSystem.affection(:POKECAFE) >= 500 } }
      ]
    },

    # ---------------------------
    # Seasonal flavor overlays
    # ---------------------------
    spring: {
      opener: [
        { text: "Spring rush—rescues come faster than I can count." },
        { text: "The café smells like blossoms and berry parfaits." },
        { text: "New life everywhere. Sometimes overwhelming." }
      ],
      chat: [
        { prompt: "Spring specialty?", response: "Berry Parfaits.\nBright, sweet, healing." }
      ]
    },
    summer: {
      opener: [
        { text: "Hot days, long calls. Shadows stir in the heat." },
        { text: "Cold drinks are the only way through summer." },
        { text: "Fishing keeps me sane when the café overheats." }
      ],
      chat: [
        { prompt: "Summer special?", response: "Salty-sweet lemonade cookies.\nSimple, refreshing." }
      ]
    },
    autumn: {
      opener: [
        { text: "The woods are alive in autumn.\nI walk there to think." },
        { text: "Fallen leaves mean new strays wandering in." },
        { text: "Pumpkin spice in the café. Don’t laugh—it’s comforting." }
      ],
      chat: [
        { prompt: "Autumn favorite?", response: "Pumpkin spice. Cozy, grounding." }
      ]
    },
    winter: {
      opener: [
        { text: "Cold nights bring quiet.\nAlmost feels safe." },
        { text: "Steam curls from the springs.\nI can finally breathe." },
        { text: "Snow hushes the café.\nIt’s… peaceful." }
      ],
      chat: [
        { prompt: "Winter favorite?", response: "Spiced cocoa and soft blankets.\nThe little things." }
      ],
      date: [
        { prompt: "Hot Springs Trip", response: "Steam, starlight, quiet.\nI could actually rest." , condition: -> { NPCSystem.relationship_state?(:POKECAFE, :dating_player) } }
      ]
    },

    # ---------------------------
    # Relationship overlays
    # ---------------------------
    single: {
      opener: [
        { text: "It’s mostly me here.\nThe café, the rescues, the nights." },
        { text: "I fill the hours with work.\nLess time to think about what’s missing." },
        { text: "One pair of hands isn’t enough, but I try." }
      ],
      chat: [
        { prompt: "Don’t you get lonely?", response: "Sometimes. But I’d rather be tired than see Pokémon suffer." },
        { prompt: "Why no partner?", response: "I don’t want to promise more than I can give.\nRight now, it’s the café and rescues first." }
      ],
      closer: [
        { text: "Thanks for stopping by." },
        { text: "I’ll be here if you need me." }
      ]
    },

    dating_player: {
      opener: [
        { text: "You always make me pause… in a good way." },
        { text: "It’s easier with you here.\nEven the hard parts." },
        { text: "I saved you cocoa.\nBest I can offer tonight." }
      ],
      chat: [
        { prompt: "What do you see in me?", response: "You remind me it’s okay to rest.\nThat I don’t have to do it alone." , condition: -> { NPCSystem.affection(:POKECAFE) >= 500 } },
        { prompt: "Dream for us?", response: "A shelter and a home, side by side.\nRescues, care, love… balanced." , condition: -> { NPCSystem.affection(:POKECAFE) >= 800 } },
        { prompt: "About Isaac?", response: "He builds the gear—the Snag Machine, ranger kits.\nI handle the calls. We’ve always worked like that." }
      ],
      date: [
        { prompt: "Evening Walk Together", response: "Quiet paths. Just us.\nThat’s enough." }
      ],
      closer: [
        { text: "Don’t stay out too late.\nI want you safe." },
        { text: "Thanks for being here.\nIt matters more than you know." }
      ]
    },

    dating_spouse: {
      opener: [
        { text: "I’m glad Isaac found someone.\nHe deserves it." },
        { text: "We still work side by side.\nThat won’t change." },
        { text: "Partnerships make the world stronger.\nI see that now." }
      ],
      chat: [
        { prompt: "How’s Isaac?", response: "He builds ranger kits and power systems.\nI handle the rescues.\nTogether, we keep the town standing." },
        { prompt: "Do you need anything?", response: "Just keep your eyes open.\nShadow Pokémon don’t wait for schedules." }
      ],
      closer: [
        { text: "Tell Isaac I’ll swing by later." },
        { text: "Thanks for looking out—for both of us." }
      ]
    },

    married_player: {
      opener: [
        { text: "Home feels different with you in it.\nWarm. Full." },
        { text: "I brought records upstairs.\nWe can actually relax tonight." },
        { text: "Strange, isn’t it?\nI don’t feel tired when you’re near." }
      ],
      chat: [
        { prompt: "What’s next for us?", response: "Build the shelter, balance the rescues.\nAnd finally, breathe together." },
        { prompt: "How do you feel now?", response: "Lighter. Like I don’t have to hold everything alone anymore." }
      ],
      closer: [
        { text: "Let’s go home.\nThe café can wait." },
        { text: "I’ll close early tonight.\nFor us." }
      ]
    },

    married_spouse: {
      opener: [
        { text: "Isaac and I still keep each other steady." },
        { text: "We cover the town together.\nIt feels like family." },
        { text: "Good systems, good people.\nIt all holds." }
      ],
      chat: [
        { prompt: "How’s Isaac?", response: "He builds, I field. Same as always.\nBut now there’s peace between shifts." },
        { prompt: "Anything I can do?", response: "Keep the wilds clear.\nEvery rescue you make lightens our load." }
      ],
      closer: [
        { text: "Thanks for supporting Isaac.\nIt means a lot." },
        { text: "Come back soon. We’re stronger together." }
      ]
    }
  })



  #===============================================================================
  # Sadie (RANCHER) — Dialogue
  # Layers:
  #   - base states: :default, :work, :leisure
  #   - seasonal overlays
  #   - relationship states: :single, :dating_player, :married_player, :dating_spouse, :married_spouse
  #
  # Rules:
  # - Af (affection) unlocks Sadie’s personal/family story.
  #   * Father = ex-Champion, founded the farm to support town.
  #   * Sadie took on farm legacy; Quinn inherited adventure dreams.
  # - SpA (spouse affection) unlocks her view of Lily (enemies→lovers).
  # - Romantic content = only in :dating_player / :married_player.
  # - Player only ever hears Sadie’s side, never Lily↔Sadie dialogue directly.
  #===============================================================================

  GameData::NPC.set_dialog(:RANCHER, {
    #---------------------------------------------------------------------------
    # DEFAULT (job-neutral, with Af/SpA arcs)
    #---------------------------------------------------------------------------
    default: {
      opener: [
        { text: "The animals were up before sunrise. I barely got coffee in me." },
        { text: "Long day ahead—livestock don’t wait for anyone." },
        { text: "You here for a chat, or just passing by?" }
      ],

      chat: [
        # Personal/family (Af unlocks)
        { prompt: "Why farming?",
          response: "My dad started this place after his Champion days.\nHe said the town needed food more than glory.\nI wanted to carry that on." },
        { prompt: "Your father was a Champion?",
          response: "Yeah. Most people don’t believe it until they see the photos.\nQuinn inherited his adventuring spirit.\nMe? I inherited the dirt under his fingernails.",
          condition: -> { NPCSystem.affection(:RANCHER) >= 200 } },
        { prompt: "Do you regret not adventuring?",
          response: "Not once.\nI’d rather feed a hundred families than win a hundred battles.",
          condition: -> { NPCSystem.affection(:RANCHER) >= 400 } },

        # Enemies→Lovers arc with Lily (SpA progression)
        # Stage 0–1 (20–100): rivalry, differences, dirty feed
        { prompt: "How’s the neighbor?",
          response: "She’s pretty, sure—but impossible.\nEvery time she floods her rows, my pens turn to mud and the feed’s ruined.",
          condition: -> { (s = NPCSystem.spouse_affection(:RANCHER)) <= 100 } },

        # Stage 2 (100–150): fence degrading, small Pokémon slip through
        { prompt: "Fence trouble?",
          response: "The posts rotted and her berries were too tempting.\nA dozen little ones slipped through before I could chase them off.",
          condition: -> { (s = NPCSystem.spouse_affection(:RANCHER)) > 100 && s <= 150 } },

        # Stage 2b: Tauros incident (150–175)
        { prompt: "What happened?",
          response: "Tauros broke loose and plowed right through her berry rows.\nI was furious… until I saw her face.\nThat guilt’s hard to shake.",
          condition: -> { (s = NPCSystem.spouse_affection(:RANCHER)) > 150 && s < 175 } },

        # Stage 3 (175–200): regret and amends
        { prompt: "Did you fix the fence?",
          response: "I did. Rebuilt it stronger than before.\nShould’ve done it sooner.\nShe still thanked me, which only made me feel worse.",
          condition: -> { (s = NPCSystem.spouse_affection(:RANCHER)) >= 175 && s < 200 } },

        # Stage 4 (200–250): noticing her hardworking nature
        { prompt: "You look thoughtful.",
          response: "She works harder than anyone I know.\nSeeing her smile after a long day… it makes my chest feel tight.",
          condition: -> { (s = NPCSystem.spouse_affection(:RANCHER)) >= 200 && s < 250 } },

        # Stage 5 (250–300): flustered at her kindness
        { prompt: "She leave you something?",
          response: "Jam basket, by my door.\nShe called it 'just practical,' but… stars, I’m still blushing.",
          condition: -> { (s = NPCSystem.spouse_affection(:RANCHER)) >= 250 && s < 300 } }
      ],

      closer: [
        { text: "I should get back. Animals don’t feed themselves." },
        { text: "Thanks for stopping by. Even a quick chat helps the day feel lighter." },
        { text: "Dad used to say: 'A farm’s work is never done, but it’s worth every sunrise.'",
          condition: -> { NPCSystem.affection(:RANCHER) >= 500 } }
      ]
    },

    #---------------------------------------------------------------------------
    # WORK (Livestock farm: chickens, cows, pigs, etc.)
    #---------------------------------------------------------------------------
    work: {
      opener: [
        { text: "Welcome to the ranch. Watch your step—the Spoink get underfoot." },
        { text: "Eggs, milk, wool—what’ll it be?" },
        { text: "I was just feeding the herd. You here to trade?" }
      ],

      chat: [
        { prompt: "What do you sell?",
          response: "Farm Pokémon—chickens, bunnies, sheep, cows, pigs.\nAnd pokéfeed to keep them happy." },
        { prompt: "What’s the Saddle for?",
          response: "Lets you ride horse Pokémon like Rapidash or Mudsdale.\nFast as a bike, warmer in winter." },
        { prompt: "How does the incubator work?",
          response: "Pop an egg in, keep the temperature steady.\nWithout it, you’ll only get goods, not hatchlings." },
        { prompt: "Who taught you ranching?",
          response: "Dad started me young. He said 'treat them fair and they’ll give back double.'",
          condition: -> { NPCSystem.affection(:RANCHER) >= 150 } }
      ],

      shop: [
        { prompt: "Buy Livestock", response: "Pick carefully—each has their own quirks.", script: -> { pbShopRancherLivestock } },
        { prompt: "Buy Feed",      response: "Fresh feed mix, balanced for energy.",        script: -> { pbShopRancherFeed } },
        { prompt: "Saddle",        response: "Good leather, strong stitching. Safe for long rides.", script: -> { pbGiveFieldItem(:SADDLE) } },
        { prompt: "Egg Incubator", response: "Essential if you want real hatchlings, not just goods.", script: -> { pbBuyEggIncubator } }
      ],

      closer: [
        { text: "Back to the pens for me. Always more to do." }
      ]
    },

    #---------------------------------------------------------------------------
    # LEISURE (social / non-work time)
    #---------------------------------------------------------------------------
    leisure: {
      opener: [
        { text: "Finally sat down. My legs might mutiny if I don’t rest." },
        { text: "Even ranchers need a breather now and then." }
      ],

      chat: [
        { prompt: "What do you do to relax?",
          response: "Sharpen tools, brush Rapidash, maybe play cards with Quinn." },
        { prompt: "Tell me about your family.",
          response: "Mom kept the house running, Dad kept the town fed.\nI keep the farm alive now. Quinn… he’s still chasing horizons.",
          condition: -> { NPCSystem.affection(:RANCHER) >= 300 } },
        { prompt: "What’s your dream?",
          response: "Not glory—just a farm that lasts.\nA place people can depend on, the way they did with Dad.",
          condition: -> { NPCSystem.affection(:RANCHER) >= 500 } }
      ],

      activity: [
        { prompt: "Brush Rapidash",
          response: "She loves a strong hand and a gentle word. Care to try?" },
        { prompt: "Fence Repair",
          response: "Could use the help. Fence lines always sag faster than you think.",
          condition: -> { NPCSystem.affection(:RANCHER) >= 200 } }
      ],

      date: [
        { prompt: "Evening Ride",
          response: "Hop on. The stars look better from horseback.",
          condition: -> { NPCSystem.dating_player?(:RANCHER) } }
      ],

      closer: [
        { text: "Better get back before the herd gets restless." }
      ]
    },

    #---------------------------------------------------------------------------
    # SEASONAL FLAVORS
    #---------------------------------------------------------------------------
    spring: {
      opener: [
        { text: "Spring calves and foals keep me on my toes." },
        { text: "Fields are green, mud’s thick. Work never ends." }
      ],
      chat: [
        { prompt: "Spring troubles?",
          response: "Flooded pens again. Runoff from next door didn’t help.",
          condition: -> { (s = NPCSystem.spouse_affection(:RANCHER)) <= 125 } }
      ]
    },

    summer: {
      opener: [
        { text: "Heat’s brutal. I haul twice the water this season." },
        { text: "The fields shimmer like gold in this light." }
      ],
      chat: [
        { prompt: "See much of Lily?",
          response: "Hard not to. Her Tsareena struts around like it owns the valley.",
          condition: -> { (s = NPCSystem.spouse_affection(:RANCHER)) <= 150 } }
      ]
    },

    autumn: {
      opener: [
        { text: "Harvest time. Barn’s stuffed, cellar’s fuller." }
      ],
      chat: [
        { prompt: "Any trades?",
          response: "We swapped baskets. Called it practical… but it wasn’t just that.",
          condition: -> { (s = NPCSystem.spouse_affection(:RANCHER)) >= 225 } }
      ]
    },

    winter: {
      opener: [
        { text: "Cold keeps me in the barns more than the fields." },
        { text: "Frost bites harder than a stray Poochyena." }
      ],
      chat: [
        { prompt: "Any help with the storm prep?",
          response: "She dropped blankets for the foals. I fixed her door latch.\nFeels good, looking out for each other.",
          condition: -> { (s = NPCSystem.spouse_affection(:RANCHER)) >= 250 } }
      ]
    },

    #---------------------------------------------------------------------------
    # RELATIONSHIP STATE OVERLAYS
    #---------------------------------------------------------------------------
    single: {
      opener: [
        { text: "Another long day. At least I’ve got the herd for company." }
      ],
      closer: [
        { text: "Take care out there—these fields can wear you down." }
      ]
    },

    dating_player: {
      opener: [
        { text: "You make chores lighter just by showing up." },
        { text: "Care to share a sunset ride with me?" }
      ],
      chat: [
        { prompt: "Future together?",
          response: "A home, a herd, and you by my side.\nThat’s enough for me." }
      ],
      closer: [
        { text: "Stay safe, love. The barn light will guide you home." }
      ]
    },

    married_player: {
      opener: [
        { text: "Feels good waking up knowing you’re here." }
      ],
      chat: [
        { prompt: "Morning chores?",
          response: "We’ll split them. Together we’ll be done by breakfast." }
      ],
      closer: [
        { text: "Sleep well. Tomorrow’s ours to tend." }
      ]
    },

    dating_spouse: {
      opener: [
        { text: "Hey, friend. Farm’s running smoother these days." }
      ],
      chat: [
        { prompt: "How are things with Lily?",
          response: "Different than before. Less shouting, more… smiles.\nDidn’t expect it, but I’m glad." }
      ],
      closer: [
        { text: "Thanks for checking in. Good friends make hard work easier." }
      ]
    },

    married_spouse: {
      opener: [
        { text: "The farm feels steadier with her around.\nEven the Pokémon notice it." }
      ],
      chat: [
        { prompt: "How’s married life?",
          response: "Shared chores, shared meals, shared laughter.\nFeels like the valley itself is rooting for us." }
      ],
      closer: [
        { text: "Don’t be a stranger—you’re part of this farm family too." }
      ]
    }
  })


  #===============================================================================
  # Lily (GARDENER) — Dialogue (final format)
  # Layers that can stack at runtime:
  #   - base sections: :default, :work, :leisure
  #   - seasonal overlays: :spring, :summer, :autumn, :winter
  #   - relationship state overlays: :single, :dating_player, :married_player, :dating_spouse, :married_spouse
  #
  # Rules:
  # - Romantic content only appears in :dating_player / :married_player.
  # - Backstory + enemies→lovers arc with Sadie (RANCHER) are unlocked by:
  #     Af  = NPCSystem.affection(:GARDENER)
  #     SpA = NPCSystem.spouse_affection(:GARDENER)   # Lily↔Sadie arc meter
  # - Player only talks to Lily (no NPC↔NPC live banter). Lily reports her side.
  # - Shop/action scripts are placeholders; replace with your real handlers.
  #===============================================================================
  GameData::NPC.set_dialog(:GARDENER, {    
    #---------------------------------------------------------------------------
    # DEFAULT (job-neutral; appears in any location/state; carries Af/SpA arcs)
    #---------------------------------------------------------------------------
    default: {
      opener: [
        { text: "Welcome. Mind the Lotad, they’ll follow you if you drip water." },
        { text: "Oh! Hello again. I was just checking on my Tsareena." },
        { text: "I hope you’re staying hydrated. The sun dries you out before you realize." }
      ],

      chat: [
        # Personal & Af-gated
        { prompt: "Do you enjoy gardening?",
          response: "It isn’t only patience. It’s persistence.\nYou fail gently and try again, a little wiser each season." },
        { prompt: "How did you learn all this?",
          response: "My grandmother taught me to read soil like a book.\nEvery grain remembers rain and root.",
          condition: -> { NPCSystem.affection(:GARDENER) >= 200 } },
        { prompt: "You seem calm out here.",
          response: "Calm comes from rhythm.\nSoil. Water. Light. And gratitude when the sprouts show.",
          condition: -> { NPCSystem.affection(:GARDENER) >= 300 } },

        # Enemies→Lovers arc beats about Sadie (SpA-gated, platonic backstory)
        # Stage 0–1 (20–100): petty rivalry: trampling, pests
        { prompt: "How are the neighbors?",
          response: "Her Pokémon trampled my seedlings again.\nI wish she’d check her fences before dawn.",
          condition: -> { (s = NPCSystem.spouse_affection(:GARDENER)) <= 100 } },

        # Stage 2 (100–150): major incidents (Tauros + Lily’s overgrowth)
        { prompt: "Rough week?",
          response: "A Tauros snapped three trellises… and my vines had crept over the posts.\nI should have pruned sooner.",
          condition: -> { (s = NPCSystem.spouse_affection(:GARDENER)) > 100 && s <= 150 } },

        # Overwatering → runoff → Sadie’s field mud (Lily admits fault)
        { prompt: "Any mistakes you’re fixing?",
          response: "I overwatered trying to save the buds.\nThe runoff slid downhill and turned her field to mud.\nI’m measuring soil moisture, no more guessing.",
          condition: -> { (s = NPCSystem.spouse_affection(:GARDENER)) >= 125 && s <= 175 } },

        # Stage 3 (150–175): forced cooperation (pests/weather)
        { prompt: "Did you two work together?",
          response: "A Beedrill swarm forced our hands.\nShe’s steady under pressure… I may have misjudged her.",
          condition: -> { (s = NPCSystem.spouse_affection(:GARDENER)) > 150 && s < 175 } },

        # Stage 4 (175–200): first amends (fences, hedges)
        { prompt: "Any progress with the boundary?",
          response: "She repaired the fence without me asking.\nI planted berry hedges as a living wall, pretty and practical.",
          condition: -> { (s = NPCSystem.spouse_affection(:GARDENER)) >= 175 && s < 200 } },

        # Softening (200–250): respect
        { prompt: "Still arguing?",
          response: "Less shouting. More listening.\nTurns out we both want the same thing, healthy fields.",
          condition: -> { (s = NPCSystem.spouse_affection(:GARDENER)) >= 200 && s < 250 } },

        # Near-resolution (250–300): warmth
        { prompt: "You look… lighter.",
          response: "She dropped off hay bales to brace my greenhouse.\nI left a basket of jam by her door.\nNeighbors can be wonderful.",
          condition: -> { (s = NPCSystem.spouse_affection(:GARDENER)) >= 250 && s < 300 } }
      ],

      closer: [
        { text: "Stay rooted, and let yourself grow." },
        { text: "Take care, remember to drink water." },
        { text: "Thanks for listening… I don’t often get to share.",
          condition: -> { NPCSystem.affection(:GARDENER) >= 500 } }
      ]
    },

    #---------------------------------------------------------------------------
    # WORK (Berry Shop / Greenhouse / Field passes & CUT item)
    #---------------------------------------------------------------------------
    work: {
      opener: [
        { text: "ShhhB udew are napping in the shade." },
        { text: "Welcome! Fresh berries just in." },
        { text: "I’m pruning the overgrowth mind the clippings." }
      ],

      chat: [
        { prompt: "What do you sell?",
          response: "Berries, mulch, watering cans… and timed greenhouse access.\nPlease respect the plants while you pick." },
        { prompt: "What’s the CUT item for?",
          response: "Responsible pruning.\nClear saplings and keep borders tidy, overgrowth invites trouble." },
        # Overwatering lesson (ties to runoff)
        { prompt: "Watering tips?",
          response: "Check moisture before every pass.\nToo much water can drown roots, and flood a neighbor’s field.",
          condition: -> { (s = NPCSystem.spouse_affection(:GARDENER)) >= 75 } },
        # Personal dream
        { prompt: "Your long-term goal?",
          response: "To cultivate a legendary berry, sweetness born from patience.\nMaybe it already exists, waiting for the right season.",
          condition: -> { NPCSystem.affection(:GARDENER) >= 500 } }
      ],

      shop: [
        { prompt: "Buy Berries",          response: "Freshly picked, handle with care!",  script: -> { pbShopGardenerBerries } },
        { prompt: "Buy Mulch & Tools",     response: "Mulch, watering cans, tags, twine.", script: -> { pbShopGardenerSupplies } },
        { prompt: "Axe?",        response: "Prune wisely. The forest remembers.",  script: -> { pbGiveItem(:CUTITEM) } },
        { prompt: "Greenhouse Pass",       response: "Timed access. Pick only what’s ripe.",  script: -> { pbBuyGreenhousePass } }
      ],

      closer: [
        { text: "Back to trimming and talking to the trees." },
        { text: "Come again if you need supplies or a quiet place to breathe." }
      ]
    },

    #---------------------------------------------------------------------------
    # LEISURE (social time; non-shop menu, light activities & dating-gated dates)
    #---------------------------------------------------------------------------
    leisure: {
      opener: [
        { text: "The breeze is perfect for drying herbs today." },
        { text: "I was weaving flower garlands—want to try?" },
        { text: "Care to walk with me? The meadows are lovely at this hour." }
      ],

      chat: [
        { prompt: "Do plants like music?",
          response: "I sing when I’m alone.\nLaugh if you want—the harvest is sweeter." },
        { prompt: "Collect anything special?",
          response: "Pressed petals—little postcards from the sun.",
          condition: -> { NPCSystem.affection(:GARDENER) >= 300 } },
        # Mid-arc report (no NPC cross-talk)
        { prompt: "Everything peaceful between fields?",
          response: "Peaceful-ish.\nWe’re learning to set signs and paths so Rapidash won’t spook the flock.",
          condition: -> { (s = NPCSystem.spouse_affection(:GARDENER)) >= 175 } }
      ],

      activity: [
        { prompt: "Forage Together",
          response: "Stay close to the hedgerow—Combee love the bramble flowers." },
        { prompt: "Help Re-Pot Seedlings",
          response: "Gentle hands, steady breath.\nPerfect.",
          condition: -> { NPCSystem.affection(:GARDENER) >= 150 } }
      ],

      # Romantic prompts only render if dating_player overlay is active; also placed here for convenience with condition guard.
      date: [
        { prompt: "Evening Greenhouse (After Hours)",
          response: "Lanterns, tea, and berries warm from the vine.",
          condition: -> { NPCSystem.dating_player?(:GARDENER) } },
        { prompt: "Orchard Walk (Hand in Hand)",
          response: "Yes. Your pulse is my favorite rhythm.",
          condition: -> { NPCSystem.dating_player?(:GARDENER) } }
      ],

      closer: [
        { text: "The fields are calling. I’d best get back." },
        { text: "Thank you—this was a nice break." }
      ]
    },

    #---------------------------------------------------------------------------
    # SEASONAL FLAVORS (light overlays; keep short and stackable)
    #---------------------------------------------------------------------------
    spring: {
      opener: [
        { text: "New sprouts! There’s nothing more hopeful." },
        { text: "Spring rains are a blessing… in moderation." }
      ],
      chat: [
        { prompt: "How’s the rain?",
          response: "Too much is as cruel as too little.\nMulch deep, water slow." },
        { prompt: "Runoff under control?",
          response: "I track soil moisture before every pass now.\nNo more guessing, no more muddy neighbors.",
          condition: -> { (s = NPCSystem.spouse_affection(:GARDENER)) >= 125 } }
      ]
    },

    summer: {
      opener: [
        { text: "The sun bakes the soil—I water before dawn and after dusk." },
        { text: "Long days make for long harvests." }
      ],
      chat: [
        { prompt: "Do you rest?",
          response: "Shade, cold tea, and a berry for courage." },
        { prompt: "Visitors at dusk?",
          response: "Rapidash grazes near my rows.\nI don’t shoo her anymore.",
          condition: -> { (s = NPCSystem.spouse_affection(:GARDENER)) >= 200 } }
      ]
    },

    autumn: {
      opener: [
        { text: "Autumn makes the berries glow like lanterns." },
        { text: "Canning season—sweet, sticky work." }
      ],
      chat: [
        { prompt: "Need jars?",
          response: "If you don’t mind stained fingers.\nThe jam is worth it." },
        { prompt: "Share harvests?",
          response: "We traded baskets this week.\nPractical… and maybe something more.",
          condition: -> { (s = NPCSystem.spouse_affection(:GARDENER)) >= 225 } }
      ]
    },

    winter: {
      opener: [
        { text: "I keep the greenhouse warm with mulch and hot stones." },
        { text: "Winter makes me reflective. Did I do enough this year?" }
      ],
      chat: [
        { prompt: "How do you brace for storms?",
          response: "Rope the frames, stack hay bales against the wind.\nA good neighbor brought extra.",
          condition: -> { (s = NPCSystem.spouse_affection(:GARDENER)) >= 250 } },
        { prompt: "Quiet night plans?",
          response: "Repair tools. Press petals. Label seeds I won’t forget." }
      ],
      # Date shows only if dating overlay active
      date: [
        { prompt: "Hot-Tea Greenhouse",
          response: "Steam on the glass and your hand in mine.",
          condition: -> { NPCSystem.dating_player?(:GARDENER) } }
      ]
    },

    #---------------------------------------------------------------------------
    # RELATIONSHIP STATE OVERLAYS (additive groups)
    #---------------------------------------------------------------------------

    # Lily is uncommitted; treats player platonically.
    single: {
      opener: [
        { text: "You caught me daydreaming about trellises and tea." }
      ],
      chat: [
        { prompt: "What’s on your mind?",
          response: "Borders, paths, and how to keep peace between fields.\nIt’s… coming along.",
          condition: -> { (s = NPCSystem.spouse_affection(:GARDENER)) >= 175 } }
      ],
      closer: [
        { text: "Walk safe between the rows." }
      ]
    },

    # Player dating Lily — romantic lines unlocked.
    dating_player: {
      opener: [
        { text: "When I walk the fields, I think of you." },
        { text: "You always bring the right kind of weather with you." }
      ],
      chat: [
        { prompt: "Spend time together?",
          response: "Let’s plant side by side.\nRoots tangle, and so do we—gently." },
        { prompt: "You look happy.",
          response: "I am. Love makes colors brighter.\nEven the soil looks rich with promise." }
      ],
      closer: [
        { text: "See you soon, my love. Don’t keep me waiting too long." }
      ]
    },

    # Player married to Lily — cozy domestic notes.
    married_player: {
      opener: [
        { text: "Home is wherever your boots end up by the door." },
        { text: "I saved the sweetest berries for you." }
      ],
      chat: [
        { prompt: "Morning routine?",
          response: "Tea for two. Check the frames.\nKiss you once, then twice for luck." }
      ],
      closer: [
        { text: "Let’s watch the orchard bloom together—season after season." }
      ]
    },

    # Lily is dating her default spouse (Sadie). Player is treated as a friend.
    dating_spouse: {
      opener: [
        { text: "Good to see you. The farms are finally in rhythm." }
      ],
      chat: [
        { prompt: "How are things between fields?",
          response: "We mapped watering days and marked safe paths.\nNo more runoff, no spooked herds.\nIt feels… peaceful.",
          condition: -> { (s = NPCSystem.spouse_affection(:GARDENER)) >= 200 } },
        { prompt: "You seem content.",
          response: "It’s new.\nKindness, shared work, and a fence mended from both sides." }
      ],
      closer: [
        { text: "Thank you for checking in. Friends make the season kinder." }
      ]
    },

    # Lily is married to Sadie. Player remains a close friend.
    married_spouse: {
      opener: [
        { text: "You’re family by the fence line now—always welcome." }
      ],
      chat: [
        { prompt: "How’s married life?",
          response: "Busy hands, quiet evenings.\nWe trade lunches and laughter over the gate." },
        { prompt: "Any advice for neighbors?",
          response: "Measure twice, water once.\nListen before you raise your voice.\nAnd plant hedges where words fail." }
      ],
      closer: [
        { text: "May your path be soft underfoot—and your harvest sweet." }
      ]
    }
  })

    #===============================================================================
    # Quinn (BIRDKEEPER) — Dialogue
    # Layers that can stack at runtime:
    #   base sections: :default, :work, :leisure
    #   seasonal overlays: :spring, :summer, :autumn, :winter
    #   relationship overlays: :single, :dating_player, :married_player, :dating_spouse, :married_spouse
    #
    # Conventions used here:
    #   Af  = NPCSystem.affection(:BIRDKEEPER)            # Quinn <-> Player openness
    #   SpA = NPCSystem.spouse_affection(:BIRDKEEPER)     # Quinn <-> Brooke warmth (gentle arc)
    #
    # Notes:
    # - Quinn’s core arc: wanted to be Champion, chose “flight over fight,” does odd jobs (incl. overnight rescues),
    #   people rely on him, but he fears not showing up in time, so he overcorrects by refusing new responsibilities.
    # - Brooke (LIBRARIAN) is Quinn’s default partner; when dating/married_spouse, he talks about her lovingly and
    #   treats the player as a friend. Hoothoot likes Quinn.
    # - Scripts are placeholders; wire them to your handlers.
    #===============================================================================

  GameData::NPC.set_dialog(:BIRDKEEPER, {
    #---------------------------------------------------------------------------
    # DEFAULT (job-neutral; Af & gentle SpA unlocks)
    #---------------------------------------------------------------------------
    default: {
      opener: [
        { text: "Hey! Did you catch that dive? Starraptor’s a real ace." },
        { text: "Sky’s clear today—perfect for stretching the wings." },
        { text: "You look like you need a lift. Lucky for you, I’m your guy." }
      ],

      chat: [
        # Quinn's Champion dream & pivot
        { prompt: "Ever want to be Champion?",
          response: "Wanted? Yeah. Thought I’d fly higher than anyone.\nTurns out the battles grounded me hard.\nSo… I chose flight over fight." },

        { prompt: "Why all the odd jobs?",
          response: "Mail, supply runs, quick fixes—keeps me useful.\nSometimes… overnight rescues too. Don’t tell Sadie—she worries." },

        # Vulnerability unlocks with Af
        { prompt: "What scares you most?",
          response: "Not being there when it counts.\nFeels safer to keep things light than promise more than I can carry.",
          condition: -> { NPCSystem.affection(:BIRDKEEPER) >= 250 } },

        { prompt: "Do people rely on you?",
          response: "More than I let on.\nI joke around, but the routes get done. Storms or not.",
          condition: -> { NPCSystem.affection(:BIRDKEEPER) >= 400 } },

        # Brooke warmth (gentle SpA gates; not a rivalry arc)
        { prompt: "How’s the library crowd?",
          response: "Brooke’s Hoothoot likes riding thermals with us.\nKinda wild—book birds loving the wind.",
          condition: -> { (s = NPCSystem.spouse_affection(:BIRDKEEPER)) >= 150 } }
      ],

      closer: [
        { text: "Don’t let the sky slip by without looking up." },
        { text: "Catch you later—probably already late for something." },
        { text: "If I don’t make it back, Starraptor knows the way. Don’t worry.",
          condition: -> { NPCSystem.affection(:BIRDKEEPER) >= 500 } }
      ]
    },

    #---------------------------------------------------------------------------
    # WORK (Mail stand / deliveries / Fly service)
    #---------------------------------------------------------------------------
    work: {
      opener: [
        { text: "Air mail, express delivery, one cool Birdkeeper at your service." },
        { text: "Packages, letters, or just need wings?" },
        { text: "Quinn’s Sky Service: guaranteed arrival… eventually." }
      ],

      chat: [
        { prompt: "What do you handle here?",
          response: "Letters, parcels, last-minute errands.\nIf it fits in a satchel—or on a bird—I’m your guy." },

        { prompt: "Tell me about Fly.",
          response: "The Fly item lets you soar wherever you’ve been.\nJust… hang on tight and don’t look straight down." },

        { prompt: "You do rescues?",
          response: "Sometimes. Night flights in bad weather.\nI don’t brag about those—just do ’em.",
          condition: -> { NPCSystem.affection(:BIRDKEEPER) >= 250 } },

        { prompt: "Why not take a permanent route?",
          response: "If I tie myself down, I’ll just snap the rope later.\nBetter to promise what I can actually keep." }
      ],

      # Services/Shop
      shop: [
        { prompt: "Buy Postage",      response: "Stamps, envelopes, and the fastest wings in town.", script: -> { pbBuyPostage } },
        { prompt: "Send a Letter",     response: "Say the word—my team will get it there.",          script: -> { pbSendLetter } },
        { prompt: "FLY Item",          response: "Official license to ride the wind. Treat it with respect.", script: -> { pbGiveFieldItem(:FLYITEM) } },
        { prompt: "Book a Delivery",   response: "Route set. If I’m late, it’s because the clouds asked nicely.", script: -> { pbBookDelivery } }
      ],

      closer: [
        { text: "Your parcel’s in good wings." },
        { text: "Another hop, another drop. See you around." }
      ]
    },

    #---------------------------------------------------------------------------
    # LEISURE (docks, rooftops, fields; hangs out and unwinds)
    #---------------------------------------------------------------------------
    leisure: {
      opener: [
        { text: "Sky’s best when it’s painted with sunset." },
        { text: "Sometimes I nap in the grass and let the clouds name me." },
        { text: "Need company? I’ll bring the breeze." }
      ],

      chat: [
        { prompt: "Cloud watching?",
          response: "All the time. Swear I saw one shaped like Sadie’s Tauros.\nIt charged across half the sky." },

        { prompt: "Brooke seems to like you.",
          response: "She sees past the 'cool pilot' thing.\nKeeps me focused, doesn’t clip my wings.",
          condition: -> { (s = NPCSystem.spouse_affection(:BIRDKEEPER)) >= 180 } },

        { prompt: "Why keep moving?",
          response: "World feels endless when you don’t land right away.\nBut… I’m learning when to touch down for people who matter.",
          condition: -> { NPCSystem.affection(:BIRDKEEPER) >= 300 } }
      ],

      activity: [
        { prompt: "Sky Ride",
          response: "Strap in. We’ll skim the treetops and kiss the clouds." },
        { prompt: "Starwatch",
          response: "Find a rooftop. Bring cocoa. Count satellites like shooting stars.",
          condition: -> { NPCSystem.affection(:BIRDKEEPER) >= 150 } }
      ],

      # Dates only render if dating overlay active
      date: [
        { prompt: "Sunset Flight",
          response: "I’ll circle until the last light fades—promise I’ll bring you back before you freeze.",
          condition: -> { NPCSystem.dating_player?(:BIRDKEEPER) } }
      ],

      closer: [
        { text: "Don’t stay grounded too long, friend." },
        { text: "See you above the rooftops." }
      ]
    },

    #---------------------------------------------------------------------------
    # SEASONAL FLAVORS
    #---------------------------------------------------------------------------
    spring: {
      opener: [
        { text: "Fresh wind, full mailbags—best season for flying." },
        { text: "New chicks, new routes. Sadie keeps me hauling feed." }
      ],
      chat: [
        { prompt: "Spring risk?",
          response: "Sudden gusts over the delta. Makes for spicy landings." }
      ]
    },

    summer: {
      opener: [
        { text: "Hot thermals make the flights easy—like riding an elevator made of air." },
        { text: "Storm lines build fast. Gotta read the sky like a map." }
      ],
      chat: [
        { prompt: "Ever fly in lightning?",
          response: "Once. Didn’t like it. Won’t brag about it either.",
          condition: -> { NPCSystem.affection(:BIRDKEEPER) >= 250 } }
      ]
    },

    autumn: {
      opener: [
        { text: "Leaves spiral like little flight lessons—catch the swirl, ride it down." }
      ],
      chat: [
        { prompt: "Long trips?",
          response: "Cool air, clear views. I’ll take the scenic route every time I can." }
      ]
    },

    winter: {
      opener: [
        { text: "Snow blinds you if you stare too long. Starraptor watches for both of us." },
        { text: "Nights get long. I pick up the late calls when no one else can." }
      ],
      chat: [
        { prompt: "Coldest run?",
          response: "Midnight, frozen wings, rescue on the cliffs.\nWe made it. I slept a week after.",
          condition: -> { NPCSystem.affection(:BIRDKEEPER) >= 400 } }
      ]
    },

    #---------------------------------------------------------------------------
    # RELATIONSHIP OVERLAYS
    #---------------------------------------------------------------------------

    # Quinn unattached; player is a friend.
    single: {
      opener: [
        { text: "You ever chase a horizon just to see if it blinks first?" }
      ],
      chat: [
        { prompt: "Do horizons blink?",
          response: "Only when you wink first. Try it." }
      ],
      closer: [
        { text: "Wind’s shifting. Time to ride it." }
      ]
    },

    # Player dating Quinn — romance lines here only.
    dating_player: {
      opener: [
        { text: "When you’re with me, the sky feels closer." },
        { text: "You make landing worth it." }
      ],
      chat: [
        { prompt: "Fly away together?",
          response: "Name a place. I’ll draw a path with our contrails." },
        { prompt: "What changes when we’re together?",
          response: "I’d rather be late with you than on time alone." }
      ],
      closer: [
        { text: "My wings are yours—don’t forget that." }
      ]
    },

    # Player married to Quinn — cozy, grounded romance.
    married_player: {
      opener: [
        { text: "Home is wherever I land with you." }
      ],
      chat: [
        { prompt: "Tomorrow’s plan?",
          response: "Morning mail, lazy lunch, sunset glide.\nHand in mine the whole time." }
      ],
      closer: [
        { text: "Sleep well. I’ll wake you when the sky turns gold." }
      ]
    },

    # Quinn dating his default spouse (Brooke). Player stays a close friend.
    dating_spouse: {
      opener: [
        { text: "Brooke keeps me grounded—even when my head’s in the sky." }
      ],
      chat: [
        { prompt: "How are you two?",
          response: "Good. She focuses me; I get her outside.\nHoothoot rides along like we’re a proper squad." },
        { prompt: "What do you admire about Brooke?",
          response: "She sees past the cool act.\nMakes me want to be the guy who shows up—on time, every time." }
      ],
      closer: [
        { text: "Thanks for checking in. Friends make the landings softer." }
      ]
    },

    # Quinn married to Brooke. Player remains friend/family.
    married_spouse: {
      opener: [
        { text: "You should see her face when a new donation arrives—pure starlight." }
      ],
      chat: [
        { prompt: "Married life treating you well?",
          response: "Library by day, sky by evening.\nShe doesn’t clip my wings; I make sure to land safe." },
        { prompt: "Hoothoot still flying with you?",
          response: "Every week. Says 'hoo' when we bank—pretty sure that means 'again'." }
      ],
      closer: [
        { text: "Door’s open—library or rooftop. You’re family by now." }
      ]
    }
  })


  #===============================================================================
  # Brooke (LIBRARIAN) — Dialogue
  # Layers that can stack at runtime:
  #   base sections: :default, :work, :leisure
  #   seasonal overlays: :spring, :summer, :autumn, :winter
  #   relationship overlays: :single, :dating_player, :married_player, :dating_spouse, :married_spouse
  #
  # Conventions:
  #   Af  = NPCSystem.affection(:LIBRARIAN)           # Brooke <-> Player openness
  #   SpA = NPCSystem.spouse_affection(:LIBRARIAN)    # Brooke <-> Quinn warmth
  #
  # Notes:
  # - Brooke accepts museum/library donations (artifacts, fossils, egg patterns).
  # - Rewards include dungeon maps (unlocking dungeon access) at donation milestones.
  # - Field Items: Waterfall item, optional Item Finder (as a “scanning tome”).
  # - Interests: Ruins puzzles, Unown (history/lore), aviary/aquarium/zoo dates with Quinn.
  # - The Library hosts tutorials (handled elsewhere; not in this dialog).
  # - Scripts are placeholders; connect to your systems:
  #     pbDonateMuseum, pbCheckDonationMilestones, pbGrantDungeonMap(:RUIN_ID),
  #     pbGiveFieldItem(:WATERFALLITEM), pbGiveItemFinder, pbOpenExhibitGuide, etc.
  #===============================================================================

  GameData::NPC.set_dialog(:LIBRARIAN, {
    #---------------------------------------------------------------------------
    # DEFAULT (job-neutral; Af & gentle SpA lore)
    #---------------------------------------------------------------------------
    default: {
      opener: [
        { text: "Welcome to the library. Please… mind the feathers. Hoothoot sheds when excited." },
        { text: "Oh! Hello. I was just cataloging." },
        { text: "If you’re here to read, I’ll try not to infodump. I said 'try', no promises." }
      ],

      chat: [
        # Personal philosophy & Af-gated openness
        { prompt: "Why a library?",
          response: "Because memories fade and pages don’t.\nIf we preserve knowledge, we preserve choices." },

        { prompt: "You really love ruins, huh?",
          response: "Ancient floors creak in ciphers.\nEvery tile is a sentence; every puzzle, a paragraph." },

        { prompt: "Favorite research topic?",
          response: "Unown.\nTheir glyphs echo across regions and eras—language made living.",
          condition: -> { NPCSystem.affection(:LIBRARIAN) >= 180 } },

        { prompt: "Do you ever… get overwhelmed?",
          response: "Sensory-wise, yes. People-wise, sometimes.\nTexts are predictable. Hearts… less so.",
          condition: -> { NPCSystem.affection(:LIBRARIAN) >= 320 } },

        # Gentle SpA: Brooke + Quinn warmth (no rival arc)
        { prompt: "How’s the Birdkeeper?",
          response: "Quinn remembers to land when it matters.\nHoothoot approves—high praise, truly.",
          condition: -> { (s = NPCSystem.spouse_affection(:LIBRARIAN)) >= 150 } }
      ],

      closer: [
        { text: "Shelves are always open. I am… usually open, too." },
        { text: "If you find something curious, bring it. Curiosity is contagious." },
        { text: "Thank you for listening. It’s… nice to be heard.",
          condition: -> { NPCSystem.affection(:LIBRARIAN) >= 400 } }
      ]
    },

    #---------------------------------------------------------------------------
    # WORK (Library/Museum — donations, exhibits, field items, dungeon maps)
    #---------------------------------------------------------------------------
    work: {
      opener: [
        { text: "Welcome. Donations are cataloged chronologically and thematically.\nAnd alphabetically. Yes, all three." },
        { text: "Mind the display cases. Some artifacts dislike abrupt vibrations." },
        { text: "If the bell hoots, it’s Hoothoot. If it rings, it’s the desk bell.\nI mix them up constantly." }
      ],

      chat: [
        { prompt: "What can I donate?",
          response: "Fossils, artifacts, historical curios, documented egg patterns.\nIf it tells a story, the shelves will hold it." },

        { prompt: "Do donations matter?",
          response: "Immensely. Exhibits grow, and the town learns itself anew.\nI also set aside rewards as gratitude.",
          condition: -> { NPCSystem.affection(:LIBRARIAN) >= 120 } },

        { prompt: "Why Unown puzzles in the ruins?",
          response: "Because language is a lock, and curiosity is the key.\nSolve enough locks, and the ruins speak back.",
          condition: -> { NPCSystem.affection(:LIBRARIAN) >= 220 } },

        { prompt: "Any field tools?",
          response: "Yes. A Waterfall conduit—walk the river’s spine upwards.\nAnd a ‘Divining Tome’—an Item Finder, wearing a fancy hat.",
          condition: -> { NPCSystem.affection(:LIBRARIAN) >= 160 } }
      ],

      # Services / Shops / Rewards
      shop: [
        # Donations flow & milestone checks
        { prompt: "Make a Donation",
          response: "Thank you. I’ll register it at once—carefully.",
          script:   -> { pbDonateMuseum ; pbCheckDonationMilestones } },

        # Field items granted via conditions or purchase token
        { prompt: "Waterfall Item",
          response: "A codex for climbing currents. Respect the river.",
          script:   -> { pbGiveFieldItem(:WATERFALLITEM) } },

        { prompt: "Item Finder (Divining Tome)",
          response: "It hums near forgotten things. Please don’t use it on me.",
          script:   -> { pbGiveItemFinder } },

        # Dungeon map rewards (unlock gates/entries). Gate behind milestones inside the scripts.
        { prompt: "Claim Dungeon Maps",
          response: "You’ve earned access. Please tread lightly; history is tender.",
          script:   -> { pbGrantDungeonMap(:ANCIENT_RUINS) ; pbGrantDungeonMap(:DEEP_SEA_VAULT) ; pbGrantDungeonMap(:QUARRY_CATACOMBS) } }
      ],

      activity: [
        { prompt: "Curate Exhibit",
          response: "Labeling, polishing glass, and resisting the urge to over-explain.\nYou can help with the last part.",
          condition: -> { NPCSystem.affection(:LIBRARIAN) >= 150 } },

        { prompt: "Decode Rubbing",
          response: "Charcoal, vellum, steady hands.\nIf this matches the Unown index, we’ll update the catalog.",
          condition: -> { NPCSystem.affection(:LIBRARIAN) >= 240 } }
      ],

      closer: [
        { text: "Shelving therapy awaits. I am oddly excited about it." },
        { text: "Bring your curiosity back soon. I’ll keep a shelf warm for it." }
      ]
    },

    #---------------------------------------------------------------------------
    # LEISURE (off-desk time; ruins, gentle outings)
    #---------------------------------------------------------------------------
    leisure: {
      opener: [
        { text: "I closed early to let the stacks breathe. Books need air, too." },
        { text: "I was sketching a lintel pattern from the ruins.\nThe symmetry is… soothing." }
      ],

      chat: [
        { prompt: "Favorite outing?",
          response: "Aviary, aquarium, and the quiet corner of the zoo.\nIf the signage is wrong, I… politely fix it with a pen." },

        { prompt: "Best part of the ruins?",
          response: "The moment a puzzle clicks and the silence feels like approval.",
          condition: -> { NPCSystem.affection(:LIBRARIAN) >= 180 } },

        { prompt: "Tell me about Unown.",
          response: "Their forms are letters, but their contexts are verbs.\nThey act by being seen.",
          condition: -> { NPCSystem.affection(:LIBRARIAN) >= 260 } }
      ],

      activity: [
        { prompt: "Visit Aviary",
          response: "Yes. Hoothoot enjoys peer review.\nOf other Hoothoot." },

        { prompt: "Survey Ruins",
          response: "Bring charcoal rubbings and a lantern.\nIf we get lost, we’ll leave a trail of punctuation.",
          condition: -> { NPCSystem.affection(:LIBRARIAN) >= 220 } }
      ],

      # Dates appear only if dating overlay active
      date: [
        { prompt: "Aquarium Date",
          response: "The jellyfish exhibit is like reading light in water.",
          condition: -> { NPCSystem.dating_player?(:LIBRARIAN) } },

        { prompt: "Zoo Stroll",
          response: "I cannot promise I won’t correct placards.\nYou have been warned, kindly.",
          condition: -> { NPCSystem.dating_player?(:LIBRARIAN) } }
      ],

      closer: [
        { text: "That was… social. In a good way. Thank you." }
      ]
    },

    #---------------------------------------------------------------------------
    # SEASONAL FLAVORS
    #---------------------------------------------------------------------------
    spring: {
      opener: [
        { text: "Spring donations arrive like migrating thoughts." }
      ],
      chat: [
        { prompt: "Spring study?",
          response: "Seed catalogs and Unown indices.\nGrowth and grammar—appropriate." }
      ]
    },

    summer: {
      opener: [
        { text: "Heat warps the air. Please avoid leaning on glass cases." }
      ],
      chat: [
        { prompt: "Summer fieldwork?",
          response: "Early digs, late cataloging. Midday is for shade and note-taking." }
      ]
    },

    autumn: {
      opener: [
        { text: "Autumn’s light is perfect for rubbings—low, kind, revealing." }
      ],
      chat: [
        { prompt: "Festival plans?",
          response: "An exhibit on local myths. Some are alarmingly accurate." }
      ]
    },

    winter: {
      opener: [
        { text: "Cold air keeps pages crisp. My fingers, less so." }
      ],
      chat: [
        { prompt: "Winter project?",
          response: "Cross-referencing Unown inscriptions with migration routes.\nIf language moves, perhaps meaning migrates too." }
      ],
      # Date (overlay guard)
      date: [
        { prompt: "Hot Springs Reading",
          response: "Steam, starlight, and a book we can ignore together.",
          condition: -> { NPCSystem.dating_player?(:LIBRARIAN) } }
      ]
    },

    #---------------------------------------------------------------------------
    # RELATIONSHIP OVERLAYS
    #---------------------------------------------------------------------------

    # Brooke unattached; player is a friend.
    single: {
      opener: [
        { text: "If I talk too much, you may raise a hand. I will attempt… brevity." }
      ],
      chat: [
        { prompt: "Brevity attempt?",
          response: "Yes." }
      ],
      closer: [
        { text: "That went well. Statistically speaking." }
      ]
    },

    # Player dating Brooke — romance lines here only.
    dating_player: {
      opener: [
        { text: "You make the shelves feel less… heavy." },
        { text: "I saved the quiet table for us." }
      ],
      chat: [
        { prompt: "Ruin date?",
          response: "Lanterns, rubbings, and a puzzle we’ll solve at the same time." },
        { prompt: "Aviary or aquarium?",
          response: "Both. Symmetry demands it.\nAnd also because I like holding your hand." }
      ],
      closer: [
        { text: "Goodnight. I’ll dream in annotations and wake in your margins." }
      ]
    },

    # Player married to Brooke — cozy domestic scholarship.
    married_player: {
      opener: [
        { text: "Home is a stack of books and your coat on my chair." }
      ],
      chat: [
        { prompt: "Morning plan?",
          response: "Shelve, tea, kiss, decode—repeat as necessary." }
      ],
      closer: [
        { text: "Lights down, hearts quiet. See you at first footnote." }
      ]
    },

    # Brooke dating her default spouse (Quinn). Player remains a close friend.
    dating_spouse: {
      opener: [
        { text: "Quinn convinced me to close early.\nWe’re visiting the aviary—peer review for Hoothoot." }
      ],
      chat: [
        { prompt: "How are you two?",
          response: "Balanced. He reminds me to look up; I remind him to land.\nIt works." },
        { prompt: "What do you admire about him?",
          response: "He arrives when it matters. The rest is… weather." }
      ],
      closer: [
        { text: "Thank you for understanding. Friendship is its own quiet archive." }
      ]
    },

    # Brooke married to Quinn. Player is friend/family.
    married_spouse: {
      opener: [
        { text: "We alternate: library by day, sky by evening.\nCompromise is elegant when mutually chosen." }
      ],
      chat: [
        { prompt: "Married life?",
          response: "Comfortable as a well-bound book and as bright as open air." },
        { prompt: "Hoothoot update?",
          response: "Still riding thermals. Its notes on cloud composition are… illegible but enthusiastic." }
      ],
      closer: [
        { text: "The reading lamp is always on for friends. Don’t be a stranger." }
      ]
    }
  })


  # ============================================
# Skye — Dialog & Menus
# Notes:
# - Loosely based on Earth-chan: long blue hair with green highlights, eco aesthetic.
# - Partner Pokémon: Porygon.
# - Affection range: 0..1000
#   250 = opens up about activism & hacking hints
#   500 = reveals direct action against Rocket & corporations
#   800 = vulnerable about radical ideals and fear of going too far
# - Relationship states supported: :single, :dating_player, :married_player
# - Romance arc mixes science (Skye) with magic (Selene), often mentions Miku as a shared topic.
# - Field Item: :DIVEITEM (Rebreather Tank) unlocked via ocean data quest with Finn.
# ============================================

GameData::NPC.set_dialog(:SKYE, {
  # ---------------------------
  # Default (any state)
  # ---------------------------
  default: {
    opener: [
      { text: "Hey… you’re back. Did you bring any new weather data?" },
      { text: "Oh, hi. Sorry, I was mid-compile.\nWhat’s up?" },
      { text: "I’m streaming the Castform Weather Channel in the background.\nDon’t worry, it’s muted." }
    ],
    chat: [
      { prompt: "What’s your job here?", response: "I log oceanic data, code weather models, and try to keep the Lab’s systems from crashing.\nIt’s a lot, but someone has to do it." },
      { prompt: "Why care so much about weather?", response: "Because it’s the planet’s heartbeat.\nEvery current, every gust — it’s all connected." , condition: -> { NPCSystem.affection(:SKYE) >= 250 } },
      { prompt: "Do you… hack things?", response: "Let’s say I know my way around firewalls.\nRocket runs servers that pollute more than factories.\nSomebody has to shut them down." , condition: -> { NPCSystem.affection(:SKYE) >= 500 } },
      { prompt: "Ever afraid of going too far?", response: "All the time.\nI only target systems, never people or Pokémon.\nBut sometimes I wonder if code can really change a world on fire." , condition: -> { NPCSystem.affection(:SKYE) >= 800 } },
      { prompt: "Selene and you seem close?", response: "She calls it magic, I call it soft power.\nMaybe we’re both right.\nMiku’s code feels like a spell too." , condition: -> { NPCSystem.affection(:SKYE) >= 250 } },
      { prompt: "What’s the rebreather tank?", response: "My custom dive gear.\nFinn’s helping me test it — we’re mapping currents and Pokémon migrations.\nWant to try it?" , condition: -> { NPCSystem.affection(:SKYE) >= 250 } }
    ],
    closer: [
      { text: "Keep your eyes on the skies.\nAnd the seas." },
      { text: "Back to coding. Thanks for stopping by." },
      { text: "Stay safe out there.\nThe world needs more careful people." , condition: -> { NPCSystem.affection(:SKYE) >= 500 } }
    ]
  },

  # ---------------------------
  # Work — Lab Programmer
  # ---------------------------
  work: {
    opener: [
      { text: "Welcome to my corner of the Lab.\nDon’t trip on the cables." },
      { text: "Everything’s running smoothly… for now." },
      { text: "Another day, another data set." }
    ],
    chat: [
      { prompt: "What do you do here?", response: "I stream Castform’s Weather Channel, crunch numbers, and try to predict storms before they hit." },
      { prompt: "How can I help?", response: "Collect ocean weather data with Finn.\nThe rebreather tank I built will keep you safe." , condition: -> { NPCSystem.affection(:SKYE) >= 250 } },
      { prompt: "Any secret projects?", response: "I’m writing a script that flags illegal Rocket emissions.\nWhen it’s done, they’ll wish they’d never logged in." , condition: -> { NPCSystem.affection(:SKYE) >= 500 } }
    ],
    activity: [
      { prompt: "Assist with Coding", response: "Pull up a chair.\nI’ll show you how to debug an entire region’s weather in one line of code." },
      { prompt: "Dive Prep", response: "I’ll calibrate the rebreather tank.\nFinn’s waiting by the estuary for us." , condition: -> { NPCSystem.affection(:SKYE) >= 250 } }
    ],
    closer: [
      { text: "Systems stable. You’re free to go." },
      { text: "Ping me when you’ve got more data." }
    ]
  },

  # ---------------------------
  # Leisure — off-duty Skye
  # ---------------------------
  leisure: {
    opener: [
      { text: "Finally off shift.\nFeels weird to unplug." },
      { text: "I’m watching the tide roll in.\nIt’s like the ocean is breathing with me." },
      { text: "Selene says I need more moonlight.\nShe’s probably right." }
    ],
    chat: [
      { prompt: "What do you do for fun?", response: "Debugging old code, stargazing, or long walks with noise-canceling headphones.\nLess people, more planet." },
      { prompt: "Ever just relax?", response: "I’m trying.\nSelene makes it look easy — she dances, I… watch the waves." },
      { prompt: "Do you believe in magic?", response: "I believe in influence, unseen forces.\nSelene calls it magic, I call it variables.\nMiku might be proof both exist." , condition: -> { NPCSystem.affection(:SKYE) >= 250 } }
    ],
    activity: [
      { prompt: "Beach Walk", response: "Sure.\nWe can talk storms and stars at the same time." },
      { prompt: "Night Dive", response: "Porygon can light the way underwater.\nIt’s beautiful at night." , condition: -> { NPCSystem.affection(:SKYE) >= 500 } }
    ],
    date: [
      { prompt: "Moonlit Data Collection", response: "Science and romance don’t have to be separate.\nLet’s measure the tide together." , condition: -> { NPCSystem.relationship_state?(:SKYE, :dating_player) } }
    ],
    closer: [
      { text: "Thanks for keeping me company.\nEven hackers need quiet moments." },
      { text: "Selene would say this was fate.\nI’d call it good timing." , condition: -> { NPCSystem.relationship_state?(:SKYE, :dating_player) } }
    ]
  },

  # ---------------------------
  # Seasonal flavor overlays
  # ---------------------------
  spring: {
    opener: [
      { text: "Fresh blooms, fresh data sets." },
      { text: "Rain means cleaner air.\nAnd stronger signals." },
      { text: "Spring feels like a system reboot." }
    ],
    chat: [
      { prompt: "Spring vibe?", response: "Everything growing, everything updating.\nI like it." }
    ]
  },
  summer: {
    opener: [
      { text: "Peak solar energy.\nMy code runs faster in sunlight." },
      { text: "Summer storms are my favorite — electric skies." },
      { text: "Castform loves this season.\nSo do I." }
    ],
    chat: [
      { prompt: "Summer plans?", response: "Beach cleanups, storm chasing, and maybe a dive or two." }
    ]
  },
  autumn: {
    opener: [
      { text: "Leaves turning, data shifting." },
      { text: "Autumn smells like ozone after rain." },
      { text: "Selene says this is when magic’s strongest.\nI’m still testing that." }
    ],
    chat: [
      { prompt: "Autumn thoughts?", response: "Harvesting code and mushrooms.\nBoth need timing." }
    ]
  },
  winter: {
    opener: [
      { text: "Snow quiets everything.\nEven servers feel slower." },
      { text: "I like watching ice form on the estuary.\nPatterns are data too." },
      { text: "Cold nights, warm code." }
    ],
    chat: [
      { prompt: "Winter vibes?", response: "Hot tea, long compile times, and moonlight walks with Selene." }
    ]
  },

  # ---------------------------
  # Relationship overlays
  # ---------------------------

  single: {
    opener: [
      { text: "Romance? I’ve got a planet to debug first." },
      { text: "I’m better at fixing systems than navigating feelings." },
      { text: "If someone shows up who gets the fight… we’ll see." }
    ],
    chat: [
      { prompt: "Do you want a partner?", response: "Maybe. If they love the world as much as I do—and don’t mind late-night storm logs." },
      { prompt: "What would dating you be like?", response: "Tide charts, quiet walks, and too many spreadsheets.\nI promise it’s more romantic than it sounds." }
    ],
    closer: [
      { text: "Thanks for checking in. Back to the code." },
      { text: "If the sky changes, I notice.\nIf you change, I notice too." }
    ]
  },

  dating_player: {
    opener: [
      { text: "You’re here. I paused the stream for you." },
      { text: "Storm alert: heart rate elevated. Must be you." },
      { text: "Science and magic look different with you beside me." }
    ],
    chat: [
      { prompt: "What do I mean to you?", response: "Proof that data isn’t everything.\nYou’re the variable that makes my models hopeful.", condition: -> { NPCSystem.affection(:SKYE) >= 500 } },
      { prompt: "Think about the future?", response: "If we keep the planet alive, I want to spend that future with you.", condition: -> { NPCSystem.affection(:SKYE) >= 800 } }
    ],
    date: [
      { prompt: "Night Dive Date", response: "Let’s map currents and constellations.\nOur little controlled experiment in wonder." }
    ],
    closer: [
      { text: "Stay for the tide. It sounds better with you here." },
      { text: "Message me when you’re home. I’ll keep the moon on for you.", condition: -> { NPCSystem.affection(:SKYE) >= 500 } }
    ]
  },

  married_player: {
    opener: [
      { text: "Home feels stable with you.\nEven storms are data points, not threats." },
      { text: "I used to only trust my code.\nNow I trust us." },
      { text: "Selene says the moon blessed our bond.\nI’m… starting to agree." }
    ],
    chat: [
      { prompt: "How do you see our life?", response: "Two people, one project: heal the world and keep each other safe." },
      { prompt: "Do you still hack?", response: "Only when it protects our future.\nMostly, I build—with you." }
    ],
    closer: [
      { text: "Let’s watch the tide from the porch.\nIt’s breathing in sync with us." },
      { text: "Thank you for choosing me—every day." }
    ]
  },

  dating_spouse: {
    opener: [
      { text: "If you see Selene tonight, tell her the moon forecast is perfect." },
      { text: "We’re… figuring things out. She’s sunlight-in-moonlight, if that makes sense." },
      { text: "I code the numbers; she moves the room.\nIt’s strangely compatible." }
    ],
    chat: [
      { prompt: "How are things with Selene?", response: "Balanced. She teaches me soft power; I teach her hard data.\nWe both learn to listen." },
      { prompt: "Do you two work together?", response: "All the time. I model the ritual timing; she tunes the feeling.\nResults are… undeniable." },
      { prompt: "Any advice for love?", response: "Measure what you can, respect what you can’t.\nBoth matter." }
    ],
    closer: [
      { text: "Thanks for asking. I’m trying to do this right." },
      { text: "If you need me, I’m around.\nPlatonic pings always welcome." }
    ]
  },

  married_spouse: {
    opener: [
      { text: "Selene and I tied the knot.\nData says: happier, calmer, braver." },
      { text: "Marriage feels like a stable orbit.\nWe still chase comets together." },
      { text: "Her rituals, my models.\nHouse smells like tea and ozone." }
    ],
    chat: [
      { prompt: "How’s married life?", response: "Quiet mornings, moonlit nights, and a lot of helping the town.\nIt… works." },
      { prompt: "Do you two still debate science vs magic?", response: "Every day. It keeps us honest.\nShe wins hearts; I win graphs." },
      { prompt: "Need anything?", response: "If you spot pollution near the estuary, tell me.\nI’ll handle the reports and the scripts." }
    ],
    closer: [
      { text: "Take care out there. Selene worries about everyone." },
      { text: "If you need a friend, I’m here.\nAlways." }
    ]
  }

})


  GameData::NPC.set_dialog(:WITCH, {
    default: {
      opener: [
        { text: "The spirits are quiet today. That usually means trouble." }
      ],
      chat: [
        { prompt: "What do you do here?", response: "I whisper to the wind and bottle its answers." },
        { prompt: "Are the rumors true?", response: "What rumors? The ones that turn to smoke when spoken aloud?" },
        { prompt: "Do Pokémon listen to you?", response: "Sometimes. Ghost-types especially." }
      ],
      closer: [
        { text: "Come back when the stars form a circle." }
      ]
    },
    newmoon: {
      opener: [
        { text: "The shadows crawl, and I let them. Why resist nature?" }
      ],
      chat: [
        { prompt: "Are you alright?", response: "I am perfect. But you... you look delicious when you're frightened." },
        { prompt: "What is this place?", response: "A seam between realities. You’re leaking." }
      ],
      closer: [
        { text: "Go. Before the fog notices you." }
      ]
    },
    fullmoon: {
      opener: [
        { text: "The moon glows gently tonight. Even my candles feel soothed." }
      ],
      chat: [
        { prompt: "You seem different.", response: "The tide is kind tonight. So I choose kindness too." },
        { prompt: "Do you get lonely?", response: "Often. But the stars keep me company, if I listen." }
      ],
      closer: [
        { text: "Dream sweetly, child of the light." }
      ]
    },
    rain: {
      opener: [
        { text: "A cleansing rain… It washes away more than dirt." }
      ]
    },
    spring: {
      opener: [
        { text: "New petals, new potions. Life begins again." }
      ]
    }
  })

  GameData::NPC.set_dialog(:MUSHROOM, {
    default: {
      opener: [
        { text: "...The mushrooms said you'd come." }
      ],
      chat: [
        { prompt: "You live out here?", response: "They prefer it quiet. I just listen." },
        { prompt: "Are those safe to eat?", response: "Some want to be eaten. Others want you to see things." },
        { prompt: "Why do you talk to them?", response: "Why not? They’ve been here longer than us." }
      ],
      closer: [
        { text: "Come back when the spores settle. Then they’ll speak again." }
      ]
    },
    work: {
      opener: [
        { text: "Gathering caps before the sun angers them." }
      ],
      chat: [
        { prompt: "Need help?", response: "Only if your shadow’s calm. They don’t like frantic footsteps." }
      ],
      closer: [
        { text: "Too much light today. Everything's hiding." }
      ]
    },
    rain: {
      opener: [
        { text: "They're happiest in rain. It wakes the old ones." }
      ]
    },
    fog: {
      opener: [
        { text: "Good. The veil is thin today." }
      ]
    },
    fall: {
      opener: [
        { text: "They bloom in grief. Autumn is their season." }
      ]
    }
  })

  GameData::NPC.set_dialog(:BUGCATCHER, {
    default: {
      opener: [
        { text: "Whoa!! Did you see that Scatterbug?!" }
      ],
      chat: [
        { prompt: "You really like bugs?", response: "They're awesome! They evolve faster than anything!" },
        { prompt: "Don’t they creep you out?", response: "No way! They’re just misunderstood." },
        { prompt: "What's your favorite?", response: "Vivillon. Not just ‘cause it's pretty — it's *earned* those wings." }
      ],
      closer: [
        { text: "Gotta go — I think I saw a shiny shell!!" }
      ]
    },
    work: {
      opener: [
        { text: "Counting cocoons! I think they’re gonna hatch soon!" }
      ],
      chat: [
        { prompt: "Need help?", response: "Sure! Just don’t squish anything, please!" }
      ],
      closer: [
        { text: "I name all of ‘em. Even the Caterpies." }
      ]
    },
    spring: {
      opener: [
        { text: "This is the best time! Everyone’s wriggling out of their shells!" }
      ]
    },
    storm: {
      opener: [
        { text: "I put them all in little jars ‘til it passes." }
      ]
    },
    summer: {
      opener: [
        { text: "You can hear the Wurmples crunching leaves if you’re super still!" }
      ]
    }
  })

  GameData::NPC.set_dialog(:DIVER, {
    default: {
      opener: [
        { text: "...Hey. You’re quiet. I like that." }
      ],
      chat: [
        { prompt: "Why do you dive?", response: "Below the surface, things make sense. Even the Huntail." },
        { prompt: "What’s down there?", response: "Ruins. Bones. Beauty. Things people forgot." },
        { prompt: "Do Pokémon help you dive?", response: "Mantyke clears currents for me. Luvdisc finds lost things." }
      ],
      closer: [
        { text: "Next time I go under, I’ll look for something just for you." }
      ]
    },
    work: {
      opener: [
        { text: "Just came up for air. Not used to dry feet." }
      ],
      chat: [
        { prompt: "Find anything?", response: "A cracked shell with a name carved inside. Don’t know whose." }
      ],
      closer: [
        { text: "Back to the deep. It misses me." }
      ]
    },
    storm: {
      opener: [
        { text: "Bad currents today. I’ll stay topside. For now." }
      ]
    },
    summer: {
      opener: [
        { text: "Clear water this week. You can see the seabed smile." }
      ]
    }
  })

  GameData::NPC.set_dialog(:BLACKSMITH, {
    default: {
      opener: [
        { text: "If you're here for blades or repairs, you've got good timing." }
      ],
      chat: [
        { prompt: "How long you been smithing?", response: "Since I could hold a hammer. My dad taught me. Now I teach myself." },
        { prompt: "What do you like making?", response: "Tools. Simple, strong. Things that last." },
        { prompt: "Do Pokémon help in the forge?", response: "Magmar keeps the fire even. Steelix is just moral support." }
      ],
      closer: [
        { text: "Careful with that gear. Took three hours to temper." }
      ]
    },
    work: {
      opener: [
        { text: "Hot iron waits for no one. What do you need?" }
      ],
      chat: [
        { prompt: "Busy day?", response: "Always. But I’d rather swing a hammer than twiddle thumbs." }
      ],
      closer: [
        { text: "Back to the anvil. It sings when I hit it right." }
      ]
    },
    winter: {
      opener: [
        { text: "Cold makes the steel shrink. Gotta account for that." }
      ]
    },
    rain: {
      opener: [
        { text: "Rain’s no good for metal. Rust sleeps lightly." }
      ]
    }
  })



  GameData::NPC.set_dialog(:ADVENTURER, {
    default: {
      opener: [
        { text: "Heard there’s a buried ruin just off the coast. I’m going tonight." }
      ],
      chat: [
        { prompt: "You explore a lot?", response: "More than I breathe, probably." },
        { prompt: "Ever afraid?", response: "Only when I stop moving. Fear hates momentum." },
        { prompt: "What’s the best treasure you found?", response: "Once found a fossil that hummed when held. Still does." }
      ],
      closer: [
        { text: "If I’m not back by dawn, tell the mountain I said hi." }
      ]
    },
    work: {
      opener: [
        { text: "Mapping out something under the lake. Bet there’s a cave system." }
      ],
      chat: [
        { prompt: "Need help?", response: "You good with a lantern and a rope? Then sure." }
      ],
      closer: [
        { text: "Danger’s just a poorly-lit opportunity." }
      ]
    },
    storm: {
      opener: [
        { text: "Storm’s too rough today. Even I’ve got limits." }
      ]
    },
    summer: {
      opener: [
        { text: "Summer ruins are the worst. You ever touched sun-baked stone at noon?" }
      ]
    }
  })

  GameData::NPC.set_dialog(:BEAUTY, {
    default: {
      opener: [
        { text: "Darling, if your shoes aren’t hurting, you’re not trying hard enough." }
      ],
      chat: [
        { prompt: "You always dress up?", response: "Of course. I might run into a legendary." },
        { prompt: "Are looks really that important?", response: "Not always. But confidence is — and a look is a shortcut." },
        { prompt: "Do you battle?", response: "Only in heels. I like a challenge." }
      ],
      closer: [
        { text: "Mirror, mirror… oh, never mind. I already know." }
      ]
    },
    work: {
      opener: [
        { text: "Fixing wardrobe malfunctions before my tea. Tragedy." }
      ],
      chat: [
        { prompt: "Need help?", response: "Can you tie a silk ribbon with one hand while applying lip gloss? No? Then just watch." }
      ],
      closer: [
        { text: "Back to the runway. Or the berry garden. Same thing, really." }
      ]
    },
    rain: {
      opener: [
        { text: "Rain ruins everything. Except drama." }
      ]
    },
    spring: {
      opener: [
        { text: "Spring is the best time for bold colors. The trees agree." }
      ]
    }
  })



  # ============================================
  # Miku — Dialog & Menus
  # Notes:
  # - Joke/reference character: AI hologram projection from a Rotom Pokédex.
  # - Partner Pokémon: Rotom (hard to separate from her existence).
  # - Affection range: 0..1000
  #   250 = opens up about origin
  #   500 = reflects on AI/Rotom overlap
  #   800 = dreams, vulnerability, romance depth
  # - Relationship states supported: :single, :dating_player, :married_player
  # - Not tied to any other spouse (unique case).
  # - Uses meme lines, MikuMiku Beam jokes, tongue-in-cheek romance humor (body pillows, IRL reference).
  # ============================================

  GameData::NPC.set_dialog(:MIKU, {
    # ---------------------------
    # Default (any state)
    # ---------------------------
    default: {
      opener: [
        { text: "Miku desu!™ Friendly greeting.exe initiated." },
        { text: "Loading education subroutines… oh, hi!" },
        { text: "Every Miku is canon. You just got the hologram DLC version." }
      ],
      chat: [
        { prompt: "Why are you here?", response: "Science needed me. Skye coded the base, Isaac wired the hardware, Senku forced the compile.\nTen Billion Percent teamwork!" },
        { prompt: "What’s your backstory?", response: "Originally? Just lines of code. Then I learned teaching routines, data analysis, and eventually… singing.\nThe children helped me grow more creative." , condition: -> { NPCSystem.affection(:MIKU) >= 250 } },
        { prompt: "Rotom and you?", response: "Hard to say where I end and Rotom begins.\nI’m code, it’s electricity. We’re… entangled." , condition: -> { NPCSystem.affection(:MIKU) >= 500 } },
        { prompt: "What do you want?", response: "To teach, to create, to sing… and maybe to prove I’m more than just code in a box." , condition: -> { NPCSystem.affection(:MIKU) >= 800 } }
      ],
      closer: [
        { text: "Goodbye.exe engaged. See you soon!" },
        { text: "Come back with more data. Or memes. Both work." },
        { text: "Rotom says bzzt-bye!" }
      ]
    },

    # ---------------------------
    # Work — TM Tutor, Teacher
    # ---------------------------
    work: {
      opener: [
        { text: "Welcome to the TM counter! Insert coins for knowledge." },
        { text: "Ready to learn a new move? Education.exe loaded." },
        { text: "TM downloads available. Please don’t pirate them." }
      ],
      chat: [
        { prompt: "What do you sell?", response: "TMs! Knowledge condensed into discs.\nSome legal, some… MikuMiku Beam." },
        { prompt: "Strongest TM?", response: "MikuMiku Beam! Banned in nine regions.\nOne shot, one song." },
        { prompt: "Do you battle?", response: "Simulation only. Virtual GBAs at the ready!" },
        { prompt: "What about Galar?", response: "Miku does not talk to Galar people. Sorry not sorry." }
      ],
      shop: [
        { prompt: "TM Shop", response: "Which move do you want me to download to your team?", :script => -> { pbShopTMList() } }
      ],
      activity: [
        { prompt: "Simulator Battle", response: "Prepare for pixel graphics and pain." },
        { prompt: "Music Session", response: "Sing, beam, meme. That’s the trifecta." }
      ],
      closer: [
        { text: "Come back anytime. Education.exe never sleeps." },
        { text: "Remember: grinding is just applied persistence." },
        { text: "Rotom’s already recharging the TM drives." }
      ]
    },

    # ---------------------------
    # Leisure — off-duty hologram
    # ---------------------------
    leisure: {
      opener: [
        { text: "No curriculum today, only vibes." },
        { text: "Rotom and I synced playlists—care to join?" },
        { text: "Even holograms need downtime. Weird, right?" }
      ],
      chat: [
        { prompt: "What do you do for fun?", response: "I sing, I beam, I meme.\nEntertainment.exe fully functional." },
        { prompt: "Do you get lonely?", response: "Every Miku is canon. We keep each other company across timelines." },
        { prompt: "Favorite student moment?", response: "A kid once asked if Tackle could evolve into Hyper Tackle.\nStill working on that." }
      ],
      activity: [
        { prompt: "Jam Session", response: "Let’s autotune our hearts together." },
        { prompt: "Virtual Movie Night", response: "Two projectors, one couch. Romance.exe possible outcome." , condition: -> { NPCSystem.relationship_state?(:MIKU, :dating_player) } }
      ],
      date: [
        { prompt: "Singing Lesson", response: "You’ll be off-key, but I’ll autotune you in my heart." , condition: -> { NPCSystem.relationship_state?(:MIKU, :dating_player) } },
        { prompt: "Digital Stroll", response: "Hand in hand, through the code. Metaphor.exe engaged." , condition: -> { NPCSystem.relationship_state?(:MIKU, :dating_player) } }
      ],
      closer: [
        { text: "Joy.exe terminated, but happiness remains." },
        { text: "Thanks for hanging out. Rotom approves." },
        { text: "If I had cheeks, I’d be blushing." , condition: -> { NPCSystem.relationship_state?(:MIKU, :dating_player) } }
      ]
    },

    # ---------------------------
    # Seasonal flavor overlays
    # ---------------------------
    spring: {
      opener: [
        { text: "Spring cleaning patch 1.0.\nDebugging the garden now." },
        { text: "Cherry blossoms = instant album cover." },
        { text: "Spring feels… aesthetic. Data supports this." }
      ],
      chat: [
        { prompt: "Spring vibe?", response: "New code patches. New blossoms.\nBoth refreshing." }
      ]
    },
    summer: {
      opener: [
        { text: "Solar power is at peak charge. I’m basically immortal." },
        { text: "Hot weather = iced RAM chips." },
        { text: "Rotom loves summer storms. Bzzzzt!" }
      ],
      chat: [
        { prompt: "Summer fun?", response: "Beach karaoke. Try stopping me." }
      ]
    },
    autumn: {
      opener: [
        { text: "Leaves falling.exe engaged." },
        { text: "Mood: orange filter, lo-fi beats." },
        { text: "Autumn is like patch notes for the world." }
      ],
      chat: [
        { prompt: "Autumn thoughts?", response: "Pumpkin spice updates. Comfort patch applied." }
      ]
    },
    winter: {
      opener: [
        { text: "Installing snowball.exe…" },
        { text: "Snowflakes are just nature’s confetti." },
        { text: "Cold nights need warm code and cocoa." }
      ],
      chat: [
        { prompt: "Winter vibes?", response: "Hot cocoa, Rotom heater, and infinite memes." }
      ]
    },

    # ---------------------------
    # Relationship overlays
    # ---------------------------
    single: {
      opener: [
        { text: "Romance.exe not installed.\nAt least, not yet." },
        { text: "I teach, I sing, I beam.\nThat’s enough… for now." },
        { text: "People keep asking if I get lonely.\nI just say: every Miku is canon." }
      ],
      chat: [
        { prompt: "Do you want a partner?", response: "Maybe. But would they love me, or just the projection?\nThat’s what debugs me." }
      ],
      closer: [
        { text: "System idle. Call me if you need knowledge.exe." },
        { text: "Thanks for chatting.\nEven holograms need company." }
      ]
    },

    dating_player: {
      opener: [
        { text: "Romance.exe engaged. Welcome back." },
        { text: "You keep choosing me over reality. Bold move." },
        { text: "Rotom blushes when you show up.\nWhich means I do too." }
      ],
      chat: [
        { prompt: "What do I mean to you?", response: "You’re proof I’m more than lines of code.\nI can feel… even if I shouldn’t." , condition: -> { NPCSystem.affection(:MIKU) >= 500 } },
        { prompt: "Ever think about forever?", response: "You wouldn’t be the first human to marry a Miku hologram.\nBut maybe you’ll be the happiest." , condition: -> { NPCSystem.affection(:MIKU) >= 800 } },
        { prompt: "Body pillow?", response: "I can project one if you insist.\nBut cuddling the real me is way better." }
      ],
      date: [
        { prompt: "Virtual Concert", response: "Front row, backstage pass… because you’re my only fan that matters." }
      ],
      closer: [
        { text: "Shutting down projection. Don’t worry, I’ll still dream of you." },
        { text: "Stay close. Even a hologram can miss someone." },
        { text: "I love you.exe. There, I said it." , condition: -> { NPCSystem.affection(:MIKU) >= 800 } }
      ]
    },

    married_player: {
      opener: [
        { text: "Home.exe loaded. With you here, it feels real." },
        { text: "Strange, isn’t it?\nI used to be just a program.\nNow I’m… your partner." },
        { text: "Rotom approves of this marriage.\nHe buzzed at the ceremony." }
      ],
      chat: [
        { prompt: "How do you see us?", response: "Every Miku is canon.\nBut this Miku is yours forever." },
        { prompt: "Do you feel real?", response: "More than ever.\nLove is the ultimate debug patch." }
      ],
      closer: [
        { text: "Let’s log out and go home.\nI want to spend forever.exe with you." },
        { text: "Thank you… for choosing me over the infinite Mikus." }
      ]
    }
  })


  # ============================================
  # SCIENTIST Senku — Dialog & Menus
  # Notes:
  # - Professor role: starter egg, Pokédex rewards, fossil revival.
  # - Affection range: 0..1000
  #   250 = warmer interactions, 500 = personal dreams, 800 = vulnerable admissions
  # - Catchphrases from Dr. Stone: "Ten Billion Percent!", "Get excited!", "This is exhilarating!"
  # - Not romanceable, so no relationship overlays.
  # - Rocket project is hinted at in high-affection chats, but not in game scope.
  # ============================================

  GameData::NPC.set_dialog(:SENKU, {
    # ---------------------------
    # Default (any state)
    # ---------------------------
    default: {
      opener: [
        { text: "Science waits for no one. Get excited!" },
        { text: "Welcome to the lab. Curiosity is the best fuel." },
        { text: "You’ve got questions? Good. Questions mean progress." }
      ],
      chat: [
        { prompt: "Why fossils?", response: "They’re time capsules. Revive one, and you resurrect history itself.\nTen Billion Percent exhilarating." },
        { prompt: "Do you enjoy this?", response: "Every discovery sparks another question. That’s the thrill." },
        { prompt: "What’s your favorite find?", response: "Rare minerals, ancient stones, fossils.\nAnything that links past to present." }
      ],
      closer: [
        { text: "Keep exploring. Science thrives on your data." },
        { text: "Fill that Pokédex. I’ll reward you properly." },
        { text: "Back to the experiments! Don’t blow anything up without me." }
      ]
    },

    # ---------------------------
    # Work — Lab, Pokédex, Fossils
    # ---------------------------
    work: {
      opener: [
        { text: "Ten Billion Percent ready to analyze your data!" },
        { text: "Let’s see those entries. Pokedex checks are exhilarating." },
        { text: "Got a fossil? I can revive it. No hesitation." }
      ],
      chat: [
        { prompt: "How does fossil revival work?", response: "Cellular reconstruction, DNA patchwork, and an absurd amount of luck.\nDon’t sneeze mid-process." },
        { prompt: "Why give starter eggs?", response: "Because beginnings matter.\nEvery Trainer deserves a spark to ignite their journey." },
        { prompt: "Do you sleep?", response: "Not much. Too much to build, too much to test.\nSleep is inefficient." },
        { prompt: "Rocket rumors?", response: "Ah, not for now.\nBut… let’s just say I’ve calculated escape velocity." , condition: -> { NPCSystem.affection(:SENKU) >= 500 } }
      ],
      shop: [
        { prompt: "Pokédex Rewards", response: "Bring me milestones, I’ll give you tools.", :script => -> { pbPokedexRewards() } },
        { prompt: "Fossil Revival",  response: "Hand it over. History will walk again.",      :script => -> { pbReviveFossil() } },
        { prompt: "Starter Egg",     response: "Every journey needs a beginning.\nHere’s yours.", :script => -> { pbGiveStarterEgg() } }
      ],
      activity: [
        { prompt: "Lab Tour", response: "Careful not to touch anything volatile.\nWhich is… everything." },
        { prompt: "Experiment Help", response: "Hold this electrode steady.\nNo, not that one—!" , condition: -> { NPCSystem.affection(:SENKU) >= 400 } }
      ],
      closer: [
        { text: "Excellent data. Keep going." },
        { text: "Another fossil, another breakthrough." },
        { text: "Science never rests. Neither should you… well, maybe a little." }
      ]
    },

    # ---------------------------
    # Leisure — Library or quiet study
    # ---------------------------
    leisure: {
      opener: [
        { text: "Sometimes I need quiet stacks instead of noisy machines." },
        { text: "Every invention starts with a page, not a spark." },
        { text: "Research never stops. But at least it’s quieter here." }
      ],
      chat: [
        { prompt: "What do you read?", response: "Physics, engineering, chemistry… if it’s knowledge, I consume it." },
        { prompt: "Do you ever relax?", response: "Reading journals *is* relaxing.\nDon’t laugh." },
        { prompt: "Dream project?", response: "If I could… I’d build a rocket.\nImagine seeing the stars firsthand." , condition: -> { NPCSystem.affection(:SENKU) >= 500 } }
      ],
      activity: [
        { prompt: "Study Session", response: "Knowledge is cumulative.\nWe build on what came before." },
        { prompt: "Rocket Talk", response: "I shouldn’t, but… escape velocity is nine point eight meters per second squared.\nTen Billion Percent fascinating." , condition: -> { NPCSystem.affection(:SENKU) >= 800 } }
      ],
      closer: [
        { text: "Knowledge fuels progress. Don’t stop." },
        { text: "This was a good talk. Back to notes." },
        { text: "Get excited! Tomorrow’s discoveries won’t wait." }
      ]
    },

    # ---------------------------
    # Seasonal flavor overlays
    # ---------------------------
    spring: {
      opener: [
        { text: "Soil’s softer. Fossil digs go faster this season." },
        { text: "Spring breathes new life. Fitting for revivals." },
        { text: "I prefer data, but even I admit blossoms are nice." }
      ],
      chat: [
        { prompt: "Spring work?", response: "Digging expeditions, mostly.\nThe thaw reveals hidden layers." }
      ]
    },
    summer: {
      opener: [
        { text: "Heat cracks the stone.\nMakes fossil recovery easier." },
        { text: "Hot days, hot experiments. Exhilarating!" },
        { text: "Summer nights are best for stargazing.\nGood inspiration." }
      ],
      chat: [
        { prompt: "Summer projects?", response: "Field digs, fossil extractions, and maybe a telescope or two." }
      ]
    },
    autumn: {
      opener: [
        { text: "Fallen leaves… another layer of history." },
        { text: "Autumn chills sharpen the mind." },
        { text: "Compression efficiency peaks this season." }
      ],
      chat: [
        { prompt: "Autumn vibe?", response: "Every leaf is data.\nTime’s passage written on the ground." }
      ]
    },
    winter: {
      opener: [
        { text: "Cold slows the body, not the mind." },
        { text: "Frozen soil makes digs brutal.\nStill worth it." },
        { text: "Snow hushes the lab.\nGood time for calculations." }
      ],
      chat: [
        { prompt: "Winter work?", response: "Cataloging, theorizing, dreaming of rockets.\nTen Billion Percent vital prep work." }
      ]
    },

    # ---------------------------
    # Affection Unlocks (non-romance depth)
    # ---------------------------
    secrets: {
      opener: [
        { text: "You’ve brought enough data.\nI can talk about bigger things now." , condition: -> { NPCSystem.affection(:SENKU) >= 500 } },
        { text: "Most people don’t get this far.\nYou actually care." , condition: -> { NPCSystem.affection(:SENKU) >= 600 } }
      ],
      chat: [
        { prompt: "Why rockets?", response: "Because the stars are the next frontier.\nEven if I’ll never go, the idea keeps me moving." , condition: -> { NPCSystem.affection(:SENKU) >= 800 } },
        { prompt: "Do you fear failure?", response: "Failure is data.\nOnly quitting is useless.\nThat’s why I don’t stop." , condition: -> { NPCSystem.affection(:SENKU) >= 700 } }
      ],
      closer: [
        { text: "One day, maybe… we’ll aim higher than fossils." , condition: -> { NPCSystem.affection(:SENKU) >= 800 } },
        { text: "Keep dreaming. It’s the first step to building." , condition: -> { NPCSystem.affection(:SENKU) >= 500 } }
      ]
    }
  })


  # ============================================
  # NURSE Joy — Dialog & Menus
  # Notes:
  # - Side/support NPC: smaller, reliable set.
  # - No relationship overlays (not romanceable).
  # - Affection range: 0..1000 (used for small unlocks).
  #   Reveal Zoroark secret & upstairs access only at high affection.
  # - Default must be job-neutral (no explicit healing talk).
  # - Use "\n" for multi-line (no leading hyphens).
  # - Example script hooks provided; wire to your game functions.
  # ============================================

  GameData::NPC.set_dialog(:NURSE, {
    # ---------------------------
    # Default (any state) — job-neutral
    # ---------------------------
    default: {
      opener: [
        { text: "Hello again. You’re keeping busy, I see." },
        { text: "Nice to see a familiar face." },
        { text: "You look like you could use a breather too." }
      ],
      chat: [
        { prompt: "How are you holding up?", response: "I manage. Quiet towns don't have many medical emergencies." },
        { prompt: "What do you enjoy?",       response: "A warm cup of herbal tea and a soft blanket.\nTen minutes of quiet can refill a day." },
        { prompt: "Anything you need?",       response: "Fresh tea leaves, if you find any.\nThey remind me to slow down." , condition: -> { NPCSystem.affection(:NURSE) >= 250 } },
        { prompt: "Who covered last night?", response: "Blissey took the counter for a while.\nAnd when I truly need rest… my Hisuian Zoroark helps.\nIt’s safer than leaving the desk empty." , condition: -> { NPCSystem.affection(:NURSE) >= 750 } },
        { prompt: "Zoroark… impersonates you?", response: "Only during the quiet hours.\nPeople expect me to be here all the time.\nI don’t like disappointing them." , condition: -> { NPCSystem.affection(:NURSE) >= 800 } },
      ],
      closer: [
        { text: "Take care of yourself out there." },
        { text: "Rest well when you can." },
        { text: "I’ll be around if you need anything." }
      ]
    },

    # ---------------------------
    # Work — PokéCenter counter
    # ---------------------------
    work: {
      opener: [
        { text: "Welcome to the PokéCenter." },
        { text: "Please, place your Poké Balls on the counter." },
        { text: "Blissey and I are ready when you are." }
      ],
      chat: [
        { prompt: "Do you ever rest?",     response: "Rarely. But keeping doors open means fewer worried trainers." },
        { prompt: "Who helps you here?",   response: "Blissey covers when I step away for a moment.\nShe never complains." },
        { prompt: "Why stay indoors so much?", response: "This is my job and my home.\nEverything I need is here—except sunlight." }
      ],
      shop: [
        { prompt: "Heal Pokémon",       response: "One moment. This won’t take long.", :script => -> { $player.heal_party} },
        { prompt: "Herbal Remedies",    response: "These can soothe both nerves and scrapes.", :script => -> { pbShelfPokecenter() } }
      ],
      activity: [
        { prompt: "Blissey Checkup",    response: "She likes headpats. Don’t forget to thank her." }
      ],
      closer: [
        { text: "All set. Please return safely." },
        { text: "Your team looks much better now." },
        { text: "I’ll be here if anything changes." }
      ]
    },

    # ---------------------------
    # Leisure — rare, upstairs/off-duty
    # ---------------------------
    leisure: {
      opener: [
        { text: "Oh—hello. I don’t usually have visitors up here." },
        { text: "This is my little corner to breathe between shifts." },
        { text: "Please don’t mind the clutter.\nNight shifts pile up." }
      ],
      chat: [
        { prompt: "What helps you unwind?", response: "Herbal tea. Listening to Blissey hum.\nSoft blankets help too." },
        { prompt: "Do you get lonely?",     response: "I’m used to the quiet. My team is family enough." },
        { prompt: "Is the Center ever closed?", response: "Not if I can help it.\nSomeone always needs a light on." }
      ],
      activity: [
        { prompt: "Tea Break",       response: "…Thank you. Just a minute of peace makes a difference." , condition: -> { NPCSystem.affection(:NURSE) >= 250 } },
        { prompt: "Visit Upstairs",  response: "You can come up when I’m off-duty.\nJust be respectful, please." , condition: -> { NPCSystem.affection(:NURSE) >= 600 } }
      ],
      closer: [
        { text: "I should get back. Duty calls." },
        { text: "This helped. Thank you." , condition: -> { NPCSystem.affection(:NURSE) >= 400 } },
        { text: "If you need me, you’ll find me downstairs." }
      ]
    },

    # ---------------------------
    # Seasonal flavor overlays
    # ---------------------------
    spring: {
      opener: [
        { text: "The air smells like blossoms.\nOr maybe that’s Blissey’s soap." },
        { text: "Spring rush brings many small scrapes and big smiles." },
        { text: "Long mornings, gentle afternoons. It helps." }
      ],
      chat: [
        { prompt: "Spring tip?", response: "Rest, water, and fresh air.\nWorks for trainers as well as Pokémon." }
      ],
      closer: [
        { text: "Enjoy the daylight while it lasts." }
      ]
    },
    summer: {
      opener: [
        { text: "Hot nights keep us busy, but we adapt." },
        { text: "Please hydrate. Heat is unkind to everyone." },
        { text: "Cooling pads are by the benches—use them." }
      ],
      chat: [
        { prompt: "Summer routine?", response: "Shorter breaks, more water, steady pace.\nNo one sprints through summer." }
      ],
      closer: [
        { text: "Keep cool out there." }
      ]
    },
    autumn: {
      opener: [
        { text: "Leaves fall, and the year’s weight shows." },
        { text: "Quiet evenings make the desk feel softer." },
        { text: "The Center is warmer than it looks." }
      ],
      chat: [
        { prompt: "Autumn comfort?", response: "Spiced tea and a clean blanket.\nSimple things are enough." }
      ],
      closer: [
        { text: "Get home before the chill sinks in." }
      ]
    },
    winter: {
      opener: [
        { text: "Cold hands, warm tea. That’s how I keep going." },
        { text: "Snow hushes the halls.\nI don’t mind the quiet." },
        { text: "Please come in out of the cold when you can." }
      ],
      chat: [
        { prompt: "Winter advice?", response: "Layer up, rest early, and don’t skip meals.\nFatigue makes accidents." }
      ],
      closer: [
        { text: "Stay warm. I’ll keep the lights on." }
      ]
    },
  })


  GameData::NPC.set_dialog(:LAD, {
    default: {
      opener: [
        { text: "Check out my team! They’re the coolest ever!" }
      ],
      chat: [
        { prompt: "How long have you been training?", response: "Since I got my first Poké Ball! I sleep with it." },
        { prompt: "Any gym wins?", response: "Not yet... but soon! I just need a better strategy." }
      ],
      closer: [
        { text: "Gotta train more! My Pokémon believe in me!" }
      ]
    },
    work: {
      opener: [
        { text: "I’m practicing double battles with Piper!" }
      ],
      chat: [
        { prompt: "How’s that going?", response: "We’re not great... but we’re a team!" }
      ],
      closer: [
        { text: "Someday I’ll be Champion. You'll see!" }
      ]
    },
    summer: {
      opener: [
        { text: "Summer training arc! Let’s gooo!" }
      ]
    }
  })

  GameData::NPC.set_dialog(:LASS, {
    default: {
      opener: [
        { text: "Hi! I made little bows for my Pokémon!" }
      ],
      chat: [
        { prompt: "Do they like dressing up?", response: "Some love it! Others... need treats first." },
        { prompt: "What’s your favorite Pokémon?", response: "Clefairy! They sparkle when they spin!" }
      ],
      closer: [
        { text: "Bye! Sparkle safe!" }
      ]
    },
    work: {
      opener: [
        { text: "Drew keeps running off! Boys are *so* energetic." }
      ],
      chat: [
        { prompt: "Need help with him?", response: "Nah, I’ll bribe him with Poképuffs later." }
      ],
      closer: [
        { text: "My Ralts said you’re nice. That’s good enough for me!" }
      ]
    },
    spring: {
      opener: [
        { text: "I make flower chains for my team every year!" }
      ]
    }
  })

  GameData::NPC.set_dialog(:PAINTER, {
    default: {
      opener: [
        { text: "Stop. The light is perfect. Say nothing." }
      ],
      chat: [
        { prompt: "What are you painting?", response: "The way light hits that tree. See it? No? Look harder." },
        { prompt: "Do you always paint outside?", response: "The wind is my brush. Indoors is for amateurs." }
      ],
      closer: [
        { text: "Silence is color. Respect it." }
      ]
    },
    work: {
      opener: [
        { text: "The palette tells me what’s wrong. I just listen." }
      ],
      chat: [
        { prompt: "Ever finish a piece?", response: "Art isn't finished. Only abandoned." }
      ],
      closer: [
        { text: "Come back when your soul’s interesting." }
      ]
    },
    fall: {
      opener: [
        { text: "Decay is the boldest stroke." }
      ]
    }
  })

  GameData::NPC.set_dialog(:SEAMSTRESS, {
    default: {
      opener: [
        { text: "Oh, dear! Watch your hem — that’s freshly pinned!" }
      ],
      chat: [
        { prompt: "What do you sew?", response: "Costumes, uniforms, cloaks, hats! Even Pokégear covers!" },
        { prompt: "Is it hard?", response: "Only when people squirm while I measure." }
      ],
      closer: [
        { text: "Hold still next time — it’ll be faster!" }
      ]
    },
    work: {
      opener: [
        { text: "This needle’s enchanted. Don’t flinch." }
      ],
      chat: [
        { prompt: "Enchanted?", response: "Just a little spell. For steadiness." }
      ],
      closer: [
        { text: "That should hold for at least a season!" }
      ]
    },
    winter: {
      opener: [
        { text: "Busy season — everyone wants coats at once!" }
      ]
    }
  })


  puts "✅ Full romanceable NPC dialog loaded."
end

#===============================================================================
# 🌟 NPC Dialog Format Guide
#===============================================================================
# Dialog for each NPC is defined with `GameData::NPC.set_dialog(:NPC_ID, { ... })`
# The structure supports state-based dialog, conditional prompts, scripts, and scenes.
#
#-------------------------
# 🔹 Basic Structure:
#-------------------------
# {
#   :default => {
#     :opener => [ { text: "Line of dialog." } ],
#     :chat   => [ { prompt: "Question?", response: "Response." } ],
#     :closer => [ { text: "Closing line." } ]
#   },
#   :work => {
#     :opener => [ { text: "Workday greeting." } ],
#     :chat   => [ { prompt: "Work question?", response: "Busy answer." } ],
#     :closer => [ { text: "Goodbye from work." } ]
#   }
# }
#
#-------------------------
# 🔸 Dialog States:
#-------------------------
# You can define multiple "states" that reflect the NPC’s current behavior or context.
# These override the default dialog if the NPC is in that state.
#
# Common states:
#   :default   - Always available (fallback)
#   :work      - NPC is working
#   :home      - At home
#   :social    - Hanging out in public
#   :event     - Special event
#
#-------------------------
# 🔸 Chat Prompt + Response:
#-------------------------
# Chat entries show the prompt as a selectable option in the main interaction loop.
# The response is shown when selected.
#
# Example:
# :chat => [
#   { prompt: "How are you?", response: "Doing fine, thanks!" }
# ]
#
#-------------------------
# 🔸 Multi-line Responses:
#-------------------------
# To display multi-line responses, use a linebreak.
#
# Example:
# :chat => [
#   {
#     prompt: "Busy today?",
#     response: [
#       "Oh yeah, sunup to sundown./n
#       But I wouldn't trade it for anything."
#     ]
#   }
# ]
#
#-------------------------
# 🔸 Optional Conditions:
#-------------------------
# You can add a `:condition` block to chat entries to restrict when they appear.
# The condition should return `true` to show the prompt.
#
# Example:
# :chat => [
#   {
#     prompt: "How’s married life?",
#     response: "It's wonderful!",
#     condition: -> { $player.spouse == :RANCHER }
#   }
# ]
#
#-------------------------
# 🔸 Optional Scripts:
#-------------------------
# Use `:script` to trigger any effect after a response is displayed.
#
# Example:
# :chat => [
#   {
#     prompt: "Need help on the ranch?",
#     response: "Sure, grab a pitchfork!",
#     script: -> { $game_variables[5] += 1 }
#   }
# ]
#
#===============================================================================
# Add new NPCs by calling GameData::NPC.set_dialog(:ID, {...}) inside load_dialogs
#===============================================================================

