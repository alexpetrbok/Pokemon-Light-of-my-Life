#===============================================================================
# NPC Logic - Interaction, Affection, Gifts, Activity, Work
#===============================================================================
SPOUSE_PAIRS = [
  [:POKECAFE, :ENGINEER, 100],
  [:RANCHER, :GARDENER, 30],
  [:LIBRARIAN, :BIRDKEEPER, 75],
  [:MUSHROOM, :BUGCATCHER, 120],
  [:BLACKSMITH, :DIVER, 75],
  [:ADVENTURER, :BEAUTY, 50],
  [:PAINTER, :SEAMSTRESS, 900]
  ]


module NPCSystem
  @affection_data = {}
  @relationship_state_data = {}
  @affection_spouse_pairs = {}   
  @spouse_affection_data  = {}
  @state_data = {}
  @daily_interacted = {}
  @daily_gifts = {}
  @daily_gifts_detailed = {}

  SPOUSE_DATE_THRESHOLD   = 300
  SPOUSE_MARRY_THRESHOLD  = 900

    # --- id normalization (so symbols/strings behave) ---
  def self._key(id)
    return nil if id.nil?
    id.is_a?(Symbol) ? id : id.to_s.upcase.to_sym
  end

  # --- quick seeding defaults (only if you want a default) ---
  def self._ensure_defaults(id)
    k = _key(id)
    @affection_data[k]           = 50        unless @affection_data.key?(k)
    @relationship_state_data[k]  = :Single  unless @relationship_state_data.key?(k)
    @state_data[k]               = :work    unless @state_data.key?(k)
    k
  end

  def self.bootstrap_minimal!
    GameData::NPC.each { |npc| _ensure_defaults(npc.id) }
  end

  # ---------- Affection ----------
  def self.affection(npc_id)
    k = _ensure_defaults(npc_id)
    @affection_data[k]
  end

  def self.set_affection(npc_id, value)
    k = _ensure_defaults(npc_id)
    @affection_data[k] = value.to_i
  end

  def self.add_affection(npc_id, amount)
    k = _ensure_defaults(npc_id)
    @affection_data[k] += amount.to_i
  end

  def self.spouse_affection(npc_id)
    k = _ensure_defaults(npc_id)
    @spouse_affection_data[k] ||= 0
    @spouse_affection_data[k]
  end

  def self.set_spouse_affection(npc_id, value)
    k = _ensure_defaults(npc_id)
    @spouse_affection_data[k] = value.to_i
  end

  def self.add_spouse_affection(npc_id, amount)
    k = _ensure_defaults(npc_id)
    @spouse_affection_data[k] ||= 0
    @spouse_affection_data[k] += amount.to_i
  end

  # ---------- Relationship State ----------
  # valid examples: :single, :dating_player, :married_player
  def self.relationship_state(npc_id)
    k = _ensure_defaults(npc_id)
    @relationship_state_data[k]
  end

  def self.set_relationship_state(npc_id, state_sym)
    k = _ensure_defaults(npc_id)
    @relationship_state_data[k] = (state_sym || :none).to_sym
  end

  # Convenience checks
  def self.single?(npc_id)         = relationship_state(npc_id) == :Single
  def self.dating_player?(npc_id)  = relationship_state(npc_id) == :Dating_Player || relationship_state(npc_id) == :Married_Player
  def self.married_player?(npc_id) = relationship_state(npc_id) == :Married_Player
  def self.dating_spouse?(npc_id)  = relationship_state(npc_id) == :Dating_Spouse || relationship_state(npc_id) == :Married_Spouse
  def self.married_spouse?(npc_id) = relationship_state(npc_id) == :Married_Spouse

  # ---------- Behavior / Schedule State ----------
  # examples: :idle, :work, :home, :leisure, :social, :sleep
  # Leisure/free states you’ll use in schedules
  FREE_STATES = [:leisure, :fish, :swim, :home, :walk]

  def self.free_state?(state_sym)
    FREE_STATES.include?(state_sym.to_sym)
  end
  
  def self.state(npc_id)
    k = _ensure_defaults(npc_id)
    @state_data[k]
  end

  def self.set_state(npc_id, state_sym)
    k = _ensure_defaults(npc_id)
    @state_data[k] = (state_sym || :idle).to_sym
  end

  # ---------- Daily Interaction ----------
  def self.daily_interaction(npc_id)
    k = _key(npc_id)
    unless interacted_today?(k)
      add_affection(k, 4)
      # DEBUG: First talk today → small affection bonus applied
      set_interacted_today(k)
    end
  end
  
  def self.interacted_today?(npc_id)
    @daily_interacted[_key(npc_id)] == true
  end

  def self.set_interacted_today(npc_id)
    @daily_interacted[_key(npc_id)] = true
  end


  def self.current_season_symbol
    case pbGetSeason
      when 0 then :spring
      when 1 then :summer
      when 2 then :autumn
      when 3 then :winter
      else nil
    end
  end

  def self.nightly_npc_update
    @daily_interacted     ||= {}
    @daily_gifts          ||= {}
    @daily_gifts_detailed ||= {}
    @daily_interacted.clear
    @daily_gifts.clear
    @daily_gifts_detailed.clear
    overnight_spouse_affection
    puts "🧠 NPC daily update complete."
  end

  def self.overnight_spouse_affection
    SPOUSE_PAIRS.each do |npc1_id, npc2_id, num|
      a = _key(npc1_id)
      b = _key(npc2_id)
      next unless a && b

      base = rand(2..5)
      base -= 1 if dating_player?(a) || dating_player?(b)
      base -= 1 if affection(a) > spouse_affection(a) || affection(b) > spouse_affection(b)
      base += 3 if dating_spouse?(a) || dating_spouse?(b)

      add_spouse_affection(a, base)
      add_spouse_affection(b, base)

      if spouse_affection(a) >= SPOUSE_DATE_THRESHOLD && single?(a) && single?(b)
        set_relationship_state(a, :Dating_Spouse)
        set_relationship_state(b, :Dating_Spouse)
        puts "💞 #{GameData::NPC.try_get(a).name} and #{GameData::NPC.try_get(b).name} are now dating!"
      end
      if spouse_affection(a) >= SPOUSE_MARRY_THRESHOLD && dating_spouse?(a) && dating_spouse?(b) && !married_spouse?(a) && !married_spouse?(b)
        set_relationship_state(a, :Married_Spouse)
        set_relationship_state(b, :Married_Spouse)
        puts "💍 #{GameData::NPC.try_get(a).name} and #{GameData::NPC.try_get(b).name} are now married!"
      end
    end
  end

  def self.seed_NPCs
    a= _key(:MIKU)
    set_relationship_state(a, :Single)
    set_spouse_affection(a, 10)
    SPOUSE_PAIRS.each do |npc1_id, npc2_id, num|
      a = _key(npc1_id)
      b = _key(npc2_id)
      next unless a && b && num

      set_spouse_affection(a, num)
      set_spouse_affection(b, num)

      if npc1_id == :PAINTER
        set_relationship_state(a, :Married_Spouse)
        set_relationship_state(b, :Married_Spouse)
      else
        set_relationship_state(a, :Single)
        set_relationship_state(b, :Single)
      end
      puts "💞 Seeded #{GameData::NPC.try_get(a).name} and #{GameData::NPC.try_get(b).name} with #{num} spouse affection."
    end
  end

  # ---------- Daily Gifts ----------
  def self.track_gift_given(npc_id, weight = 1, item=nil)
    k = _key(npc_id)
    @daily_gifts[k] ||= 0
    @daily_gifts[k] += weight.to_i

    if (weight>1) && !item.nil?
      puts "⚠️ Warning: Important gift given!"
      @daily_gifts_detailed[k] ||= []
      @daily_gifts_detailed[k] << {
        item:   item,            # Symbol (e.g., :LAVACOOKIE)
        weight: weight.to_i,     # our gift weighting
      }
    end
  end

  def self.gift_count(npc_id)
    @daily_gifts[_key(npc_id)] || 0
  end

  def self.gift_limit_reached?(npc_id)
    (@daily_gifts[_key(npc_id)] || 0) >= 5
  end

  def self.gift_type_weight(item)
    data = GameData::Item.get(item)
    return 2 if data.is_evolution_stone? || data.is_fossil? || data.price >= 3000
    1
  end

  def self.give_gift(npc_id)
    npc = GameData::NPC.try_get(npc_id)
    return unless npc

  
    item = pbChooseItem
    return unless item

    # Relationship item logic
    if item == :STARPIECENECKLACE
      if affection(npc_id) > 200 && npc.relationship_state == :Single
        npc.relationship_state = :Dating_Player
        pbMessage("#{npc.name} accepts the Starpiece Necklace. You're now dating!")
      else 
        pbMessage("#{npc.name} doesn't feel ready for something that serious...")
        return
      end
    elsif item == :SOULDEWRING
      if affection(npc_id) > 700 && npc.relationship_state == :Dating_Player
        npc.relationship_state = :Married_Player
        pbMessage("#{npc.name} accepts the Souldew Ring. You're going to get married!")
      else
        pbMessage("#{npc.name} looks away... This moment isn't right.")
        return
      end
    end

    return if GameData::Item.get(item).is_important?

    gift_weight = gift_type_weight(item)
    if gift_limit_reached?(npc_id) || (@daily_gifts[npc_id] || 0) + gift_weight > 5
      pbMessage("You've already given too many gifts today.")
      return
    end

    # Calculate affection
    base_affection = npc.fav_gifts[item] || (npc.bad_gifts[item] ? -2 : 1)

    # Relationship multiplier
    multiplier = case npc.relationship_state
                when :Dating_Player then 1.5
                when :Married_Player then 2
                else 1
                end

    total_affection = base_affection * multiplier

    # Gift limit tracking
    weight = gift_type_weight(item)
    if gift_limit_reached?(npc_id) || (@daily_gifts[npc_id] || 0) + weight > 5
      pbMessage("You've already given too many gifts today.")
      return
    end

    # Give gift
    pbMessage("#{npc.name} accepts your #{GameData::Item.get(item).name}!")
    #track_gift_given(npc_id, gift_weight, GameData::Item.get(item).name)
    track_gift_given(npc_id, gift_weight, item)
    add_affection(npc_id, total_affection)
    $bag.remove(item)
    pbShowItemDisplay(item, -1)
  end


  def self.talk_to(npc_input)
    npc = npc_input.is_a?(Symbol) || npc_input.is_a?(String) ? GameData::NPC.try_get(npc_input.to_sym) : npc_input
    return unless npc

    show_dialog(npc.id, :opener)
    npc_main_loop(npc)
    show_dialog(npc.id, :closer)
  end

  def self.npc_main_loop(npc)
    loop do
      choices = []
      actions = []

      # Shop only if working
      if npc.state == :work
        choices << "Shop"
        actions << -> { show_dialog(npc.id, :shop) }
      end

      # Always available
      choices << "Chat"
      actions << -> { show_dialog(npc.id, :chat) }

      choices << "Give Gift"
      actions << -> { give_gift(npc.id) }

      
      # Activities if at home or leisure
      if [:home, :leisure].include?(npc.state)
        choices << "Activities"
        actions << -> {show_dialog(npc.id, :activity)}
        

        # NEW — Date option appears when dating (you can add an affection floor if desired)
        if npc.dating_player?
          choices << "Date"
          actions << -> {show_dialog(npc.id, :date)}
        end
      end

      # if quest_active?(:gardener_help)
      #   choices << "Quest"
      #   actions << -> { show_dialog(npc.id, :quest) }
      # end

      choices << "[Back]"
      choice = pbMessage("What would you like to do?", choices)
      break if choice == choices.size - 1 || choice < 0

      action = actions[choice]
      if action
        action.call
      else
        puts "⚠️ No action bound for choice index #{choice} (#{choices[choice]})"
      end
    end
  end


  def self.show_dialog(npc_input, type)
    npc = npc_input.is_a?(Symbol) || npc_input.is_a?(String) ? GameData::NPC.try_get(npc_input.to_sym) : npc_input
    unless npc
      puts "❌ NPC not found: #{npc_input.inspect}"
      return
    end

    dialog = npc.dialog
    unless dialog.is_a?(Hash)
      puts "❌ No dialog hash found for #{npc.id}"
      return
    end

    state_key = npc.state.to_s.downcase.to_sym
    relation_key = npc.relationship_state.to_s.downcase.to_sym
    season_key = current_season_symbol
    free_now   = free_state?(state_key)

    # ----- gather candidate lists by source priority -----
    # 1) state bucket
    state_list = (dialog[state_key] && dialog[state_key][type]).is_a?(Array) ? dialog[state_key][type] : []

    # 2) relationship state bucket
    relation_list = (dialog[relation_key] && dialog[relation_key][type]).is_a?(Array) ? dialog[relation_key][type] : []

    # 2) seasonal add-on to default
    season_list = (season_key && dialog[season_key] && dialog[season_key][type]).is_a?(Array) ? dialog[season_key][type] : []

    # 3) default bucket
    default_list = (dialog[:default] && dialog[:default][type]).is_a?(Array) ? dialog[:default][type] : []

    # nothing at all?
    if state_list.empty? && season_list.empty? && default_list.empty? && relation_list.empty?
      puts "⚠️ No dialog of type :#{type} for #{npc.id} (state=#{state_key}, season=#{season_key || :none})"
      return
    end

    # ----- helpers: condition check + weighting -----
    condition_true_weight  = 6   # favor entries with :condition == true
    condition_nil_weight   = 1   # neutral entries with no :condition
    source_state_weight    = 6   # source priority: state > seasonal-default > default
    source_season_weight   = 4
    source_default_weight  = 1

    eval_condition = lambda do |entry|
      return false if entry.nil?
      cond = entry[:condition]
      return false if cond == false
      return true  if cond.nil?
      return !!cond.call if cond.respond_to?(:call)
      !!cond
    end

    entry_weight = lambda do |entry, source_weight|
      base = eval_condition.call(entry) ? condition_true_weight : condition_nil_weight
      base + source_weight
    end

    # decide menu vs linear from the highest-priority non-empty list
    head = !state_list.empty? ? state_list : (!season_list.empty? ? season_list : default_list)
    uses_menu = head.any? { |e| e.is_a?(Hash) && e.key?(:prompt) }

    # ----- MENU MODE -----
    if uses_menu
      # build the full candidate pool (order matters for tiebreak randomness)
      pool = []
      state_list.each               { |e| pool << [e, source_state_weight] }
      relation_list.each               { |e| pool << [e, source_state_weight] }
      season_list.each    { |e| pool << [e, source_season_weight] }
      default_list.each             { |e| pool << [e, source_default_weight] }

      # filter out false conditions
      pool.select! { |(e, _)| e.is_a?(Hash) && e[:prompt] && eval_condition.call(e) }


      if pool.empty?
        puts "⚠️ No valid menu entries for :#{type} (conditions filtered) on #{npc.id}"
        return
      end

      # pagination / cycling
      seen = {}
      pool = pool.reject do |(e, _)|
        key = e[:prompt].to_s
        dup = seen[key]
        seen[key] = true
        dup
      end

      # score once and sort once to get a STABLE order for paging
      scored_sorted = pool.map { |(e, srcw)| [e, entry_weight.call(e, srcw), srcw] }
                          .sort_by { |(_e, w, _)| -w } # high weight first

      # 2) Page through in slices of MENU_PAGE_SIZE
      total_items = scored_sorted.length
      start_index = 0

      loop do
        page = scored_sorted.slice(start_index, 5) || []
        visible_entries = page.map(&:first)

        remaining = total_items - (start_index + 5)
        remaining = 0 if remaining < 0

        choices = visible_entries.map { |e| e[:prompt] }
        # add pager if more remain
        choices << "[More]" if remaining > 0
        choices << "[Back]"

        # input
        idx = pbMessage("What do you want to choose?", choices)
        break if idx < 0 || choices[idx] == "[Back]"

        if remaining > 0 && choices[idx] == "[More]"
          start_index += 5
          # wrap-around: once we reach the end, cycle back to the beginning
          start_index = 0 if start_index >= scored_sorted.size
          next
        end

        # resolve selected entry
        selected_entry = visible_entries[idx]
        unless selected_entry
          puts "⚠️ Menu index out of range (idx=#{idx}) for #{npc.id}"
          next
        end

        pbMessage(selected_entry[:response]) if selected_entry[:response]
        if selected_entry[:script].respond_to?(:call)
          # DEBUG: running attached script for this menu entry
          selected_entry[:script].call
        end
      end
      return
    end

    # ----- LINEAR MODE -----
    # Merge all three sources; seasonal/default carry lower weights.
    candidates = []
    state_list.each            { |e| candidates << [e, source_state_weight] }
    season_list.each { |e| candidates << [e, source_season_weight] }
    default_list.each          { |e| candidates << [e, source_default_weight] }

    valid = candidates.select { |(e, _)| e.is_a?(Hash) && (e[:text] || e[:script]) && eval_condition.call(e) }
    if valid.empty?
      puts "⚠️ No valid linear entries for :#{type} on #{npc.id}"
      return
    end

    # DEBUG: see where linear entries are coming from
    puts "DEBUG LINEAR pool sizes: state=#{state_list.length}, relationship=#{relation_list.length} seasonal=#{season_list.length}, default=#{default_list.length}, valid=#{valid.length}"

    # weighted random across merged pool
    weights = valid.map { |(e, srcw)| entry_weight.call(e, srcw) }
    total   = [weights.sum, 1].max
    roll    = rand(total)
    acc     = 0
    pick_i  = 0
    weights.each_with_index do |w, i|
      acc += w
      if roll < acc
        pick_i = i
        break
      end
    end

    entry, _srcw = valid[pick_i]
    pbMessage(entry[:text]) if entry[:text]
    if entry[:script].respond_to?(:call)
      # DEBUG: running attached script after linear text
      entry[:script].call
    end
  end



  def self.do_activity(npc_id)
    # Placeholder - perform an activity with this NPC
    pbMessage("You spent some time with #{GameData::NPC.try_get(npc_id).name}.")
    update_affection(npc_id, 8)
  end



  #===============================================================================
  # NPC Scheduling and Spawning
  #===============================================================================
  def self.spawn_npc(map_id, event_id, sprite, x, y)
    map = $MapFactory.getMap(map_id)
    event = map.events[event_id]
    return unless event

    event.character_name = sprite
    event.moveto(x, y)
    event.through = false
    event.transparent = false
  end


  def get_schedule_for_today(npc)
    season = $game_variables[SEASON_VAR].downcase.to_sym         # e.g., :spring
    day = $game_variables[DAY_VAR]                               # e.g., 17
    weekday = pbGetDayOfWeekName.downcase.to_sym                # e.g., :monday

    keys = [
      :"#{season}_#{day}",       # :spring_17
      :"#{season}_#{weekday}",   # :spring_monday
      weekday,                   # :monday
      :default
    ]

    keys.each do |key|
      return npc.schedule[key] if npc.schedule.has_key?(key)
    end

    {}
  end


  def npc_in_state?(npc, state)
    schedule = get_schedule_for_today(npc)
    return false if schedule.empty?

    current_hour = pbGetTimeNow.hour

    # Get the last activity that started before or at the current hour
    active_state = schedule
      .select { |hour, _| hour <= current_hour }
      .max_by { |hour, _| hour }
      &.last || :idle

    return active_state == state
  end

end

def debug_set_all_npcs_relationship
  affection_levels = {
    "💙 50 (Acquaintance)" => 50,
    "💖 300 (Dating Threshold)" => 300,
    "💍 950 (Marriage Threshold)" => 950
  }

  relationship_states = {
    "🔓 Single" => :Single,
    "💞 Dating Player" => :Dating_Player,
    "💘 Dating Spouse (Other)" => :Dating_Spouse,
    "💍 Married Player" => :Married_Player,
    "💔 Married Spouse (Other)" => :Married_Spouse
  }

  aff_choice = pbMessage("Set affection to:", affection_levels.keys)
  return if aff_choice < 0
  aff_value = affection_levels.values[aff_choice]

  state_choice = pbMessage("Set relationship state to:", relationship_states.keys)
  return if state_choice < 0
  state_value = relationship_states.values[state_choice]

  GameData::NPC.each do |npc|
    NPCSystem.set_affection(npc.id, aff_value)
    npc.relationship_state = state_value
  end

  $bag.add(:STARPIECENECKLACE, 5)
  $bag.add(:SOULDEWRING, 5)

  pbMessage("All NPCs updated: Affection = #{aff_value}, State = #{state_value}")
end


#===============================================================================
# NPC Data Definitions
#===============================================================================
module GameData
  class NPC
    @@data = {}
    @@dialogs = {}

    attr_reader :id, :name, :birthday
    attr_accessor :spouse, :schedule,  :dialog
    attr_accessor :fav_gifts, :bad_gifts, :log

    def initialize(hash)
      @id                 = hash[:id].to_sym
      @name               = hash[:name]
      @birthday           = hash[:birthday]
      @spouse             = hash[:spouse]
      @fav_gifts          = hash[:fav_gifts] || {}
      @bad_gifts          = hash[:bad_gifts] || {}
      @schedule           = hash[:schedule] || {}
      @dialog             = hash[:dialog] || {}
      @log                = {}
    end

    def affection
      NPCSystem.affection(@id)
    end

    def affection=(val)
      NPCSystem.set_affection(@id, val)
    end

    def add_affection(delta)
      NPCSystem.add_affection(@id, delta)
    end

    def spouse_affection
      NPCSystem.spouse_affection(@id)
    end

    def spouse_affection=(val)
      NPCSystem.set_spouse_affection(@id, val)
    end

    def add_spouse_affection(delta)
      NPCSystem.add_spouse_affection(@id, delta)
    end

    # Relationship
    def relationship_state
      NPCSystem.relationship_state(@id)
    end

    def relationship_state=(sym)
      NPCSystem.set_relationship_state(@id, sym)
    end

    def single?         = NPCSystem.single?(@id)
    def dating_player?  = NPCSystem.dating_player?(@id)
    def married_player? = NPCSystem.married_player?(@id)

    # Behavior / schedule state
    def state
      NPCSystem.state(@id)
    end

    def state=(sym)
      NPCSystem.set_state(@id, sym)
    end

    # --- Class methods for managing NPCs ---
    def self.register(hash)
      npc = new(hash)
      @@data[npc.id] = npc
    end

    def self.get(id)
      try_get(id)
    end

    def self.try_get(id)
      return nil if id.nil?
      key = (id.is_a?(Symbol) ? id : id.to_s.upcase.to_sym)
      @@data[key]
    end


    def self.each(&block)
      @@data.each_value(&block)
    end

    def self.clear
      @@data.clear
    end

    def self.keys
      @@data.keys
    end
 
#===============================================================================
# NPC Dialog
#===============================================================================

    def self.set_dialog(id, dialog_hash)
      npc = try_get(id)
      return unless npc

      npc.dialog ||= {}

      dialog_hash.each do |state, types_hash|
        next unless types_hash.is_a?(Hash)
        st = state.to_sym
        npc.dialog[st] ||= {}

        types_hash.each do |type, entries|
          typ = type.to_sym
          entries = [entries] if entries.is_a?(Hash)     # coerce single entry
          npc.dialog[st][typ] ||= []
          npc.dialog[st][typ].concat(entries)
        end
      end
    end




    def self.load
      @@data.clear
      load_npcs
    end


    def self.exists?(id)
      @@data.key?(id)
    end

    def self.dialog_for(symbol)
      @@dialogs[symbol]
    end
  end
end


def pbNPC(id, interaction_type = :talk)
  npc = GameData::NPC.get(id)
  return pbMessage("That NPC doesn't exist.") unless npc

  # Show portraits
  portrait = "#{npc.id}_#{npc.state}".upcase
  unless pbResolveBitmap("Graphics/Trainers/#{portrait}")
    portrait = npc.id
  end
  Rf.new_portrait(portrait)

  # Handle daily affection bonus
  NPCSystem.daily_interaction(id)
  
  NPCSystem.talk_to(npc)

  # Close portraits
  Rf.close_portrait
end

def debug_print_all_npcs
  puts "🧠 DEBUG: All Loaded NPC Data"
  GameData::NPC.each do |npc|
    puts "--------------------------------------"
    puts "🆔 ID: #{npc.id}"
    puts "👤 Name: #{npc.name}"
    puts "🎂 Birthday: #{npc.birthday}"
    puts "❤️ Spouse: #{npc.spouse}"
    puts "💌 Affection: #{npc.affection}"
    puts "🧠 State: #{npc.state}"
    puts "🎭 Relationship State: #{npc.relationship_state}"
    puts "🎁 Fav Gifts: #{npc.fav_gifts.inspect}"
    puts "❌ Bad Gifts: #{npc.bad_gifts.inspect}"
    puts "📋 Schedule: #{npc.schedule.inspect}"
    puts "💬 Dialog States:"
    if npc.dialog
      npc.dialog.each do |state, types|
        puts "  ▪ State: #{state}"
        types.each do |type, entries|
          puts "    ▶ #{type}:"
          entries.each_with_index do |entry, idx|
            preview = entry[:text] || entry[:prompt]
            puts "      #{idx + 1}. #{preview.inspect}"
          end
        end
      end
    else
      puts "  ⚠️ No dialog found."
    end
  end
end
