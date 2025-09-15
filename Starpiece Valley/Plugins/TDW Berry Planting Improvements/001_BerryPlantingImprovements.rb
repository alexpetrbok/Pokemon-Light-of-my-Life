#===============================================================================
# BerryPlantData
#===============================================================================
class BerryPlantData
    attr_accessor :event
    attr_accessor :event_base_speed
    attr_accessor :town_map_location
    attr_accessor :town_map_checking
    attr_accessor :mutated_berry_tried
    attr_accessor :mutated_berry_info
    attr_accessor :preferred_weather
    attr_accessor :exposed_to_preferred_weather
    attr_accessor :plant_zone
    attr_accessor :preferred_zone
    attr_accessor :unpreferred_zone
    attr_accessor :weeds
    attr_accessor :weeds_timer
    attr_accessor :pests
    attr_accessor :pests_timer
    attr_accessor :soil
    attr_accessor :preferred_soil
    attr_accessor :withered_item
    attr_accessor :persistent
    attr_accessor :watering_cans_used
    attr_accessor :debug_info
    attr_accessor :seed_id

    alias tdw_berry_plant_init initialize
    def initialize(event = nil)
        tdw_berry_plant_init
        tdw_new_init(event)
    end

    def tdw_new_init(event)
        @event = event || pbMapInterpreter.get_self
        @event_base_speed = @event&.move_speed
        @town_map_location = nil
        @town_map_location = [$~[1].to_i,$~[2].to_i,$~[3].to_i] if @event && @event.name[/map\((\d+),(\d+),(\d+)\)/i]
        @plant_zone = $~[1].to_s if @event && @event.name[/berryzone\((\w+)\)$/i]
        @mutated_berry_tried = false
        @mutated_berry_info = nil
        @exposed_to_preferred_weather = false
        @preferred_zone = nil
        @unpreferred_zone = nil
        @withered_item = nil
        @persistent = nil
        @seed_id = nil
        @watering_cans_used = []
        if Settings::BERRY_USE_WEED_MECHANICS
            @weeds = false
            @weeds_timer = nil
        end
        if Settings::BERRY_USE_PEST_MECHANICS
            @pests = false
            @pests_timer = nil
        end
        if @event && @event.name[/berrysoil\((\w+)\)$/i]
            id = $~[1].to_sym
            if Settings::BERRY_SOIL_DEFINITIONS[id]
                @soil = Settings::BERRY_SOIL_DEFINITIONS[id].clone
                @soil[:id] = id 
            end
        end
        if @soil.nil?
            @soil = Settings::BERRY_SOIL_DEFINITIONS[Settings::BERRY_SOIL_DEFAULT].clone
            @soil[:id] = Settings::BERRY_SOIL_DEFAULT if @soil
        end
        @preferred_soil = nil
        @debug_info = init_debug_info
    end

    def init_debug_info
        return {
            :time_per_stage => nil,
            :drying_per_hour => nil,
            :max_replants => nil,
            :stages_fully_grown => nil,
            :mutation_chance => 0,
            :propagation_chance => 0
        }
    end

    def update
        return update_new if Settings::BERRY_USE_NEW_UPDATE_LOGIC && @event
        return if !planted?
        time_now = pbGetTimeNow
        time_delta = time_now.to_i - @time_last_updated
        return if time_delta <= 0
        new_time_alive = @time_alive + time_delta
        # Get all growth data
        plant_data = GameData::BerryPlant.get(@berry_id)
        time_per_stage = plant_data.hours_per_stage * 3600   # In seconds
        time_per_stage += (Settings::BERRY_PREFERRED_WEATHER_TRAITS[:hours_per_stage] * 3600) if @exposed_to_preferred_weather
        time_per_stage += (Settings::BERRY_PREFERRED_ZONE_TRAITS[:hours_per_stage] * 3600) if @preferred_zone
        time_per_stage += (Settings::BERRY_UNPREFERRED_ZONE_TRAITS[:hours_per_stage] * 3600) if @unpreferred_zone
        time_per_stage += (Settings::BERRY_HAS_WEEDS_TRAITS[:hours_per_stage] * 3600) if Settings::BERRY_USE_WEED_MECHANICS && @event && @weeds
        time_per_stage += (Settings::BERRY_HAS_PESTS_TRAITS[:hours_per_stage] * 3600) if Settings::BERRY_USE_PEST_MECHANICS && @event && @pests
        time_per_stage += (@soil[:hours_per_stage] * 3600) if @soil
        time_per_stage += (Settings::BERRY_PREFERRED_SOIL_TRAITS[:hours_per_stage] * 3600) if @preferred_soil
        time_per_stage += (getWateringCansUsedTraits(:hours_per_stage) * 3600)
        time_per_stage = 3600 if time_per_stage < 3600
        drying_per_hour = plant_data.drying_per_hour
        drying_per_hour += (Settings::BERRY_PREFERRED_WEATHER_TRAITS[:drying_per_hour]) if @exposed_to_preferred_weather
        drying_per_hour += (Settings::BERRY_PREFERRED_ZONE_TRAITS[:drying_per_hour]) if @preferred_zone
        drying_per_hour += (Settings::BERRY_UNPREFERRED_ZONE_TRAITS[:drying_per_hour]) if @unpreferred_zone
        drying_per_hour += Settings::BERRY_HAS_WEEDS_TRAITS[:drying_per_hour] if Settings::BERRY_USE_WEED_MECHANICS && @event && @weeds
        drying_per_hour += Settings::BERRY_HAS_PESTS_TRAITS[:drying_per_hour] if Settings::BERRY_USE_PEST_MECHANICS && @event && @pests
        drying_per_hour += @soil[:drying_per_hour] if @soil
        drying_per_hour += (Settings::BERRY_PREFERRED_SOIL_TRAITS[:drying_per_hour]) if @preferred_soil
        drying_per_hour += getWateringCansUsedTraits(:drying_per_hour)
        drying_per_hour = 0 if drying_per_hour < 0
        max_replants = max_replant_count
        max_replants += (Settings::BERRY_PREFERRED_WEATHER_TRAITS[:max_replants]) if @exposed_to_preferred_weather
        max_replants += (Settings::BERRY_PREFERRED_ZONE_TRAITS[:max_replants]) if @preferred_zone
        max_replants += (Settings::BERRY_UNPREFERRED_ZONE_TRAITS[:max_replants]) if @unpreferred_zone
        max_replants += (Settings::BERRY_PREFERRED_SOIL_TRAITS[:max_replants]) if @preferred_soil
        max_replants = 1 if max_replants < 1
        stages_growing = GameData::BerryPlant::NUMBER_OF_GROWTH_STAGES
        stages_fully_grown = GameData::BerryPlant::NUMBER_OF_FULLY_GROWN_STAGES
        case @mulch_id
        when :GROWTHMULCH
            time_per_stage = (time_per_stage * 0.75).to_i
            drying_per_hour = (drying_per_hour * 1.5).ceil
        when :DAMPMULCH
            time_per_stage = (time_per_stage * 1.25).to_i
            drying_per_hour /= 2
        when :GOOEYMULCH
            max_replants = (max_replants * 1.5).ceil
        when :STABLEMULCH
            stages_fully_grown = (stages_fully_grown * 1.5).ceil
        when :BOOSTMULCH
            drying_per_hour = (drying_per_hour * 2).ceil
        when :AMAZEMULCH
            drying_per_hour = (drying_per_hour * 2).ceil
        end
        # Save debug info
        @debug_info = init_debug_info if !@debug_info
        @debug_info[:time_per_stage] = time_per_stage / 3600
        @debug_info[:drying_per_hour] = drying_per_hour
        @debug_info[:max_replants] = max_replants
        @debug_info[:stages_fully_grown] = stages_fully_grown
        @debug_info[:propagation_chance] = Settings::BERRY_MULCHES_IMPACTING_PROPAGATION[@mulch_id] || Settings::BERRY_BASE_PROPAGATION_CHANCE
        # Do replants
        done_replant = false
        loop do
            stages_this_life = stages_growing + stages_fully_grown - (replanted? ? 1 : 0)
            break if new_time_alive < stages_this_life * time_per_stage
            if @replant_count >= max_replants
                reset_withered
                return
            end
            replant
            done_replant = true
            new_time_alive -= stages_this_life * time_per_stage
        end
        # Weed counts
        if Settings::BERRY_USE_WEED_MECHANICS && @event && @weeds_timer && !@weeds && @growth_stage > 1
            weed_delta = time_now.to_i - @weeds_timer
            time_for_checks = Settings::BERRY_WEED_HOURS_BETWEEN_CHECKS * 3600
            rolls = (weed_delta / time_for_checks).floor
            rolls.times do 
                @weeds = true if rand(100) < getWeedGrowthChance
                @weeds_timer += time_for_checks
                break if @weeds
            end   
        end
        #Pests
        if Settings::BERRY_USE_PEST_MECHANICS && @event && @pests_timer
            if !@pests && @growth_stage > 2
                pests_delta = time_now.to_i - @pests_timer
                time_for_checks = Settings::BERRY_PEST_HOURS_BETWEEN_CHECKS * 3600
                rolls = (pests_delta / time_for_checks).floor
                rolls.times do 
                    @pests = true if rand(100) < getPestAppearChance
                    @pests_timer += time_for_checks
                    break if @pests
                end  
            end
            @event.move_speed = @pests ? 6 : @event_base_speed
            $game_map.events[@event.id].move_speed = @event.move_speed if $game_map.map_id == @event.map_id
        end
        # Update how long plant has been alive for
        old_growth_stage = @growth_stage
        @time_alive = new_time_alive
        @growth_stage = 1 + (@time_alive / time_per_stage)
        @growth_stage += 1 if replanted?   # Replants start at stage 2
        @time_last_updated = time_now.to_i
        @weeds_timer += time_per_stage if Settings::BERRY_USE_WEED_MECHANICS && @event && @weeds_timer && old_growth_stage == 1 && @growth_stage > old_growth_stage
        @pests_timer += time_per_stage*2 if Settings::BERRY_USE_PEST_MECHANICS && @event && @pests_timer && old_growth_stage <= 2 && @growth_stage > old_growth_stage
        # Record watering (old mechanics), and apply drying out per hour (new mechanics)
        if @new_mechanics
            old_growth_hour = (done_replant) ? 0 : (@time_alive - time_delta) / 3600
            new_growth_hour = @time_alive / 3600
            if new_growth_hour > old_growth_hour
                (new_growth_hour - old_growth_hour).times do
                    if @moisture_level > 0 
                        @moisture_level -= drying_per_hour
                    else
                        @yield_penalty += 1
                    end
                end
            end
            water if $game_screen && Settings::BERRY_WATER_IF_RAINING && GameData::Weather.get($game_screen.weather_type).category == :Rain
        else
            old_growth_stage = 0 if done_replant
            new_growth_stage = [@growth_stage, stages_growing + 1].min
            @watered_this_stage = false if new_growth_stage > old_growth_stage
            water if $game_screen && Settings::BERRY_WATER_IF_RAINING && GameData::Weather.get($game_screen.weather_type).category == :Rain
        end
        @exposed_to_preferred_weather = true if pbBerryPreferredWeatherEnabled? && checkPreferredWeather
        return if !planted? || !@event || @mutated_berry_tried || @growth_stage < 2 || !pbAllowBerryMutations?
        checkNearbyPlantsForMutation
    end

    def update_new
        return if !planted?
        time_now = pbGetTimeNow
        time_delta = time_now.to_i - @time_last_updated
        return if time_delta <= 0
        new_time_alive = @time_alive + time_delta
        # Get all growth data
        plant_data = GameData::BerryPlant.get(@berry_id)

        time_per_stage = plant_data.hours_per_stage * 3600   # In seconds
        dynamic_time_per_stage = 0
        time_per_stage += (Settings::BERRY_PREFERRED_WEATHER_TRAITS[:hours_per_stage] * 3600) if @exposed_to_preferred_weather
        time_per_stage += (Settings::BERRY_PREFERRED_ZONE_TRAITS[:hours_per_stage] * 3600) if @preferred_zone
        time_per_stage += (Settings::BERRY_UNPREFERRED_ZONE_TRAITS[:hours_per_stage] * 3600) if @unpreferred_zone
        time_per_stage += (@soil[:hours_per_stage] * 3600) if @soil
        time_per_stage += (Settings::BERRY_PREFERRED_SOIL_TRAITS[:hours_per_stage] * 3600) if @preferred_soil
        time_per_stage += (getWateringCansUsedTraits(:hours_per_stage) * 3600)
        time_per_stage = 3600 if time_per_stage < 3600
        dynamic_time_per_stage += (Settings::BERRY_HAS_WEEDS_TRAITS[:hours_per_stage] * 3600) if Settings::BERRY_USE_WEED_MECHANICS && @event && @weeds
        dynamic_time_per_stage += (Settings::BERRY_HAS_PESTS_TRAITS[:hours_per_stage] * 3600) if Settings::BERRY_USE_PEST_MECHANICS && @event && @pests

        drying_per_hour = plant_data.drying_per_hour
        dynamic_drying_per_hour = 0
        drying_per_hour += (Settings::BERRY_PREFERRED_WEATHER_TRAITS[:drying_per_hour]) if @exposed_to_preferred_weather
        drying_per_hour += (Settings::BERRY_PREFERRED_ZONE_TRAITS[:drying_per_hour]) if @preferred_zone
        drying_per_hour += (Settings::BERRY_UNPREFERRED_ZONE_TRAITS[:drying_per_hour]) if @unpreferred_zone
        drying_per_hour += @soil[:drying_per_hour] if @soil
        drying_per_hour += (Settings::BERRY_PREFERRED_SOIL_TRAITS[:drying_per_hour]) if @preferred_soil
        drying_per_hour += getWateringCansUsedTraits(:drying_per_hour)
        drying_per_hour = 0 if drying_per_hour < 0
        dynamic_drying_per_hour += Settings::BERRY_HAS_WEEDS_TRAITS[:drying_per_hour] if Settings::BERRY_USE_WEED_MECHANICS && @event && @weeds
        dynamic_drying_per_hour += Settings::BERRY_HAS_PESTS_TRAITS[:drying_per_hour] if Settings::BERRY_USE_PEST_MECHANICS && @event && @pests

        max_replants = max_replant_count
        max_replants += (Settings::BERRY_PREFERRED_WEATHER_TRAITS[:max_replants]) if @exposed_to_preferred_weather
        max_replants += (Settings::BERRY_PREFERRED_ZONE_TRAITS[:max_replants]) if @preferred_zone
        max_replants += (Settings::BERRY_UNPREFERRED_ZONE_TRAITS[:max_replants]) if @unpreferred_zone
        max_replants += (Settings::BERRY_PREFERRED_SOIL_TRAITS[:max_replants]) if @preferred_soil
        max_replants = 1 if max_replants < 1
        
        stages_growing = GameData::BerryPlant::NUMBER_OF_GROWTH_STAGES
        stages_fully_grown = GameData::BerryPlant::NUMBER_OF_FULLY_GROWN_STAGES
        case @mulch_id
        when :GROWTHMULCH
            time_per_stage = (time_per_stage * 0.75).to_i
            drying_per_hour = (drying_per_hour * 1.5).ceil
            dynamic_time_per_stage = (time_per_stage * 0.75).to_i
            dynamic_drying_per_hour = (drying_per_hour * 1.5).ceil
        when :DAMPMULCH
            time_per_stage = (time_per_stage * 1.25).to_i
            drying_per_hour /= 2
            dynamic_time_per_stage = (time_per_stage * 1.25).to_i
            dynamic_drying_per_hour /= 2
        when :GOOEYMULCH
            max_replants = (max_replants * 1.5).ceil
        when :STABLEMULCH
            stages_fully_grown = (stages_fully_grown * 1.5).ceil
        when :BOOSTMULCH
            drying_per_hour = (drying_per_hour * 2).ceil
        when :AMAZEMULCH
            drying_per_hour = (drying_per_hour * 2).ceil
        end
        # Save debug info
        @debug_info = init_debug_info if !@debug_info
        @debug_info[:time_per_stage] = time_per_stage / 3600
        @debug_info[:drying_per_hour] = drying_per_hour
        @debug_info[:max_replants] = max_replants
        @debug_info[:stages_fully_grown] = stages_fully_grown
        @debug_info[:propagation_chance] = Settings::BERRY_MULCHES_IMPACTING_PROPAGATION[@mulch_id] || Settings::BERRY_BASE_PROPAGATION_CHANCE
        # Weed counts
        if Settings::BERRY_USE_WEED_MECHANICS && @event && @weeds_timer && !@weeds && @growth_stage > 1
            weed_delta = time_now.to_i - @weeds_timer
            time_for_checks = Settings::BERRY_WEED_HOURS_BETWEEN_CHECKS * 3600
            rolls = (weed_delta / time_for_checks).floor
            rolls.times do 
                @weeds = true if rand(100) < getWeedGrowthChance
                @weeds_timer += time_for_checks
                break if @weeds
            end   
        end
        #Pests
        if Settings::BERRY_USE_PEST_MECHANICS && @event && @pests_timer 
            if !@pests && @growth_stage > 2
                pests_delta = time_now.to_i - @pests_timer
                time_for_checks = Settings::BERRY_PEST_HOURS_BETWEEN_CHECKS * 3600
                rolls = (pests_delta / time_for_checks).floor
                rolls.times do 
                    @pests = true if rand(100) < getPestAppearChance
                    @pests_timer += time_for_checks
                    break if @pests
                end  
            end
            @event.move_speed = @pests ? 6 : @event_base_speed
            $game_map.events[@event.id].move_speed = @event.move_speed if $game_map.map_id == @event.map_id
        end

        # Update how long plant has been alive for
        old_growth_stage = @growth_stage
        old_time_alive = @time_alive
        countdown = time_delta
        @time_in_stage += time_delta
        total_time_per_stage = [(time_per_stage + dynamic_time_per_stage), 3600].max
        done_replant = false
        loop do
            tps = (@growth_stage > 4) ? time_per_stage : total_time_per_stage
            countdown -= tps
            break if @time_in_stage < tps
            @time_in_stage -= tps
            @growth_stage += 1
            if @growth_stage > stages_growing + stages_fully_grown
                if @replant_count >= max_replants
                    reset_withered
                    return
                end
                replant
                done_replant = true
                new_time_alive = countdown
            end
            @weeds_timer += tps if Settings::BERRY_USE_WEED_MECHANICS && @event && @weeds_timer && @growth_stage == 2
            @pests_timer += tps*2 if Settings::BERRY_USE_PEST_MECHANICS && @event && @pests_timer && @growth_stage == 3
        end
        @time_alive = new_time_alive
        @time_last_updated = time_now.to_i

        # Record watering (old mechanics), and apply drying out per hour (new mechanics)
        if @new_mechanics
            old_growth_hour = (done_replant) ? 0 : (@time_alive - time_delta) / 3600
            new_growth_hour = @time_alive / 3600
            if new_growth_hour > old_growth_hour
                (new_growth_hour - old_growth_hour).times do
                    if @moisture_level > 0
                        @moisture_level -= drying_per_hour
                    else
                        @yield_penalty += 1
                    end
                end
            end
            water if $game_screen && Settings::BERRY_WATER_IF_RAINING && GameData::Weather.get($game_screen.weather_type).category == :Rain
        else
            old_growth_stage = 0 if done_replant
            new_growth_stage = [@growth_stage, stages_growing + 1].min
            @watered_this_stage = false if new_growth_stage > old_growth_stage
            water if $game_screen && Settings::BERRY_WATER_IF_RAINING && GameData::Weather.get($game_screen.weather_type).category == :Rain
        end
        @exposed_to_preferred_weather = true if pbBerryPreferredWeatherEnabled? && checkPreferredWeather
        return if !planted? || !@event || @mutated_berry_tried || @growth_stage < 2 || !pbAllowBerryMutations?
        checkNearbyPlantsForMutation
    end


    alias tdw_berry_plant_plant plant
    def plant(berry_id, seed_id = nil)
        tdw_berry_plant_plant(berry_id)
        @seed_id = seed_id
        @withered_item = nil
        
        # Pre-fetch once
        bd = (@berry_id && @event) ? TDW_BerrySafe.berry_data(@berry_id) : nil

        # Preferred weather -> always an Array (possibly empty)
        @preferred_weather = (pbBerryPreferredWeatherEnabled? && bd) ? TDW_BerrySafe.list(bd, :preferred_weather) : []

        # Preferred / Unpreferred zone flags -> always booleans, safe if @plant_zone is nil
        if pbBerryPreferredZonesEnabled? && bd
        @preferred_zone = TDW_BerrySafe.includes?(bd, :preferred_zones, @plant_zone)
        else
        @preferred_zone = false
        end

        if pbBerryUnpreferredZonesEnabled? && bd && !@preferred_zone
        @unpreferred_zone = TDW_BerrySafe.includes?(bd, :unpreferred_zones, @plant_zone)
        else
        @unpreferred_zone = false
        end

        # Preferred soil (boolean) -> safe if @soil or BerryData is missing
        if pbBerryPreferredSoilEnabled? && bd && @soil && @soil[:id]
        @preferred_soil = TDW_BerrySafe.equals?(bd, :preferred_soil, @soil[:id])
        else
        @preferred_soil = false
        end
        #@preferred_weather = (@berry_id && @event && pbBerryPreferredWeatherEnabled? ) ? tdw_safe_preferred_weather_for(@berry_id) : []
        #@preferred_zone = @berry_id && @event && pbBerryPreferredZonesEnabled? && GameData::BerryData.try_get(@berry_id).preferred_zones.include?(@plant_zone)
        #@unpreferred_zone = @berry_id && @event && pbBerryUnpreferredZonesEnabled? && !@preferred_zone && 
        #        GameData::BerryData.try_get(@berry_id).unpreferred_zones.include?(@plant_zone)
        #@preferred_soil = @berry_id && @event && @soil && pbBerryPreferredSoilEnabled? && 
        #        GameData::BerryData.try_get(@berry_id).preferred_soil == @soil[:id]
        
        
        @time_in_stage = 0
        @watering_cans_used = []
        if Settings::BERRY_USE_WEED_MECHANICS
            @weeds = false
            @weeds_timer = pbGetTimeNow.to_i
        end
        if Settings::BERRY_USE_PEST_MECHANICS
            @pests = false
            @pests_timer = pbGetTimeNow.to_i
        end
    end

    alias tdw_berry_plant_reset reset
    def reset(planting = false)
        if !planting && persistent && @growth_stage && @growth_stage > 1
            persistent_replant
            persistent = nil
            return 
        end
        tdw_berry_plant_reset(planting)
        @exposed_to_preferred_weather = false
        @mutated_berry_tried = false
        @mutated_berry_info = nil
        @preferred_zone = nil
        @unpreferred_zone = nil
        @preferred_soil = nil
        @seed_id = nil
        @time_in_stage = 0
        @watering_cans_used = []
        if Settings::BERRY_USE_WEED_MECHANICS
            @weeds = false
            @weeds_timer = nil
        end
        if Settings::BERRY_USE_PEST_MECHANICS
            @pests = false
            @pests_timer = nil
        end
        @debug_info = init_debug_info
    end

    def reset_withered
        item_list = Settings::BERRY_WITHERED_ITEMS
        if item_list.length > 0
            item_list.sort! { |a, b| b[0] <=> a[0] }
            r = rand(100)
            item_list.each do |item|
                r -= item[0]
                next if r >= 0
                itm = item[1]
                itm = @berry_id if itm == :DropParentBerry
                @withered_item = itm
                break
            end
        end
        reset
    end

    alias tdw_berry_plant_replant replant
    def replant
        propagate if pbAllowBerryPropagation?
        tdw_berry_plant_replant
        @exposed_to_preferred_weather = false
        @watering_cans_used = []
        @seed_id = nil
        if Settings::BERRY_REPLANT_RESETS_MUTATION
            @mutated_berry_tried = false
            @mutated_berry_info = nil
        end
        if Settings::BERRY_USE_PEST_MECHANICS 
            @pests = false
            @pests_timer = pbGetTimeNow.to_i
        end
    end

    def persistent_replant
        @time_alive         = 0
        @growth_stage       = Settings::BERRY_PERSISTENT_REPLANT_STAGE
        @replant_count      += 1 if Settings::BERRY_PERSISTENT_COUNTS_AS_REPLANT
        @watered_this_stage = false
        @watering_count     = 0
        @moisture_level     = 100
        @yield_penalty      = 0
        @watering_cans_used = []
        @exposed_to_preferred_weather = false
        if Settings::BERRY_REPLANT_RESETS_MUTATION
            @mutated_berry_tried = false
            @mutated_berry_info = nil
        end
        if Settings::BERRY_USE_PEST_MECHANICS 
            @pests = false
            @pests_timer = pbGetTimeNow.to_i
        end
    end

    alias tdw_berry_plant_water water
    def water(used_can = nil)
        return if @town_map_checking
        if Settings::BERRY_SHOW_WATERING_ANIMATION && used_can
            $game_player.set_watering_charset(used_can)
        end
        @watering_cans_used.push(used_can) if used_can && Settings::BERRY_WATERING_CAN_TRAITS[used_can] && !@watering_cans_used.include?(used_can)
        tdw_berry_plant_water
    end

    alias tdw_berry_plant_berry_yield berry_yield
    def berry_yield
        ret = tdw_berry_plant_berry_yield
        ret += 2 if [:RICHMULCH, :AMAZEMULCH].include?(@mulch_id)
        ret += Settings::BERRY_PREFERRED_WEATHER_TRAITS[:yield] if @exposed_to_preferred_weather
        ret += Settings::BERRY_PREFERRED_ZONE_TRAITS[:yield] if @preferred_zone
        ret += Settings::BERRY_UNPREFERRED_ZONE_TRAITS[:yield] if @unpreferred_zone
        if @soil
            if @soil[:yield].is_a?(Array)
                arr = @soil[:yield]
                ret += rand(arr[0]..arr[1])
            else
                ret += @soil[:yield] 
            end
            ret += Settings::BERRY_PREFERRED_SOIL_TRAITS[:yield] if @preferred_soil
        end
        ret += getWateringCansUsedTraits(:yield)
        return ret
    end

    def max_replant_count
        ret = GameData::BerryPlant::NUMBER_OF_REPLANTS
        ret += @soil[:max_replants] if @soil
        return ret
    end

    def propagate
        return if !@event
        propagation = []
        berry = @berry_id
        qty = berry_yield
        qty.times { propagation.push(berry) }
        if @mutation_info
            mut_berry = @mutation_info[0] 
            mut_berry_qty = @mutation_info[1]
            mut_berry_qty -= 1 while qty - mut_berry_qty < 1
            mut_berry_qty.times { propagation.push(mut_berry) }
        end
        checkNearbyPlantsForPropagation(propagation)
    end

    def pullWeeds
        @weeds = false
        @weeds_timer = pbGetTimeNow.to_i
        $stats.berry_weeds_pulled ||= 0
        $stats.berry_weeds_pulled += 1
    end

    def pbGetNeighbors(position_array = nil, map = nil)
        position = position_array || [@event.map_id, @event.x, @event.y]
        map = map || $map_factory.getMap(position[0])
        neighbors = []
        neighbors[0] = $PokemonGlobal.eventvars[[position[0],map.check_event(position[1], position[2]-1)]]
        neighbors[1] = $PokemonGlobal.eventvars[[position[0],map.check_event(position[1]+1, position[2])]]
        neighbors[2] = $PokemonGlobal.eventvars[[position[0],map.check_event(position[1], position[2]+1)]]
        neighbors[3] = $PokemonGlobal.eventvars[[position[0],map.check_event(position[1]-1, position[2])]]
        return neighbors
    end

    def checkNearbyPlantsForMutation
        $PokemonGlobal.compilePlantMutationParents if !$PokemonGlobal.berry_plant_mutation_parents
        @mutated_berry_tried = true
        return if !@event || !$PokemonGlobal.berry_plant_mutation_parents.include?(@berry_id)
        mutation_chance = Settings::BERRY_MULCHES_IMPACTING_MUTATIONS[@mulch_id] || Settings::BERRY_BASE_MUTATION_CHANCE
        mutation_chance += Settings::BERRY_PREFERRED_WEATHER_TRAITS[:mutation_chance] if @exposed_to_preferred_weather
        mutation_chance += Settings::BERRY_PREFERRED_ZONE_TRAITS[:mutation_chance] if @preferred_zone
        mutation_chance += Settings::BERRY_UNPREFERRED_ZONE_TRAITS[:mutation_chance] if @unpreferred_zone
        mutation_chance += @soil[:mutation_chance] if @soil
        mutation_chance += Settings::BERRY_PREFERRED_SOIL_TRAITS[:mutation_chance] if @preferred_soil
        mutation_chance += Settings::BERRY_HAS_WEEDS_TRAITS[:mutation_chance] if Settings::BERRY_USE_WEED_MECHANICS && @event && @weeds
        mutation_chance += Settings::BERRY_HAS_PESTS_TRAITS[:mutation_chance] if Settings::BERRY_USE_PEST_MECHANICS && @event && @pests
        mutation_chance += getWateringCansUsedTraits(:mutation_chance)
        @debug_info = init_debug_info if !@debug_info
        @debug_info[:mutation_chance] = mutation_chance
        return if mutation_chance <= 0 || rand(100) >= mutation_chance
        #position = [@event.map_id, @event.x, @event.y]
        #map = $map_factory.getMap(position[0])
        neighbors = pbGetNeighbors
        possible = []
        neighbors.each do |data|
            next if data.nil? || !data.is_a?(BerryPlantData) || !data.planted?
            id = data.berry_id
            if Settings::BERRY_MUTATION_POSSIBILITIES[[@berry_id,id]]
                possible.concat(Settings::BERRY_MUTATION_POSSIBILITIES[[@berry_id,id]])
            elsif Settings::BERRY_MUTATION_POSSIBILITIES[[id,@berry_id]]
                possible.concat(Settings::BERRY_MUTATION_POSSIBILITIES[[id,@berry_id]])
            end
        end
        @mutated_berry_info = [possible.sample,Settings::BERRY_MUTATION_COUNT] if possible.length > 0
    end

    def checkNearbyPlantsForPropagation(dropped_berries)
        return if dropped_berries.nil? || dropped_berries.empty?
        neighbors = pbGetNeighbors
        neighbors.each do |data|
            next if data.nil? || !data.is_a?(BerryPlantData) || data.planted?
            mulch_id = data.mulch_id
            propagation_chance = Settings::BERRY_MULCHES_IMPACTING_PROPAGATION[mulch_id] || Settings::BERRY_BASE_PROPAGATION_CHANCE
            next if propagation_chance <= 0 || rand(1000) >= propagation_chance
            data.plant(dropped_berries.sample)
            $stats.berries_propagated ||= 0
            $stats.berries_propagated += 1
        end
    end

    def checkPreferredWeather
        return true  if @exposed_to_preferred_weather
        return false if !@preferred_weather || @preferred_weather.empty?
        return false if @growth_stage <= 1 || @growth_stage >= 5
        wt = ($game_screen) ? $game_screen.weather_type : nil
        return (!!wt && @preferred_weather.include?(wt))
    end


    def getWeedGrowthChance
        return 0 unless Settings::BERRY_USE_WEED_MECHANICS
        weeds_chance = Settings::BERRY_MULCHES_IMPACTING_WEEDS[@mulch_id] || Settings::BERRY_WEED_GROWTH_CHANCE
        weeds_chance += @soil[:weed_chance] if @soil
        weeds_chance += getWateringCansUsedTraits(:weed_chance) if @event
        return weeds_chance
    end

    def getPestAppearChance
        return 0 unless Settings::BERRY_USE_PEST_MECHANICS
        pests_chance =  Settings::BERRY_MULCHES_IMPACTING_PESTS[@mulch_id] || Settings::BERRY_PEST_APPEAR_CHANCE
        pests_chance += Settings::BERRY_HAS_WEEDS_TRAITS[:pest_chance] if Settings::BERRY_USE_WEED_MECHANICS && @event && @weeds
        pests_chance += @soil[:pest_chance] if @soil
        pests_chance += getWateringCansUsedTraits(:pest_chance) if @event
        pests_chance -= 20 if $game_switches[72]
        pests_chance = 0 if @plant_zone.to_s.downcase == "greenhouse"
        return pests_chance
    end

    def getWateringCansUsedTraits(trait_sym)
        return 0 if !@watering_cans_used || @watering_cans_used.empty?
        ret = 0
        @watering_cans_used.each do |can|
            next if !Settings::BERRY_WATERING_CAN_TRAITS[can]
            traits = Settings::BERRY_WATERING_CAN_TRAIT_DEFINITIONS[Settings::BERRY_WATERING_CAN_TRAITS[can]]
            next if !traits
            ret += traits[trait_sym] || 0
        end
        return ret
    end

end

def pbInitializeAllBerryPlants(zone: nil, soil: nil, reset: false)
  initialized = 0
  $game_map.events.each_value do |event|
    next unless event.name.downcase.include?("berryplant")
    key = [$game_map.map_id, event.id]
    
    berry_plant = $PokemonGlobal.eventvars[key]

    # Rename to include map location
    #event.name = sprintf("BerryPlant map(0,%d,%d)", event.x, event.y)
    berry_plant = BerryPlantData.new(event)
    $PokemonGlobal.eventvars[key] = berry_plant
    initialized += 1
    
    if reset
      berry_plant.reset(true)
    end

    # Apply zone/soil tags if requested
    berry_plant.plant_zone = zone if zone
    #berry_plant.soil_type = soil if soil

    # Recalculate town map location in case it wasn't set
    region_id = 0
    berry_plant.town_map_location = [region_id, event.x, event.y]
  end

  #puts(_INTL("Initialized {1} berry plants!", initialized)) if initialized > 0
end


#===============================================================================
# GameStats
#===============================================================================

class GameStats
    attr_accessor :mutated_berries_picked
    attr_accessor :berries_propagated
    attr_accessor :berry_weeds_pulled
    attr_accessor :berry_pest_battles
    attr_accessor :berries_auto_planted

    alias tdw_berry_improvements_stats_init initialize
    def initialize
        tdw_berry_improvements_stats_init
        @mutated_berries_picked = 0
        @berries_propagated = 0
        @berry_weeds_pulled = 0
        @berry_pest_battles = 0
        @berries_auto_planted = 0
    end
end

#===============================================================================
# BerryPlant Overwrite
#===============================================================================
# Streamlined, energy-aware, quiet interaction.
# Call from a BerryPlant event:  Script: pbBerrySpotQuickMenu

# Short label matching the default flow vibe
def pbBerryStageLabel(plant)
  return _INTL("Empty Soil") unless plant && plant.planted?
  return _INTL("ready to Harvest") if plant.respond_to?(:grown?) && plant.grown?
  stg = (plant.instance_variable_defined?(:@growth_stage) ? plant.instance_variable_get(:@growth_stage).to_i : 1)
  case stg
  when 1 then _INTL("Planted")
  when 2 then _INTL("Sprouted")
  when 3 then _INTL("Growing")
  else        _INTL("Blooming")
  end
end

def pbBerrySpotQuickMenu(ev = nil, quiet = true)
  ev ||= pbMapInterpreter.get_self
  return if !ev

  data = $PokemonGlobal.eventvars[[$game_map.map_id, ev.id]]
  unless data.is_a?(BerryPlantData)
    data = BerryPlantData.new(ev)
    $PokemonGlobal.eventvars[[$game_map.map_id, ev.id]] = data
  end

  # --- Pests auto-attack immediately unless too tired ---
  pests = (data.instance_variable_defined?(:@pests) ? data.instance_variable_get(:@pests) : false)
  if pests
    if $player_energy && $player_energy.modify_energy(ENERGY_PESTS)
      if defined?(pbStartBerryPlantPestBattle)
        pbStartBerryPlantPestBattle(data)
      else
        data.instance_variable_set(:@pests, false)
        data.instance_variable_set(:@pests_timer, pbGetTimeNow.to_i)
      end
      return
    else
      pbMessage(_INTL("Pests are eating your berries, but you're too tired to do anything..."))
      return
    end
  end

  planted   = data.planted?
  grown     = (planted && data.respond_to?(:grown?) ? data.grown? : false)
  weeds     = (data.instance_variable_defined?(:@weeds) ? data.instance_variable_get(:@weeds) : false)
  moisture  = (data.instance_variable_defined?(:@moisture_level) ? (data.instance_variable_get(:@moisture_level) || 0) : 0)
  dry_enough_to_water = (planted && moisture <= 70)   # tweak threshold to taste

  # --- Stage-based facing like the default handler ---
  if planted
    if grown
      ev.turn_up
    else
      stg = (data.instance_variable_defined?(:@growth_stage) ? data.instance_variable_get(:@growth_stage).to_i : 1)
      case stg
        when 1; ev.turn_down
        when 2; ev.turn_down
        when 3; ev.turn_left
        else   ev.turn_right
      end
    end
  end

  # Header (berry name + default-style stage label)
  berry_id   = (planted ? data.berry_id : nil)
  berry_name = (berry_id ? GameData::Item.get(berry_id).name : _INTL("Empty Soil"))
  header_txt = planted ? _INTL("The {1} is {2}", berry_name, pbBerryStageLabel(data)) : _INTL("Empty Soil")

  # Build options
  entries = []
  if planted
    entries << [_INTL("Harvest"),    :harvest]      if grown
    entries << [_INTL("Upkeep"),   :maintain]       if (dry_enough_to_water && weeds) 
    entries << [_INTL("Water"),      :water]        if dry_enough_to_water
    entries << [_INTL("Pull weeds"), :weeds]        if weeds
    can_dig = planted && !grown && (data.instance_variable_defined?(:@growth_stage) ? data.instance_variable_get(:@growth_stage).to_i : 1) <= 1
    entries << [_INTL("Dig up"),       :dig]        if can_dig
  else
    entries << [_INTL("Plant"),      :plant]
  end
  entries << [_INTL("Mulch"),        :mulch]
  
  entries << [_INTL("Leave"),        :leave]        # keep last

  idx = pbMessage(header_txt, entries.map { |e| e[0] }, -1)
  return if idx < 0
  action = entries[idx][1]

  case action
  when :leave
    return

  when :maintain
    # Order: Weeds -> Water -> Harvest
    if weeds
      unless $player_energy && $player_energy.modify_energy(ENERGY_WEEDS)
        pbMessage(_INTL("You're too tired to pull weeds.")); return
      end
      data.pullWeeds if data.respond_to?(:pullWeeds)
      weeds = false
    end
    if dry_enough_to_water
      unless $player_energy && $player_energy.modify_energy(ENERGY_WATER)
        pbMessage(_INTL("You're too tired to water.")); return
      end
      if quiet
        data.water
      else
        if defined?(pbBerryPlantWater)
          pbBerryPlantWater(data)
        else
          data.water
        end
      end
    end

  when :water
    if $player_energy && $player_energy.modify_energy(ENERGY_WATER)
      if quiet
        data.water
      else
        if defined?(pbBerryPlantWater)
          pbBerryPlantWater(data)
        else
          data.water
        end
      end
    else
      pbMessage(_INTL("You're too tired to water."))
    end
    return

  when :weeds
    if $player_energy && $player_energy.modify_energy(ENERGY_WEEDS)
      data.pullWeeds if data.respond_to?(:pullWeeds)
    else
      pbMessage(_INTL("You're too tired to pull weeds."))
    end
    return

  when :harvest
    if grown && $player_energy && $player_energy.modify_energy(ENERGY_HARVEST)
      if quiet
        qty = data.berry_yield
        bid = data.berry_id
        $bag.add(bid, qty)
        pbShowItemDisplay(bid, qty) rescue nil
        data.reset
      else
        if pbPickBerry(berry_id, data.berry_yield)
          data.reset
        end
      end
    else
      pbMessage(_INTL("You're too tired to harvest.")) unless grown
    end
    return

  when :mulch
    unless $player_energy && $player_energy.modify_energy(ENERGY_MULCH)
      pbMessage(_INTL("You're too tired to spread mulch.")); return
    end
    mulch = nil
    pbFadeOutIn do
      scene  = PokemonBag_Scene.new
      screen = PokemonBagScreen.new(scene, $bag)
      mulch  = screen.pbChooseItemScreen(proc { |item| GameData::Item.get(item).is_mulch? })
    end
    if mulch
      md = GameData::Item.get(mulch)
      if md.is_mulch?
        data.mulch_id = mulch
        $bag.remove(mulch)
        pbMessage(_INTL("The {1} was scattered on the soil.", md.name)) unless quiet
      else
        pbMessage(_INTL("That won't fertilize the soil!")) unless quiet
      end
    end
    return

  when :plant
    # Empty soil → choose a berry or seed based on settings
    unless $player_energy && $player_energy.modify_energy(ENERGY_PLANT)
      pbMessage(_INTL("You're too tired to plant.")); return
    end
    berry = nil
    seed  = nil
    planted_item = nil
    pbFadeOutIn do
      scene  = PokemonBag_Scene.new
      screen = PokemonBagScreen.new(scene, $bag)
      if Settings::BERRY_USE_BERRY_SEEDS
        seed = screen.pbChooseItemScreen(proc { |it| GameData::Item.get(it).is_berry_seed? && GameData::Item.get(it).can_plant? })
        if seed
          if Settings::BERRY_MYSTERY_SEED_POOLS[seed]
            pool = Settings::BERRY_MYSTERY_SEED_POOLS[seed]
            pool.sort! { |a, b| b[1] <=> a[1] }
            total = 0; pool.each { |a| total += a[1] }
            rnd = rand(total)
            pool.each do |b|
              rnd -= b[1]
              next if rnd >= 0
              berry = b[0]; break
            end
          elsif seed.to_s.include?("_SEED")
            berry = seed.to_s.sub("_SEED","").to_sym
          end
          planted_item = seed
        end
      else
        berry = screen.pbChooseItemScreen(proc { |it| GameData::Item.get(it).is_berry? && GameData::Item.get(it).can_plant? })
        planted_item = berry
      end
    end
    if berry
      $stats.berries_planted += 1 rescue nil
      data.plant(berry, seed)
      if Settings::BERRY_USE_BERRY_SEEDS && seed
        $bag.remove(seed)
      else
        $bag.remove(berry)
      end
      unless quiet
        soil_desc = (data.soil ? data.soil[:planting_description] : _INTL("soft, earthy"))
        pbMessage(_INTL("The {1} was planted in the {2} soil.", GameData::Item.get(planted_item).name, soil_desc))
      end
    end
    return

  when :dig
    if planted && (data.instance_variable_defined?(:@growth_stage) ? data.instance_variable_get(:@growth_stage).to_i : 1) <= 1
      if ($player_energy && $player_energy.modify_energy(ENERGY_DIGBERRY))
        bid = data.berry_id
        data.reset(true)
        $bag.add(bid, 1)
        pbShowItemDisplay(bid, 1) rescue nil
      else
        pbMessage(_INTL("You're too tired to dig."))
      end
    else
      pbMessage(_INTL("It’s too established to dig up now."))
    end
    return
  end
end






def pbBerryPlantOrig
    interp = pbMapInterpreter
    this_event = interp.get_self
    berry_plant = interp.getVariable
    if !berry_plant
        berry_plant = BerryPlantData.new
        interp.setVariable(berry_plant)
    end
    berry = berry_plant.berry_id
    planted_item = berry_plant.seed_id ? berry_plant.seed_id : berry
    # Interact with the event based on its growth
    if berry_plant.grown?
        this_event.turn_up   # Stop the event turning towards the player
        berry_yield = berry_plant.berry_yield
        if pbPickBerry(berry, berry_yield)
            berry_plant.reset
            pbDropBerrySeeds(berry, berry_yield)
        end
        return
    elsif berry_plant.growing?
        berry_name = GameData::Item.get(berry).name
        case berry_plant.growth_stage
        when 1   # X planted
            this_event.turn_down   # Stop the event turning towards the player
            planted_item_name = GameData::Item.get(planted_item).name
            if berry_name.starts_with_vowel?
                pbMessage(_INTL("An {1} was planted here.", planted_item_name))
            else
                pbMessage(_INTL("A {1} was planted here.", planted_item_name))
            end
        when 2   # X sprouted
            this_event.turn_down   # Stop the event turning towards the player
            pbMessage(_INTL("The {1} has sprouted.", berry_name))
        when 3   # X taller
            this_event.turn_left   # Stop the event turning towards the player
            pbMessage(_INTL("The {1} plant is growing bigger.", berry_name))
        else     # X flowering
            this_event.turn_right   # Stop the event turning towards the player
            if Settings::NEW_BERRY_PLANTS
                pbMessage(_INTL("This {1} plant is in bloom!", berry_name))
            else
                case berry_plant.watering_count
                when 4
                    pbMessage(_INTL("This {1} plant is in fabulous bloom!", berry_name))
                when 3
                    pbMessage(_INTL("This {1} plant is blooming very beautifully!", berry_name))
                when 2
                    pbMessage(_INTL("This {1} plant is blooming prettily!", berry_name))
                when 1
                    pbMessage(_INTL("This {1} plant is blooming cutely!", berry_name))
                else
                    pbMessage(_INTL("This {1} plant is in bloom!", berry_name))
                end
            end
        end
        # Water the growing plant
        pbBerryPlantWater(berry_plant)
        return
    end
    # Nothing planted yet
    ask_to_plant = true
    if Settings::NEW_BERRY_PLANTS
        # New mechanics
        if berry_plant.mulch_id
            pbMessage(_INTL("{1} has been laid down.", GameData::Item.get(berry_plant.mulch_id).name))
        else
            case pbMessage(_INTL("It's {1} soil.", (berry_plant.soil ? berry_plant.soil[:planting_description] : _INTL("soft, earthy"))),
                       [_INTL("Fertilize"), _INTL("Plant #{(Settings::BERRY_USE_BERRY_SEEDS ? "Berry Seed" : "Berry")}"), _INTL("Exit")], -1)
            when 0   # Fertilize
                mulch = nil
                pbFadeOutIn do
                    scene = PokemonBag_Scene.new
                    screen = PokemonBagScreen.new(scene, $bag)
                    mulch = screen.pbChooseItemScreen(proc { |item| GameData::Item.get(item).is_mulch? })
                end
                return if !mulch
                mulch_data = GameData::Item.get(mulch)
                if mulch_data.is_mulch?
                    berry_plant.mulch_id = mulch
                    $bag.remove(mulch)
                    pbMessage(_INTL("The {1} was scattered on the soil.", mulch_data.name))
                else
                    pbMessage(_INTL("That won't fertilize the soil!"))
                    return
                end
            when 1   # Plant Berry
                ask_to_plant = false
            else   # Exit/cancel
                return
            end
        end
    else
        # Old mechanics
        return if !pbConfirmMessage(_INTL("It's {1} soil. Want to plant a #{(Settings::BERRY_USE_BERRY_SEEDS ? "berry seed" : "berry")}?", (berry_plant.soil ? berry_plant.soil[:planting_description] : _INTL("soft, loamy"))))
        ask_to_plant = false
    end
    if !ask_to_plant || pbConfirmMessage(_INTL("Want to plant a #{(Settings::BERRY_USE_BERRY_SEEDS ? "Berry Seed" : "Berry")}?"))
        seed = nil
        planted_item = nil
        pbFadeOutIn do
            scene = PokemonBag_Scene.new
            screen = PokemonBagScreen.new(scene, $bag)
            if Settings::BERRY_USE_BERRY_SEEDS
                seed = screen.pbChooseItemScreen(proc { |item| GameData::Item.get(item).is_berry_seed? && GameData::Item.get(item).can_plant? })
                if seed
                    if Settings::BERRY_MYSTERY_SEED_POOLS[seed]
                        pool = Settings::BERRY_MYSTERY_SEED_POOLS[seed]
                        pool.sort! { |a, b| b[1] <=> a[1] }
                        chance_total = 0
                        pool.each { |a| chance_total += a[1] }
                        rnd = rand(chance_total)
                        pool.each do |b|
                            rnd -= b[1]
                            next if rnd >= 0
                            berry = b[0]
                            planted_item = seed
                            break
                        end
                    elsif seed.to_s.include?("_SEED")
                        berry = seed.to_s.sub("_SEED", "").to_sym 
                        planted_item = seed
                    end
                end
            else
                berry = screen.pbChooseItemScreen(proc { |item| GameData::Item.get(item).is_berry? && GameData::Item.get(item).can_plant? })
                planted_item = berry
            end
        end
        if berry
            planted_item = berry if planted_item.nil?
            $stats.berries_planted += 1
            berry_plant.plant(berry, seed)
            if Settings::BERRY_USE_BERRY_SEEDS && seed
                $bag.remove(seed)
            else
                $bag.remove(berry)
            end
            if Settings::NEW_BERRY_PLANTS
                pbMessage(_INTL("The {1} was planted in the {2} soil.", 
                                GameData::Item.get(planted_item).name, (berry_plant.soil ? berry_plant.soil[:planting_description] : _INTL("soft, earthy"))))
            elsif GameData::Item.get(planted_item).name.starts_with_vowel?
                pbMessage(_INTL("{1} planted an {2} in the {3} soil.",
                                $player.name, GameData::Item.get(planted_item).name,
                                (berry_plant.soil ? berry_plant.soil[:planting_description] : _INTL("soft, loamy"))))
            else
                pbMessage(_INTL("{1} planted a {2} in the {3} soil.",
                                $player.name, GameData::Item.get(planted_item).name,
                                (berry_plant.soil ? berry_plant.soil[:planting_description] : _INTL("soft, loamy"))))
            end
			
        end
    end
end

#===============================================================================
# Watering Changes
#===============================================================================

def pbBerryPlantWater(berry_plant)
    return if Settings::BERRY_PREVENT_WATERING_IF_MAXED && berry_plant.moisture_level == 100
    cans = []
    commands = []
    cmd = nil
    if Settings::BERRY_WATERING_MUST_FILL
        GameData::BerryPlant::WATERING_CANS.each do |item|
            next if !$bag.has?(item)
            cans.push(item)
            commands.push(_INTL("Use") + " " + GameData::Item.get(item).name + " " + pbGetWateringCanLevel(item,true))
        end
        return if cans.empty?
        commands[0] = _INTL("Yes") + pbGetWateringCanLevel(cans[0],true) if commands.length == 1
        commands.push(_INTL("No"))
        loop do
            cmd = pbMessage(_INTL("Want to sprinkle some water on it?"), commands, -1)
            break unless cans[cmd] && pbGetWateringCanLevel(cans[cmd]).is_a?(Integer) && pbGetWateringCanLevel(cans[cmd]) <= 0
            pbMessage(_INTL("The {1} is empty!",GameData::Item.get(cans[cmd]).name))
        end
        return if cmd < 0 || cmd == commands.length - 1
        berry_plant.water(cans[cmd])
        $PokemonGlobal.watering_can_levels[cans[cmd]] -= 1 unless $PokemonGlobal.watering_can_levels[cans[cmd]] == "Full"
    else
        GameData::BerryPlant::WATERING_CANS.each do |item|
            next if !$bag.has?(item)
            cans.push(item)
            commands.push(_INTL("Use") + " "  + GameData::Item.get(item).name)
        end
        return if cans.empty?
        commands[0] = _INTL("Yes") if commands.length == 1
        commands.push(_INTL("No"))
        cmd = pbMessage(_INTL("Want to sprinkle some water on it?"), commands, -1)
        return if cmd < 0 || cmd == commands.length - 1
        berry_plant.water(cans[cmd])
    end
    pbMessage(_INTL("{1} watered the plant.", $player.name) + "\\wtnp[40]")
    if Settings::NEW_BERRY_PLANTS
        pbMessage(_INTL("There! All happy!"))
    else
        pbMessage(_INTL("The plant seemed to be delighted."))
    end
    pbMessage(_INTL("The {1} is now empty.",GameData::Item.get(cans[cmd]).name)) if Settings::BERRY_WATERING_MUST_FILL && pbGetWateringCanLevel(cans[cmd]).is_a?(Integer) &&
            pbGetWateringCanLevel(cans[cmd]) <= 0
end

def pbGetWateringCanLevel(can, string = false)
    return if !Settings::BERRY_WATERING_MUST_FILL
    $PokemonGlobal.initializeWateringCanLevels if !$PokemonGlobal.watering_can_levels
    level = $PokemonGlobal.watering_can_levels[can]
    return level unless string
    case level
    when pbGetWateringCanMax(can)
        return " (F)"
    when 0
        return " (E)"
    else
        return " (" + level.to_s + ")"
    end
end

def pbFillWateringCans(count_var = 1, single_name_var = 3)
    count = 0
    return pbSet(count_var,count) if !Settings::BERRY_WATERING_MUST_FILL || !$PokemonGlobal.watering_can_levels
    can = ""
    GameData::BerryPlant::WATERING_CANS.each do |item|
        next if !$bag.has?(item)
        count += 1
        can = GameData::Item.get(item).name
        $PokemonGlobal.watering_can_levels[item] = pbGetWateringCanMax(item)
    end
    pbSet(count_var,count)
    pbSet(single_name_var,can)
    return true
end

def pbGetWateringCanMax(can)
    return "Full" if Settings::BERRY_WATERING_USES_ALWAYS_FULL.include?(can)
    ret = Settings::BERRY_WATERING_USES_OVERRIDES[can] || Settings::BERRY_WATERING_USES_BEFORE_EMPTY
    return ret
end

#===============================================================================
# Mutations
#===============================================================================

#alias tdw_berry_improvements_berry_plant pbBerryPlant
def pbBerryPlant
    berry_plant = pbMapInterpreter.getVariable
    if $DEBUG && Input.press?(Input::CTRL) && berry_plant
        loop do
            cmds = [_INTL("Plant Info"),_INTL("Make Fully Grown"),_INTL("Reset Plant"), _INTL("Continue")]
            help = [_INTL("View info about the plant event."), _INTL("Make the plant fully grown and ready to harvest."), 
                        _INTL("Reset the entire plant (will clear all data)."), _INTL("Continue.")]
            cmd = pbShowCommandsWithHelp(nil, cmds, help, cmds.length, cmds.length - 1)
            if cmd == 0
                infowindow = Window_AdvancedTextPokemon.new("")
                infowindow.viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
                infowindow.x        = 0
                infowindow.y        = 0
                infowindow.width    = Graphics.width
                infowindow.height   = Graphics.height
                overlay = BitmapSprite.new(Graphics.width, Graphics.height, infowindow.viewport)
                overlay.z = infowindow.z + 1
                pbSetSmallFont(overlay.bitmap)
                textpos = []
                textpos.push(_INTL("Zone: {1}", berry_plant.plant_zone || "None") + "  |  " + _INTL("Map Location: {1}", berry_plant.town_map_location))
                if berry_plant.soil
                    textpos.push(_INTL("Soil: {1}  |  Mulch: {2}", berry_plant.soil[:name], berry_plant.mulch_id ? GameData::Item.get(berry_plant.mulch_id).name : "None"))
                else
                    textpos.push(_INTL("Mulch: {1}", berry_plant.mulch_id ? GameData::Item.get(berry_plant.mulch_id).name : "None"))
                end
                if berry_plant.planted?
                    if berry_plant.seed_id
                        textpos.push(_INTL("Seed: {1}", GameData::Item.get(berry_plant.berry_id).name) + "  |  " + 
                                    _INTL("Current Yield: {1}", berry_plant.berry_yield))
                    else
                        textpos.push(_INTL("Berry: {1}", GameData::Item.get(berry_plant.berry_id).name) + "  |  " + 
                                    _INTL("Current Yield: {1}", berry_plant.berry_yield))
                    end
                    textpos.push(_INTL("Stage: {1}", berry_plant.growth_stage) + "  |  " + 
                                _INTL("Hrs per stage: {1}", berry_plant.debug_info[:time_per_stage]) + "  |  " + 
                                _INTL("Max replants: {1}", berry_plant.debug_info[:max_replants]))
                    textpos.push(_INTL("Moisture: {1}%  |  Dry rate: {2}%/hr", berry_plant.moisture_level, berry_plant.debug_info[:drying_per_hour]))
                    textpos.push(_INTL("Fully grown stage count: {1}", berry_plant.debug_info[:stages_fully_grown]))
                    textpos.push(_INTL("Exposed to Pref Weather?: {1}", berry_plant.exposed_to_preferred_weather))

                    if Settings::BERRY_PREFERRED_ZONES_ENABLED && Settings::BERRY_UNPREFERRED_ZONES_ENABLED
                        textpos.push(_INTL("In Pref Zone?: {1}", berry_plant.preferred_zone) + "  |  " + _INTL("In Unpref Zone?: {1}", berry_plant.unpreferred_zone))
                    elsif Settings::BERRY_PREFERRED_ZONES_ENABLED
                        textpos.push(_INTL("In Pref Zone?: {1}", berry_plant.preferred_zone))
                    elsif Settings::BERRY_UNPREFERRED_ZONES_ENABLED
                        textpos.push(_INTL("In Unpref Zone?: {1}", berry_plant.unpreferred_zone))
                    end

                    textpos.push(_INTL("In Pref Soil?: {1}", berry_plant.preferred_soil)) if Settings::BERRY_PREFERRED_SOIL_ENABLED 

                    if Settings::BERRY_USE_WEED_MECHANICS && Settings::BERRY_USE_PEST_MECHANICS
                        textpos.push(_INTL("Weed chance: {1}%", berry_plant.getWeedGrowthChance) + "  |  " + _INTL("Pest chance: {1}%", berry_plant.getPestAppearChance))
                    elsif Settings::BERRY_USE_WEED_MECHANICS
                        textpos.push(_INTL("Weed chance: {1}%", berry_plant.getWeedGrowthChance))
                    elsif Settings::BERRY_USE_PEST_MECHANICS
                        textpos.push(_INTL("Pest chance: {1}%", berry_plant.getPestAppearChance))
                    end

                    if ![-1, false].include?(Settings::ALLOW_BERRY_MUTATIONS_SWITCH_ID) 
                        text = _INTL("Mutation chance: {1}%", berry_plant.debug_info[:mutation_chance]) 
                        text += "  |  " + _INTL("Mutation: {1} [{2}]", GameData::Item.get(berry_plant.mutation_info[0]), berry_plant.mutation_info[1]) if @mutation_info
                        textpos.push(text)
                    end
                    
                    textpos.push(_INTL("Propagation chance: {1}%", berry_plant.debug_info[:propagation_chance]/10.0)) if ![-1, false].include?(Settings::ALLOW_BERRY_PROPAGATION_SWITCH_ID) 
                    
                    if berry_plant.watering_cans_used.empty?
                        textpos.push(_INTL("Watering cans (with traits) used: None"))
                    else
                        berry_plant.watering_cans_used.each_with_index do |c, i| 
                            text = ""
                            text += _INTL("Watering cans (with traits) used:") if i == 0
                            text += _INTL(" {1}", c)
                            textpos.push(text)
                        end
                    end
                end
                line_y = 16
                textpos.each_with_index do |t, i|
                    textpos[i] = [t, 16, line_y + i*25, 0, MessageConfig::DARK_TEXT_MAIN_COLOR, MessageConfig::DARK_TEXT_SHADOW_COLOR]
                end
                pbDrawTextPositions(overlay.bitmap, textpos)
                loop do
                    Graphics.update
                    Input.update
                    if Input.trigger?(Input::USE) || Input.trigger?(Input::BACK)
                        infowindow.dispose
                        overlay.dispose
                        break
                    end
                end
            elsif cmd == 1
                    berry_plant = pbMapInterpreter.getVariable
                    berry_plant.growth_stage = GameData::BerryPlant::NUMBER_OF_GROWTH_STAGES + 1
                    pbMessage(_INTL("The berry plant is ready to harvest."))
            elsif cmd == 2
                if pbConfirmMessageSerious(_INTL("Are you sure you want to reset all data for this plant?"))
                    pbMapInterpreter.setVariable(BerryPlantData.new(pbMapInterpreter.get_self))
                    berry_plant = pbMapInterpreter.getVariable
                    pbMessage(_INTL("Berry plant reset."))
                end
            else
                break
            end
        end
    end
    not_planted = !berry_plant&.planted?
    pbBerryPlantWitheredItem
    pbPestInteraction
    return if $game_switches[Settings::STARTING_OVER_SWITCH]
    if berry_plant&.mutated_berry_info
        pbBerryPlantWithMutation
        if Settings::BERRY_SHOW_WATERING_ANIMATION && $game_player.berry_watering
            $game_player.stop_watering_charset
        end
        pbOtherInteractions if !not_planted
    else
        #pbBerryPlantOrig
        pbBerrySpotQuickMenu
        if Settings::BERRY_SHOW_WATERING_ANIMATION && $game_player.berry_watering
            $game_player.stop_watering_charset
        end
        #pbOtherInteractions if !not_planted
    end
    if Settings::BERRY_PREFERRED_ZONE_WARNING && not_planted && berry_plant && 
                berry_plant.berry_id && (berry_plant.plant_zone || berry_plant.soil)
        planted_item_id = (Settings::BERRY_USE_BERRY_SEEDS && berry_plant.seed_id) ? berry_plant.seed_id : berry_plant.berry_id
        if berry_plant.plant_zone && pbBerryPreferredZonesEnabled? && GameData::BerryData.get(berry_plant.berry_id).preferred_zones.include?(berry_plant.plant_zone)
            pbMessage(_INTL("The {1} seemed happy to be planted here!", GameData::Item.get(planted_item_id).name))
        elsif berry_plant.plant_zone && pbBerryUnpreferredZonesEnabled? && GameData::BerryData.get(berry_plant.berry_id).unpreferred_zones.include?(berry_plant.plant_zone)
            pbMessage(_INTL("The {1} didn't seem happy to be planted here...", GameData::Item.get(planted_item_id).name))
        elsif berry_plant.soil && pbBerryPreferredSoilEnabled? && GameData::BerryData.get(berry_plant.berry_id).preferred_soil == berry_plant.soil[:id]
            pbMessage(_INTL("The {1} seemed happy to be planted here!", GameData::Item.get(planted_item_id).name))
        end
    end
end

def pbBerryPlantWithMutation
    interp = pbMapInterpreter
    this_event = interp.get_self
    berry_plant = interp.getVariable
    berry = berry_plant.berry_id
    # Interact with the event based on its growth
    if berry_plant.grown?
        this_event.turn_up   # Stop the event turning towards the player
        berry_yield = berry_plant.berry_yield
        if pbPickBerryWithMutation(berry, berry_yield, berry_plant.mutated_berry_info)
            berry_plant.reset 
            pbDropBerrySeeds(berry, berry_yield)
        end
        return
    elsif berry_plant.growing?
        berry_name = GameData::Item.get(berry).name
        case berry_plant.growth_stage
        when 1   # X planted
            this_event.turn_down   # Stop the event turning towards the player
            if berry_name.starts_with_vowel?
                pbMessage(_INTL("An {1} was planted here.", berry_name))
            else
                pbMessage(_INTL("A {1} was planted here.", berry_name))
            end
        when 2   # X sprouted
            this_event.turn_down   # Stop the event turning towards the player
            pbMessage(_INTL("The {1} has sprouted.", berry_name))
        when 3   # X taller
            this_event.turn_left   # Stop the event turning towards the player
            pbMessage(_INTL("The {1} plant is growing bigger.", berry_name))
        else     # X flowering
            this_event.turn_right   # Stop the event turning towards the player
            mutation_comment = Settings::BERRY_PLANT_BLOOMING_COMMENT
            if Settings::NEW_BERRY_PLANTS
                pbMessage(_INTL("This {1} plant is in bloom!", berry_name))
            else
                case berry_plant.watering_count
                when 4
                    pbMessage(_INTL("This {1} plant is in fabulous bloom!", berry_name))
                when 3
                    pbMessage(_INTL("This {1} plant is blooming very beautifully!", berry_name))
                when 2
                    pbMessage(_INTL("This {1} plant is blooming prettily!", berry_name))
                when 1
                    pbMessage(_INTL("This {1} plant is blooming cutely!", berry_name))
                else
                    pbMessage(_INTL("This {1} plant is in bloom!", berry_name))
                end
            end
            pbMessage(mutation_comment) if mutation_comment
        end
        # Water the growing plant
        pbBerryPlantWater(berry_plant)
        return
    end
end

def pbPickBerryWithMutation(berry, qty = 1, mutation_info)
    berry = GameData::Item.get(berry)
    mut_berry = GameData::Item.get(mutation_info[0])
    mut_berry_qty = mutation_info[1]
    mut_berry_qty -= 1 while qty - mut_berry_qty < 1
    berry_name = (qty > 1) ? berry.name_plural : berry.name
    mut_berry_name = (mut_berry_qty > 1) ? mut_berry.name_plural : mut_berry.name
    if qty > 1 && mut_berry_qty > 1
        message = _INTL("There are {1} \\c[1]{2}\\c[0] and {3} \\c[1]{4}\\c[0]! \1Want to pick them?", qty, berry_name, mut_berry_qty, mut_berry_name)
    elsif qty > 1
        message = _INTL("There are {1} \\c[1]{2}\\c[0] and 1 \\c[1]{3}\\c[0]! \1Want to pick them?", qty, berry_name, mut_berry_name)
    elsif mut_berry_qty > 1
        message = _INTL("There is 1 \\c[1]{1}\\c[0] and {2} \\c[1]{3}\\c[0]! \1Want to pick them?", berry_name, mut_berry_qty, mut_berry_name)
    else
        message = _INTL("There is 1 \\c[1]{1}\\c[0] and 1 \\c[1]{2}\\c[0]! \1Want to pick them?", berry_name, mut_berry_name)
    end
    return false if !pbConfirmMessage(message)
    if !$bag.can_add?(berry, qty) || !$bag.can_add?(mut_berry, mut_berry_qty)
        pbMessage(_INTL("Too bad...\nThe Bag is full..."))
        return false
    end
    $stats.berry_plants_picked += 1
    $stats.mutated_berries_picked ||= 0
    $stats.mutated_berries_picked += mut_berry_qty
    if qty + mut_berry_qty >= GameData::BerryPlant.get(berry.id).maximum_yield
        $stats.max_yield_berry_plants += 1
    end
    $bag.add(berry, qty)
    $bag.add(mut_berry, mut_berry_qty)
    if qty > 1 && mut_berry_qty > 1
        pbMessage(_INTL("\\me[Berry get]You picked the {1} \\c[1]{2}\\c[0] and {3} \\c[1]{4}\\c[0].\\wtnp[30]", qty, berry_name, mut_berry_qty, mut_berry_name))
    elsif qty > 1
        pbMessage(_INTL("\\me[Berry get]You picked the {1} \\c[1]{2}\\c[0] and \\c[1]{3}\\c[0].\\wtnp[30]", qty, berry_name, mut_berry_name))
    elsif mut_berry_qty > 1
        pbMessage(_INTL("\\me[Berry get]You picked the \\c[1]{1}\\c[0] and {2} \\c[1]{3}\\c[0].\\wtnp[30]", berry_name, mut_berry_qty, mut_berry_name))
    else
        pbMessage(_INTL("\\me[Berry get]You picked the \\c[1]{1}\\c[0] and \\c[1]{2}\\c[0].\\wtnp[30]", berry_name, mut_berry_name))
    end
    pocket = berry.pocket
    pbMessage(_INTL("{1} put them in\\nyour Bag's <icon=bagPocket{2}>\\c[1]{3}\\c[0] Pocket.\1", $player.name, pocket, PokemonBag.pocket_names[pocket - 1]))
    berry_plant = pbMapInterpreter.getVariable
    berry_plant.persistent = true if Settings::BERRY_PERSISTENT_PLANT_CHANCE > 0 && berry_plant && berry_plant.replant_count < berry_plant.max_replant_count && 
            rand(100) < Settings::BERRY_PERSISTENT_PLANT_CHANCE
    unless berry_plant&.persistent
        if Settings::NEW_BERRY_PLANTS
            pbMessage(_INTL("The soil returned to its {1} state.", (berry_plant.soil ? berry_plant.soil[:picked_description] : _INTL("soft and earthy"))))
        else
            pbMessage(_INTL("The soil returned to its {1} state.", (berry_plant.soil ? berry_plant.soil[:picked_description] : _INTL("soft and loamy"))))
        end
    end
    this_event = pbMapInterpreter.get_self
    pbSetSelfSwitch(this_event.id, "A", true)
    return true
end

def pbPickBerryPersistent(berry, qty)
    berry = GameData::Item.get(berry)
    berry_name = (qty > 1) ? berry.name_plural : berry.name
    if qty > 1
        message = _INTL("There are {1} \\c[1]{2}\\c[0]!\nWant to pick them?", qty, berry_name)
    else
        message = _INTL("There is 1 \\c[1]{1}\\c[0]!\nWant to pick it?", berry_name)
    end
    return false if !pbConfirmMessage(message)
    if !$bag.can_add?(berry, qty)
        pbMessage(_INTL("Too bad...\nThe Bag is full..."))
        return false
    end
    $stats.berry_plants_picked += 1
    if qty >= GameData::BerryPlant.get(berry.id).maximum_yield
        $stats.max_yield_berry_plants += 1
    end
    $bag.add(berry, qty)
    if qty > 1
        pbMessage("\\me[Berry get]" + _INTL("You picked the {1} \\c[1]{2}\\c[0].", qty, berry_name) + "\\wtnp[30]")
    else
        pbMessage("\\me[Berry get]" + _INTL("You picked the \\c[1]{1}\\c[0].", berry_name) + "\\wtnp[30]")
    end
    pocket = berry.pocket
    pbMessage(_INTL("You put the {1} in\\nyour Bag's <icon=bagPocket{2}>\\c[1]{3}\\c[0] pocket.",
                    berry_name, pocket, PokemonBag.pocket_names[pocket - 1]) + "\1")
    #Create berry plant data now so preplanted plants can be persistent
    interp = pbMapInterpreter
    berry_plant = interp.getVariable
    preplanted = false
    will_persist = rand(100) < Settings::BERRY_PERSISTENT_PLANT_CHANCE
    if !berry_plant && Settings::BERRY_PERSISTENT_FOR_PREPLANTED && will_persist
        berry_plant = BerryPlantData.new
        interp.setVariable(berry_plant)
        berry_plant = interp.getVariable
        berry_plant.plant(berry.id)
        berry_plant.growth_stage = 2
        preplanted = true
    end
    berry_plant.persistent = true if Settings::BERRY_PERSISTENT_PLANT_CHANCE > 0 && berry_plant && berry_plant.replant_count < berry_plant.max_replant_count && will_persist
    unless berry_plant&.persistent
        if Settings::NEW_BERRY_PLANTS
            pbMessage(_INTL("The soil returned to its {1} state.", (berry_plant.soil ? berry_plant.soil[:picked_description] : _INTL("soft and earthy"))))
        else
            pbMessage(_INTL("The soil returned to its {1} state.", (berry_plant.soil ? berry_plant.soil[:picked_description] : _INTL("soft and loamy"))))
        end
    end
    this_event = pbMapInterpreter.get_self
    pbSetSelfSwitch(this_event.id, "A", true)
    berry_plant.reset if preplanted
    return true
end

def pbPestInteraction
    interp = pbMapInterpreter
    berry_plant = interp.getVariable
    return if !Settings::BERRY_USE_PEST_MECHANICS || !berry_plant || !berry_plant.pests
    berry = berry_plant.berry_id
    this_event = interp.get_self
    if berry_plant.grown?
        this_event.turn_up
    elsif
        case berry_plant.growth_stage
        when 1 then this_event.turn_down
        when 2 then this_event.turn_down
        when 3 then this_event.turn_left
        else this_event.turn_right
        end
    end
    if Settings::BERRY_REPEL_WORKS_ON_PESTS && $PokemonGlobal.repel > 0
        pbMessage(_INTL("A Pokémon jumped out, but the repellent made it run away!"))
    else
        pbMessage(_INTL("A Pokémon jumped out at you!"))
        pbBerryPlantPestRandomEncounter(berry)
    end
    berry_plant.pests = false
    berry_plant.pests_timer = pbGetTimeNow.to_i
end

def pbOtherInteractions
    berry_plant = pbMapInterpreter.getVariable
    berry = berry_plant.berry_id
    # Dig Up
    if berry_plant.growing? && berry_plant.growth_stage == 1 && pbCanDigUpBerry?
        if berry_plant.seed_id
            if pbConfirmMessageSerious(_INTL("You may be able to dig up the seed. Dig up the {1}?", GameData::Item.get(berry_plant.seed_id).name))
                seed = berry_plant.seed_id
                berry_plant.reset
                if rand(100) < Settings::BERRY_DIG_UP_KEEP_CHANCE
                    $bag.add(seed)
                    pbMessage(_INTL("The dug up {1} was in good enough condition to keep.", GameData::Item.get(seed).name))
                else
                    pbMessage(_INTL("The dug up {1} broke apart in your hands.", GameData::Item.get(seed).name))
                end
            end
        else
            if pbConfirmMessageSerious(_INTL("You may be able to dig up the berry. Dig up the {1}?", GameData::Item.get(berry).name))
                berry_plant.reset
                if rand(100) < Settings::BERRY_DIG_UP_KEEP_CHANCE
                    $bag.add(berry)
                    pbMessage(_INTL("The dug up {1} was in good enough condition to keep.",GameData::Item.get(berry).name))
                else
                    pbMessage(_INTL("The dug up {1} broke apart in your hands.",GameData::Item.get(berry).name))
                end
            end
        end
    end
    #Weeds
    if Settings::BERRY_USE_WEED_MECHANICS && berry_plant.weeds
        if pbConfirmMessage(_INTL("Weeds are growing here. Pull out the weeds?"))
            berry_plant.pullWeeds
            pbMessage(_INTL("{1} pulled out the weeds!", $player.name))
        end
    end
end

def pbBerryPlantWitheredItem
    berry_plant = pbMapInterpreter.getVariable
    return if !berry_plant
    item = berry_plant.withered_item
    return if berry_plant.planted? || !item
    pbMessage(_INTL("There's something on the ground..."))
    pbReceiveItem(item)
    berry_plant.withered_item = nil
end

class PokemonGlobalMetadata
    attr_accessor :berry_plant_mutation_parents
    attr_accessor :maps_first_setups
    attr_accessor :watering_can_levels

    alias tdw_berry_plant_global_init initialize
    def initialize
        tdw_berry_plant_global_init
        compilePlantMutationParents
        @maps_first_setups = {}
    end

    def compilePlantMutationParents
        @berry_plant_mutation_parents = []
        Settings::BERRY_MUTATION_POSSIBILITIES.each { |key| 
            @berry_plant_mutation_parents.push(key[0][0]) if !@berry_plant_mutation_parents.include?(key[0][0])
            @berry_plant_mutation_parents.push(key[0][1]) if !@berry_plant_mutation_parents.include?(key[0][1])
        }
    end

    def initializeWateringCanLevels
        return if !Settings::BERRY_WATERING_MUST_FILL
        @watering_can_levels = {}
        GameData::BerryPlant::WATERING_CANS.each do |item|
            @watering_can_levels[item] = pbGetWateringCanMax(item)
        end
    end
end


#===============================================================================
# Set Up Berry Data sooner
#===============================================================================
# This sets up berry data after a static berry plant is picked.
alias tdw_berry_improvements_pickberry pbPickBerry
def pbPickBerry(berry, qty = 1)
    ret = (Settings::BERRY_PERSISTENT_PLANT_CHANCE > 0) ? pbPickBerryPersistent(berry, qty) : tdw_berry_improvements_pickberry(berry, qty)
    if ret
        interp = pbMapInterpreter
        berry_plant = interp.getVariable
        if !berry_plant
          berry_plant = BerryPlantData.new
          interp.setVariable(berry_plant)
        end
    end
    return ret
end

# This sets up berry data if the event has pbberryplant in the event pages, but not pbpickberry before it.
class Game_Map
    alias tdw_berry_improvements_map_setup setup
    def setup(map_id)
        tdw_berry_improvements_map_setup(map_id)
        return if $PokemonGlobal.maps_first_setups && $PokemonGlobal.maps_first_setups[map_id]
        @events.each do |event|
            next if !event[1].name[/berryplant/i]
            next if $PokemonGlobal.eventvars[[map_id, event[1].id]]
            next if event[1].list.nil?
            next unless event[1].list.is_a?(Array)
            plant = false
            pick = false
            event[1].list.each do |item|
                break if pick || plant
                next if ![355, 655].include?(item.code)
                next plant = true if item.parameters[0][/pbberryplant/i]
                next pick = true if item.parameters[0][/pbpickberry/i]
            end
            if plant && !pick
                berry_plant = $PokemonGlobal.eventvars[[map_id, event[1].id]]
                if !berry_plant
                    berry_plant = BerryPlantData.new(event[1])
                    berry_plant.town_map_location = [$~[1].to_i,$~[2].to_i,$~[3].to_i] if event[1].name[/map\((\d+),(\d+),(\d+)\)/i]
                    berry_plant.plant_zone = $~[1].to_s if event[1].name[/berryzone\((\w+)\)$/i]
                    $PokemonGlobal.eventvars[[map_id, event[1].id]] = berry_plant
                end
            end
        end
        $PokemonGlobal.maps_first_setups ||= {}
        $PokemonGlobal.maps_first_setups[map_id] = true
    end
end


#===============================================================================
# Town Map
#===============================================================================

def pbForceUpdateAllBerryPlants(mapOnly: false, region: -1, returnArray: false)
    array = []
    $PokemonGlobal.eventvars.each do |info|
        plant = info[1]
        next if !plant.is_a?(BerryPlantData)
        Console.echo_warn _INTL("BerryPlant Event #{info[0][1]} on map #{pbGetBasicMapNameFromId(info[0][0])}[#{info[0][0]}] has no map(region,x,y) defined.") if plant.town_map_location.nil?
        next if mapOnly && plant.town_map_location.nil?
        next if region >= 0 && plant.town_map_location[0] != region
        plant.town_map_checking = true
        plant.update
        plant.town_map_checking = nil
        array.push(plant) if plant.planted?
    end
    return returnArray ? array : nil
end

class PokemonRegionMap_Scene
    def allowShowingBerries
        return false if @wallmap
        return pbMapShowBerries?
    end
        
    if !PluginManager.installed?("Arcky's Region Map") 
        alias tdw_berry_improvements_map_fy_refresh refresh_fly_screen
        def refresh_fly_screen
            tdw_berry_improvements_map_fy_refresh
            refresh_berry_screen if allowShowingBerries
        end

        def add_berry_icon_sprites
            regionID = -1
            playerpos = ($game_map.metadata) ? $game_map.metadata.town_map_position : nil
            if @region >= 0 && playerpos && @region != playerpos[0]
                regionID = @region
            elsif playerpos
                regionID = playerpos[0]
            end
            berryIcons = {}
            berryPlants = pbForceUpdateAllBerryPlants(mapOnly: true, region: regionID, returnArray: true)
            settings = Settings::BERRIES_ON_MAP_SHOW_PRIORITY
            berryPlants.each do |plant|
                img = 999
                settings.each_with_index { |set, i|
                    if set == :ReadyToPick && plant.grown? then img = i
                    elsif set == :HasPests && plant.pests then img = i
                    elsif set == :NeedsWater && plant.moisture_stage == 0 then img = i
                    elsif set == :HasWeeds && plant.weeds then img = i
                    end
                    break if img != 999
                }
                if berryIcons[plant.town_map_location]
                    berryIcons[plant.town_map_location] = img if img < berryIcons[plant.town_map_location]
                else
                    berryIcons[plant.town_map_location] = img
                end
            end
            k = 0
            berryIcons.each { |key, value|
                conversion = {:NeedsWater => "mapBerryDry", :ReadyToPick => "mapBerryReady", 
                        :HasPests => "mapBerryPest", :HasWeeds => "mapBerryWeeds"}[settings[value]] || "mapBerry"
                @sprites["berry#{k}"] = IconSprite.new(0, 0, @viewport)
                @sprites["berry#{k}"].setBitmap(pbGetBerryMapIcon(conversion))
                @sprites["berry#{k}"].x        = point_x_to_screen_x(key[1])
                @sprites["berry#{k}"].y        = point_y_to_screen_y(key[2])
                @sprites["berry#{k}"].visible  = @mode == 0
                k += 1
            }
            @sprites.each { |key, sprite|
                next if ["background","map","map2","mapbottom"].include?(key)
                next if key.include?("berry")
                sprite.z += 1
            }
        end

        def refresh_berry_screen
            return if @fly_map || @wallmap
            add_berry_icon_sprites if !@sprites["berry0"]
            @sprites.each do |key, sprite|
                next if !key.include?("berry")
                sprite.visible = (@mode == 0)
            end
        end
    end

    def pbGetBerryMapIcon(id)
        if Essentials::VERSION.include?("21")
            return "Graphics/UI/Berry Improvements/#{id}"
        else
            return "Graphics/Pictures/Berry Improvements/#{id}"
        end
    end
end

#===============================================================================
# Moisture Graphic
#===============================================================================

class BerryPlantMoistureSprite
    alias tdw_berry_improvements_moisture_update_graphic update_graphic
    def update_graphic
        if @event&.variable && @event.variable.is_a?(BerryPlantData) && @event.variable.soil && @event.variable.soil[:moisture_graphic_ext]
            case @moisture_stage
            when -1 then @sprite.setBitmap("")
            when 0  then @sprite.setBitmap("Graphics/Characters/berrytreedry#{@event.variable.soil[:moisture_graphic_ext]}")
            when 1  then @sprite.setBitmap("Graphics/Characters/berrytreedamp#{@event.variable.soil[:moisture_graphic_ext]}")
            when 2  then @sprite.setBitmap("Graphics/Characters/berrytreewet#{@event.variable.soil[:moisture_graphic_ext]}")
            end
        else
            tdw_berry_improvements_moisture_update_graphic
        end
    end
end

#===============================================================================
# Mulch Graphic
#===============================================================================

EventHandlers.add(:on_new_spriteset_map, :add_berry_plant_mulch_graphic,
    proc { |spriteset, viewport|
      next if Settings::BERRY_JUST_MULCH_GRAPHIC.nil? || Settings::BERRY_JUST_MULCH_GRAPHIC.empty?
      map = spriteset.map
      map.events.each do |event|
        next if !event[1].name[/berryplant/i]
        spriteset.addUserSprite(BerryPlantMulchSprite.new(event[1], map, viewport))
      end
    }
)

class BerryPlantMulchSprite
    def initialize(event, map, viewport = nil)
        @event          = event
        @map            = map
        @mulch          = false
        @sprite         = IconSprite.new(0, 0, viewport)
        @sprite.ox      = 16
        @sprite.oy      = 24
        @disposed       = false
        update_graphic
    end
  
    def dispose
        @sprite.dispose
        @map      = nil
        @event    = nil
        @disposed = true
    end
  
    def disposed?
        return @disposed
    end
  
    def update_graphic
        if @mulch
            if @event&.variable && @event.variable.is_a?(BerryPlantData) && @event.variable.soil && @event.variable.soil[:moisture_graphic_ext]
                @sprite.setBitmap("Graphics/Characters/#{Settings::BERRY_JUST_MULCH_GRAPHIC}#{@event.variable.soil[:moisture_graphic_ext]}")
            else
                @sprite.setBitmap("Graphics/Characters/#{Settings::BERRY_JUST_MULCH_GRAPHIC}")
            end
        else
            @sprite.setBitmap("") 
        end
    end
  
    def update
        return if !@sprite || !@event
        cur_mulch = @mulch
        berry_plant = @event.variable
        return if !berry_plant.is_a?(BerryPlantData)
        if berry_plant.planted? || !berry_plant.mulch_id
            @mulch = false
        else
            @mulch = true
        end
        update_graphic if cur_mulch != @mulch
        @sprite.update
        @sprite.x      = ScreenPosHelper.pbScreenX(@event)
        @sprite.y      = ScreenPosHelper.pbScreenY(@event)
        @sprite.zoom_x = ScreenPosHelper.pbScreenZoomX(@event)
        @sprite.zoom_y = @sprite.zoom_x
        pbDayNightTint(@sprite)
    end
end

#===============================================================================
# Weeds Graphic
#===============================================================================

EventHandlers.add(:on_new_spriteset_map, :add_berry_plant_weed_graphic,
    proc { |spriteset, viewport|
      next if !Settings::BERRY_USE_WEED_MECHANICS
      map = spriteset.map
      map.events.each do |event|
        next if !event[1].name[/berryplant/i]
        spriteset.addUserSprite(BerryPlantWeedSprite.new(event[1], map, viewport))
      end
    }
)

class BerryPlantWeedSprite
    def initialize(event, map, viewport = nil)
        @event          = event
        @map            = map
        @weeds          = false
        @sprite         = IconSprite.new(0, 0, viewport)
        @sprite.ox      = 16
        @sprite.oy      = 24
        @disposed       = false
        update_graphic
    end
  
    def dispose
        @sprite.dispose
        @map      = nil
        @event    = nil
        @disposed = true
    end
  
    def disposed?
        return @disposed
    end
  
    def update_graphic
        if @weeds  
            @sprite.setBitmap("Graphics/Characters/berrytreeweeds")
        else
            @sprite.setBitmap("") 
        end
    end
  
    def update
        return if !@sprite || !@event
        cur_weeds = @weeds
        berry_plant = @event.variable
        return if !berry_plant.is_a?(BerryPlantData)
        @weeds = berry_plant.weeds
        update_graphic if cur_weeds != @weeds
        @sprite.update
        @sprite.x      = ScreenPosHelper.pbScreenX(@event)
        @sprite.y      = ScreenPosHelper.pbScreenY(@event)
        @sprite.zoom_x = ScreenPosHelper.pbScreenZoomX(@event)
        @sprite.zoom_y = @sprite.zoom_x
        pbDayNightTint(@sprite)
    end
end

#===============================================================================
# Preferred Traits checks
#===============================================================================

def pbBerryPreferredWeatherEnabled?
    return PluginManager.installed?("TDW Berry Core and Dex") && Settings::BERRY_PREFERRED_WEATHER_ENABLED
end

def pbBerryPreferredZonesEnabled?
    return PluginManager.installed?("TDW Berry Core and Dex") && Settings::BERRY_PREFERRED_ZONES_ENABLED
end

def pbBerryUnpreferredZonesEnabled?
    return PluginManager.installed?("TDW Berry Core and Dex") && Settings::BERRY_UNPREFERRED_ZONES_ENABLED
end

def pbBerryPreferredSoilEnabled?
    return PluginManager.installed?("TDW Berry Core and Dex","1.6") && Settings::BERRY_PREFERRED_SOIL_ENABLED
end

#===============================================================================
# Settings Checks
#===============================================================================

def pbCanDigUpBerry?
    switch = true
    switch = false if Settings::BERRY_ALLOW_DIGGING_UP_SWITCH_ID == false
    if Settings::BERRY_ALLOW_DIGGING_UP_SWITCH_ID.is_a?(Integer)
        if Settings::BERRY_ALLOW_DIGGING_UP_SWITCH_ID == -1
            switch = false
        elsif Settings::BERRY_ALLOW_DIGGING_UP_SWITCH_ID == 0
            switch = true
        else 
            switch = $game_switches[Settings::BERRY_ALLOW_DIGGING_UP_SWITCH_ID]
        end
    end
    item = !Settings::BERRY_DIG_UP_ITEM || $bag.has?(Settings::BERRY_DIG_UP_ITEM)
    return switch && item
end

def pbAllowBerryMutations?
    switch = true
    switch = false if Settings::ALLOW_BERRY_MUTATIONS_SWITCH_ID == false
    if Settings::ALLOW_BERRY_MUTATIONS_SWITCH_ID.is_a?(Integer)
        if Settings::ALLOW_BERRY_MUTATIONS_SWITCH_ID == -1
            switch = false
        elsif Settings::ALLOW_BERRY_MUTATIONS_SWITCH_ID == 0
            switch = true
        else 
            switch = $game_switches[Settings::ALLOW_BERRY_MUTATIONS_SWITCH_ID]
        end
    end
    return switch
end

def pbAllowBerryPropagation?
    switch = true
    switch = false if Settings::ALLOW_BERRY_PROPAGATION_SWITCH_ID == false
    if Settings::ALLOW_BERRY_PROPAGATION_SWITCH_ID.is_a?(Integer)
        if Settings::ALLOW_BERRY_PROPAGATION_SWITCH_ID == -1
            switch = false
        elsif Settings::ALLOW_BERRY_PROPAGATION_SWITCH_ID == 0
            switch = true
        else 
            switch = $game_switches[Settings::ALLOW_BERRY_PROPAGATION_SWITCH_ID]
        end
    end
    return switch
end

def pbMapShowBerries?
    switch = true
    switch = false if Settings::SHOW_BERRIES_ON_MAP_SWITCH_ID == false
    if Settings::SHOW_BERRIES_ON_MAP_SWITCH_ID.is_a?(Integer)
        if Settings::SHOW_BERRIES_ON_MAP_SWITCH_ID == -1
            switch = false
        elsif Settings::SHOW_BERRIES_ON_MAP_SWITCH_ID == 0
            switch = true
        else 
            switch = $game_switches[Settings::SHOW_BERRIES_ON_MAP_SWITCH_ID]
        end
    end
    return switch
end

def pbGetBerrySeedDrops(berry_id, qty)
    seed_id = GameData::Item.try_get((berry_id.to_s + "_SEED").to_sym)
    return nil unless seed_id
    seed_id = seed_id.id
    if Settings::BERRY_SEED_DROP_OVERRIDES[berry_id]
        chance = Settings::BERRY_SEED_DROP_OVERRIDES[berry_id][:chance] || Settings::BERRY_SEED_DROP_CHANCE || 0
        amt = Settings::BERRY_SEED_DROP_OVERRIDES[berry_id][:amount] || Settings::BERRY_SEED_DROP_AMOUNT || 0
    else
        chance = Settings::BERRY_SEED_DROP_CHANCE || 0
        amt = Settings::BERRY_SEED_DROP_AMOUNT || 0
    end
    return nil unless rand(100) < chance
    if amt.is_a?(Array)
        val_1 = (amt[0] == :Yield ? qty : amt[0])
        val_2 = (amt[1] == :Yield ? qty : amt[1])
        if val_2 < val_1
            amt = rand(val_2..val_1)
        else
            amt = rand(val_1..val_2)
        end
    elsif amt == :Yield
        amt = qty
    end
    return nil unless amt > 0
    return [seed_id, amt]
end

def pbDropBerrySeeds(berry_id, berry_yield)
    return false unless Settings::BERRY_USE_BERRY_SEEDS
    drops = pbGetBerrySeedDrops(berry_id, berry_yield)
    if drops && $bag.can_add?(drops[0], drops[1])
        pbMessage(_INTL("Oh, something dropped!"))
        pbReceiveItem(drops[0], drops[1])
        return true
    end
    return false
end

def pbClearBerryTimeDelta
  return unless $PokemonGlobal && $PokemonGlobal.eventvars
  now = pbGetTimeNow.to_i
  region_id = 0

  $PokemonGlobal.eventvars.each do |key, plant|
    # key is [map_id, event_id]
    #next unless key.is_a?(Array) && key[0] == map_id
    next unless plant.is_a?(BerryPlantData)

    # Ensure Town Map location exists (no need to rename the event)
    ev_id = key[1]
    ev    = $game_map.events[ev_id]
    if plant.town_map_location.nil? && ev
      plant.town_map_location = [region_id, ev.x, ev.y]
    end

    # Just sync timestamp; do NOT call update (which would advance growth)
    plant.instance_variable_set(:@pests_timer, now)
    plant.instance_variable_set(:@weeds_timer, now)
    plant.instance_variable_set(:@time_last_updated, now)
    $game_switches[71] = true
  end
end

def pbDebugFillBerryPlants
  # IDs of BerryPlant events on current map
  events = []
  $game_map.events.each_value do |e|
    if e.name =~ /\ABerryPlant\b/i
      events << e.id
    end
  end
  return if events.empty?

  # Collect berry item IDs (GameData::Item.each requires a block)
  berry_ids = []
  GameData::Item.each do |it|
    berry_ids << it.id if it.is_berry?
  end
  if berry_ids.empty?
    pbMessage(_INTL("No berry items defined."))
    return
  end

  now       = pbGetTimeNow.to_i
  region_id =  0
  seeded    = 0

  for eid in events
    ev = $game_map.events[eid]
    next if ev.nil?

    key  = [$game_map.map_id, eid]
    data = $PokemonGlobal.eventvars[key]

    # Ensure BerryPlantData exists
    if !data.is_a?(BerryPlantData)
      data = BerryPlantData.new(ev)
      $PokemonGlobal.eventvars[key] = data
    end

    # Ensure Town Map location is set (no renaming needed)
    if data.town_map_location.nil?
      data.town_map_location = [region_id, ev.x, ev.y]
    end

    # Reset to empty planting state, then plant a random berry
    data.reset(true)
    berry = berry_ids[rand(berry_ids.length)]
    data.plant(berry)

    # Randomize growth stage & internal timers
    plant_def   = GameData::BerryPlant.get(berry)
    # Fallback hours_per_stage if missing (shouldn't be)
    hps         = plant_def ? plant_def.hours_per_stage : 12
    time_per    = (hps * 3600)
    time_per    = 3600 if time_per < 3600

    max_stage = GameData::BerryPlant::NUMBER_OF_GROWTH_STAGES +
                GameData::BerryPlant::NUMBER_OF_FULLY_GROWN_STAGES
    stage     = rand(max_stage) + 1
    time_in   = rand(time_per)

    data.instance_variable_set(:@growth_stage, stage)
    data.instance_variable_set(:@time_in_stage, time_in)
    data.instance_variable_set(:@time_alive, ((stage - 1) * time_per) + time_in)
    data.instance_variable_set(:@time_last_updated, now)

    # Keep moisture healthy if variable exists
    if data.instance_variable_defined?(:@moisture_level)
      data.instance_variable_set(:@moisture_level, 100)
    end

    seeded += 1
  end

  pbMessage(_INTL("Filled {1} berry plots with random plants!", seeded)) if seeded > 0
end



# Update plant_zone / soil_type for a set of BerryPlant events (or all),
# without resetting or harming existing plants.
def pbSetBerryZones(event_ids = nil, zone: nil, soil: nil)
  ids = event_ids || $game_map.events.values.select { |e| e.name =~ /\ABerryPlant\b/i }.map(&:id)
  ids.each do |eid|
    data = $PokemonGlobal.eventvars[[$game_map.map_id, eid]]
    next unless data.is_a?(BerryPlantData)
    data.plant_zone = zone if zone
    data.soil_type  = soil if soil
    # Keep Town Map location current (safe no-op if already set)
    region_id = 0
    ev = $game_map.events[eid]
    data.town_map_location = [region_id, ev.x, ev.y]
  end
end

# Example seasonal mapping; tweak names to match your PBS zones.
SEASON_ZONES = {
  0 => "SpringFarm",  # spring
  1 => "SummerFarm",  # summer
  2 => "AutumnFarm",  # fall
  3 => "WinterFarm"   # winter
}

def pbApplySeasonalZones(event_ids = nil, soil: nil)
  pbClearBerryTimeDelta()
  season = pbGetSeason
  zone   = SEASON_ZONES[season]
  pbSetBerryZones(event_ids, zone: zone, soil: soil)
end


#===============================================================================
# Watering sprites, Seed check
#===============================================================================

module GameData
    class PlayerMetadata

        alias tdw_berry_improvements_player_met_init initialize
        def initialize(hash)
            tdw_berry_improvements_player_met_init(hash)
            init_berry_watering
        end

        def init_berry_watering
            @watering_charset = Settings::BERRY_WATERING_SPRITES[@id-1]
        end

        def watering_charset
            @watering_charset ||= Settings::BERRY_WATERING_SPRITES[@id-1] || nil
            return @watering_charset
        end

    end

    class Item
        def is_berry_seed?; return has_flag?("BerrySeed"); end

        def can_plant?
            return false if has_flag?("NoPlant")
            return true
        end
    end
end

class Game_Player < Game_Character
    attr_reader :berry_watering

    alias tdw_berry_improvements_player_refresh_charset refresh_charset
    def refresh_charset
        tdw_berry_improvements_player_refresh_charset unless @berry_watering
    end

    def set_watering_charset(used_can)
        meta = GameData::PlayerMetadata.get($player&.character_ID || 1)
        @berry_watering = true
        new_charset = pbGetPlayerCharset(meta.watering_charset)
        if new_charset
            possible = new_charset + get_pail_image(used_can) if pbResolveBitmap("Graphics/Characters/" + new_charset + get_pail_image(used_can))
            @character_name = possible || new_charset
        end
        @step_anime = true
    end

    def stop_watering_charset
        @berry_watering = false
        @step_anime = false
        @pattern = @original_pattern
        @anime_count = 0
        refresh_charset
    end

    def get_pail_image(used_can)
        image = ""
        if used_can && $bag.has?(used_can)
            image = "_" + used_can.to_s
        else
            GameData::BerryPlant::WATERING_CANS.each do |item|
                next if !$bag.has?(item)
                    image = "_" + item.to_s
                break
            end
        end
        return image
    end

end

def pbDebugListBerryPlants(map_id = $game_map.map_id)
  return unless $PokemonGlobal && $PokemonGlobal.eventvars
  total = 0
  puts "=== BerryPlants on Map #{map_id} (#{pbGetBasicMapNameFromId(map_id) rescue ""}) ==="
  $game_map.events.each_value do |ev|
    next unless ev.name =~ /\ABerryPlant\b/i
    key  = [$game_map.map_id, ev.id]
    data = $PokemonGlobal.eventvars[key]
    unless data.is_a?(BerryPlantData)
      # Initialize missing data so we can inspect it
      data = BerryPlantData.new(ev)
      $PokemonGlobal.eventvars[key] = data
    end
    total += 1

    zone   = (data.respond_to?(:plant_zone) && data.plant_zone) ? data.plant_zone : "(none)"
    soil   = if data.instance_variable_defined?(:@soil) && data.instance_variable_get(:@soil).is_a?(Hash)
               (data.instance_variable_get(:@soil)[:id] rescue nil) || "(none)"
             else
               "(none)"
             end
    berry  = (data.respond_to?(:berry_id) ? data.berry_id : nil) || "(empty)"
    stage  = (data.instance_variable_defined?(:@growth_stage) ? data.instance_variable_get(:@growth_stage) : nil) || 0
    moist  = (data.instance_variable_defined?(:@moisture_level) ? data.instance_variable_get(:@moisture_level) : nil)
    weeds  = (data.instance_variable_defined?(:@weeds) ? data.instance_variable_get(:@weeds) : false)
    pests  = (data.instance_variable_defined?(:@pests) ? data.instance_variable_get(:@pests) : false)
    ypen   = (data.instance_variable_defined?(:@yield_penalty) ? data.instance_variable_get(:@yield_penalty) : 0)
    wither = (data.instance_variable_defined?(:@withered_item) ? data.instance_variable_get(:@withered_item) : nil)

    tmloc  = if data.respond_to?(:town_map_location) && data.town_map_location
               data.town_map_location.join(",")
             else
               "(nil)"
             end

    puts sprintf(
      "ID:%-3d XY:(%2d,%2d) Zone:%-12s Soil:%-10s Berry:%-14s Stage:%-2d Moist:%-3s Weeds:%-5s Pests:%-5s YPen:%-2d Withered:%s TMap:[%s]",
      ev.id, ev.x, ev.y, zone.to_s, soil.to_s, berry.to_s, stage, (moist.nil? ? "-" : moist.to_s),
      weeds ? "yes" : "no", pests ? "yes" : "no", ypen, (wither || "-").to_s, tmloc
    )
  end
  puts "=== Total BerryPlants found: #{total} ==="
  pbMessage(_INTL("{1} BerryPlants listed in console.", total))
end

# ===== Universal safe fetch/normalize for BerryData fields (RMXP/Ruby 1.8 safe) =====
module TDW_BerrySafe
  # Return BerryData or nil (no exceptions)
  def self.berry_data(berry_id)
    begin
      GameData::BerryData.try_get(berry_id)
    rescue
      nil
    end
  end

  # Normalize anything to a downcased Symbol (or nil)
  def self.norm_sym(x)
    return nil if x.nil?
    begin
      s = x.is_a?(Symbol) ? x.to_s : x.to_s
      s = s.strip.gsub(/\s+/, "")
      s.downcase.to_sym
    rescue
      nil
    end
  end

  # Get a normalized array from a BerryData list field (e.g., :preferred_zones, :preferred_weather)
  def self.list(data, meth)
    return [] unless data && data.respond_to?(meth)
    raw = data.send(meth) rescue nil
    return [] if !raw || (raw.respond_to?(:empty?) && raw.empty?)
    arr = []
    # Essentials older Ruby: no map(&:to_sym), do it manually
    for v in raw
      ns = self.norm_sym(v)
      arr << ns if ns
    end
    arr
  end

  # Safe equality for single-valued fields (e.g., :preferred_soil)
  def self.equals?(data, meth, value)
    return false unless data && data.respond_to?(meth)
    lhs = data.send(meth) rescue nil
    return false if lhs.nil? || value.nil?
    self.norm_sym(lhs) == self.norm_sym(value)
  end

  # Safe include? check for list fields
  def self.includes?(data, meth, value)
    return false if value.nil?
    lst = self.list(data, meth)
    return false if lst.empty?
    lst.include?(self.norm_sym(value))
  end
end
