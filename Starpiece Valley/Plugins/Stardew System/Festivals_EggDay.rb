#===============================================================================
# * Egg Day Festival Starter Quiz
# * Uses personality quiz to assign a trio of starter eggs, then lets player pick one.
# * Displays eggs instead of Pokémon sprites.
#===============================================================================

# Define personality types and their starter trios (using first trio only)
PERSONALITY_TRIOS = {
  :COURAGEOUS => [:CHARMANDER, :TOTODILE, :CHESPIN],
  :CURIOUS    => [:CHIMCHAR, :PIPLUP, :TURTWIG],
  :COMPASSIONATE => [:CYNDAQUIL, :SOBBLE, :BULBASAUR],
  :ANALYTICAL => [:LITTEN, :FROAKIE, :SNIVY],
  :CREATIVE   => [:FENNEKIN, :POPPLIO, :CHIKORITA],
  :FREE_SPIRIT => [:SCORBUNNY, :MUDKIP, :TREECKO]
}

PERSONALITY_VAR = 30


#===============================================================================
# * Fixed Egg Display Class
#===============================================================================
class EggDisplay
  # Proper sprite spacing constants
  EGG_SPACING = Graphics.width / 4  # Space between egg centers
  EGG_Y_POS = Graphics.height * 0.6  # Vertical position
  EGG_SCALE = 0.8  # Size multiplier

  def initialize(viewport, species_list)
    @viewport = viewport
    @sprites = {}
    create_egg_sprites(species_list)
  end

  def create_egg_sprites(species_list)
  # Convert to array if it's a hash or other enumerable
  species_array = species_list.to_a
  
  # Traditional for loop for RPGMXP compatibility
  for i in 0...species_array.size
    species = species_array[i]
    
    # Create sprite
    @sprites[i] = Sprite.new(@viewport)
    
    # Load egg graphic
    egg_path = "Graphics/Pokemon/Eggs/#{species}"
    unless pbResolveBitmap(egg_path)
      pbMessage("Missing egg sprite: #{species}")
      next
    end
    @sprites[i].bitmap = Bitmap.new(egg_path)

    # Apply transparency
    make_transparent(@sprites[i].bitmap)

    # Position and scale
    @sprites[i].zoom_x = EGG_SCALE
    @sprites[i].zoom_y = EGG_SCALE
    @sprites[i].x = (EGG_SPACING * (i + 1)) - (@sprites[i].bitmap.width * EGG_SCALE / 2).floor
    @sprites[i].y = EGG_Y_POS - (@sprites[i].bitmap.height * EGG_SCALE / 2).floor
    @sprites[i].z = 50
  end
end

# Alternative version if you need to process a hash
def create_egg_sprites_from_hash(species_hash)
  i = 0
  species_hash.each do |key, species|
    # Same sprite creation code as above
    # ...
    i += 1
  end
end

  def refresh_egg_selection(trio)
    trio.each_with_index do |_, i|
      if @sprites["egg_#{i}"]
        # Highlight selected egg
        @sprites["egg_#{i}"].tone = (i == @index) ? Tone.new(100, 100, 100) : Tone.new(0, 0, 0)
      end
    end
  end

  # RPGMXP-compatible transparency processing
  def make_transparent(bitmap)
    for y in 0...bitmap.height
      for x in 0...bitmap.width
        pixel = bitmap.get_pixel(x, y)
        if pixel.red < 25 && pixel.green < 25 && pixel.blue < 25
          bitmap.set_pixel(x, y, Color.new(0, 0, 0, 0))
        end
      end
    end
  end

  def dispose
    @sprites.each_value { |sprite| sprite.dispose }
  end
end


class StarterQuiz
  def initialize
    @current_question = 0
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    setup_background
    setup_quiz_questions
    @personality_score = Hash.new(0)
    run_quiz
    dispose
  end

  # Set up UI (modified for egg graphics)
  def setup_background
    color = Color.new(0, 0, 0, 128)
    @sprites["bg"] = ColoredPlane.new(color, @viewport)
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["title"] = BitmapSprite.new(Graphics.width, 64, @viewport)
    pbSetSystemFont(@sprites["title"].bitmap)
    @sprites["title"].bitmap.font.size = 32
    draw_text("Egg Day Festival - Personality Quiz", 0, 8, :center)
  end

  # Quiz questions (10 questions total)
  def setup_quiz_questions
  @questions = [
    {
      text: "What's your first reaction to a challenge?",
      options: [
        ["Charge in headfirst!", :COURAGEOUS],
        ["Study it from all angles.", :ANALYTICAL],
        ["Find a creative workaround.", :CREATIVE],
        ["Ask for help from friends.", :COMPASSIONATE]
      ]
    },
    {
      text: "Your ideal weekend involves:",
      options: [
        ["Exploring uncharted woods.", :CURIOUS],
        ["Helping at a Pokémon shelter.", :COMPASSIONATE],
        ["Painting or composing music.", :CREATIVE],
        ["A spontaneous road trip!", :FREE_SPIRIT]
      ]
    },
    {
      text: "How do you solve disagreements?",
      options: [
        ["Stand my ground firmly.", :COURAGEOUS],
        ["Find a logical compromise.", :ANALYTICAL],
        ["Lighten the mood with humor.", :FREE_SPIRIT],
        ["Ensure everyone feels heard.", :COMPASSIONATE]
      ]
    },
    {
      text: "Which skill do you value most?",
      options: [
        ["Quick thinking under pressure.", :COURAGEOUS],
        ["Attention to tiny details.", :ANALYTICAL],
        ["Coming up with wild ideas.", :CREATIVE],
        ["Understanding others' feelings.", :COMPASSIONATE]
      ]
    },
    {
      text: "In a team project, you:",
      options: [
        ["Take the lead confidently.", :COURAGEOUS],
        ["Research everything first.", :CURIOUS],
        ["Design the coolest visuals.", :CREATIVE],
        ["Keep the group harmonious.", :COMPASSIONATE]
      ]
    },
    {
      text: "Your dream vacation is:",
      options: [
        ["Climbing a treacherous mountain.", :COURAGEOUS],
        ["Documenting rare Pokémon.", :CURIOUS],
        ["A festival with street performers.", :FREE_SPIRIT],
        ["A quiet retreat by the sea.", :ANALYTICAL]
      ]
    },
    {
      text: "Which quote resonates with you?",
      options: [
        ["\"Fortune favors the bold!\"", :COURAGEOUS],
        ["\"Knowledge is power.\"", :ANALYTICAL],
        ["\"Why walk when you can dance?\"", :FREE_SPIRIT],
        ["\"Discoveries come big and small.\"", :CURIOUS]
      ]
    },
    {
      text: "Your Pokédex style is:",
      options: [
        ["Rushing to fill entries fast.", :COURAGEOUS],
        ["Studying each Pokémon deeply.", :CURIOUS],
        ["Sketching them artistically.", :CREATIVE],
        ["Noting their social behaviors.", :COMPASSIONATE]
      ]
    },
    {
      text: "Which weather do you love?",
      options: [
        ["A thunderstorm's energy.", :COURAGEOUS],
        ["Fog that hides secrets.", :CURIOUS],
        ["Sunshine for outdoor fun.", :FREE_SPIRIT],
        ["Gentle rain for reflection.", :ANALYTICAL]
      ]
    },
    {
      text: "Your battle strategy focuses on:",
      options: [
        ["Overwhelming power.", :COURAGEOUS],
        ["Predicting the opponent's moves.", :ANALYTICAL],
        ["Unconventional tactics.", :CREATIVE],
        ["Protecting your team.", :COMPASSIONATE]
      ]
    }
  ]
  end

  # Main quiz loop
  def run_quiz
    @questions.each_with_index do |question, q_index|
      @current_question = q_index
      draw_question(question)
      selected = get_selected_option(question[:options].length)
      @personality_score[selected] += 1
    end
    determine_personality
  end


  # Draw question and options
  def draw_question(question)
    @sprites["overlay"].bitmap.clear
    # Draw progress (e.g., "Question 2/10")
    draw_text("Question #{@current_question+1}/#{@questions.size}", 0, 40, :center)
    # Original question text
    draw_text(question[:text], 0, 80, :center)
    # Draw options
    question[:options].each_with_index do |(text, _), i|
      draw_text("#{text}", -120, 120 + (i * 32), :left)
    end
  end

  # Get player's selected option
  def get_selected_option(num_options)
    option_index = 0
    # Initialize arrow sprite
    @sprites["q_arrow"] = IconSprite.new(80, 120, @viewport)
    @sprites["q_arrow"].setBitmap("Graphics/UI/arrow")
    @sprites["q_arrow"].z = @sprites["overlay"].z + 1

    loop do
      Graphics.update
      Input.update
      #pbUpdate
      
      # Update arrow position
      @sprites["q_arrow"].y = 120 + (option_index * 32)
      
      # Input handling
      if Input.trigger?(Input::USE)
        pbPlayDecisionSE
        @sprites["q_arrow"].dispose
        return @questions[@current_question][:options][option_index][1]
      elsif Input.trigger?(Input::DOWN)
        option_index = (option_index + 1) % num_options
        pbPlayCursorSE
      elsif Input.trigger?(Input::UP)
        option_index = (option_index - 1) % num_options
        pbPlayCursorSE
      end
    end
  end

  # Determine final personality
  def determine_personality
    personality = @personality_score.max_by { |k, v| v }[0]
    $game_variables[PERSONALITY_VAR] = personality
  end

  def refresh_egg_selection(trio)
    trio.each_with_index do |_, i|
      if @sprites["egg_#{i}"]
        # Highlight selected egg
        @sprites["egg_#{i}"].tone = (i == @index) ? Tone.new(100, 100, 100) : Tone.new(0, 0, 0)
      end
    end
  end 

  def dispose
    @sprites.each { |_,s| s.dispose }
    @viewport.dispose
  end
  
  # Helper method for drawing text
  def draw_text(text, x, y, align)
    text_pos = [[text, Graphics.width / 2 + x, y, align, Color.new(255, 255, 255), Color.new(0, 0, 0)]]
    pbDrawTextPositions(@sprites["overlay"].bitmap, text_pos)
  end

  def result
    return @selected_species
  end
end

def pbStarterQuiz
  quiz = StarterQuiz.new
  return $game_variables[PERSONALITY_VAR]
end

def pbStarterEggs
  # Get personality from variable (default to COURAGEOUS)
  personality = PERSONALITY_TRIOS.has_key?($game_variables[PERSONALITY_VAR]) ? $game_variables[PERSONALITY_VAR] : :COURAGEOUS
  trio = PERSONALITY_TRIOS[personality]
  
  # Set up display
  viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  viewport.z = 99999
  sprites = {}
  
  # Background
  sprites["bg"] = ColoredPlane.new(Color.new(0, 0, 0, 128), viewport)
  
  # Display eggs
  for i in 0...trio.size
    species = trio[i]
    sprites["egg_#{i}"] = Sprite.new(viewport)
    sprites["egg_#{i}"].bitmap = Bitmap.new("Graphics/Pokemon/Eggs/#{species}")
    sprites["egg_#{i}"].x = (Graphics.width * (i + 1)) / 4 - sprites["egg_#{i}"].bitmap.width/2
    sprites["egg_#{i}"].y = Graphics.height/2 - sprites["egg_#{i}"].bitmap.height/2
    sprites["egg_#{i}"].z = 50
  end
  
  # Selection arrow
  sprites["arrow"] = IconSprite.new(0, 0, viewport)
  sprites["arrow"].setBitmap("Graphics/UI/arrow")
  sprites["arrow"].z = 51
  
  # Selection logic
  index = 0
  loop do
    # Update arrow position
    sprites["arrow"].x = sprites["egg_#{index}"].x + sprites["egg_#{index}"].bitmap.width/2 - sprites["arrow"].bitmap.width/2
    sprites["arrow"].y = sprites["egg_#{index}"].y - 30
    
    Graphics.update
    Input.update
    
    if Input.trigger?(Input::USE)
      pbPlayDecisionSE
      break
    elsif Input.trigger?(Input::RIGHT)
      index = (index + 1) % trio.size
      pbPlayCursorSE
    elsif Input.trigger?(Input::LEFT)
      index = (index - 1) % trio.size
      pbPlayCursorSE
    end
  end
  
  # Cleanup and return chosen species
  chosen = trio[index]
  sprites.each { |_,s| s.dispose }
  viewport.dispose
  return chosen
end

def pbShowCoopEggsUI(show_names = false)
  if ChickenBreeding.empty?
    pbMessage(_INTL("There are no eggs in the coop."))
    return :none
  end

  # Build a snapshot list of species (kept in sync as we take eggs)
  species_list = ChickenBreeding.eggs.map { |e| e.species }

  # --- Viewport / Sprites ---
  viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  viewport.z = 99999
  sprites = {}

  # Dim background
  sprites["bg"] = ColoredPlane.new(Color.new(0, 0, 0, 128), viewport)

  # Egg sprites laid out evenly across screen width
  egg_count = species_list.length
  centers = []
  egg_sprites = []
  total_slots = egg_count + 1
  # Place eggs at fractions of width: (1..egg_count) / (egg_count+1)
  species_list.each_with_index do |species, i|
    x_center = (Graphics.width * (i + 1)) / total_slots
    centers << x_center

    spr = Sprite.new(viewport)
    spr.bitmap = resolve_egg_bitmap(species)
    spr.x = x_center - (spr.bitmap.width / 2)
    spr.y = (Graphics.height / 2) - (spr.bitmap.height / 2)
    spr.z = 50
    egg_sprites << spr
  end

  # Arrow
  sprites["arrow"] = IconSprite.new(0, 0, viewport)
  if pbResolveBitmap("Graphics/UI/arrow")
    sprites["arrow"].setBitmap("Graphics/UI/arrow")
  else
    # Fallback: reuse cursor if needed
    sprites["arrow"].setBitmap(Window_Base::CursorBitmap)
  end
  sprites["arrow"].z = 51

  # Name window (optional)
  if show_names
    sprites["name"] = Window_UnformattedTextPokemon.newWithSize("",
      0, Graphics.height - 64, Graphics.width, 64, viewport)
    sprites["name"].z = 52
    sprites["name"].visible = true
  end

  # Helper: update arrow (and name)
  index = 0
  update_arrow = proc do
    if egg_sprites[index] && egg_sprites[index].bitmap
      sprites["arrow"].x = egg_sprites[index].x + egg_sprites[index].bitmap.width / 2 - sprites["arrow"].bitmap.width / 2
      sprites["arrow"].y = egg_sprites[index].y - 30
    end
    if show_names && sprites["name"]
      name = GameData::Species.get(species_list[index]).real_name rescue "Egg"
      sprites["name"].text = _INTL("{1}", name)
    end
  end
  update_arrow.call

  result = :cancel
  loop do
    Graphics.update
    Input.update

    if Input.trigger?(Input::USE)   # Take selected egg
      pbPlayDecisionSE
      if ChickenBreeding.collect_one(index)
        # remove sprite + species entry
        egg_sprites[index].bitmap.dispose if egg_sprites[index]&.bitmap
        egg_sprites[index].dispose
        egg_sprites.delete_at(index)
        species_list.delete_at(index)
        centers.delete_at(index)
        egg_count -= 1
        if egg_count <= 0
          pbMessage(_INTL("You took the last egg."))
          result = :took_last
          break
        else
          index = [[index, egg_count - 1].min, 0].max
          # Re-lay remaining eggs evenly
          total_slots = egg_count + 1
          egg_sprites.each_with_index do |spr, i|
            x_center = (Graphics.width * (i + 1)) / total_slots
            centers[i] = x_center
            spr.x = x_center - (spr.bitmap.width / 2)
          end
          update_arrow.call
          pbMessage(_INTL("You took an egg."))
          result = :took_one
        end
      else
        pbMessage(_INTL("You don't have room for that egg."))
      end

    elsif Input.trigger?(Input::ACTION) # Take All
      moved = ChickenBreeding.collect_all
      if moved > 0
        pbMessage(_INTL("You took {1} egg(s).", moved))
        result = :took_all
        break
      else
        pbMessage(_INTL("You don't have room for more eggs."))
      end

    elsif Input.trigger?(Input::RIGHT)
      index = (index + 1) % egg_count
      pbPlayCursorSE
      update_arrow.call

    elsif Input.trigger?(Input::LEFT)
      index = (index - 1) % egg_count
      pbPlayCursorSE
      update_arrow.call

    elsif Input.trigger?(Input::BACK)
      pbPlayCancelSE
      result = :cancel
      break
    end
  end

  # Cleanup
  sprites.each_value do |s|
    if s.is_a?(Window)
      s.dispose
    else
      s.bitmap.dispose if s.respond_to?(:bitmap) && s.bitmap
      s.dispose
    end
  end
  egg_sprites.each do |s|
    next unless s && !s.disposed?
    s.bitmap.dispose if s.bitmap
    s.dispose
  end
  viewport.dispose

  return result
end

# Loads a species-specific egg bitmap with graceful fallback.
def resolve_egg_bitmap(species)
  path = sprintf("Graphics/Pokemon/Eggs/%s", species)
  if pbResolveBitmap(path)
    return Bitmap.new(path)
  end
  if pbResolveBitmap("Graphics/Pokemon/Eggs/000")
    return Bitmap.new("Graphics/Pokemon/Eggs/000")
  end
  # Last resort: species icon
  begin
    return Bitmap.new(GameData::Species.icon_filename(species))
  rescue
    # Plain 32x32 blank bitmap as emergency fallback
    return Bitmap.new(32, 32)
  end
end

##__________________________________________________________________________________

## Egg Hunt

##__________________________________________________________________________________



