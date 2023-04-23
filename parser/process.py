import os
import json
import math

doubleTiles = ["Large Snow Corridor", "Log", "Large Water", "Bookshelf", "Control Console", "Large Debris", "Large Cave Rock", "Large Dungeon Corridor", "Large Ice Corridor", "Large Cave Corridor", "Large Metal Corridor", "Large Snow Rock", "Power Conduit", "Supply Shelf", "Sarcophagus"]
tripleTiles = ["Tree", "Huge Water", "Large Ice Crystal"]

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
                x += xDisplacement[0] / 2
            case 60 :
                x += yDisplacement[0] / 2
                y += yDisplacement[1] / 2
            case 300:
                x += yDisplacement[0] / 2
                y -= yDisplacement[1] / 2
    if name in tripleTiles:
        match orientation:
            case 0:
                x -= yDisplacement[0]
                y += yDisplacement[1] / 3
            case 60:
                y += yDisplacement[1] * 2 /3
            case 120:
                x += yDisplacement[0]
                y += yDisplacement[1] / 3
            case 180:
                x -= yDisplacement[0]
                y -= yDisplacement[1] / 3
            case 240:
                y -= yDisplacement[1] * 2 / 3
            case 300:
                x -= yDisplacement[0] / 2
                y -= yDisplacement[1] / 2
    return x, y

def mapToHexCoordinate(x, y):   
    fy = y / yDisplacement[1]
    my = round(fy)
    fx = (x - my * yDisplacement[0]) / xDisplacement[0]
    mx = round(fx)
    return mx, my


smallYDisplacement = [14.71, -25.4]
smallXDisplacement = [29.42, 0]
def mapToSmallHexCoordinate(x, y):   
    fy = y / smallYDisplacement[1]
    my = round(fy)
    fx = (x - my * smallYDisplacement[0]) / smallXDisplacement[0]
    mx = round(fx)
    return mx, my

def getName(item):
    assetName = item['name']
    if "-" in assetName:
        parts = assetName.split("-")
        return parts[0]
    else:
        return assetName.split('.')[0]

def getOrientation(item):
    if 'orientation' in item:
        orientation = item['orientation']
        result = 0
        if '-' in orientation:
            parts = orientation.split('-')
            result = int(parts[1])
        elif orientation == "":
            result =  0
        else:
            result =  int(orientation)
        if item['name'] in tripleTiles:
            result = 360 - result
            # if result >= 360:
            #     result -= 360
        return result
    else:
        return 0
    
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

def removeTriggers(entries, mapTriggers):
    triggerLocations = {} 
    for trigger in mapTriggers:
        target = trigger['target']
        if target['type'] == 'token':
            for entry in entries:
                if entry['name'] == target['name']:
                    entries.remove(entry)
                    for position in entry['positions']:
                        locationKey = positionToKey(position)
                        triggerLocations[locationKey] = trigger
    return triggerLocations

def attachTriggersToOverlays(overlays, triggerLocations):
    if len(triggerLocations) == 0:
        return
    for overlay in overlays:
        for position in overlay["positions"]:
            key = positionToKey(position)
            if key in triggerLocations:
                position['trigger'] = triggerLocations[key]['data']

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

def addToEntries(entries, positions, key, bosses=[]):
    for entry in entries:
        for position in entry['positions']:
            name = positionToKey(position)
            if name in positions:
                if entry['name'] in bosses:
                    position[key] = 'bbb'
                else:
                    position[key] = positions[name]['name'].split('.')[0]

def rotateHexCoordinates(x,y,orientation):
    match int(orientation):
        case 0: return x,y
        case 60: return -y,x+y
        case 120: return -x-y,x
        case 180: return -x,-y
        case 240: return y,-x-y
        case 300: return x+y,-x
    # return rotateHexCoordinates(x,y,int(orientation)+30)
    raise ValueError(f"unhandled orientation : {orientation}")


def removeTokens(tokens, scenarioSpecials):
    if 'remove-tokens' in scenarioSpecials:
        for tokenToRemove in scenarioSpecials['remove-tokens']:
            for token in tokens:
                if token['name'] == tokenToRemove:
                    tokens.remove(token)

def processMap(tileInfos, map, mapTriggers, scenarioSpecials):
    bosses = scenarioSpecials['bosses'] if 'bosses' in scenarioSpecials else []
    result = {"type" : map["type"], "name" : map["name"]}
    entries = map['results']
    tiles = list(filter(lambda e : e['type'] == "tile", entries))
    # First we should try and find tiles    
    if len(tiles) > 0:
        tiles.sort(key= lambda e: e['results'][0]['score'], reverse=True)
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
                    name = getName(item)
                    orientation = getOrientation(item)                
                    itemOutput = {"name" : name, "orientation" : orientation}
                    positions = []
                    for r in item['results']:
                        x,y = getCenterPoint(r, name, orientation)
                        x,y = mapToHexCoordinate(x-xOffset, y-yOffset)
                        positions.append({"x":x, "y":y, "score" : r["score"]})
                    itemOutput["positions"] = positions
                    output.append(itemOutput)
                output = removeDuplicates(output)
                processed[key] = output
            
            # We simply copy over the overlays
            processedTokens = removeScore(processed["tokens"])
            removeTokens(processed["tokens"], scenarioSpecials)

            triggerLocations = removeTriggers(processedTokens, mapTriggers)
            result["tokens"] = processedTokens

            attachTriggersToOverlays(processed['overlays'], triggerLocations)

            positionToMonsterLevels = mapToPositions(processed['monsterLevels'])
            positionToOverlayTypes = mapToPositions(processed['overlayTypes'])
            addToEntries(processed['monsters'], positionToMonsterLevels, "levels", bosses)
            addToEntries(processed['overlays'], positionToOverlayTypes, "type")

            result["monsters"] = removeScore(processed['monsters'])
            result["overlays"] = removeScore(processed['overlays'])

    return result

def getTileNumberAndName(name):
    parts = name.split("-")
    return parts[0],parts[1]

def processLayout(layout:list, removedTiles:list):
    # Remove tiles based on special rules
    for removedTile in removedTiles:
        for tile in layout:
            if tile['name'] == removedTile:
                layout.remove(tile)
    
    # larger tiles tend to be more accurate in positioning, so use those are a reference
    layout.sort(reverse=True, key=lambda e:e['name'])

    originPosition = None
    result = []
    averageX = 0
    averageY = 0
    for tile in layout:
        number,name = getTileNumberAndName(tile['name'])
        orientation = tile['orientation'].split("-")[1]
        # TODO : Handle multiple occurences of the same tile (one scenario does that...)
        position = tile['positions'][0]
        tileInfo = tileInfos[number]
        tileCenter = tileInfo['center']
        flipped = True if name in ['B','D','F','H','J','L'] else False
        if flipped and 'center_flipped' in tileInfo:
            tileCenter = tileInfo['center_flipped']
        
        effectiveOrientation = int(orientation)
        if 'angle' in tileInfo:
            effectiveOrientation -= tileInfo['angle']
        
        dx,dy = rotateVector(tileCenter['x'], tileCenter['y'], effectiveOrientation)
        cx,cy = getCenterPoint(position)
        if originPosition == None:            
            originPosition = {"x":cx + dx, "y": cy+dy}
        
        x = cx + dx - originPosition['x'] 
        y = cy + dy - originPosition['y']

        hx,hy = mapToSmallHexCoordinate(x,y)
        # Apply the offset to the origin
        origin = tileInfo['origin']
        if flipped and 'origin_flipped' in tileInfo:
            origin = tileInfo['origin_flipped']
        ox,oy = rotateHexCoordinates(origin['x'], origin['y'], effectiveOrientation)
        result.append({"name" : f"{number}-{name}", "orientation" : orientation, "center" : {"x" : hx, "y": hy}, "origin" : {"x" : hx+ox, "y":hy+oy}})
        averageX += hx
        averageY += hy

    # Attempt to center the map
    if len(result) > 0:
        averageX = int(averageX/len(result))
        averageY = int(averageY/len(result))
        for r in result:
            for key in ["center", "origin"]:
                r[key]["x"] = r[key]["x"] - averageX
                r[key]["y"] = r[key]["y"] - averageY
    return result


def loadTriggers():
    with open("triggers.json", 'r') as f:
        return json.load(f)

def loadSpecials():
    with open("specials.json", 'r') as f:
        return json.load(f)
    
with open("tileInfos.json", 'r') as tf:
    tileInfos = json.load(tf)
    with open("out/scenarioData.json", 'r') as f:    
        scenarios = json.load(f)
        triggers = loadTriggers()
        specials = loadSpecials()
        scenariosOutput = {}
        for scenario in scenarios:
            id = scenario["id"]
            scenarioOutput = {"id" :id}
            scenarioTriggers = triggers[id] if id in triggers else []
            scenarioSpecials = specials[id] if id in specials else []
            removedMaps = scenarioSpecials['remove-maps'] if 'remove-maps' in scenarioSpecials else []
            removedTiles = scenarioSpecials['remove-tiles'] if 'remove-tiles' in scenarioSpecials else []
            if 'maps' in scenario:
                mapsOutput = []
                for map in scenario['maps']:
                    removed = False
                    for removedMap in removedMaps:
                        if removedMap['type'] == map['type'] and removedMap['name'] == map['name']:
                            removed = True
                    if not removed :
                        mapTriggers = filter(lambda e : e['in']['type'] == map['type'] and e['in']['name'] == map['name'], scenarioTriggers)        
                        result = processMap(tileInfos, map, mapTriggers, scenarioSpecials)
                        mapsOutput.append(result)
                scenarioOutput['maps'] = mapsOutput
            if 'layout' in scenario:                
                scenarioOutput['layout'] = processLayout(scenario['layout'], removedTiles)
            scenariosOutput[id] = scenarioOutput
        with open("out/processedScenarios.human.json", 'w') as fw:
            json.dump(scenariosOutput, fw, indent=2)
        with open("out/processedScenarios.json", 'w') as fw:
            json.dump(scenariosOutput, fw)