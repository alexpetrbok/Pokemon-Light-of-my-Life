#===============================================================================
# Example NPCs
#===============================================================================

def load_test_npcs
  GameData::NPC.register({
    id: "RANCHER",
    name: "Sadie",
    spouse: "GARDENER",
    birthday: "summer 17",
    fav_gifts: {
      :RAREBONE => 10,
      :BERRYJUICE => 3,
      :PERSIMBERRY => 3
    },
    bad_gifts: {
      :SOFTSAND => -5,
      :ORANBERRY => -2,
      :SITRUSBERRY => -2
    },
    schedule: {
      weekday: {
        9 => :work,
        17 => :home,
        21 => :sleep
      },
      weekend: {
        10 => :leisure,
        16 => :home,
        21 => :sleep
      }
    }
  })

  GameData::NPC.register({
    id: "GARDENER",
    name: "Lily",
    spouse: "RANCHER",
    birthday: "spring 4",
    fav_gifts: {
      :BOTTLECAP => 10,
      :TINYMUSHROOM => 4,
      :SWEETHEART => 3
    },
    bad_gifts: {
      :REVIVE => -3,
      :BIGROOT => -2
    },
    schedule: {
      weekday: {
        8 => :work,
        18 => :home,
        22 => :sleep
      },
      weekend: {
        12 => :leisure,
        18 => :home,
        22 => :sleep
      }
    }
  })

  GameData::NPC.register({
    id: "POKECAFE",
    name: "Robyn",
    spouse: nil,
    birthday: "fall 9",
    fav_gifts: {
      :MOOMOOMILK => 10,
      :LAVACOOKIE => 3,
      :CHESTOBERRY => 2
    },
    bad_gifts: {
      :CASTELIBONE => -4,
      :ENERGYPOWDER => -2
    },
    schedule: {
      weekday: {
        6 => :work,
        15 => :social,
        20 => :home,
        23 => :sleep
      },
      weekend: {
        8 => :leisure,
        18 => :social,
        22 => :sleep
      }
    }
  })

  GameData::NPC.register({
    id: "PROGRAMMER",
    name: "Cassia",
    spouse: nil,
    birthday: "winter 2",
    fav_gifts: {
      :UPGRADE => 10,
      :XACCURACY => 3,
      :EVIOLITE => 5
    },
    bad_gifts: {
      :HONEY => -3,
      :POMEGBERRY => -2
    },
    schedule: {
      weekday: {
        10 => :work,
        19 => :home,
        2 => :sleep
      },
      weekend: {
        12 => :leisure,
        20 => :home,
        2 => :sleep
      }
    }
  })

  puts "✅ Test NPCs registered!"
end


