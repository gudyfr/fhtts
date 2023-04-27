# fhtts
This is a port of Frosthaven for tabletop simulator.
It integrates, and relies heavily on Frosthaven assistant (for monster and loot management), which, as of now, requires a custom build.
The goal is to have everything scripted.

# LIMITATIONS
**There is no mechanism yet to save / load your campaign state other than the built-in mechanism from Tabletop simulator. This mod is going under very frequent updates, and there is currently no way to update to a newer version without reseting your campaign.
At this point your interest in using this mod should be in helping / contributing to finalize it.**

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
- Automatic layout of scenarios and sections (not complete, and still needs a fair amount of work)
- Integration with x-haven assistant :
  - Automatically sets the scenario in the assistant when loaded in TTS
  - Monsters automatically get a standee number associated to them when pulled from their bag.
  - Start round is automated and sends initiative to assistant
  - Show Character and Monster hp, conditions and base shield / retaliate
  - Automated looting
  - End of round is automated, and returns cards to proper area (discard, lost, persistent)
  - Highligthing of figurines whose turn it is
 
 # What's buggy
  - The automatic scenario layout is still buggy, and many scenarios still need work.
  - Sometimes the overlay stickers showing health / conditions on top of figurines disapear.
  
