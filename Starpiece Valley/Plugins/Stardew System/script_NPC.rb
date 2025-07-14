#===============================================================================
# NPC Logic - Interaction, Affection, Gifts, Activity, Work
#===============================================================================

module NPCSystem
  @affection_data = {}
  @daily_interacted = {}
  @daily_gifts = {}
  @daily_gifts_detailed = {}


  # ---------- Affection ----------
  def self.affection(npc_id)
    @affection_data[npc_id] ||= 0
  end

  def self.set_affection(npc_id, value)
    @affection_data[npc_id] = value
  end

  def self.add_affection(npc_id, amount)
    @affection_data[npc_id] ||= 0
    @affection_data[npc_id] += amount
  end

      # ---------- Daily Interaction ----------
  def self.interacted_today?(npc_id)
    @daily_interacted[npc_id] == true
  end

  def self.set_interacted_today(npc_id)
    @daily_interacted[npc_id] = true
  end

  def self.reset_daily_interactions
    @daily_interacted.clear
  end

  # ---------- Daily Gifts ----------
  def self.track_gift_given(npc_id, weight = 1)
    @daily_gifts[npc_id] ||= 0
    @daily_gifts[npc_id] += weight
  end

  def self.gift_limit_reached?(npc_id)
    (@daily_gifts[npc_id] || 0) >= 5
  end


  def self.reset_daily_gifts
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
    if item == :STARPIECE_NECKLACE
      if affection(npc_id) > 200 && npc.relationship_state == :Single
        npc.relationship_state = :Dating_Player
        pbMessage("#{npc.name} accepts the Starpiece Necklace. You're now dating!")
      else 
        pbMessage("#{npc.name} doesn't feel ready for something that serious...")
        return
      end
    elsif item == :SOULDEW_RING
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
    track_gift_given(npc_id, gift_weight)
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

      # 🔒 Placeholder checks for future filtering of dialog types
      # if npc.affection >= 100
      #   choices << "Special Event"
      #   actions << -> { show_dialog(npc.id, :event) }
      # end

      # if npc.relationship_state == :dating
      #   choices << "Date"
      #   actions << -> { start_date_scene(npc.id) }
      # end

      # if quest_active?(:gardener_help)
      #   choices << "Ask about Garden"
      #   actions << -> { show_dialog(npc.id, :quest) }
      # end

      choices << "[Back]"
      choice = pbMessage("What would you like to do?", choices)
      break if choice == choices.size - 1

      actions[choice].call
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

    # Normalize state key
    state_key = npc.state.to_sym rescue :default

    # Get dialog for current state or fallback to default
    dialog_set = dialog[state_key] || dialog[:default]
    unless dialog_set
      puts "⚠️ No dialog for state :#{state_key} or :default for #{npc.id}"
      return
    end

    # Get dialog for specific type (e.g., :chat, :opener, :closer)
    type_dialog = dialog_set[type]
    unless type_dialog.is_a?(Array) && !type_dialog.empty?
      puts "⚠️ No dialog of type :#{type} for #{npc.id} in state :#{state_key}"
      return
    end

    # Display dialog
    if type == :chat
      choices = type_dialog.map { |entry| entry[:prompt] }
      choices << "[Back]"

      loop do
        choice = pbMessage("What do you want to say?", choices)
        break if choice < 0 || choices[choice] == "[Back]"

        selected = type_dialog[choice]
        if selected[:response]
          pbMessage(selected[:response])
        else
          puts "⚠️ Missing response for prompt: #{selected[:prompt]}"
        end
      end
    else
      # Normal linear display for opener/closer
      type_dialog.each do |entry|
        pbMessage(entry[:text]) if entry[:text]
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
  def self.run_schedule_for(npc_id)
    npc = GameData::NPC.try_get(npc_id)
    return unless npc

    now = Graphics.frame_count / Graphics.frame_rate
    schedule = npc.schedule[now]
    return unless schedule

    map_id = schedule[:map_id]
    event_id = schedule[:event_id]
    x = schedule[:x]
    y = schedule[:y]

    spawn_npc(map_id, event_id, npc.sprite, x, y)
  end

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
    "🔓 Single" => :single,
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
    attr_accessor :spouse, :affection, :relationship_state
    attr_accessor :fav_gifts, :bad_gifts, :log
    attr_accessor :schedule, :state, :dialog

    def initialize(hash)
      @id                 = hash[:id].to_sym
      @name               = hash[:name]
      @birthday           = hash[:birthday]
      @spouse             = hash[:spouse]
      @affection          = 20
      @relationship_state = :single
      @fav_gifts          = hash[:fav_gifts] || {}
      @bad_gifts          = hash[:bad_gifts] || {}
      @schedule           = hash[:schedule] || {}
      @dialog             = hash[:dialog] || {}
      @log                = {}
      @state              = :work
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
  NPCSystem.interacted_today?(id)
  
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
