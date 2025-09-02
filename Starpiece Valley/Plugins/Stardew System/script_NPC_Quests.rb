# --- quest helpers ---
def quest_available?(q)
  !getActiveQuests.include?(q) &&
  !getCompletedQuests.include?(q) &&
  !getFailedQuests.include?(q)
end

def quest_stage?(q, s)  ; getCurrentStage(q) == s ; end
def quest_active?(q)    ; !!getCurrentStage(q)    ; end
def quest_done?(q)      ; getCompletedQuests.include?(q) ; end

def npc_affection(npc_sym)
  # Replace with your affection lookup for that NPC
  $game_system.affection_for(npc_sym) || 0
end

def has_items?(pairs)
  pairs.all? {|item,qty| $bag.has?(item, qty) }
end

def take_items!(pairs)
  pairs.each {|item,qty| $bag.remove(item, qty) }
end

def pbNPCQuestPrompt(npc_sym)
  entries = pbBuildQuestEntriesFor(npc_sym)
  return false if entries.empty?

  labels = entries.map{|e| e[:label] } + ["Back"]
  cmd = pbMessage("\\l[2]Quests", labels, 0)
  return false if cmd.nil? || cmd >= entries.length

  entries[cmd][:call].call
  return true
end

def pbBuildQuestEntriesFor(npc_sym)
  case npc_sym
  when :ROBYN   then qb_robyn
  when :SELENE  then qb_selene
  when :HIKER   then qb_hiker_rescue
  # when :ISAAC, :NURSE, :FISHER, ... add more here
  else
    []
  end
end


def qb_robyn
  npc = :ROBYN
  out = []

  # START: affection gate + not already seen
  if quest_available?(:CAFE_SUPPLY_RUN) && npc_affection(npc) >= 80
    out << {
      label: "Start: Café Supply Run",
      call: proc {
        activateQuest(:CAFE_SUPPLY_RUN, colorQuest("yellow"), true)
        pbMessage("Robyn: \"Could you bring me 10 Moomoo Milk for tomorrow's special?\"")
      }
    }
  end

  # STAGE 1 → deliver 10 Moomoo Milk
  if quest_stage?(:CAFE_SUPPLY_RUN, 1)
    out << {
      label: "Deliver 10× Moomoo Milk",
      call: proc {
        if has_items?([[:MOOMOOMILK,10]])
          take_items!([[:MOOMOOMILK,10]])
          advanceQuestToStage(:CAFE_SUPPLY_RUN, 2, nil, true)
          taskCompleteJingle
          pbMessage("Robyn: \"Perfect! Come by the register for your tip.\"")
        else
          pbMessage("Robyn: \"You don't have 10 yet. Check your ranch or market.\"")
        end
      }
    }
    out << {
      label: "Details: Café Supply Run",
      call: proc {
        pbMessage($quest_data.getStageDescription(:CAFE_SUPPLY_RUN, 1))
      }
    }
  end

  # STAGE 2 → collect reward and complete
  if quest_stage?(:CAFE_SUPPLY_RUN, 2)
    out << {
      label: "Collect Reward",
      call: proc {
        # Give reward (items/money/discount). Example:
        $bag.add(:LAVACOOKIE, 3)
        completeQuest(:CAFE_SUPPLY_RUN, nil, true)
        pbMessage("Robyn: \"Here you go—fresh sweets on the house!\"")
      }
    }
  end

  out
end
