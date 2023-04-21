import os
import json

with open("out/scenarioData.json", 'r') as f:
    scenarios = json.load(f)
    with open('../scenarios.json', 'r') as f2:
        scenarioInfos = json.load(f2)
        uniqueLayoutTiles = {}
        for scenario in scenarios:
            if 'layout' in scenario:
                layout = scenario["layout"]
                for tile in layout:
                    fullName = f"{tile['name']}{tile['orientation']}"
                    if fullName not in uniqueLayoutTiles:
                        uniqueLayoutTiles[fullName] = []
                    uniqueLayoutTiles[fullName].append(scenario["id"])
        missingTiles = []
        for tileName in uniqueLayoutTiles.keys():
            if not os.path.isfile(f"assets/tiles/maps/{tileName}.png") and not os.path.isfile(f"assets/tiles/maps/{tileName}-Alt.png"):
                missingTiles.append(tileName)
        
        missingTiles.sort()
        for tileName in missingTiles:
            pages = []
            for id in uniqueLayoutTiles[tileName]:
                scenario = scenarioInfos[id]                    
                pages.append(f"{scenario['page']}")
                if 'otherPages' in scenario:
                    pages = pages + [str(p) for p in scenario['otherPages']]
                pages = pages + scenario['sections']
            print(f"Missing Map Tile {tileName}, Pages : {', '.join(pages)}")