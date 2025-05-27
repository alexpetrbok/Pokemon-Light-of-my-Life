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
  def self.gift_count(npc_id)
    @daily_gifts[npc_id] ||= 0
  end

  def self.give_gift(npc_id)
    @daily_gifts[npc_id] ||= 0
    @daily_gifts[npc_id] += 1
  end

  def self.reset_daily_gifts
    @daily_gifts.clear
    @daily_gifts_detailed.clear
  end

  # Placeholder - called once per day per NPC
  def self.daily_npc_update
    reset_daily_interactions
    reset_daily_gifts
  end

  def self.start_interaction(npc_input)
    npc = npc_input.is_a?(Symbol) || npc_input.is_a?(String) ? GameData::NPC.try_get(npc_input.to_sym) : npc_input
    
    return unless npc

    show_dialog(npc, :opener)
    npc_main_loop(npc)
    show_dialog(npc, :closer)
  end

  def self.npc_main_loop(npc)
    loop do
      cmd = pbMessage("What would you like to do?", ["Chat", "Gift", "Activity", "Bye"], 4)
      case cmd
      when 0 then show_dialog(npc, :chat)
      when 1 then give_gift(npc.id)
      when 2 then do_activity(npc.id)
      else break
      end
    end
  end

  def self.start_work_interaction(npc_input)
    npc = npc_input.is_a?(Symbol) || npc_input.is_a?(String) ? GameData::NPC.try_get(npc_input.to_sym) : npc_input
    return unless npc

    show_dialog(npc, :opener)
    loop do
      cmd = pbMessage("What would you like to do?", ["Shop", "Sell", "Chat", "Gift", "Bye"], 5)
      case cmd
      when 0 then open_shop(npc_id)
      when 1 then open_sell(npc_id)
      when 2 then show_dialog(npc, :chat)
      when 3 then give_gift(npc.id)
      else break
      end
    end
    show_dialog(npc, :closer)
  end

  def self.show_dialog(npc, type)
    #npc = npc_input.is_a?(Symbol) || npc_input.is_a?(String) ? GameData::NPC.try_get(npc_input.to_sym) : npc_input
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


  def self.give_gift(npc_id)
    npc = GameData::NPC.try_get(npc_id)
    return unless npc

    items = $PokemonBag.all_items
    item_choices = items.map { |i| [GameData::Item.get(i).name, i] }
    choice = pbChooseItem(item_choices)
    return unless choice

    type = get_gift_type(choice)
    daily_gifts = NPCSystem.give_gift(npc_id)
    limit = type == :treasure ? 1 : 3
    if daily_gifts[type] >= limit
      pbMessage("You've already given too many #{type.to_s.capitalize}s today.")
      return
    end

    affection = npc.gifts[choice.upcase] || 1
    update_affection(npc_id, affection)
    pbMessage("#{npc.name} accepted the #{GameData::Item.get(choice).name}!")
    daily_gifts[type] += 1
    $PokemonBag.remove(choice)
  end

  def self.get_gift_type(item_symbol)
    data = GameData::Item.get(item_symbol)
    return :treasure if data.is_evolution_stone? || data.is_fossil?
    return :snack if data.is_berry? || data.is_medicine?
    :snack
  end

  def self.do_activity(npc_id)
    # Placeholder - perform an activity with this NPC
    pbMessage("You spent some time with #{GameData::NPC.try_get(npc_id).name}.")
    update_affection(npc_id, 2)
  end

  def self.open_shop(npc_id)
    # Placeholder - opens the NPC's shop
    pbMessage("Opening shop...")
  end

  def self.open_sell(npc_id)
    # Placeholder - lets player sell items to the NPC
    pbMessage("Selling items...")
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
    GameData::NPC.each do |npc|
      NPCSystem.daily_npc_update(npc.id)
      run_schedule_for(npc.id)
    end
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
      load_test_npcs
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

  # Run appropriate interaction
  case interaction_type
  when :talk     then NPCSystem.start_interaction(npc)
  when :work     then NPCSystem.start_work_interaction(npc)
  else pbMessage("Unknown interaction type.")
  end

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
