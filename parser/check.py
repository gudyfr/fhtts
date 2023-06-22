import os
import json

def checkMonsters(processedScenarios):
    for key, scenario in processedScenarios.items():
        for map in scenario['maps'] if 'maps' in scenario else []:
            for entry in map['entries'] if 'entries' in map else []:
                for monster in entry['monsters'] if 'monsters' in entry else []:
                    for positions in monster['positions'] if 'positions' in monster else []:
                        if 'levels' not in positions:
                            print(f"Missing levels for {monster['name']} in {key}/{map['type']}/{map['name']}/{entry['reference']['tile']}")

with open("../processedScenarios.human.json") as f:
    processedScenarios = json.load(f)
    checkMonsters(processedScenarios)