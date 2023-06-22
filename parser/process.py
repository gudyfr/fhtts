import os
import json
import math

doubleTiles = ["Barricade", "Large Snow Corridor", "Log", "Large Water", "Bookshelf", "Control Console", "Large Debris", "Large Cave Rock",
               "Large Dungeon Corridor", "Large Ice Corridor", "Large Cave Corridor", "Large Metal Corridor", "Large Snow Rock", "Power Conduit", "Supply Shelf", "Sarcophagus"]
tripleTiles = ["Tree", "Huge Water", "Large Ice Crystal"]

yDisplacement = [66, -114]
xDisplacement = [132, 0]


def rotateVector(x, y, orientation):
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
            case 0:
                x += xDisplacement[0] / 2
            case 60:
                x += yDisplacement[0] / 2
                y += yDisplacement[1] / 2
            case 300:
                x += yDisplacement[0] / 2
                y -= yDisplacement[1] / 2
    if name in tripleTiles:
        match orientation:
            case 0:
                x += yDisplacement[0]
                y -= yDisplacement[1] / 3
            case 60:
                x += yDisplacement[0]
                y += yDisplacement[1] * 1 / 3
            case 120:
                x += 0
                y -= yDisplacement[1] * 2 / 3
            case 180:
                x -= yDisplacement[0]
                y += yDisplacement[1] / 3
            case 240:
                x -= yDisplacement[0]
                y += yDisplacement[1] * 1 / 3
            case 300:
                x += 0
                y -= yDisplacement[1] / 3
    return x, y


def mapToHexCoordinate(x, y):
    fy = y / yDisplacement[1]
    my = round(fy)
    fx = (x - my * yDisplacement[0]) / xDisplacement[0]
    mx = round(fx)
    return mx, my


def mapFromHexCoordinate(x, y):
    return x*xDisplacement[0] + y*yDisplacement[0], y*yDisplacement[1]


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
            result = 0
        else:
            result = int(orientation)
        # if item['name'] in tripleTiles:
        #     result = result + 180
        #     if result >= 360:
        #         result -= 360
        return result
    else:
        return 0


def removeDuplicates(entries):
    entriesMap = {}
    for entry in entries:
        key = entry["name"] + "-" + str(entry["orientation"])
        if not key in entriesMap:
            entriesMap[key] = {"name": entry["name"],
                               "orientation": entry["orientation"], "positions": []}
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
            entriesToRemove = []
            for entry in entries:
                if entry['name'] == target['name']:
                    if 'selfTarget' in target and target['selfTarget']:
                        if 'random' in trigger:
                            entry['random'] = trigger['random']
                        if 'trigger' in trigger:
                            for position in entry['positions']:
                                position['trigger'] = trigger['trigger']
                    else:
                        entriesToRemove.append(entry)
                        for position in entry['positions']:
                            locationKey = positionToKey(position)
                            triggerLocations[locationKey] = trigger
            for entry in entriesToRemove:
                entries.remove(entry)

    return triggerLocations


def ensureId(trigger):
    if 'trigger' in trigger:
        if not id in trigger['trigger']:
            _in = trigger["in"]
            _target = trigger["target"]
            trigger['trigger']['id'] = f"{_in['type']}/{_in['name']}/{_target['type']}/{_target['name']}"


def attachTriggersToOverlays(overlays, triggerLocations):
    if len(triggerLocations) == 0:
        return
    for overlay in overlays:
        for position in overlay["positions"]:
            key = positionToKey(position)
            if key in triggerLocations:
                trigger = triggerLocations[key]
                overlay_type = trigger['target']['overlay_type'] if 'overlay_type' in trigger['target'] else None
                if overlay_type == None or overlay_type == (position['type'] if 'type' in position else None):
                    if 'trigger' in trigger:
                        position['trigger'] = trigger['trigger']
                    if 'condition' in trigger:
                        position['condition'] = trigger['condition']
                    if 'renamed' in trigger:
                        position['renamed'] = trigger['renamed']
                    if 'rename' in trigger:
                        position['rename'] = trigger['rename']
                    if 'random' in trigger:
                        position['random'] = trigger['random']


def attachItemTriggersToItems(items, triggers):
    for trigger in triggers:
        itemName = trigger['target']['name']
        for item in items:
            if item['name'] == itemName:
                for position in item['positions']:
                    position['trigger'] = trigger['trigger']

def positionToKey(position):
    return f"({position['x']},{position['y']})"

def positionToScore(position):
    if 'deltaY' in position:
        return 0.75 * position['score'] + 0.25 * (1 / (1 + position['deltaY']))
    return position['score']

def mapToPositions(entries):
    result = {}
    for entry in entries:
        for position in entry['positions']:
            name = positionToKey(position)
            score = positionToScore(position)
            if not name in result:
                result[name] = {"name": entry['name'],
                                "score": score}
            else:
                existing = result[name]
                if existing['score'] < score:
                    result[name] = {"name": entry['name'],
                                    "score": score}
    return result


def addToEntries(entries, positions, key, bosses=[]):
    extractedBosses = {}
    entriesToRemove = []
    for entry in entries:
        positionsToRemove = []
        for position in entry['positions']:
            name = positionToKey(position)
            if name in positions:
                position[key] = positions[name]['name'].split('.')[0]
                # Some elite monsters are really bosses
                if position[key] == 'eee':
                    for boss in bosses:
                        if entry['name'] == boss['from']:
                            position[key] = 'bbb'
                            if 'forceStandeeNr' in boss:
                                position['standeeNr'] = boss['forceStandeeNr']
                            bossName = boss['to']
                            if bossName in extractedBosses:
                                extractedBosses[bossName]['positions'].append(
                                    position)
                            else:
                                extractedBosses[bossName] = {"name": boss['to'], "orientation": entry['orientation'], "positions": [position]}
                            positionsToRemove.append(position)        
        entry['positions'] = [position for position in entry['positions'] if position not in positionsToRemove]

        # If we've removed the only instance of that monster, let's remove it
        if len(entry['positions']) == 0:
            entriesToRemove.append(entry)

    for entry in entriesToRemove:
        entries.remove(entry)

    for name, boss in extractedBosses.items():
        entries.append(boss)


def rotateHexCoordinates(x, y, orientation):
    if x == 0 and y == 0:
        return x, y
    match int(orientation):
        case 0: return x, y
        case 60: return -y, x+y
        case 120: return -x-y, x
        case 180: return -x, -y
        case 240: return y, -x-y
        case 300: return x+y, -x
    # return rotateHexCoordinates(x,y,int(orientation)+30)
    raise ValueError(f"unhandled orientation : {orientation}")


def removeTokens(tokens, removedTokens):
    return [token for token in tokens if token['name'] not in removedTokens]


def removeMonsters(monsters, removedMonsters):
    return [monster for monster in monsters if not monster['name'] in removedMonsters]


def elementSize(e):
    if e in tripleTiles:
        return 3
    if e in doubleTiles:
        return 2
    return 1


def getSimpleName(name):
    name = name.replace("Huge ", "")
    name = name.replace("Large ", "")
    return name

def itemSort(e):
    if 'Corridor' in e['name']:
        return f"AAA{e['name']}"
    else:
        return e['name']

def positionSort(pos):
    return f"{pos['x']},{pos['y']}"

def cleanup(entries, layout, scenarioId, keptTokens):
    # Let's remove numberred tokens
    for entry in entries:
        tokensToRemove = []
        tokens = entry['tokens']
        for token in tokens:
            tokenNamesToRemove = ['1', '1g', '2', '2g', '3', '3g',
                                  '4', '4g', '5', '6', '7', '8', '9', '10', '11', '12']
            tokenNamesToRemove = [
                token for token in tokenNamesToRemove if token not in keptTokens]
            if token['name'] in tokenNamesToRemove:
                hasTrigger = False
                for position in token['positions']:
                    if 'trigger' in position:
                        hasTrigger = True
                if not hasTrigger:
                    tokensToRemove.append(token)
        entry['tokens'] = [
            token for token in tokens if token not in tokensToRemove]

    # Let's remove duplicate overlays (same name, same position)
    overlaysPerPosition = {}
    for entry in entries:
        origin = None
        reference = entry['reference']['tile']
        for tile in layout:
            if tile['name'] == reference:
                origin = tile['origin']
        if origin != None:
            for overlay in entry['overlays']:
                overlayPositions = [{'x': 0, 'y': 0}]
                if overlay['name'] in doubleTiles:
                    overlayPositions = [{'x': 0, 'y': 0}, {'x': -1, 'y': 0}]
                if overlay['name'] in tripleTiles:
                    overlayPositions = [{'x': 0, 'y': 0}, {
                        'x': -1, 'y': 0}, {'x': -1, 'y': 1}]
                actualPositions = []
                for position in overlayPositions:
                    x, y = rotateHexCoordinates(
                        position['x'], position['y'], overlay['orientation'])
                    actualPositions.append(
                        {'x': x + origin['x'], 'y': y+origin['y']})

                for position in overlay['positions']:
                    for subPosition in actualPositions:
                        positionName = f"{subPosition['x']+position['x']},{subPosition['y']+position['y']}"
                        if not positionName in overlaysPerPosition:
                            overlaysPerPosition[positionName] = []
                        overlays = overlaysPerPosition[positionName]
                        overlays.append(
                            {'overlay': overlay, 'position': position, 'reference': reference})
        else:
            print(f"No reference Tile in {scenarioId}")

    for position, overlays in overlaysPerPosition.items():
        if len(overlays) > 1:
            # Sort the overlays by size
            overlays.sort(key=lambda e: elementSize(
                e['overlay']['name']), reverse=True)
            validOverlays = []
            for overlayHolder in overlays:
                overlay = overlayHolder['overlay']
                simpleName = getSimpleName(overlay['name'])
                isValid = True
                for validOverlay in validOverlays:
                    if getSimpleName(validOverlay['name']) == simpleName:
                        isValid = False
                if isValid:
                    validOverlays.append(overlay)
                else:
                    if overlayHolder['position'] in overlay['positions']:
                        print(
                            f"Removing {overlay['name']} at {overlayHolder['position']} in reference {overlayHolder['reference']} of {scenarioId}")
                        overlay['positions'].remove(overlayHolder['position'])

    for entry in entries:
        entry['overlays'] = [overlay for overlay in entry['overlays']
                             if len(overlay['positions']) > 0]
        entry['overlays'].sort(key=itemSort)
        for monster in entry['monsters']:
            for position in monster['positions']:
                if 'levels' in position:
                    position['levels'] = position['levels'][0:3]
        entry['monsters'].sort(key=itemSort)
        for type in ['overlays', 'monsters']:
            for item in entry[type]:
                item['positions'].sort(key=positionSort)

    return [entry for entry in entries if len(entry['tokens']) > 0 or len(
        entry['overlays']) > 0 or len(entry['monsters']) > 0]


def safeGetOrEmptyList(dict, key):
    return dict[key] if key in dict else []


def processMap(tileInfos, mapData, mapTriggers, scenarioSpecials):    
    removedTokens = safeGetOrEmptyList(scenarioSpecials, 'remove-tokens')
    removedMonsters = safeGetOrEmptyList(scenarioSpecials, 'remove-monsters')
    bosses = safeGetOrEmptyList(scenarioSpecials, 'bosses')
    renamed = safeGetOrEmptyList(scenarioSpecials, 'rename')
    tileOrder = safeGetOrEmptyList(scenarioSpecials, 'tile-order')

    result = {"type": mapData["type"], "name": mapData["name"]}

    # offsetsByReference = {}
    # resultsByReference = {}
    # attractorsByReference = {}
    references = []

    subResults = []
    entries = mapData['results']

    tiles = list(filter(lambda e: e['type'] == "tile", entries))
    tileCenters = []
    tileNames = []
    # First we should try and find tiles
    if len(tiles) > 0:
        # We need to flatten the tiles
        allTiles = []
        for tile in tiles:
            for position in tile['results']:
                allTiles.append(
                    {'name': tile['name'], 'orientation': tile['orientation'], 'position': position})

        allTiles.sort(key=lambda e: e['position']['score'], reverse=True)
        for tile in allTiles:
            tileNumber, tileName = getTileNumberAndName(tile['name'])
            tileOrientation = tile['orientation'].split("-")[1]
            if tileNumber in tileInfos:
                tileInfo = tileInfos[tileNumber]
                tileOffset = tileInfo['offset']
                flipped = True if tileName in [
                    'B', 'D', 'F', 'H', 'J', 'L'] else False
                if flipped and 'offset_flipped' in tileInfo:
                    tileOffset = tileInfo['offset_flipped']
                angle = tileInfo['angle'] if 'angle' in tileInfo else 0
                tileX, tileY = getCenterPoint(tile['position'])
                skip = False
                for tileCenter in tileCenters:
                    dx = tileCenter['x'] - tileX
                    dy = tileCenter['y'] - tileY
                    distance = math.sqrt(dx*dx+dy*dy)
                    if distance < 100:
                        skip = True
                if tile['name'] in tileNames:
                    # If we already have a tile with the same name, add a higher constraint on the matching score
                    if tile['position']['score'] < 0.95:
                        skip = True

                if not skip:
                    tileNames.append(tile['name'])
                    tileCenters.append({'x': tileX, 'y': tileY})
                    effectiveOrientation = int(tileOrientation) - angle
                    tOX, tOY = rotateVector(
                        tileOffset["x"], tileOffset["y"], effectiveOrientation)
                    xOffset = tileX + tOX
                    yOffset = tileY + tOY
                    # Calculate the coordinate of the attractors
                    attractors = tileInfo['attractors'] if 'attractors' in tileInfo else [
                        {'x': -tileInfo['origin']['x'], 'y':-tileInfo['origin']['y']}]
                    processedAttractors = []
                    for attractor in attractors:
                        x, y = rotateHexCoordinates(
                            attractor['x'], attractor['y'], effectiveOrientation)
                        dx, dy = mapFromHexCoordinate(x, y)
                        processedAttractors.append(
                            {"x": dx+xOffset, "y": dy + yOffset})

                    references.append({
                        'tile': tile["name"],
                        'attractors': processedAttractors,
                        'results': {"reference": {"tile": tile['name'], "tileOrientation": f"{effectiveOrientation}"}},
                        'offset': {"x": xOffset, "y": yOffset},
                        'outputs': [],
                        'processed': {}})

                    # attractorsByReference[tile["name"]] = processedAttractors
                    # resultsByReference[tile["name"]] = {"reference":{"tile" : tile['name'], "tileOrientation" : f"{effectiveOrientation}"}}
                    # offsetsByReference[tile["name"]] = {"x" : xOffset, "y" : yOffset}
        references.sort(key= lambda e : tileOrder.index(e['tile']) if e['tile'] in tileOrder else 99)

        # We now have a reference point (0,0) at tileOffset
        # map every object we've found to its tile coordinate
        overlays = filter(lambda e: e['type'] == 'overlay', entries)
        overlayTypes = filter(lambda e: e['type'] == 'overlay types', entries)
        monsters = filter(lambda e: e['type'] == 'monster', entries)
        monsterLevels = filter(
            lambda e: e['type'] == 'monster levels', entries)
        tokens = filter(lambda e: e['type'] == 'tokens', entries)

        all = {
            "overlays": overlays,
            "overlayTypes": overlayTypes,
            "monsters": monsters,
            "monsterLevels": monsterLevels,
            "tokens": tokens
        }
        for key, items in all.items():

            for reference in references:
                reference["outputs"] = []

            for item in items:
                name = getName(item)
                orientation = getOrientation(item)
                for nameMapping in renamed:
                    if nameMapping['from'] == name:
                        name = nameMapping['to']
                for reference in references:
                    reference["itemOutput"] = {
                        "name": name, "orientation": orientation, "positions": []}
                for r in item['results']:
                    x, y = getCenterPoint(r, name, orientation)
                    # Determine the best tile
                    bestReference = None
                    bestDistance = 10000
                    for reference in references:
                        attractors = reference['attractors']

                        for attractor in attractors:
                            dX = x - attractor['x']
                            dY = y - attractor['y']
                            # monsters have a small x offset (because of the level indicator)
                            if key == "monsterLevels":
                                # if name ends with s, it's a monster on an overlay, so the offset is smaller
                                if name[-1] == 's':
                                    dX = dX + 30
                                else:
                                    dX = dX + 44
                                dY = dY - 9
                            distance = math.sqrt(dX*dX+dY*dY)
                            betterMatch = bestReference == None                            
                            if distance < bestDistance:
                                fuzzyDoorMatch = len(tileOrder) > 0 and ("Door" in name or key == "tokens")
                                if not fuzzyDoorMatch or distance < bestDistance-300:
                                    betterMatch = True
                            if betterMatch:
                                bestDistance = distance
                                bestReference = reference
                    xOffset = bestReference['offset']["x"]
                    yOffset = bestReference['offset']["y"]

                    relativeX = x-xOffset
                    relativeY = y-yOffset
                    x, y = mapToHexCoordinate(x-xOffset, y-yOffset)
                    outputPosition = {"x": x, "y": y, "score": r["score"]}
                    if key == "monsterLevels":
                        # Calculate the deviation from the ideal position
                        tx,ty = mapFromHexCoordinate(x,y)
                        outputPosition['deltaY'] = abs(relativeY-ty-10)
                    bestReference["itemOutput"]["positions"].append(outputPosition)

                    for reference in references:
                        if len(reference['itemOutput']["positions"]) > 0:
                            reference["outputs"].append(
                                reference['itemOutput'])

            for reference in references:
                output = removeDuplicates(reference["outputs"])
                reference["processed"][key] = output

        for reference in references:
            processed = reference["processed"]
            subResult = {}
            subResult['reference'] = reference['results']['reference']
            # We simply copy over the overlays
            processedTokens = removeScore(processed["tokens"])
            processed['tokens'] = removeTokens(
                processed["tokens"], removedTokens)

            tokenTriggerLocations = removeTriggers(
                processedTokens, mapTriggers)
            subResult["tokens"] = processedTokens

            overlayTriggers = list(
                filter(lambda e: e['target']['type'] == 'overlay', mapTriggers))
            attachItemTriggersToItems(
                processed['overlays'], overlayTriggers)
            attachTriggersToOverlays(
                processed['overlays'], tokenTriggerLocations)
            
            monsterTriggers = list(
                filter(lambda e: e['target']['type'] == 'monster', mapTriggers))
            
            attachItemTriggersToItems(processed['monsters'], monsterTriggers)

            processed['monsters'] = removeMonsters(
                processed['monsters'], removedMonsters)

            positionToMonsterLevels = mapToPositions(
                processed['monsterLevels'])
            positionToOverlayTypes = mapToPositions(processed['overlayTypes'])
            addToEntries(processed['monsters'], positionToMonsterLevels, "levels", list(filter(
                lambda e: e['in'] == mapData["name"] if 'in' in e else True, bosses)))
            addToEntries(processed['overlays'], positionToOverlayTypes, "type")
           

            subResult["monsters"] = removeScore(processed['monsters'])
            subResult["overlays"] = removeScore(processed['overlays'])
            subResults.append(subResult)

        result['entries'] = subResults #cleanup(subResults, layout, scenarioId, keepTokens)

    globalTriggers = list(map(lambda e: e['trigger'], [trigger for trigger in mapTriggers if trigger['target']['type'] == 'global']))
    result['triggers'] = globalTriggers

    return result


def getTileNumberAndName(name):
    parts = name.split("-")
    return parts[0], parts[1]


def processLayout(layout: list, removedTiles: list, scenarioSpecials: dict):
    shiftX = scenarioSpecials['shiftX'] if 'shiftX' in scenarioSpecials else 0
    shiftY = scenarioSpecials['shiftY'] if 'shiftY' in scenarioSpecials else 0
    # Remove tiles based on special rules
    layout = [tile for tile in layout if tile['name'] not in removedTiles]

    # larger tiles tend to be more accurate in positioning, so use those are a reference
    layout.sort(reverse=True, key=lambda e: e['name'])

    originPosition = None
    result = []
    averageX = 0
    averageY = 0
    for tile in layout:
        number, name = getTileNumberAndName(tile['name'])
        orientation = tile['orientation'].split("-")[1]
        # TODO : Handle multiple occurences of the same tile (one scenario does that...)
        position = tile['positions'][0]
        tileInfo = tileInfos[number]
        tileCenter = tileInfo['center']
        flipped = True if name in ['B', 'D', 'F', 'H', 'J', 'L'] else False
        if flipped and 'center_flipped' in tileInfo:
            tileCenter = tileInfo['center_flipped']

        effectiveOrientation = int(orientation)
        if 'angle' in tileInfo:
            effectiveOrientation -= tileInfo['angle']

        dx, dy = rotateVector(
            tileCenter['x'], tileCenter['y'], effectiveOrientation)
        cx, cy = getCenterPoint(position)
        if originPosition == None:
            originPosition = {"x": cx + dx, "y": cy+dy}

        x = cx + dx - originPosition['x']
        y = cy + dy - originPosition['y']

        hx, hy = mapToSmallHexCoordinate(x, y)
        # Apply the offset to the origin
        origin = tileInfo['origin']
        if flipped and 'origin_flipped' in tileInfo:
            origin = tileInfo['origin_flipped']
        ox, oy = rotateHexCoordinates(
            origin['x'], origin['y'], effectiveOrientation)
        result.append({"name": f"{number}-{name}", "orientation": orientation,
                      "center": {"x": hx, "y": hy}, "origin": {"x": hx+ox, "y": hy+oy}})
        averageX += hx
        averageY += hy

    # Attempt to center the map
    if len(result) > 0:
        averageX = int(averageX/len(result))
        averageY = int(averageY/len(result))
        for r in result:
            for key in ["center", "origin"]:
                r[key]["x"] = r[key]["x"] - averageX + shiftX
                r[key]["y"] = r[key]["y"] - averageY + shiftY

    result.sort(key=lambda e: e['name'])
    return result


def loadTriggers():
    with open("triggers.json", 'r') as f:
        triggers = json.load(f)
        for key, scenarioTriggers in triggers.items():
            for trigger in scenarioTriggers:
                ensureId(trigger)
        return triggers


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
            scenarioOutput = {"id": id}
            scenarioTriggers = safeGetOrEmptyList(triggers, id)
            scenarioSpecials = safeGetOrEmptyList(specials, id)
            removedMaps = safeGetOrEmptyList(scenarioSpecials, 'remove-maps')
            removedTiles = safeGetOrEmptyList(scenarioSpecials, 'remove-tiles')
            
            if 'set-layout' in scenarioSpecials:
                scenarioOutput['layout'] = scenarioSpecials['set-layout']
            else:
                if 'layout' in scenario:
                    scenarioOutput['layout'] = processLayout(
                        scenario['layout'], removedTiles, scenarioSpecials)
            if 'maps' in scenario:
                mapsOutput = []
                for scenarioMap in scenario['maps']:
                    removed = False
                    for removedMap in removedMaps:
                        if removedMap['type'] == scenarioMap['type'] and removedMap['name'] == scenarioMap['name']:
                            removed = True
                    if not removed:
                        mapTriggers = list(filter(
                            lambda e: e['in']['type'] == scenarioMap['type'] and e['in']['name'] == scenarioMap['name'], scenarioTriggers))
                        result = processMap(tileInfos, scenarioMap, mapTriggers, scenarioSpecials)
                        mapsOutput.append(result)
                entriesToMap = safeGetOrEmptyList(
                    scenarioSpecials, 'entries-to-map')
                for entryToMap in entriesToMap:
                    entryToMove = None
                    for _map in mapsOutput:
                        matches = True
                        for key, value in entryToMap['in'].items():
                            if _map[key] != value:
                                matches = False
                        if matches:
                            for entry in _map['entries']:
                                havingFullfiled = False
                                for key, value in entryToMap['having'].items():
                                    if key == 'reference':
                                        if value == entry['reference']['tile']:
                                            entryToMove = entry
                                    else:
                                        for item in entry[f"{key}s"]:
                                            for fieldKey, fieldValue in value.items():
                                                if item[fieldKey] == fieldValue:
                                                    entryToMove = entry
                    if entryToMove != None:
                        destination = None
                        for _map in mapsOutput:
                            if entryToMove in _map['entries']:
                                _map['entries'].remove(entryToMove)
                        for _map in mapsOutput:
                            matches = True
                            for key, value in entryToMap['to'].items():
                                if _map[key] != value:
                                    matches = False
                            if matches:
                                destination = _map
                        if destination == None:
                            destination = entryToMap['to']
                            destination['entries'] = []
                            mapsOutput.append(destination)
                        destination['entries'].append(entryToMove)

                keepTokens = safeGetOrEmptyList(scenarioSpecials, 'keep-tokens')
                for _map in mapsOutput:
                    if 'entries' in _map:
                        _map['entries'] = cleanup(_map['entries'], scenarioOutput['layout'] if 'layout' in scenarioOutput else {}, id, keepTokens)

                scenarioOutput['maps'] = mapsOutput

            scenariosOutput[id] = scenarioOutput
        with open("../processedScenarios.human.json", 'w') as fw:
            json.dump(scenariosOutput, fw, indent=2)
        with open("../docs/processedScenarios3.json", 'w') as fw:
            json.dump(scenariosOutput, fw)
