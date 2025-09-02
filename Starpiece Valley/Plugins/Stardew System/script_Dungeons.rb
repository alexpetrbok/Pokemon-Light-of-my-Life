# =======================
# Starpiece Dungeon Symbols (plugin)
# =======================
module SPV_Deco
  DEFAULTS = {
    rock_density:        550,   # 1 :rock per N usable tiles
    rock_large_density: 1400,   # 1 2x2 rock per N usable tiles
    flowers_density:     500,
    grass_cell_chance:      8,  # % per cell to seed a grass blob
    grass_radius:          3,
    water_cell_chance:      5,  # % per cell to seed a water blob
    water_radius:          3,
    tree_edge_chance:    0.06,  # chance to try a tree on suitable void next to ground
    tree_a_ratio:         0.5   # mix A/B (0..1)
  }
end

# ---------- helpers on RandomDungeon::Dungeon's @map_data ----------
module SPV_Deco_Op
  module_function
  def ground?(d, x, y)
    v = d[x, y, 0]
    [:room, :corridor, :floor_patch, :grass].include?(v)
  end

  def seed_blob(d, cx, cy, radius, sym)
    ((cy - radius)..(cy + radius)).each do |y|
      ((cx - radius)..(cx + radius)).each do |x|
        next if x < 0 || y < 0 || x >= d.width || y >= d.height
        next unless ground?(d, x, y)
        d[x, y, 0] = sym
      end
    end
  end

  # write a 2x2 anchor (top-left gets sym; others marked :ignore on layer 0)
  def stamp_2x2(d, x, y, sym)
    return false if x+1 >= d.width || y+1 >= d.height
    return false unless ground?(d, x, y) && ground?(d, x+1, y) && ground?(d, x, y+1) && ground?(d, x+1, y+1)
    d[x,   y,   0] = sym
    d[x+1, y,   0] = :ignore
    d[x,   y+1, 0] = :ignore
    d[x+1, y+1, 0] = :ignore
    true
  end

  # stamp a 3x3 tree: trunks on layer 1 (bottom two rows), canopy on layer 2 (top row)
  # we store abstract symbols; tileset mapping supplies actual tiles later
  def stamp_tree_3x3(d, base_x, base_y, variant)  # variant :a or :b
    return false if base_x+2 >= d.width || base_y+2 >= d.height
    trunk_sym = (variant == :a) ? :tree_a_trunk : :tree_b_trunk
    top_sym   = (variant == :a) ? :tree_a_top   : :tree_b_top
    # bottom two rows: layer 1
    2.times do |dy|
      3.times do |dx|
        d[base_x + dx, base_y + 1 + dy, 1] = trunk_sym
      end
    end
    # top row: layer 2 canopy
    3.times { |dx| d[base_x + dx, base_y, 2] = top_sym }
    true
  end
end

class RandomDungeon::Dungeon
  # --- 1) extend vanilla decoration pass ---
  alias spv__paint_decorations paint_decorations
  def paint_decorations(maxWidth, maxHeight)
    spv__paint_decorations(maxWidth, maxHeight)           # vanilla first
    spv_paint_starpiece_decorations(maxWidth, maxHeight)  # then ours
  end

  def spv_paint_starpiece_decorations(maxWidth, maxHeight)
    # knobs (you can replace with map-name tags or parameters later)
    cfg = SPV_Deco::DEFAULTS
    rng = Random
    bx, by = @buffer_x, @buffer_y
    usable_area = @usable_width * @usable_height

    # --- rocks (1x1) ---
    rocks_n = (usable_area / cfg[:rock_density]).to_i
    rocks_n.times do
      x = bx + rng.rand(@usable_width)
      y = by + rng.rand(@usable_height)
      next unless SPV_Deco_Op.ground?(self, x, y) && @map_data[x, y, 1] == :none
      @map_data[x, y, 0] = :rock
    end

    # --- large rocks (2x2 anchor) ---
    big_n   = (usable_area / cfg[:rock_large_density]).to_i
    tries   = big_n * 15
    placed  = 0
    while placed < big_n && tries > 0
      tries -= 1
      x = bx + rng.rand(@usable_width - 1)
      y = by + rng.rand(@usable_height - 1)
      placed += 1 if SPV_Deco_Op.stamp_2x2(self, x, y, :rock_large)
    end

    # --- flowers (1x1) ---
    flowers_n = (usable_area / cfg[:flowers_density]).to_i
    flowers_n.times do
      x = bx + rng.rand(@usable_width)
      y = by + rng.rand(@usable_height)
      next unless SPV_Deco_Op.ground?(self, x, y) && @map_data[x, y, 1] == :none
      @map_data[x, y, 0] = :flowers
    end

    # --- grass blobs (like floor_patch but distinct symbol) ---
    if cfg[:grass_cell_chance] > 0
      (maxHeight / @parameters.cell_height).times do |j|
        (maxWidth / @parameters.cell_width).times do |i|
          next if rng.rand(100) >= cfg[:grass_cell_chance]
          mid_x = bx + (i * @parameters.cell_width)  + rng.rand(@parameters.cell_width)
          mid_y = by + (j * @parameters.cell_height) + rng.rand(@parameters.cell_height)
          SPV_Deco_Op.seed_blob(self, mid_x, mid_y, cfg[:grass_radius], :grass)
        end
      end
    end

    # --- water blobs (semi-navigable pools/paths) ---
    if cfg[:water_cell_chance] > 0
      (maxHeight / @parameters.cell_height).times do |j|
        (maxWidth / @parameters.cell_width).times do |i|
          next if rng.rand(100) >= cfg[:water_cell_chance]
          mid_x = bx + (i * @parameters.cell_width)  + rng.rand(@parameters.cell_width)
          mid_y = by + (j * @parameters.cell_height) + rng.rand(@parameters.cell_height)
          SPV_Deco_Op.seed_blob(self, mid_x, mid_y, cfg[:water_radius], :water)
        end
      end
    end

    # --- trees (3x3 composite) along void edges near ground ---
    tree_p = cfg[:tree_edge_chance]
    return if tree_p <= 0
    (by...by+@usable_height).each do |y|
      (bx...bx+@usable_width).each do |x|
        next unless @map_data.value(x, y) == :void
        # must touch ground (4-neighborhood)
        next unless [[x+1,y],[x-1,y],[x,y+1],[x,y-1]].any? { |xx,yy|
          next false if xx < 0 || yy < 0 || xx >= @width || yy >= @height
          SPV_Deco_Op.ground?(self, xx, yy)
        }
        next if rng.rand >= tree_p
        var = (rng.rand < SPV_Deco::DEFAULTS[:tree_a_ratio]) ? :a : :b
        base_x = (x - 1).clamp(0, @width - 3)
        base_y = (y - 2).clamp(0, @height - 3)
        SPV_Deco_Op.stamp_tree_3x3(self, base_x, base_y, var)
      end
    end
  end

  # --- 2) teach writer how to stamp our composites ---
  alias spv__generateMapInPlace generateMapInPlace
  def generateMapInPlace(map)
    # handle 2x2 and tree 3x3 anchors explicitly, then fall back to vanilla
    @width.times do |i|
      @height.times do |j|
        # 2x2 large rock on layer 0
        if @map_data[i, j, 0] == :rock_large
          base = @tileset.get_random_tile_of_type(:rock_large, self, i, j, 0)
          4.times do |c|
            t = base
            t += (c % 2) + (8 * (c / 2)) if t >= 384   # tile offset
            map.data[i + (c % 2), j + (c / 2), 0] = t
          end
          next   # skip vanilla writer for this anchor
        end

        # 3x3 trees: the grid already has layer 1 (trunks) and layer 2 (tops) symbols at each cell;
        # we just need to convert them to tiles as-is (no offset math here; each cell is a real tile symbol)
      end
    end
    spv__generateMapInPlace(map)  # vanilla handles singles & our per-cell trunk/top symbols
  end
end
