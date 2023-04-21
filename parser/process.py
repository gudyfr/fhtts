import os
import json
import math

doubleTiles = ["Large Snow Corridor"]
tripleTiles = ["Tree"]
yDisplacement = [66, -114]
xDisplacement = [132, 0]



def rotateVector(x,y, orientation):
    angle = -orientation*math.pi / 180
    ox = x * math.cos(angle) - y * math.sin(angle)
    oy = x * math.sin(angle) + y * math.cos(angle)
    return [ox, oy]

def getCenterPoint(result, name="", orientation=0):
    position = result["position"]
    size = result["size"]
    x = position["x"] + size["x"] / 2
    y = position["y"] + size["y"] / 2
    if name in doubleTiles:
        match orientation:
            case 0 :
                x -= xDisplacement[0] / 2
            case 60 :
                x -= yDisplacement[0] / 2
                y -= yDisplacement[1] / 2
            case 300:
                x -= yDisplacement[0] / 2
                y += yDisplacement[1] / 2
    if name in tripleTiles:
        match orientation:
            case 0:
                x -= yDisplacement[0] / 2
                y -= yDisplacement[1] / 2
            case 180:
                x -= yDisplacement[0] / 2
                y += yDisplacement[1] / 2
    return x, y

def mapToHexCoordinate(xOffset,yOffset, x, y):   
    fy = (y-yOffset) / yDisplacement[1]
    my = round(fy)
    fx = (x - xOffset - my * yDisplacement[0]) / xDisplacement[0]
    mx = round(fx)
    return mx, my

def getNameAndOrientation(assetName):
    if "-" in assetName:
        parts = assetName.split("-")
        return parts[0], parts[1]
    else:
        return assetName.split('.')[0], 0

def removeDuplicates(entries):
    entriesMap = {}
    for entry in entries:
        key = entry["name"] + "-" + str(entry["orientation"])
        if not key in entriesMap:
            entriesMap[key] = {"name" : entry["name"], "orientation" : entry["orientation"], "positions":[]}
        entryOutput = entriesMap[key]
        for position in entry["positions"]:
            found = False
            for otherPosition in entryOutput["positions"]:
                if otherPosition["x"] == position["x"] and otherPosition["y"] == position["y"]:
                    found = True
            if not found:
                entryOutput["positions"].append(position)
    return list(entriesMap.values())

def removeScore(entries):
    for entry in entries:
        for position in entry["positions"]:
            position.pop("score")
    return entries

def positionToKey(position):
    return f"({position['x']},{position['y']})"

def mapToPositions(entries):
    result = {}
    for entry in entries:
        for position in entry['positions']:
            name = positionToKey(position)
            if not name in result:
                result[name] = {"name" : entry['name'], "score" : position['score']}
            else:
                existing = result[name]
                if existing['score'] < position['score']:
                    result[name] = {"name" : entry['name'], "score" : position['score']}
    return result

def addToEntries(entries, positions, key):
    for entry in entries:
        for position in entry['positions']:
            name = positionToKey(position)
            if name in positions:
                position[key] = positions[name]['name'].split('.')[0]

def processMap(tileInfos, map):
    result = {}
    entries = map['results']
    tiles = list(filter(lambda e : e['type'] == "tile", entries))
    # First we should try and find tiles    
    if len(tiles) > 0:
        reference = tiles[0]
        tileNumber = reference['name'].split("-")[0]
        tileOrientation = reference['orientation'].split("-")[1]
        if tileNumber in tileInfos:
            tileInfo = tileInfos[tileNumber]
            tileOffset = tileInfo['offset']
            tileX,tileY = getCenterPoint(reference["results"][0])
            tOX,tOY = rotateVector(tileOffset["x"], tileOffset["y"], int(tileOrientation))
            xOffset = tileX + tOX
            yOffset = tileY + tOY
            result['reference'] = {"tile" : reference['name'], "tileOrientation" : tileOrientation}
            # We now have a reference point (0,0) at tileOffset
            # map every object we've found to its tile coordinate
            overlays = filter(lambda e :e['type'] == 'overlay', entries)
            overlayTypes = filter(lambda e :e['type'] == 'overlay types', entries)
            monsters = filter(lambda e :e['type'] == 'monster', entries)
            monsterLevels = filter(lambda e :e['type'] == 'monster levels', entries)
            tokens = filter(lambda e :e['type'] == 'tokens', entries)
            
            all = {
                "overlays" : overlays,
                "overlayTypes" : overlayTypes,
                "monsters" : monsters,
                "monsterLevels" : monsterLevels,
                "tokens" : tokens
            }
            processed = {}
            for key,items in all.items():
                output = []
                for item in items:
                    name, orientation = getNameAndOrientation(item["name"])                
                    itemOutput = {"name" : name, "orientation" : orientation}
                    positions = []
                    for r in item['results']:
                        x,y = getCenterPoint(r, name, orientation)
                        x,y = mapToHexCoordinate(xOffset, yOffset, x, y)
                        positions.append({"x":x, "y":y, "score" : r["score"]})
                    itemOutput["positions"] = positions
                    output.append(itemOutput)
                output = removeDuplicates(output)
                processed[key] = output
            
            # We simply copy over the overlays
            result["tokens"] = removeScore(processed["tokens"])

            positionToMonsterLevels = mapToPositions(processed['monsterLevels'])
            positionToOverlayTypes = mapToPositions(processed['overlayTypes'])
            addToEntries(processed['monsters'], positionToMonsterLevels, "levels")
            addToEntries(processed['overlays'], positionToOverlayTypes, "type")

            result["monsters"] = removeScore(processed['monsters'])
            result["overlays"] = removeScore(processed['overlays'])

    return result


with open("tileInfos.json", 'r') as tf:
    tileInfos = json.load(tf)
    with open("out/scenarioData.json", 'r') as f:    
        scenarios = json.load(f)
        scenariosOutput = []
        for scenario in scenarios:
            scenarioOutput = {"id" :scenario["id"]}            
            if 'maps' in scenario:
                mapsOutput = []
                for map in scenario['maps']:
                    result = processMap(tileInfos, map)
                    mapsOutput.append(result)
                scenarioOutput['maps'] = mapsOutput
            scenariosOutput.append(scenarioOutput)
        with open("out/processedScenarios.json", 'w') as fw:
            json.dump(scenariosOutput, fw, indent=2)