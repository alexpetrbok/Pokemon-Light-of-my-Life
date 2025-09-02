#===============================================================================
# NPC Logic - Interaction, Affection, Gifts, Activity, Work
#===============================================================================

module NPCSystem
  @affection_data = {}
  @relationship_state_data = {}
  @state_data = {}
  @daily_interacted = {}
  @daily_gifts = {}
  @daily_gifts_detailed = {}

    # --- id normalization (so symbols/strings behave) ---
  def self._key(id)
    return nil if id.nil?
    id.is_a?(Symbol) ? id : id.to_s.upcase.to_sym
  end

  # --- quick seeding defaults (only if you want a default) ---
  def self._ensure_defaults(id)
    k = _key(id)
    @affection_data[k]           = 50        unless @affection_data.key?(k)
    @relationship_state_data[k]  = :single  unless @relationship_state_data.key?(k)
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

  # ---------- Relationship State ----------
  # valid examples: :single, :dating_player, :married_player
  def self.relationship_state(npc_id)
    k = _ensure_defaults(npc_id)
    @relationship_state_data[k]
  end

  def self.set_relationship_state(npc_id, state_sym)
    k = _ensure_defaults(npc_id)
    @relationship_state_data[k] = (state_sym || :single).to_sym
  end

  # Convenience checks
  def self.single?(npc_id)         = relationship_state(npc_id) == :single
  def self.dating_player?(npc_id)  = relationship_state(npc_id) == :dating_player
  def self.married_player?(npc_id) = relationship_state(npc_id) == :married_player

  # ---------- Behavior / Schedule State ----------
  # examples: :idle, :work, :home, :leisure, :social, :sleep
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

  def self.reset_daily_interactions
    @daily_interacted.clear
  end

  # ---------- Daily Gifts ----------
  def self.track_gift_given(npc_id, weight = 1, item: nil)
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
    (@daily_gifts[npc_id] || 0) >= 5
  end


  def self.reset_daily_gifts
    # PLACEHOLDER: Overnight “thank-you mail” chance for important gifts.
    # Example heuristic: if any entry has weight >= 2 (evo stones/fossils/expensive),
    # roll a small chance to queue mail from this NPC for tomorrow morning.
    # @daily_gifts_detailed.each do |npc_key, entries|
    #   next if entries.nil? || entries.empty?
    #   important = entries.any? { |e| e[:weight].to_i >= 2 }
    #   if important && rand(100) < 20
    #     # TODO: enqueue_thank_you_mail(npc_key)  # your mail system hook
    #   end
    # end

    @daily_gifts.clear
    @daily_gifts_detailed.clear
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
                when :Dating_Player then 2
                when :Married_Player then 3
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
    track_gift_given(npc_id, gift_weight, GameData::Item.get(item).name)
    add_affection(npc_id, total_affection)
    $bag.remove(item)
    pbShowItemDisplay(item, -1)
  end

  # Placeholder - called once per day per NPC
  def self.daily_npc_update
    reset_daily_interactions
    reset_daily_gifts
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

      

      # Activities only if at home or leisure
      if [:home, :leisure].include?(npc.state)
        choices << "Spend Time"
        actions << -> { show_dialog(npc.id, :activity) }
      end
      # Activities if at home or leisure
      if [:home, :leisure].include?(npc.state)
        choices << "Spend Time"
        actions << -> {
          # DEBUG: placeholder for activity scene start (e.g., minigame, timed hangout)
          # start_activity_scene(npc.id)
          show_dialog(npc.id, :activity)
        }

        # NEW — Date option appears when dating (you can add an affection floor if desired)
        if npc.dating_player?
          choices << "Date"
          actions << -> {
            # DEBUG: placeholder date scene trigger
            # start_date_scene(npc.id)
            show_dialog(npc.id, :date)
          }
        end
      end

      # if quest_active?(:gardener_help)
      #   choices << "Ask about Garden"
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

    state_key = npc.state.to_sym rescue :default
    dialog_set = dialog[state_key] || dialog[:default]
    unless dialog_set
      puts "⚠️ No dialog for state :#{state_key} or :default for #{npc.id}"
      return
    end

    type_dialog = dialog_set[type]
    unless type_dialog.is_a?(Array) && !type_dialog.empty?
      puts "⚠️ No dialog of type :#{type} for #{npc.id} in state :#{state_key}"
      return
    end

    # Decide menu vs. linear: if any entry has :prompt, treat as a menu
    uses_menu = type_dialog.any? { |entry| entry.key?(:prompt) }

    if uses_menu
      choices = type_dialog.map { |entry| entry[:prompt] }
      choices << "[Back]"

      loop do
        choice = pbMessage("What do you want to choose?", choices)
        break if choice < 0 || choices[choice] == "[Back]"

        selected = type_dialog[choice]
        if selected[:response]
          pbMessage(selected[:response])
        else
          puts "⚠️ Missing response for prompt: #{selected[:prompt]}"
        end

        # Optional line-level script hook (e.g., open shop)
        if selected[:script].respond_to?(:call)
          # DEBUG: running attached script for this entry
          selected[:script].call
        end
      end
    else
      # Linear display expects :text entries
      type_dialog.each do |entry|
        pbMessage(entry[:text]) if entry[:text]
        # Optional script after a text line
        if entry[:script].respond_to?(:call)
          # DEBUG: running attached script after linear text
          entry[:script].call
        end
      end
    end
  end



  def self.do_activity(npc_id)
    # Placeholder - perform an activity with this NPC
    pbMessage("You spent some time with #{GameData::NPC.try_get(npc_id).name}.")
    update_affection(npc_id, 2)
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

  def self.daily_schedule_update
    NPCSystem.daily_npc_update
    #GameData::NPC.each do |npc|
      #NPCSystem.daily_npc_update(npc.id)
      #run_schedule_for(npc.id)
    #end
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

      dialog_hash.each do |state, dialogs|
        npc.dialog[state] ||= {}
        dialogs.each do |type, entries|
          npc.dialog[state][type] ||= []
          npc.dialog[state][type].concat(entries)
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
