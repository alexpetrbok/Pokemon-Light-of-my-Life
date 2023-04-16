Secret Bases Remade
By Vendily
All included graphics are from Pokemon Emerald
Except for the Secret Base Arrows, which are edited fishing sprites, and the horizontal and square holes and boards, which are edited Emerald tiles.

==FEATURES==
- Creation of Secret Bases from RSE.
- User configurable Bases and Decorations
- Gifting, Buying, and Selling Decorations

==INCLUDED COMPONENTS==
- Graphics, consisting of the Tileset, some character files for events, icon files for the decorations, an animation file for base opening, and essential graphics for the script itself.
- Data, consisting of the Tilesets.rxdata, and Animations.rxdata, the .dat files for the PBS, SecretBaseItemsMap.rxdata (a Map file), as well as a folder of included (but optional) template maps from Pokemon Emerald.
- PBS, consisting of two new PBS files, secret_bases.txt (which contains the locations and templates of some bases for the example maps) and secret_decorations.txt (which contains the data for most of the decorations from Pokemon Emerald).
- Plugins, which contains the scripts. There is a contained 001_Settings.rb file, in case you need to edit constants for the script, including necessary Terrain Tags, or MessageTypes constants. There is also a Hardcoded GameData that can be edited to add or remove Map Templates, 001_SecretBaseTemplate.rb
- A Graphical User Manual PDF, to explain how some data must be configured. Easier to show than explain.

!!CAUTION!!
If you have made changes to your Tilesets.rxdata, or Animations.rxdata, you must copy these files into a new project and open both the project you want to install the script into, and the new project to copy them over in the editor.

==QUICKSTART==
The script requires at minimum 3 new maps.
- A dummy SECRET_BASE_MAP, which can be completely empty, as the map data is overwritten. To clarify, only the map's data is overwritten. The name, tileset, BGM, or BGS, given to the dummy map is kept, as well as any map metadata for it.
- A SECRET_BASE_DECOR_MAP which contains events for decorations. These events should only apply animations to "This Event" or "Player". Self Switches are not properly saved (as event IDs change on every map reload), so only Temp Switches should be used.
- At least 1 Secret Base Template Map. Secret Base Templates are defined in GameData::SecretBaseTemplate.
Each of these maps should be set to the tileset SECRET_BASE_TILESET.

A Secret Base PBS entry consists of 3 parts: a unique ID, a MapTemplate, and a Location.
The ID can be any name you want, so feel free to make it descriptive.
The MapTemplate must be an ID from GameData::SecretBaseTemplate.
The Location is 3 numbers: Map ID, X Position, Y Position.

A Secret Base Decoration PBS entry requires 3 parts: a unique ID, a player facing Name, and a Pocket number.
Additionally, entries can contain the following properties:
- Price, SellPrice, and Description => Same as in items.txt
- TileOffset => The Tile ID of the top left tile in SECRET_BASE_TILESET. A simple formula is (Y_Pixels/16)*8 + (X_Pixels/16), rounding down when dividing. Do NOT add 384 to compensate for autotiles.
- EventID => The ID of the event in SECRET_BASE_DECOR_MAP to copy. Copies events exactly.
- TileSize => The width and height of this decoration. Can be combined with EventID (The event will be in the bottom right tile of the overall decoration).
- PlacingPerms => One of Floor, Wall, Decor, or Board. Determines valid locations for placing. Floor require all tiles to be passable; Wall can only be placed on :SecretWall terrain tags; Decor can be placed on mats or desks if SECRET_BASE_DECOR_ANYWHERE is false, or any passable tile, including mats and desks if true; and Board can be placed over holes, but otherwise requires passable tiles.

TileOffset and EventID can be used together, in which case, the Event's Graphic will be used if it has one while placing. The event will be in the bottom right tile of the overall decoration.

==USEFUL METHODS AND VARIABLES==
$secret_bag => A new bag for Secret Bases. An instance of class SecretBag.
pbSecretBaseMart(stock,speech=nil,cansell=false) => A mart for Secret Base Decorations. Use like regular Marts.
pbReceiveDecoration(item) => Gives the player the decoration. Returns true if it was successfully added, and false otherwise.
pbGetPlayerBaseLocation(mapname=-1,mapid=-1) => Sets the passed game variables to the map name and map id respectively of the player's secret base. Also returns an array of the same information. map id is -1 if the player does not have a base.
$stats.moved_secret_base_count => A count of every time the Player packs up their base, from the inside or outside.


====
There's some extra stuff in the scripts that's incomplete for this version of the script. It has no impact on the script, but may be completed in a future update.