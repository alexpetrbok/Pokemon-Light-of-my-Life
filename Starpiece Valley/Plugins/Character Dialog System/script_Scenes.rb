#===============================================================================
#  Scene System
#===============================================================================
module GameData
  class Scene
    attr_reader :id, :participants, :dialogue

    DATA = {}
    DATA_FILENAME = "scenes.dat"
    PBS_FILENAME = "scenes.txt"

    def initialize(hash)
      @id = hash[:id]
      @participants = hash[:participants] || []
      @dialogue = hash[:dialogue] || []
    end

    def self.register(hash)
      scene = self.new(hash)
      DATA[scene.id] = scene
    end

    def self.try_get(scene_id)
      return DATA[scene_id]
    end

    def self.compile
      data = []
      pbs_path = "PBS/#{PBS_FILENAME}"
      if FileTest.exist?(pbs_path)
        File.open(pbs_path, "rb") do |f|
          file_data = f.read
          eval(file_data).each do |scene_hash|
            data.push(scene_hash)
          end
        end
      else
        raise "PBS file not found: #{pbs_path}"
      end
      save_data(data, "Data/#{DATA_FILENAME}")
    end

    def self.load
      if FileTest.exist?("Data/#{DATA_FILENAME}")
        @data = load_data("Data/#{DATA_FILENAME}")
        @data.each { |scene| register(scene) }
      else
        compile
      end
    end
  end
end

# Load scene data on game start
GameData::Scene.load

#===============================================================================
#  Scene Playback
#===============================================================================
def pbPlayScene(scene_id)
  return if !$scene.is_a?(Scene_Map)
  scene_data = GameData::Scene.try_get(scene_id)
  return if !scene_data

  # Initialize participants
  participants = scene_data.participants || []
  Rf.new_portrait(*participants) if participants.any?

  # Process dialogue lines
  scene_data.dialogue.each do |line|
    # Parse speaker and text
    speaker_tag, text = line[:speaker].to_s, line[:text].gsub("\\PN", $player.name)
    
    # Update speaker
    speaker = participants.find { |p| p.to_s == speaker_tag }
    Rf.set_speaker(speaker ? GameData::Character.try_get(speaker).name : "")

    # Process commands in text (e.g., [MOVE_EVENT 1,5,5] or [ANIMATION 12])
    while text[/\[(.*?)\]/]
      command = $1
      case command
      when /MOVE_EVENT (\d+),(\d+),(\d+)/
        #pbMoveRoute($game_events[$1.to_i], [PBMoveRoute::StepForward] * $2.to_i)
      when /ANIMATION (\d+)/
        pbCommonAnimation($1.to_i)
      end
      text.gsub!("[#{command}]", "")
    end

    pbMessage(text)
  end

rescue => e
  pbMessage(_INTL("Scene error: {1}", e.message))
ensure
  Rf.close_portrait
  Rf.clear_speaker
end