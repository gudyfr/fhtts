# A set of scripts to parse and process the scenario and section books of Frosthaven

## Usage
 - **scenario.py** is used to identify all elements present in a given scenario. For each scenario it creates a json file with all the collected data, as well as debug images showing what was identified.
 - **merge.py** is used to merge all individual json files from each scenario into a common one
 - **process.py** processes the collected image matches, and converts them into a usable data format, with hex coordinates.
 - **analysis.py** can be used to run some sanity checks and was used to identify missing assets for element identification

## Data format
 Each scenario is a json object:
 ```json
 {
  "id" : "0",
  "maps" : [...],
  "layout" : [...],
 }
 ```
 `layout` contains a list of tiles in the scenario, each entry is an object with the following structure :
 ```json
{
  "name": "13-C",
  "orientation": "0",
  "center": {
    "x": 6,
    "y": -1
  },
  "origin": {
    "x": 9,
    "y": -4
  }
}
 ```
 where `name` is the name of the map tile, `orientation` is its rotation in degrees, with **0** always being the tile with its name readable normally. All tiles, except for tile 14 will have orientations of 0, 60, 120, 180, 240 and 300. Tile 14 is shifted by 30 degrees.
 `center` are the hex coordinates of the rotational center of the tile, as defined in TTS, within this specific layout.
 `origin` are the hex coordinates of the origin of the tile, compared to its center. The origin of a tile is always the hex closest to its printed name.
 `origin` is defined as if no rotation / orientation was applied to the tile, and as such, some calculations need to be used to map the origin in world coordinate.
 To summarize, in order to place the tiles on a board, the `center` coordinate should be used, and after mapping from hex coordinates to world coordinates, the center of the tile should be place at that location. The `origin` should be used for laying out items in the `maps` entries, when this tile is used as a `reference`.
 
 `maps` contains a list of maps in the scenario, each entry is an object with the following structure. A map corresponds to a page within the scenario or section book.
  ```json
      {
        "type": "scenario",
        "name": 3,
        "reference": {
          "tile": "13-A",
          "tileOrientation": "180"
        },
        "tokens": [
          ...
        ],
        "monsters": [
          ...
        ],
        "overlays": [
          ...
        ]
      },
 ```
 with `tokens`, `monsters` and `overlays` all following a similar structure and corresponding to their respective elements in the game.
 Each entry there has the following structure :
 ```json
 {
  "name": "1",
  "orientation": 0,
  "positions": [
    {
      "x": 2,
      "y": 1
    }
  ]
}
 ```
 where `name` is the element name, `orientation` is its orientation, and positions are all the positions where this element is present on the map.
 
 In addition, for monsters, each position entry also contains a `levels` field :
 ```json
{
  "x": 0,
  "y": 0,
  "levels": "aan"
}
```
levels corresponds to 2p,3p and 4p monster levels concatenated into a single string. The letters represent :
  - **a** absent
  - **n** normal
  - **e** elite
  - **b** boss
 In the example above, the monster is not present for 2 and 3 players and normal for 4 players.
 
 Finally, overlay positions also contain a `type` entry (the overlay type) and may contain a `trigger` entry, as in:
 ```json
{
  "x": 2,
  "y": 1,
  "trigger": {
    "type": "door",
    "action": "reveal",
    "what": {
      "type": "section",
      "name": "2.1"
    }
  },
  "type": "Door"
}
 ```
 
 ## Triggers
 Triggers represent links between maps. Currently, there is only one trigger being handled, which is the `door` type with a `reveal` action. `what` points to the type and name of the map that should be layed out upon opening the corresponding door.
 Triggers are **not** parsed from the books, but are merged from the triggers.json file when running the process.py script.
 
 
 
 
