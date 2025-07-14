#===============================================================================
# Souldew Valley NPCs
#===============================================================================

def load_npcs
  GameData::NPC.register({
    id: "ENGINEER",
    name: "Isaac",
    spouse: "POKECAFE",
    birthday: "summer 1",
    fav_gifts: {
      :IRON => 10,
      :SOLARCELL => 5,
      :SMOKEBALL => 3
    },
    bad_gifts: {
      :PRETTYWING => -4,
      :LAVACOOKIE => -3,
      :PECHA => -2
    },
    schedule: {
      weekday: {
        7 => :work,
        18 => :home,
        1 => :sleep
      },
      weekend: {
        9 => :work,
        17 => :leisure,
        23 => :sleep
      }
    }
  })


  GameData::NPC.register({
    id: "POKECAFE",
    name: "Robyn",
    spouse: "ENGINEER",
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
    id: "PROGRAMMER",
    name: "Skye",
    spouse: "WITCH",
    birthday: "spring 22",
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

  GameData::NPC.register({
    id: "WITCH",
    name: "Selene",
    spouse: "PROGRAMMER",
    birthday: "winter 21",
    fav_gifts: {
      :BLACKSLUDGE => 10,
      :MOONSTONE => 7,
      :TINYMUSHROOM => 3
    },
    bad_gifts: {
      :REVIVE => -4,
      :LUXURYBALL => -3
    },
    schedule: {
      weekday: {
        10 => :home,
        18 => :leisure,
        0 => :sleep
      },
      weekend: {
        12 => :leisure,
        19 => :home,
        0 => :sleep
      }
    }
  })

  GameData::NPC.register({
    id: "DIVER",
    name: "Finn",
    spouse: "BLACKSMITH",
    birthday: "spring 11",
    fav_gifts: {
      :PEARL => 10,
      :PECHA => 3,
      :HEARTSCALE => 5
    },
    bad_gifts: {
      :TINYMUSHROOM => -4,
      :CASTELIBONE => -3
    },
    schedule: {
      weekday: {
        8 => :work,
        16 => :home,
        22 => :sleep
      },
      weekend: {
        9 => :leisure,
        17 => :home,
        22 => :sleep
      }
    }
  })

  GameData::NPC.register({
    id: "BLACKSMITH",
    name: "Ford",
    spouse: "DIVER",
    birthday: "winter 18",
    fav_gifts: {
      :METALCOAT => 10,
      :IRONBALL => 4,
      :CHARCOAL => 3
    },
    bad_gifts: {
      :TINYMUSHROOM => -2,
      :FLOWERMAIL => -5
    },
    schedule: {
      weekday: {
        6 => :work,
        17 => :home,
        22 => :sleep
      },
      weekend: {
        8 => :work,
        15 => :leisure,
        21 => :sleep
      }
    }
  })

  GameData::NPC.register({
    id: "BIRDKEEPER",
    name: "Quinn",
    spouse: "LIBRARIAN",
    birthday: "spring 28",
    fav_gifts: {
      :SHARPBEAK => 10,
      :WATMELBERRY => 3,
      :PERSIMBERRY => 4
    },
    bad_gifts: {
      :HARDSTONE => -3,
      :TINYMUSHROOM => -2
    },
    schedule: {
      weekday: {
        6 => :work,
        16 => :leisure,
        21 => :home,
        23 => :sleep
      },
      weekend: {
        8 => :leisure,
        17 => :home,
        23 => :sleep
      }
    }
  })

  GameData::NPC.register({
    id: "LIBRARIAN",
    name: "Brooke",
    spouse: "BIRDKEEPER",
    birthday: "autumn 5",
    fav_gifts: {
      :WISEGLASSES => 10,
      :SWEETHEART => 5,
      :LOVEBALL => 4
    },
    bad_gifts: {
      :XATTACK => -4,
      :IRONBALL => -3
    },
    schedule: {
      weekday: {
        9 => :work,
        17 => :home,
        22 => :sleep
      },
      weekend: {
        10 => :leisure,
        18 => :home,
        22 => :sleep
      }
    }
  })

  GameData::NPC.register({
    id: "ADVENTURER",
    name: "Atlas",
    spouse: "BEAUTY",
    birthday: "summer 13",
    fav_gifts: {
      :ESCAPEROPE => 10,
      :QUICKBALL => 5,
      :HARDSTONE => 3
    },
    bad_gifts: {
      :TINYMUSHROOM => -2,
      :BERRYJUICE => -3
    },
    schedule: {
      weekday: {
        7 => :work,
        18 => :home,
        23 => :sleep
      },
      weekend: {
        10 => :leisure,
        16 => :home,
        23 => :sleep
      }
    }
  })

  GameData::NPC.register({
    id: "BEAUTY",
    name: "Mara",
    spouse: "ADVENTURER",
    birthday: "spring 19",
    fav_gifts: {
      :LUXURYBALL => 10,
      :PECHA => 4,
      :POKEDOLL => 5
    },
    bad_gifts: {
      :REVIVE => -5,
      :MIRACLESEED => -3
    },
    schedule: {
      weekday: {
        10 => :work,
        17 => :leisure,
        21 => :home,
        23 => :sleep
      },
      weekend: {
        12 => :leisure,
        18 => :home,
        23 => :sleep
      }
    }
  })

  GameData::NPC.register({
    id: "MUSHROOM",
    name: "Myca",
    spouse: "BUGCATCHER",
    birthday: "autumn 13",
    fav_gifts: {
      :BIGMUSHROOM => 10,
      :SILVERPOWDER => 4,
      :TAMATOBERRY => 3
    },
    bad_gifts: {
      :NUGGET => -4,
      :XACCURACY => -2
    },
    schedule: {
      weekday: {
        6 => :work,
        16 => :leisure,
        20 => :home,
        23 => :sleep
      },
      weekend: {
        9 => :leisure,
        17 => :home,
        23 => :sleep
      }
    }
  })

  GameData::NPC.register({
    id: "BUGCATCHER",
    name: "Reed",
    spouse: "MUSHROOM",
    birthday: "spring 11",
    fav_gifts: {
      :SILVERPOWDER => 10,
      :PECHABERRY => 4,
      :NESTBALL => 3
    },
    bad_gifts: {
      :FIRESTONE => -5,
      :MOOMOOMILK => -2
    },
    schedule: {
      weekday: {
        8 => :work,
        15 => :leisure,
        20 => :home,
        23 => :sleep
      },
      weekend: {
        10 => :leisure,
        17 => :home,
        23 => :sleep
      }
    }
  })

  GameData::NPC.register({
    id: "MIKU",
    name: "Miku",
    spouse: nil,
    birthday: "winter 14",
    fav_gifts: {
      :SWEETHEART => 10,
      :MIRACLESEED => 5,
      :SHUCA => 3
    },
    bad_gifts: {
      :BLACKSLUDGE => -5,
      :TINYMUSHROOM => -2
    },
    schedule: {
      weekday: {
        9 => :work,
        16 => :leisure,
        21 => :home,
        23 => :sleep
      },
      weekend: {
        11 => :leisure,
        18 => :home,
        23 => :sleep
      }
    }
  })

  GameData::NPC.register({
    id: "LAD",
    name: "Drew",
    spouse: nil,
    birthday: "summer 7",
    fav_gifts: {
      :POKEDOLL => 10,
      :RAZZBERRY => 3,
      :LAVACOOKIE => 2
    },
    bad_gifts: {
      :REVIVE => -3,
      :BITTERHERB => -2
    },
    schedule: {
      weekday: {
        7 => :leisure,
        12 => :social,
        17 => :home,
        21 => :sleep
      },
      weekend: {
        8 => :leisure,
        13 => :social,
        18 => :home,
        21 => :sleep
      }
    }
  })

  GameData::NPC.register({
    id: "LASS",
    name: "Piper",
    spouse: nil,
    birthday: "autumn 2",
    fav_gifts: {
      :FASHIONCASE => 10,
      :NANABBERRY => 3,
      :RIBBON => 4
    },
    bad_gifts: {
      :IRONBALL => -4,
      :SOURCANDY => -2
    },
    schedule: {
      weekday: {
        8 => :leisure,
        13 => :social,
        18 => :home,
        21 => :sleep
      },
      weekend: {
        9 => :leisure,
        14 => :social,
        19 => :home,
        21 => :sleep
      }
    }
  })

  GameData::NPC.register({
    id: "PAINTER",
    name: "Andy",
    spouse: "SEAMSTRESS",
    birthday: "spring 25",
    fav_gifts: {
      :REDCARD => 10,
      :YELLOWSHARD => 4,
      :SITRUSBERRY => 2
    },
    bad_gifts: {
      :XDEFENSE => -3,
      :TINYMUSHROOM => -2
    },
    schedule: {
      weekday: {
        9 => :work,
        17 => :leisure,
        21 => :home,
        23 => :sleep
      },
      weekend: {
        10 => :leisure,
        18 => :home,
        23 => :sleep
      }
    }
  })

  GameData::NPC.register({
    id: "SEAMSTRESS",
    name: "Jenny",
    spouse: "PAINTER",
    birthday: "winter 19",
    fav_gifts: {
      :SILKSCARE => 10,
      :PECHABERRY => 3,
      :SWEETHEART => 2
    },
    bad_gifts: {
      :BLACKBELT => -4,
      :METALCOAT => -2
    },
    schedule: {
      weekday: {
        7 => :work,
        16 => :home,
        22 => :sleep
      },
      weekend: {
        9 => :leisure,
        17 => :home,
        22 => :sleep
      }
    }
  })

  GameData::NPC.register({
    id: "SCIENTIST",
    name: "Senku",
    spouse: nil,
    birthday: "spring 18",
    fav_gifts: {
      :METALCOAT => 10,
      :UPGRADE => 5,
      :RAREBONE => 3
    },
    bad_gifts: {
      :TINYMUSHROOM => -4,
      :SWEETHEART => -2
    },
    schedule: {
      weekday: {
        8 => :work,
        18 => :research,
        22 => :home,
        1 => :sleep
      },
      weekend: {
        10 => :work,
        15 => :leisure,
        21 => :home,
        1 => :sleep
      }
    }
  })

  GameData::NPC.register({
    id: "NURSE",
    name: "Joy",
    spouse: nil,
    birthday: "winter 9",
    fav_gifts: {
      :LUMIOSEGALETTE => 10,
      :MOOMOOMILK => 5,
      :PECHABERRY => 3
    },
    bad_gifts: {
      :REVIVALHERB => -4,
      :IRONBALL => -2
    },
    schedule: {
      weekday: {
        6 => :work,
        16 => :home,
        21 => :sleep
      },
      weekend: {
        8 => :leisure,
        14 => :home,
        21 => :sleep
      }
    }
  })


  puts "✅ Starpiece NPCs registered!"
end
