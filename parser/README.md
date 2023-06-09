# A set of scripts to parse and process the scenario and section books of Frosthaven

## Output Assets
The dev branch includes the output assets from the scenario parser. Each scenario will have 1 image file per relevant scenario book page and section book page, with the identified assets highlighted on each. This can be used to quickly diagnose the source of an issue in scenario data.

## Usage
 - **scenario.py** is used to identify all elements present in a given scenario. For each scenario it creates a json file with all the collected data, as well as debug images showing what was identified (both in the out/ folder). This uses the parserPatches.json file to address some of the automated parser issues (and errors in the scenario / section books), as well as tiles.json for determining parts of the image which should be parsed. All assets are under assets (pages contains the scenario / section book pages, and tiles contains all sub-images which should be found in the pages.). Also uses the scenario info from docs/scenarios.json to determine what to look for.  
 - **merge.py** is used to merge all individual json files from each scenario into a common one.  
 - **process.py** processes the collected image matches, and converts them into a usable data format, with hex coordinates. It uses data from tileInfos.json, specials.json and triggers.json. Outputs docs/processedScenarios3.json and processedScenarios.human.json at the root of the project. The later includes indentation and should be used to look at what data was created, especially when diagnoising issues.  
 - **analysis.py** can be used to run some sanity checks and was used to identify missing assets for element identification.    
 - **jsonToLua.py** converts all json files under the docs/ folder into lua files under scripts/data. This is used to load the initial data (much)faster in the mod (and without the need to make web calls)  


 ## Typical workflow
 run `py scenario.py -layout -map -all` once to (re-)generate all the scenario data. This will take multiple hours on a fast machine.  
 run `py merge.py` to merge all the individual scenario data into scenarioData.json.  
 run `py process.py` to process the scenarioData.json.  
 run `py jsonToLua.py` to regenerate all lua data files.  
 save all scripts to TTS (Ctrl + Alt + S) to reload the mod with the latest data.  
When making changes at the parser level (assets or parserPatches.json) then rerun the scenario parsing for the scenario which should get fixed :  
run `py scenario.py -layout -map <scenario number>` then run all other scripts. (merge, process, jsonToLua)
When making changes at the process level (tileInfos.json, specials.json, triggers.json) simply return the process and jsonToLua steps.

## parserPatches.json format
This is a dictionary with keys being scenario numbers. Each entry is itself a dictionary with the key being the page number (in either the scenario or section book). Those sub entries are also dictionaries, with the following possible entries :  
```json
"tiles" : ["01-A","10-C"], // Overrides the tiles that the parser will look for on that specific page.  
"also" : ["Cave Door"],    // Adds elements that the parser will look for (by default it'll look for elements defined in docs/scenarios.json)
"overrides" : [            // Changes the values of some parsed elements
  {
    "where" : {
      "name" : "Cave Door",   // Any field name from the scenario json file can be looked for here
      "orientation" : "-180"  // When multiple fields are specified, they all need to match for the override to happen
    },
    "with" : {
      "name" : "Snow Door"    // Any field can be overriden here
    }
  }
],
"maxY": 2000              // Specifies the maxixum y coordinate that the parser will look for on that page. minY, minX and maxX also available.
```

## specials.json format
A dictionary with each entry being the scenario name (usually its number but sometimes with A/B appended), containing a dictionary of special processing rules for this scenario:  
```json
"remove-maps": [              // Removes maps (pages)
    {
        "type": "scenario",
        "name": 8
    }
],
"remove-tiles": [           // Removes tiles
    "11-B"
],
"remove-tokens": [          // Removes tokens
    "a"
],
"remove-monsters": [        // Removes monsters
    "Polar Bear",
    "Hound",
    "Vermling Scout"
]
"bosses": [                 // Renames regular monster into bosses
    {
        "in": "106.2",      // Optional, if the substitution should only be done in a specific section
        "from": "Frozen Corpse",
        "to": "Coral Corpse"
    }
],
"shiftX": -3,               // Adds an offset to the automatic layout of the whole scenario (hex coordinates)
"shiftY": -3,               // Adds an offset to the automatic layout of the whole scenario (hex coordinates)
"entries-to-map": [         // Converts an entry (typically a tile) into its own map (typically a page)
  {
    "in": {                 // Where to extract the tile from
        "type": "scenario",
        "name": 113
    },
    "having": {             // How to identify the tile to be extracted (typically one of the following two entries is used, not both)
        "token": {          // the tile contains a specific token
            "name": "1"
        },
        "reference" : "14-B" // Specific tile
    },
    "to": {                 // Name for the map to be created (type and name are required)
        "type": "choice",
        "name": "1"
    }
  }
],
"set-layout": [             // Set the layout of the scenario (Solo scenarios do not have a layout provided). There is an in-game tool in the debug version of the mod which will output the current layout on the scenario mat.
  {
      "center": {
          "x": 0,
          "y": 4
      },
      "name": "15-A",
      "orientation": 0,
      "origin": {
          "x": 3,
          "y": 1
      }
  }
],
"tile-order" : ["07-D","05-B","15-A"], // Hints where doors should be setup (when a door is on 2 tiles, it'll be attached to the tile of the lowest order). Used (and required) for solo scenarios when splitting the 1 map into multiple ones.
```


## triggers.json Data format
This is a dictionary with entry being the scenario name, and each value a set of triggers in this scenario. Each trigger has the following format :  
```json
{
    "in": {                   // Where the trigger is scenario "name" is its page number as an int, section "name" is a string
        "type": "scenario",   // "scenario", "section", or possibly something else if defined in the specials.json entriesToMap
        "name": 3             // NOT the scenario number, its page number in the scenario book. The section number for sections
    },
    "target": {               // Where is this trigger on the map. Typicall targets what is underneath a token or 'global'
        "type": "token",
        "name": "1"
    },
    "condition": {            // Optional. Only setup the trigger if the condition is met.
      "players": [            // Currently only 'players' is supported as a conditon
          3,
          4
      ]
    },
    "trigger": {              // What the trigger should do
        ...
    }
}
```

## Output Data format
 Each scenario is a json object:
 ```json
 {
  "id" : "0",
  "layout" : [...],
  "maps" : [...],
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
 `center` are the world hex coordinates of the rotational center of the tile, as defined in TTS, within this specific layout.
 `origin` are the world hex coordinates of the origin of the tile. The origin of a tile is always the hex closest to its printed name.
 To summarize, in order to place the tiles on a board, the `center` coordinate should be used, and after mapping from hex coordinates to world coordinates, the center of the tile should be placed at that location. The `origin` should be used for laying out items in the `maps` entries, when this tile is used as a `reference`.
 The actual layout of elements completely ignores the orientation of the tile, which is only used to rotate the tile asset around its center when placing it on the board.  
 The hex coordinate system used, is one where +1 in x gets to the hex to the right, and +1 in y gets to the hex in the top right direction.  
 
 `maps` contains a list of maps in the scenario, each entry is an object with the following structure. A map corresponds to a page within the scenario or section book.
```json
{
  "type": "scenario",
  "name": 3,
  "entries" : [
  ...
  ],
  "triggers": [
  ...
  ]
}
```

Each entry more or less maps to a tile with its elements. Elements on tile boundaries might end up on either tile. And some tile are not properly identified (eg. when their name is hidden), and as such, their elements are part of an other tile's entry.  
The only difference between entries is that the reference point is different. This was required for 3 scenarios which tiles where not aligned on a hexagonal grid, as well as one scenario which has multiple possible versions of the same tile.  
```json
{
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
}
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
 
 Overlay positions also contain a `type` entry (the overlay type) and may contain a `trigger` entry, as in:
 ```json
{
  "x": 2,
  "y": 1,
  "type": "Door"
}
 ```
 
 Tokens and overlays positions might also contain a `trigger` entry
 ```json
 {
   "x": -4,
   "y": 3,
   "trigger": {
     "type": "pressure",
     "action": "reveal",
     "what": {
       "type": "section",
       "name": "116.1"
     },
     "id": "section/149.4/token/d"
   }
 }
 ```
 ## Triggers
 Triggers represent links between maps.
 Triggers can be attached to maps, overlays or tokens. They may have a `type`, should have an `action` parameter fields based on `action` and may have an 'also' field (additional action array), for example :
 ```json
 {
  "name": "Cave Door",
  "orientation": 0,
  "positions": [
    {
      "x": 6,
      "y": 1,
      "type": "Door",
      "trigger": {
        "type": "door",
        "action": "reveal",
        "what": {
          "type": "section",
          "name": "179.2"
        },
        "also": [
          {
            "action": "lock",
            "what": "section/152.1/token/4"
          }
        ],
        "id": "section/152.1/token/3"
      }
    }
  ]
}
```
 
 | action | description | parameters|
 |--------|-------------|-----------|
 | `reveal` |This will lead to reading a specific section, and laying it out automatically | `what` |
 | `trigger` | Triggers an other trigger | `what` |
 | `open` | Opens a door (switch its state to 2) | `what` |
 | `unlock` | Unlocks a door | `what` |
 | `lock` | Locks a door | `what` |
 | `removeMatching` | Removes any object associated with any matching trigger | `what` |
 | `attachTrigger` | Updates the trigger associated with an object | `what` `trigger` |
 | `addTrigger` | Adds a global trigger | `trigger` |
 | `choice` | Shows options to the players | `choices`|
 | `broadcast` | Shows a message to the players | `message` |
 
 
 | type | description | parameters |
 |------|-------------|------------|
 | `door`| The target object is a door, a button is created to 'Open' it, and the state of the target object will be set to 2 upon opening. Can be locked.| `locked` |
 | `countDown` | When triggered, will count down and will only fire when count reaches 0 | `current` |
 | `round` | Will automatically trigger on a specific round | `when` |
 | `alldead` | Will automatically trigger when all monsters are dead | |
 | `health` | Will automatically trigger when a specific monster health reaches a specific level | `who` `level` |
 | `pressure` | Triggers automatically is a character is on the plate. Can either be a trigger once, or trigger when occupied depending on `mode` | `mode` |
 | `manual` | Creates a custom token with a button to trigger | `by` |
 
 Examples :
 ```json
 {
   "type": "health",
   "who": "Fish King 1",
   "level": 0.75,
   "action": "reveal",
   "what": {
     "type": "section",
     "name": "102.2"
   },
   "id": "scenario/96/global/fishking75"
 }
 ```
 ```json
 {
   "type": "alldead",
   "action": "reveal",
   "what": {
     "type": "section",
     "name": "188.1"
   },
   "also": [
     {
       "action": "open",
       "what": "section/150.3/token/2"
     }
   ],
   "id": "section/95.2/global/room2enemies"
 }
 ```
 ```json
 {
   "type": "pressure",
   "action": "reveal",
   "what": {
     "type": "section",
     "name": "116.1"
   },
   "id": "section/149.4/token/d"
 }
 ```
 ```json
 {
   "type": "countDown",
   "current": 2,
   "action": "unlock",
   "what": "section/104.2/token/4",
   "also": [
     {
       "action": "broadcast",
       "message": "Door 4 is now unlocked"
     }
   ],
   "id": "scenario/148/global/door4"
 }
 ```
 ```json
 {
   "type": "door",
   "action": "choice",
   "choices": [
     {
       "tile": "04-D",
       "position": {
         "x": -1,
         "y": -2
       },
       "token": "a",
       "trigger": {
         "type": "door",
         "display": "Friend of the Fish King on the Campaing sheet",
         "action": "reveal",
         "what": {
           "type": "section",
           "name": "164.1"
         }
       }
     },
     {
       "tile": "04-D",
       "position": {
         "x": 1,
         "y": -2
       },
       "token": "b",
       "trigger": {
         "type": "door",
         "display": "Otherwise",
         "action": "reveal",
         "what": {
           "type": "section",
           "name": "151.4"
         }
       }
     }
   ],
   "id": "section/52.2/token/3"
 }
 ```
 ```json
 {
   "type": "manual",
   "by": {
     "token": "n1",
     "at": {
       "reference": "15-D",
       "x": 1,
       "y": 3
     }
   },
   "action": "reveal",
   "what": {
     "type": "section",
     "name": "83.2"
   },
   "id": "scenario/30/global/section83_2"
 }
 ```
 
