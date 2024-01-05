#===============================================================================
# Pokemon Summary handlers.
#===============================================================================

UIHandlers.add(:summary, :page_allstats, { 
  "name"      => "Stats",
  "suffix"    => "skills",
  "order"     => 33,
  "options"   => [:item, :nickname, :pokedex, :mark],
  "layout"    => proc { |pkmn, scene| scene.drawPageAllStats }
})