# fhtts
This is a port of Frosthaven for tabletop simulator.
It integrates, and relies heavily on Frosthaven assistant (for monster and loot management), which, as of now, requires a custom build.
The goal is to have everything scripted.

# What's included
- World Map, with scenario stickers added automatically upon unlocking / completing scenarios
- Campaing tracker which lets you unlock scenarios (click on the scenario number), complete a scenario (click the checkmark), lock a scenario (click the area with the lock outline), hide a scenario (click above its title), and load a scenario (click on its title)
- Rulebook, with stickers, checkmarks for the treasure index.
- Scenario book, with checkmarks for scenario completion (linked to the campaign tracker and the map), with history management (rewing, forward), which also includes the solo scenarios.
- Section book, with history management (rewind, forward)
- Scenario picker, showing available, completed and all scenarios
- Solo Scenario picker
- Player mats, with buttons to draw an attack modifier (which can also be done from an overlay UI), use/spend items
- All classes available, with their scripted character sheet.
- Potions mat, to reveal (or hide) potions
- Outpost mat, with all envelopes, their content, scripted campaign sheet, and automated building upgrade (or downgrade), linked to the world map. Non building world map elements are toggled directly on the world map (eg. walls)
- Event card holders for all event cards (searchable)
- Automatic retrieval of all assets needed upon choosing a scenario
- Automatic layout of the scenario map tiles
- Automatic layout of scenarios and sections (mostly complete, but needs to be verified)
- Integration with x-haven assistant :
  - Add characters in the assistant depending on player mats set in TTS, and update those based on level.
  - Automatically sets the scenario in the assistant when loaded in TTS
  - Monsters automatically get a standee number associated to them when pulled from their bag.
  - Start round is automated and sends initiative to assistant
  - Show Character and Monster hp, conditions and base shield / retaliate
  - Automated looting
  - End of round is automated, and returns cards to proper area (discard, lost, persistent)
  - Highligthing of figurines whose turn it is
 
 # What's buggy
  - The following scenarios are not yet automated (work in progress):
    - **37** (Map tiles need to relocate)
    - **82** (Special setup rules, with moving corridors)
    - **85** (It has a really high number of Section links)
    - **91** (The layout is random from a pool of possibilities)
    - **113** (Some doors are missing)
    - **128** (Tiles need to flip)    
  - Sometimes the overlay stickers showing health / conditions on top of figurines disapear.
  
 # How you can help
  - Find Scenario auto layout errors. The automatic scenario layout is based on a (mostly) [automated parsing](parser/) of the scenario and section book. As such, while a lot of scenarios seem to be ok, and were quickly checked as part of creating the various section links, they haven't been fully tested, especially for different number of players. Some overlay tiles or monsters might be missing, or may be of the wrong type (normal vs elite). Bosses in particular might not be properly spawned. If you spot errors in any scenario not mentionned above, please report a bug.
  - Provide Usability feedback. 
  - Join the effort
  
# Installation
  - Download the save file under [tts saves](https://github.com/gudyfr/fhtts/tree/main/tts%20saves)
  - Download and build the forked assistant (or use one of the release) : [X-Haven Assistant](https://github.com/gudyfr/FrosthavenAssistant/tree/webserver)
  - Enable the web server in the assistant, and start the server.
  - Getting started available [here](https://github.com/gudyfr/fhtts/tree/main/www/docs/Index.md)
  
# License & Attribution
  - This work is distributed under the [CC BY-NC-SA 4.0 License](https://creativecommons.org/licenses/by-nc-sa/4.0/)
  - Frosthaven is owned by [Cephalofair](https://cephalofair.com/pages/frosthaven)
  - Uses and Integrates with [X-Haven Assistant](https://github.com/Tarmslitaren/FrosthavenAssistant)
  - Leverages assets from [worldhaven](https://github.com/any2cards/worldhaven)
  
