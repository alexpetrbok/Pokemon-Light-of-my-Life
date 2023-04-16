#===============================================================================
# * Encounter Alias - by FL (Credits will be apreciated)
#===============================================================================
#
# This script is for Pokémon Essentials. It allows using an encounter table
# defined in one map in other maps, thus avoiding duplicated data. Useful for 
# multifloor caves/towers.
#
#== INSTALLATION ===============================================================
#
# To this script works, put it above main OR convert into a plugin. Edit HASH
# values below. There are some examples commented.
#
#===============================================================================

if !PluginManager.installed?("Encounter Alias")
  PluginManager.register({                                                 
    :name    => "Encounter Alias",                                        
    :version => "1.0",                                                     
    :link    => "https://www.pokecommunity.com/showthread.php?t=477487",             
    :credits => "FL"
  })
end

module EncounterAlias
  # I suggest using constants with maps ids instead of numbers for better 
  # editing, like I did below. This hash also works putting the numbers 
  # directly.
  ROUTE_4 = 39
  ROUTE_5 = 41
  ROUTE_6 = 44
  ROCK_CAVE_1F = 49
  ROCK_CAVE_B1F = 50

  # map_to_copy_encounter => original_encounter_map
  HASH = {
#    ROCK_CAVE_B1F => ROCK_CAVE_1F,
#    ROUTE_5 => ROUTE_4,
#    ROUTE_6 => ROUTE_4,
  }
end

module GameData
  class Encounter
    class << self
      alias :_old_fl_get :get
      def get(map_id, map_version = 0)
        return _old_fl_get(
          EncounterAlias::HASH.fetch(map_id, map_id), map_version
        )
      end
    end
  end
end