def load_dialogs
  
  GameData::NPC.set_dialog(:ENGINEER, {
    default: {
      opener: [
        { text: "Careful where you step. One wrong move and the whole circuit shorts." }
      ],
      chat: [
        { prompt: "What are you building?", response: "Right now? A solar-powered Pokéball printer. Don't ask." },
        { prompt: "Why so many gadgets?", response: "Because everything breaks. People, too." },
        { prompt: "Do you ever sleep?", response: "Only during firmware updates." }
      ],
      closer: [
        { text: "Let me know if you find a rare alloy or a therapist." }
      ]
    },
    work: {
      opener: [
        { text: "Wiring up a voltage regulator. Try not to breathe too loud." }
      ],
      chat: [
        { prompt: "Can I help?", response: "Got a steady hand and 0.01mm precision? No? Thought so." }
      ],
      closer: [
        { text: "Back to the sparks and cursing." }
      ]
    },
    storm: {
      opener: [
        { text: "Storm’s great for charging batteries. Not so great for staying alive." }
      ]
    },
    winter: {
      opener: [
        { text: "Cold makes everything brittle. Including my patience." }
      ]
    }
  })

  GameData::NPC.set_dialog(:POKECAFE, {
    default: {
      opener: [
        { text: "How are you?" }
      ],
      chat: [
        { prompt: "Why open a café?", response: "I saw too many Pokémon who needed a safe place to rest… so I decided to create one myself." },
        { prompt: "How do you manage alone?", response: "Spreadsheets, late nights, and a lot of coffee. I’ll manage until I can hire help." },
        { prompt: "Do you like your work?", response: "I love it. Even when I’m tired, seeing a Pokémon relax makes it worth it." }
      ],
      closer: [
        { text: "Take care, and give your partners some extra love for me." }
      ]
    },

    work: {
      opener: [
        { text: "Let me know if your Pokémon need grooming, training, or just a moment of calm." },
        { text: "Welcome to the Pokécafé. How are your partners doing today?" }
      ],
      chat: [
        { prompt: "How do you purify shadow Pokémon?", response: "Gentle care. Treats, massages, patience… it’s slow, but kindness reaches through the darkness." },
        { prompt: "Do you sell anything?", response: "Homemade treats, crafted to build trust and friendship." },
        { prompt: "What drives you?", response: "Every rescued Pokémon reminds me why I started this. One smile at a time." },
        { prompt: "Need any help?", response: "Maybe someday… I’d love to expand, but right now it’s just me." , condition: -> { NPCSystem.affection(:POKECAFE) >= 80 } },
        { prompt: "Ever take breaks?", response: "Not really. But if you stuck around, maybe I’d actually rest." , condition: -> { NPCSystem.affection(:POKECAFE) >= 120 } }
      ],
      shop: [
        { prompt: "Friendship Treats", response: "Here—homemade and healthy.", :script => -> { pbShopPokecafe }},
        { prompt: "Pokémon Massage", response: "Which partner needs some extra care?" } #pkmn.changeHappiness(groom)
      ],
      closer: [
        { text: "Come back anytime. The café’s doors are always open." }
      ]
    },

    leisure: {
      opener: [
        { text: "I finally closed up for a while. Feels strange to step away." }
      ],
      chat: [
        { prompt: "What do you do to relax?", response: "Fishing clears my head. Quiet water, no ledgers." },
        { prompt: "Do you ever think about the future?", response: "Yes… I dream of turning this into something bigger. A shelter, a real rescue center." , condition: -> { NPCSystem.affection(:POKECAFE) >= 100 } }
      ],
      activity: [
        { prompt: "Relax Together", response: "I could use a quiet moment… thank you." },
        { prompt: "Field Rescue Call", response: "There’s a Shadow Pokémon sighting. Want to come?" , condition: -> { NPCSystem.affection(:POKECAFE) >= 140 } }
      ],
      date: [
        { prompt: "Evening Walk", response: "That sounds… nice. I don’t get asked that often." , condition: -> { NPCSystem.dating_player?(:POKECAFE) } },
        { prompt: "Cafe After Hours", response: "Just us, the lights low, and maybe a cup of cocoa." , condition: -> { NPCSystem.dating_player?(:POKECAFE) } }
      ],
      closer: [
        { text: "I should head back soon… but this was good." }
      ]
    },

    # Seasonal Flavors
    spring: {
      opener: [
        { text: "Spring brings new life—and too many stray rescues at once." }
      ],
      chat: [
        { prompt: "Spring favorite?", response: "Fresh berry tea. Sweet, simple, grounding." }
      ]
    },
    summer: {
      opener: [
        { text: "Summer keeps me busy… and the heat drives a lot of Shadow Pokémon into town." }
      ],
      chat: [
        { prompt: "Summer specialty?", response: "Chilled lemonade cookies. Keeps spirits high in the heat." }
      ]
    },
    autumn: {
      opener: [
        { text: "Autumn walks help me clear my head. Haunted Woods are eerie, but strangely calming." }
      ],
      chat: [
        { prompt: "Autumn favorite?", response: "Pumpkin spice… don’t laugh. It’s comforting." }
      ]
    },
    winter: {
      opener: [
        { text: "Cold nights bring quiet here. It almost feels safe, for a while." }
      ],
      chat: [
        { prompt: "Winter favorite?", response: "Spiced cocoa and soft blankets. The little things." }
      ],
      date: [
        { prompt: "Hot Springs Trip", response: "Steam and starlight… I think I’d actually relax." , condition: -> { NPCSystem.dating_player?(:POKECAFE) } }
      ]
    }
  })


  GameData::NPC.set_dialog(:RANCHER, {
    default: {
      opener: [
        { text: "Mornin’, traveler! Tauros are fed and I'm feelin’ fine." }
      ],
      chat: [
        { prompt: "How’s ranch life?", response: "Busy, but honest work. Tauros don't let you slack." },
        { prompt: "How’d you get started?", response: "My folks ran this land before me. I reckon I was born in boots." },
        { prompt: "You ever take time off?", response: "Only if a Gogoat carries me away." }
      ],
      closer: [
        { text: "Come back any time, partner." }
      ]
    },
    work: {
      opener: [
        { text: "Easy now — just settin' up the feed lines." }
      ],
      chat: [
        { prompt: "Need help?", response: "If you ain’t afraid of mud, I won’t say no." },
        { prompt: "Do Pokémon help out?", response: "Miltank pulls her weight, and Mudbray’s got more sense than most people." }
      ],
      closer: [
        { text: "Duty calls. Or maybe that’s just a hungry Mudsdale." }
      ]
    },
    spring: {
      opener: [
        { text: "Spring’s a busy time. Lotta new foals to watch over." }
      ]
    },
    rain: {
      opener: [
        { text: "Storm’s brewin’. Tauros hate the mud, but Mudbray loves it." }
      ]
    }
  })


  GameData::NPC.set_dialog(:GARDENER, {
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
  
  #---------------------------------------------------------------------------
    # DEFAULT (job-neutral; appears in any location/state; carries Af/SpA arcs)
    #---------------------------------------------------------------------------
    default: {
      opener: [
        { text: "Welcome. Mind the Lotad—they’ll follow you if you drip water." },
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
          response: "I overwatered trying to save the buds.\nThe runoff slid downhill and turned her field to mud.\nI’m measuring soil moisture now—no more guessing.",
          condition: -> { (s = NPCSystem.spouse_affection(:GARDENER)) >= 125 && s <= 175 } },

        # Stage 3 (150–175): forced cooperation (pests/weather)
        { prompt: "Did you two work together?",
          response: "A Beedrill swarm forced our hands.\nShe’s steady under pressure… I may have misjudged her.",
          condition: -> { (s = NPCSystem.spouse_affection(:GARDENER)) > 150 && s < 175 } },

        # Stage 4 (175–200): first amends (fences, hedges)
        { prompt: "Any progress with the boundary?",
          response: "She repaired the fence without me asking.\nI planted berry hedges to guide her herd away—pretty and practical.",
          condition: -> { (s = NPCSystem.spouse_affection(:GARDENER)) >= 175 && s < 200 } },

        # Softening (200–250): respect
        { prompt: "Still arguing?",
          response: "Less shouting. More listening.\nTurns out we both want the same thing—healthy fields.",
          condition: -> { (s = NPCSystem.spouse_affection(:GARDENER)) >= 200 && s < 250 } },

        # Near-resolution (250–300): warmth
        { prompt: "You look… lighter.",
          response: "She dropped off hay bales to brace my greenhouse.\nI left a basket of jam by her door.\nNeighbors can be wonderful.",
          condition: -> { (s = NPCSystem.spouse_affection(:GARDENER)) >= 250 && s < 300 } }
      ],

      closer: [
        { text: "Stay rooted, and let yourself grow." },
        { text: "Take care—remember to drink water." },
        { text: "Thanks for listening… I don’t often get to share.",
          condition: -> { NPCSystem.affection(:GARDENER) >= 500 } }
      ]
    },

    #---------------------------------------------------------------------------
    # WORK (Berry Shop / Greenhouse / Field passes & CUT item)
    #---------------------------------------------------------------------------
    work: {
      opener: [
        { text: "Shhh—Budew are napping in the shade." },
        { text: "Welcome! Fresh berries just in." },
        { text: "I’m pruning the overgrowth—mind the clippings." }
      ],

      chat: [
        { prompt: "What do you sell?",
          response: "Berries, mulch, watering cans… and timed greenhouse access.\nPlease respect the plants while you pick." },
        { prompt: "What’s the CUT item for?",
          response: "Responsible pruning.\nClear saplings and keep borders tidy—overgrowth invites trouble." },
        # Overwatering lesson (ties to runoff)
        { prompt: "Watering tips?",
          response: "Check moisture before every pass.\nKindness can drown roots—and flood a neighbor’s field.",
          condition: -> { (s = NPCSystem.spouse_affection(:GARDENER)) >= 75 } },
        # Personal dream
        { prompt: "Your long-term goal?",
          response: "To cultivate a legendary berry—sweetness born from patience.\nMaybe it already exists, waiting for the right season.",
          condition: -> { NPCSystem.affection(:GARDENER) >= 500 } }
      ],

      shop: [
        { prompt: "Buy Berries",          response: "Freshly picked—handle with care.",  script: -> { pbShopGardenerBerries } },
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


  GameData::NPC.set_dialog(:PROGRAMMER, {
    default: {
      opener: [
        { text: "You again? Don't stand too close to the debug server." }
      ],
      chat: [
        { prompt: "What are you building?", response: "A predictive outbreak simulator. It’s… going okay." },
        { prompt: "Ever go outside?", response: "Only for shiny hunts. Pixels are safer." },
        { prompt: "What’s all this code for?", response: "Honestly? Just trying to impress you." }
      ],
      closer: [
        { text: "Back to fighting the compiler..." }
      ]
    },
    work: {
      opener: [
        { text: "If I don’t finish this patch, reality might collapse." }
      ],
      chat: [
        { prompt: "Need help?", response: "Know any JavaScript? No? Didn’t think so." }
      ]
    },
    storm: {
      opener: [
        { text: "Thunderstorm? Perfect ambiance." }
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

  GameData::NPC.set_dialog(:BIRDKEEPER, {
    default: {
      opener: [
        { text: "The wind speaks today. The flock flew higher than usual." }
      ],
      chat: [
        { prompt: "Are those your birds?", response: "They’re not mine. We just travel the skies together." },
        { prompt: "What’s it like to fly?", response: "Like dreaming while awake. Like trusting the clouds to catch you." },
        { prompt: "Do they understand you?", response: "Better than most people, I think." }
      ],
      closer: [
        { text: "If you find a stray feather, it might be from me." }
      ]
    },
    work: {
      opener: [
        { text: "Training the flock today. Pidgeotto’s leading the drills." }
      ],
      chat: [
        { prompt: "Need help?", response: "If you can whistle on pitch, they might just listen." }
      ],
      closer: [
        { text: "They’re better fliers than I’ll ever be. I just keep up." }
      ]
    },
    spring: {
      opener: [
        { text: "Spring breezes make them restless. Migration’s in their bones." }
      ]
    },
    rain: {
      opener: [
        { text: "Rain’s no trouble. Feathers dry. Spirits don’t." }
      ]
    },
    storm: {
      opener: [
        { text: "Wings grounded. But the sky’s still calling." }
      ]
    }
  })

  GameData::NPC.set_dialog(:LIBRARIAN, {
    default: {
      opener: [
        { text: "...Hello. Shh, though. The books are listening." }
      ],
      chat: [
        { prompt: "Read anything good?", response: "Mm. There’s a Kanto folk tale about a haunted Snorlax. Terrifying." },
        { prompt: "Why so quiet?", response: "Noise distracts. From thought. From truth." },
        { prompt: "Do you like it here?", response: "Yes. The dust has history in it." }
      ],
      closer: [
        { text: "If you take a book, bring it back better." }
      ]
    },
    work: {
      opener: [
        { text: "Indexing ancient League records. Some of these trainers vanished." }
      ],
      chat: [
        { prompt: "Need help?", response: "Only if you’re fluent in Johtan cursive." }
      ],
      closer: [
        { text: "The silence helps me think. Or hide." }
      ]
    },
    fall: {
      opener: [
        { text: "Autumn smells like paper and endings." }
      ]
    },
    winter: {
      opener: [
        { text: "I like winter. Less small talk. More story." }
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

  GameData::NPC.set_dialog(:MIKU, {
    default: {
      opener: [
        { text: "Oh! Hi hi! Want to hear something cool I made?" }
      ],
      chat: [
        { prompt: "Are you famous?", response: "Ehh kinda? I’m internet famous. That’s like, medium-tier." },
        { prompt: "What's that sound from?", response: "Synths! Real ones. I sampled an Emolga squeak last week." },
        { prompt: "Why music?", response: "Because my head is too loud unless I *make* it music." }
      ],
      closer: [
        { text: "Okay, I’m gonna go loop something. Byeee~" }
      ]
    },
    work: {
      opener: [
        { text: "Ugh. This mix is so close. Something's off in the bass." }
      ],
      chat: [
        { prompt: "Need help?", response: "Unless you’re a soundproof booth, probs not." }
      ],
      closer: [
        { text: "Okay okay okay—gonna hit render. Don’t talk or I’ll jinx it." }
      ]
    },
    night: {
      opener: [
        { text: "Late-night loop sessions hit *different*, y'know?" }
      ]
    },
    storm: {
      opener: [
        { text: "Yessss, perfect sample weather. Thunder is free percussion." }
      ]
    },
    winter: {
      opener: [
        { text: "I make more lo-fi tracks in winter. Probably the melancholy." }
      ]
    }
  })

  GameData::NPC.set_dialog(:SCIENTIST, {
    default: {
      opener: [
        { text: "Hypothesis: you're here to interrupt my data collection." }
      ],
      chat: [
        { prompt: "What are you working on?", response: "Cellular reactions in Poké-nervous systems. Want details?" },
        { prompt: "Do you ever rest?", response: "Rest is a variable. I optimize for results." }
      ],
      closer: [
        { text: "Return if you're useful. Or curious." }
      ]
    },
    work: {
      opener: [
        { text: "DO NOT move that flask!" }
      ],
      chat: [
        { prompt: "What’s that machine?", response: "An EEG scanner retrofitted for psychic Pokémon." }
      ],
      closer: [
        { text: "Lab hours are sacred. Come back during chaos." }
      ]
    },
    storm: {
      opener: [
        { text: "Perfect conditions for lightning experiments!" }
      ]
    }
  })

  GameData::NPC.set_dialog(:NURSE, {
    default: {
      opener: [
        { text: "Hello there! Are you or your Pokémon in need of care?" }
      ],
      chat: [
        { prompt: "How do you stay so calm?", response: "One deep breath. Then one more." },
        { prompt: "Do you ever leave the center?", response: "Of course! I volunteer at the daycare sometimes." }
      ],
      closer: [
        { text: "Stay safe, okay? Hydration and full hearts." }
      ]
    },
    work: {
      opener: [
        { text: "Hang tight — we’ll have them back to full health in no time." }
      ],
      chat: [
        { prompt: "Is that a rare wound?", response: "Burns from overclocked abilities. We see it more lately." }
      ],
      closer: [
        { text: "Keep an eye on status conditions out there!" }
      ]
    },
    rain: {
      opener: [
        { text: "I always stock more Antidotes during rainy weeks." }
      ]
    }
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

