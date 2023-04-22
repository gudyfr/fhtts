import os
import json

def getPages(tileName, uniqueLayoutTiles, scenarioInfos):
    pages = []
    for id in uniqueLayoutTiles[tileName]:
        scenario = scenarioInfos[id]                    
        pages.append(f"{scenario['page']}")
        if 'otherPages' in scenario:
            pages = pages + [str(p) for p in scenario['otherPages']]
        pages = pages + scenario['sections']
    return pages

def findInScenario(name, type, scenario):
    if 'maps' in scenario:
        for map in scenario['maps']:
            for result in map['results']:
                if result['name'] == name and result['type'] == 'overlay':
                    return True
    return False

with open("out/scenarioData.json", 'r') as f:
    scenarios = json.load(f)
    with open('../scenarios.json', 'r') as f2:
        scenarioInfos = json.load(f2)
        with open('tiles.json', 'r') as f3:
            tileInfos = json.load(f3) 
            uniqueLayoutTiles = {}            
            for scenario in scenarios:
                id = scenario["id"]
                if 'layout' in scenario:
                    layout = scenario["layout"]
                    for tile in layout:
                        fullName = f"{tile['name']}{tile['orientation']}"
                        if fullName not in uniqueLayoutTiles:
                            uniqueLayoutTiles[fullName] = []
                        uniqueLayoutTiles[fullName].append(id)
                scenarioInfo = scenarioInfos[id]
                if 'overlays' in scenarioInfo:
                    for overlay in scenarioInfo["overlays"]:
                        name = overlay['name']
                        if not findInScenario(name, 'overlay', scenario):
                            print(f"Scenario {id}, Could not find {name} on any maps")
            missingTiles = []
            for tileName in uniqueLayoutTiles.keys():
                if not os.path.isfile(f"assets/tiles/maps/{tileName}.png") and not os.path.isfile(f"assets/tiles/maps/{tileName}-Alt.png"):
                    missingTiles.append(tileName)
                number,name,orientation = tileName.split("-")
                if f"{number}-{orientation}" not in tileInfos:
                    pages = getPages(tileName, uniqueLayoutTiles, scenarioInfos)
                    print(f"Missing Tile info for {tileName}, Pages : {', '.join(pages)}")
            
            missingTiles.sort()
            for tileName in missingTiles:
                pages = getPages(tileName, uniqueLayoutTiles, scenarioInfos)
                print(f"Missing Map Tile {tileName}, Pages : {', '.join(pages)}")