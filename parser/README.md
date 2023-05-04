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
 
