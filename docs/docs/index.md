# Getting Started

## Download and install the Frosthaven Asssitant
Builds are available for windows, mac osx, and android.  
[Frosthaven Assistant](https://github.com/gudyfr/FrosthavenAssistant/releases)  
If you plan on using the narration integration, a desktop build is recommended.  

## Configure the Frosthaven Assistant
Open the Main menu, choose Settings :  
![Main Menu Settings](images/xhaven_main_menu_settings.png)  
Scroll down to "Also Enable Web Server", and enable it  
![Enable Web Server](images/xhaven_settings_enable_web_server.png)  
Make sure you turn off "Auto Add Standees" and "Auto Add Timed Spawns" as these will conflict with TTS driving the assistant to add standees.  
![](images/xhaven_auto_add_standees.png)  
(Optional) There is also an option to keep the Assistant on top of other windows, which can be useful to have it visible on top of TTS  
![Always on Top](images/xhaven_settings_always_on_top.png)  
Finally, you need to Start the Host Server (which also starts the web server), notice that the label changes to "Stop Server"  
![Settings Start Server](images/xhaven_settings_menu_start_server.png)  
**Upon next launches of the Assistant, you can simply start the server from the main menu**  
![Settings Start Server](images/xhaven_main_menu_start_server.png)  

## Setup TTS
Locate the Settings mat and make sure that "Enable X-Haven assistant is checked", in addition the address and port should be valid for you if you are the host and do not plan on using the narration.
![](images/tts_settings.png)  
### If you plan on using the narration integration
The assistant can download the narration files, assuming you provide it with a valid email and password and that you have purchased the narration. For other players to access the narration audio, you will need to change the Address settings to your public IP Address, and setup proper port forwarding to the Assistant.
### Key bindings
There are custom key bindings for common actions, to set these up locate the Game Keys menu under Options  
![](images/tts_game_keys.png) 
And set them up appropriately. **You may want to check that those keys are not also set for other shortcuts under Menu / Configuration**.  
![](images/tts_custom_controls.png) 

## Setting up Characters
To setup characters you simply drop a character envelope onto a player mat. The starting six character classes are grouped together on the left of all character envelopes.  
![](images/tts_character_envelopes.png)  
![](images/tts_drop_character_box.png)  
![](images/tts_setup_character.png)  

## Using the Campaign Tracker
There are 5 campaign tracker mats, which look like  
![](images/tts_campaign_tracker.png)  
Simply click any scenario number to unlock the scenario  
![](images/tts_scenario_zero_unlock.png)  
Once a scenario has been unlocked it will look like  
![](images/tts_scenario_zero_unlocked.png)  
You can undo (relock) the scenario by clicking above its title  
![](images/tts_scenario_zero_lock.png)  
You can load the scenario by clicking its title  
![](images/tts_scenario_zero_load.png)  
And you can mark a scenario complete by clicking its checkbox  
![](images/tts_scenario_zero_complete.png)  
Additionaly, if a scenario can be blocked out, you can click the appropriate location as well  

## Using the Scenario Picker
The Scenario Picker shows available scenarios. You can also start a scenario from the Scenario Picker by clicking its title  
![](images/tts_scenario_picker.png)

## Setting up a Scenario
Once you load a scenario, it should be layed out automatically. **Some scenarios are not currently properly handled, and when this is the case, simply uncheck the "Automatic Scenario Layout" under Settings", try again, and manually setup the scenario. Its elements will still be provided to you.**  
![](images/tts_layed_out_scenario_zero.png)  
Some components of a Scenario are actionable **The scripting of scenarios is not 100% complete, and in the event the scenario you're playing isn't complete, you will need to manually layout the subsequent rooms.**  
Starting locations can be clicked to make them all disapear  
![](images/tts_start_location.png)  
Doors can be clicked to open them and reveal the next room  
![](images/tts_open_door.png)  
In some scenarios, the pressure plates (or tokens) have been scripted, and a character needs to be placed there to activate them  
Some conditions are currently too complicated to be implemented automatically, in these situations a token will be added next to the map to trigger the appropriate section  
![](images/tts_manual_trigger.png) 

## Playing a scenario
### Overall round process
For each round, you want to first place your ability cards on the Scenario mat, either using key bindings or simply dropping them at the right location.  
![](images/tts_start_round_button.png)  
Then, once everyone is ready, you can press the "Start" button to reveal the cards. The initiative should be sent to X-Haven Assistant, which will now display the turn order.  
![](images/tts_round_started.png)  
![](images/xhaven_round_started.png)  
Track the progress of the round in X-Haven assistant, and at the end of the round, you want to end the round from TTS, by pressing the "End" button.  
![](images/tts_end_round_button.png)  
Ability Cards are automatically returned to the appropriate Player mat, at the correct location  
If a card was used as a persistent ability, or a loss, simply click the appropriate toggle **before** ending the round.  
![](images/tts_return_card_states.png)  
It should be sent to the appropriate location as well  
![](images/tts_cards_returned.png)  
**It is currently required that you Start and End rounds from TTS. Doing so from X-Haven Assistant will not work.**  

### Attack modidiers
On the side of the TTS window, there is a toggle button to enable the Attack Modifier UI  
![](images/tts_am_ui_collapsed.png)  
Clicking it will expand / collapse the Attack Modifier UI  
![](images/tts_am_ui_opened.png)  
Clicking the Draw button will draw an attack modifier card for the player who pressed the button, and will display the results to all players.  
![](images/tts_am_ui_drawn.png)  
Monsters and Allies Attack Modifiers should be drawn from the X-Haven Assistant UI.  
The deck is shuffled automatically when needed. In addition Curse and Bless cards are automatically returned to their appropriate decks at the end of each round. Minus one Cards are returned to their appropriate deck whenever a "Cleanup" occurs.

### Looting
If a monster dies it will drop a loot token (unless there are specials rules to prevent this, in which case it might drop nothing, or the appropriate item/overlay)  
![](images/tts_enemy_as_loot.png)  
If a character is on top of a loot token at the end its round, the loot token will be automatically looted. **Use the Assistant UI to end a chracter round. For the loot to work, the character had to be active in the assistant, ie skipping a character's turn will result in looting not working for that character.**  
![](images/tts_figure_standing_on_loot.png)  
![](images/xhaven_end_round.png)  

## Saving Progress and Updating
In order to update to a recent version of the mod, you will first need to save your campaign progress.  
This can be accomplished using the Campaigns mat.  
![](images/tts_campaigns_save.png)  
The state of all boards (except the scenario board) will be saved. You should ensure that all elements are at their appropriate locations before saving, in particular :
 - items should be on either the items mat or player mats (in items positions)
 - ability cards should be on player mats (only)
Each save "box" is a container in which you can add any custom object you would have added to your campaign (notes, retired player sheets, etc ...)
![](images/tts_campaign_saved.png)  
From there, you want to save this object  
![](images/tts_right_click_menu_save.png)  
**Update your save to the latest version of the mod**  
and import your saved object using the menu "Objects" / "Saved Objects", and drop it at the right location. Your progress should be restored.    
