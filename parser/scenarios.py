import os
import sys
import json
import math
import cv2 as cv
import numpy as np
from matplotlib import pyplot as plt


def distance(pt1, pt2):
    dX = pt1[0] - pt2[0]
    dY = pt1[1] - pt2[1]
    return math.sqrt(dX*dX+dY*dY)


def positionToJson(pt, w, h, score, xOffset, yOffset):
    return {
        "position": {
            "x": pt[0] + xOffset,
            "y": pt[1] + yOffset
        },
        "size": {
            "x": w,
            "y": h,
        },
        "score": score
    }


templateCache = {}

def identify(out, img, templateFile, xOffset, yOffset, threshold=0.94, showMatch=True, printMatch=True):
    template = None
    mask = None
    if templateFile in templateCache:
        cache = templateCache[templateFile]
        template = cache["template"]
        mask = cache["mask"]
    else:
        template = cv.imread(templateFile, flags=cv.IMREAD_UNCHANGED)
        assert template is not None, "template file could not be read, check with os.path.exists()"
        _, _, _, a_channel = cv.split(template)
        _, mask = cv.threshold(a_channel, thresh=254,
                            maxval=255, type=cv.THRESH_BINARY)
        templateCache[templateFile] = {"template" : template, "mask" : mask}
    
    if printMatch:
        print(f"Checking {templateFile}")

    w, h = mask.shape[::-1]
    res = cv.matchTemplate(img, template, cv.TM_CCOEFF_NORMED, mask=mask)
    loc = np.where((res >= threshold) & (res <= 1.01))
    result = []
    for pt in zip(*loc[::-1]):
        close = False
        for r in result:
            if distance(r, pt) < 10:
                close = True
                if res[r[1]][r[0]] < res[pt[1]][pt[0]]:
                    #  We have a better match
                    result.remove(r)
                    result.append(pt)
        if not close:
            result.append(pt)
    output = []
    for pt in result:
        score = res[pt[1]][pt[0]]
        if printMatch:
            print("\t\tFound {} at ({}, {}) {}".format(
                templateFile, pt[0], pt[1], score))
        if showMatch:
            cv.rectangle(out, (pt[0] + xOffset, pt[1]+yOffset),
                         (pt[0] + w + xOffset, pt[1] + h+yOffset), (0, 0, 255), 2)
        output.append(positionToJson(pt, w, h, score, xOffset, yOffset))

    return output


def loadScenarios():
    with open('../docs/scenarios.json', 'r') as openfile:
        return json.load(openfile)

def loadTiles():
    with open('tiles.json', 'r') as openfile:
        return json.load(openfile)

def loadPatches():
    with open('parserPatches.json','r') as f:
        return json.load(f)
    
class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'


class NpEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, np.integer):
            return int(obj)
        if isinstance(obj, np.floating):
            return float(obj)
        if isinstance(obj, np.ndarray):
            return obj.tolist()
        return super(NpEncoder, self).default(obj)



# maps = os.listdir('assets/images/')
scenarios = loadScenarios()
tileInfos = loadTiles()
patches = loadPatches()
scenarioIds = []
args = sys.argv[1:]
parseLayouts = False
parseMaps = False
verbose = False
startAt = 0
if "-verbose" in args:
    args.remove("-verbose")
    verbose = True
if "-layout" in args:
    args.remove('-layout')
    parseLayouts = True
if "-map" in args:
    args.remove('-map')
    parseMaps = True
if "-all" in args:
    args.remove('-all')
    scenarioIds = scenarios.keys()
if "-after" in args:
    args.remove('-after')
    startAt = int(args[0]) + 1    
    scenarioIds = list(scenarios.keys())
    index = scenarioIds.index(f"{startAt}")
    scenarioIds = scenarioIds[index:]

for arg in args:
    scenarioIds.append(arg)


def getScore(elem):
    return elem["score"]

def removeDuplicateTilesWihtWrongOrientation(tiles, scenarioData):
    if 'layout' in scenarioData:
        scenarioLayout = scenarioData['layout']
        tilesByName = {}
        for tile in tiles:
            name = tile["name"]
            if not name in tilesByName:
                tilesByName[name] = []
            tilesByName[name].append(tile)
        for key,foundTiles in tilesByName.items():
            if len(foundTiles) > 1:
                foundTiles.sort(key=lambda e:e['positions'][0]['score'], reverse=True)
                # Do we have this tile in the layout?
                for layoutTile in scenarioLayout:
                    if layoutTile['name'] == key:
                        # If one matches the target orientation, let's keep remove the others
                        toKeep = None
                        for tile in foundTiles:
                            if toKeep == None and tile['orientation'] == layoutTile['orientation']:
                                toKeep = tile
                        if toKeep != None:
                            for tile in foundTiles:
                                if tile != toKeep:
                                    tiles.remove(tile)

def applyOverrides(overrides, items):
    for override in overrides:
        where = override['where']
        for item in items:
            match = True
            for key,value in where.items():
                if key in item:
                    if item[key] != value:
                        match = False
                else:
                    match = False
            if match:
                if 'with' in override:
                    for key,value in override['with'].items():
                        item[key] = value

for id in scenarioIds:
    scenario = scenarios[id]
    print(
        f"{bcolors.HEADER}Analyzing Scenario #{id} : {scenario['title']}{bcolors.ENDC}")
    scenarioData = {"id": id, "maps": []}
    pagesToCover = []
    pagesToCover.append(
        {"type": "scenario", "page": scenario["page"], "name": scenario["page"]})
    if 'otherPages' in scenario:
        for otherPage in scenario['otherPages']:
            pagesToCover.append(
                {"type": "scenario", "page": otherPage, "name": otherPage})

    # No need to parse Sections when we're not parsing maps
    if 'sections' in scenario and parseMaps:
        for section in scenario['sections']:
            pagesToCover.append(
                {"type": "section", "page": int(float(section)), "name": section})

    layoutFound = False
    for page in pagesToCover:
        pageNumber = page['page']
        pagePatches = {}
        if id in patches:
            if f"{pageNumber}" in patches[id]:
                pagePatches = patches[id][f"{pageNumber}"]
        also = pagePatches['also'] if 'also' in pagePatches else []
        also = list(map(lambda e: {"name": e}, also))
        results = []
        path = "scenarios/p" if page["type"] == "scenario" else "sections/"
        imgFile = os.path.join(f"assets/pages/{path}{pageNumber}.png")
        if os.path.exists(imgFile):
            print(f"{bcolors.OKBLUE}Identifying elements in {imgFile}{bcolors.ENDC}")
            img = cv.imread(imgFile, flags=cv.IMREAD_UNCHANGED)
            assert img is not None, "image file could not be read, check with os.path.exists()"
            out = cv.cvtColor(img, cv.COLOR_RGBA2RGB)
            # img_gray = cv.cvtColor(img, cv.COLOR_RGBA2GRAY)

            pageHasLayout = False
            layoutPosition = {}
            layoutEnd = {}
            w = img.shape[1]
            h = img.shape[0]

            # See if this page has a layout definition
            if not layoutFound and parseLayouts:
                result = identify(
                    out, img, 'assets/tiles/layout/Map Layout.png', 0, 0, 0.90, False,printMatch=False)
                if len(result) > 0:
                    pageHasLayout = True
                    layoutPosition = result[0]["position"]
                    layoutEndImg = img[layoutPosition["y"]:h, layoutPosition["x"]:w]
                    result = identify(out, layoutEndImg, 'assets/tiles/layout/Map Layout End.png',
                                      layoutPosition["x"], layoutPosition["y"], 0.90, False,printMatch=False)
                    result.sort(key=getScore, reverse=True)
                    if len(result) > 0:
                        position = result[0]["position"]
                        size = result[0]["size"]
                        layoutEnd["x"] =  min(w, position["x"] + size["x"] + 100)
                        layoutEnd["y"] = min(h, position["y"] + size["y"] + 100)
            tiles = []
            mapTiles = []
            mapImg = None
            mapMinX = 0
            mapMinY = 0
            if pageHasLayout:
                if not "x" in layoutEnd:
                    layoutEnd["x"] = min(w, layoutPosition["x"] + 1500)
                    layoutEnd["y"] = min(h, layoutPosition["y"] + 1000)
                mapMinX = max(0, layoutPosition["x"] - 100)
                mapMinY = max(0, layoutPosition["y"] - 100)
                mapMaxX = layoutEnd["x"]
                mapMaxY = layoutEnd["y"]
                mapImg = img[mapMinY:mapMaxY, mapMinX:mapMaxX]
                cv.rectangle(out, (mapMinX, mapMinY),
                             (mapMaxX, mapMaxY), (0, 255, 0), 2)

            if 'tiles' in scenario and (parseMaps or parseLayouts):
                tilesToLookFor = pagePatches['tiles'] if 'tiles' in pagePatches else scenario['tiles']
                
                for tile in tilesToLookFor:
                    found = False
                    orientations = ["-0", "-30", "-60", "-90",
                                    "-120", "-180", "-210", "-240", "-270", "-300"]
                    variants = ["", "-Alt", "-Alt-2"]
                    for variant in variants:
                        for orientation in orientations:
                            if pageHasLayout and parseLayouts:
                                mapTileFile = f'assets/tiles/layout/tiles/{tile}{orientation}{variant}.png'
                                if os.path.exists(mapTileFile):
                                    result = identify(
                                        out, mapImg, mapTileFile, mapMinX, mapMinY, 0.92, printMatch=verbose)
                                    if len(result) > 0:
                                        mapTiles.append(
                                            {"name": tile, "orientation": orientation, "variant": variant, "positions": result})

                            if parseMaps:
                                tileFile = f'assets/tiles/maps/{tile}{orientation}{variant}.png'
                                if os.path.exists(tileFile):
                                    if verbose:
                                        print(
                                            f"\tLooking for Tile {tile}{orientation}{variant}")
                                    result = identify(
                                        out, img, tileFile, 0, 0, 0.92, printMatch=verbose)
                                    if len(result) > 0:
                                        found = True                                        
                                        tiles.append(
                                            {"name": tile, "variant": variant, "orientation": orientation, "positions": result})

            w = img.shape[1]
            h = img.shape[0]
            minX = w
            maxX = 0
            minY = h
            maxY = 0

            # if we have duplicate tiles, and we already know the scenario layout,
            # we should give preference to the one with the right orientation
            removeDuplicateTilesWihtWrongOrientation(tiles, scenarioData)

            # Apply overrides to layouts
            overrides = pagePatches['overrides'] if 'overrides' in pagePatches else []
            applyOverrides(overrides, mapTiles)

            for tile in tiles:
                results.append({"name": tile['name'], "variant": tile['variant'], "orientation": tile['orientation'],
                                                       "type": "tile", "results": tile['positions']})

           


            for tile in tiles:
                variant = tile["variant"]
                name = tile["name"].split("-")[0]
                orientation = tile["orientation"]
                tileId = f"{name}{orientation}{variant}"
                tileInfo = tileInfos[tileId]
                if tileInfo is not None:
                    for result in tile["positions"]:
                        x = result["position"]["x"]
                        y = result["position"]["y"]
                        minX = min(minX, max(x + tileInfo["minX"], 0))
                        maxX = max(maxX, min(x + tileInfo["maxX"], w))
                        minY = min(minY, max(y + tileInfo["minY"], 0))
                        maxY = max(maxY, min(y + tileInfo["maxY"], h))

            if 'minX' in pagePatches:
                minX = pagePatches['minX']
            if 'minY' in pagePatches:
                minY = pagePatches['minY']
            if 'maxX' in pagePatches:
                maxX = pagePatches['maxX']
            if 'maxY' in pagePatches:
                maxY = pagePatches['maxY']

            if parseLayouts:
                if pageHasLayout:
                    found = len(scenarioData["layout"]) if "layout" in scenarioData else 0
                    if len(mapTiles) > found:
                        scenarioData["layout"] = mapTiles

            if len(tiles) > 0 and minX < maxX and minY < maxY:
                if verbose:
                    print(f"Lookup Area : ({minX},{minY}) -> ({maxX}, {maxY})")

                cv.rectangle(out, (minX, minY), (maxX, maxY), (255, 0, 0), 2)
                img = img[minY:maxY, minX:maxX]

                for monster in scenario['monsters'] + also:
                    name = monster['name']
                    variants = ['', ' Small']
                    for variant in variants:
                        monsterFile = f'assets/tiles/monsters/{name}{variant}.png'
                        if os.path.exists(monsterFile):
                            if verbose:
                                print(f"\tLooking for monster {name}{variant}")
                            result = identify(
                                out, img, monsterFile, minX, minY, printMatch=verbose)
                            if len(result) > 0:
                                results.append(
                                    {"name": name, "type": "monster", "results": result})

                for overlay in scenario['overlays'] + also:
                    name = overlay['name']
                    orientations = ["", "-0", "-60", "-90", "-120",
                                    "-150", "-180", "-240", "-270", "-300", "-330"]
                    found = False
                    for orientation in orientations:
                        variants = ["", "-1", "-2", "-3", "-4"]
                        for variant in variants:
                            overlayFile = f'assets/tiles/overlays/{name}{orientation}{variant}.png'
                            if os.path.exists(overlayFile):
                                found = True
                                if verbose:
                                    print(
                                        f"\tLooking for overlay {name} ({orientation}/{variant})")
                                result = identify(
                                    out, img, overlayFile, minX, minY, printMatch=verbose)
                                if len(result) > 0:
                                    results.append(
                                        {"name": name, "orientation": orientation, "type": "overlay", "results": result})

                # Apply overrides to results
                applyOverrides(overrides, results)

                entries = os.listdir('assets/tiles/all')
                for entry in entries:
                    threshold = 0.96
                    if entry == 'overlay types':
                        threshold = 0.94
                    subEntries = os.listdir(
                        os.path.join('assets/tiles/all/', entry))
                    for subEntry in subEntries:
                        if verbose:
                            print("\tLooking for {}".format(subEntry))
                        result = identify(out, img, os.path.join(
                            'assets/tiles/all/', entry, subEntry), minX, minY,printMatch=False)
                        if len(result) > 0:
                            results.append(
                                {"name": subEntry, "type": entry, "results": result})
            t = "p" if page["type"] == "scenario" else "s"

            # resize image
            width = int(out.shape[1] * 0.5)
            height = int(out.shape[0] * 0.5)
            dim = (width, height)
            resized = cv.resize(out, dim, interpolation = cv.INTER_AREA)

            cv.imwrite(f"out/{id}-{t}{page['page']}.jpg", resized,[cv.IMWRITE_JPEG_QUALITY, 75])
            scenarioData["maps"].append(
                {"type": page['type'], "page": page['page'], "name": page['name'], "results": results})

    printColor = bcolors.WARNING
    nbTotalTiles = len(scenario["tiles"] if "tiles" in scenario else [])
    nbFoundTiles = len(scenarioData["layout"]
                       if "layout" in scenarioData else [])
    if nbTotalTiles == nbFoundTiles:
        layoutFound = True
        printColor = bcolors.OKGREEN
    print(f"{printColor}Found {nbFoundTiles} out of {nbTotalTiles} layout tiles{bcolors.ENDC}")

    with open(f"out/{id}.json", "w") as outfile:
        json.dump(scenarioData, outfile, indent=3, cls=NpEncoder)
