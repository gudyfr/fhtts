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
                         (pt[0] + w + xOffset, pt[1] + h+yOffset), (0, 0, 255), 1)
        output.append(positionToJson(pt, w, h, score, xOffset, yOffset))

    return output


def loadScenarios():
    with open('../scenarios.json', 'r') as openfile:
        return json.load(openfile)


def loadTiles():
    with open('tiles.json', 'r') as openfile:
        return json.load(openfile)


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
    scenarioIds = scenarios.keys()
if "-after" in args:
    args.remove('-after')
    startAt = int(args[0]) + 1    
    scenarioIds = list(scenarios.keys())
    index = scenarioIds.index(f"{startAt}")
    scenarioIds = scenarioIds[index:]
else:
    for arg in args:
        scenarioIds.append(arg)


def getScore(elem):
    return elem["score"]


for id in scenarioIds:
    nb = id
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
        results = []
        path = "scenarios/p" if page["type"] == "scenario" else "sections/"
        imgFile = os.path.join(f"assets/pages/{path}{page['page']}.png")
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
                for tile in scenario['tiles']:
                    found = False
                    orientations = ["-0", "-30", "-60", "-90",
                                    "-120", "-180", "-210", "-240", "-270", "-300"]
                    variants = ["", "-Alt"]
                    for variant in variants:
                        for orientation in orientations:
                            if pageHasLayout and parseLayouts:
                                mapTileFile = f'assets/tiles/layout/tiles/{tile}{orientation}{variant}.png'
                                if os.path.exists(mapTileFile):
                                    result = identify(
                                        out, mapImg, mapTileFile, mapMinX, mapMinY, 0.91, printMatch=verbose)
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
                                        out, img, tileFile, 0, 0, 0.90, printMatch=verbose)
                                    if len(result) > 0:
                                        found = True
                                        results.append({"name": tile, "variant": variant, "orientation": orientation,
                                                       "type": "tile", "results": result, "orientation": orientation})
                                        tiles.append(
                                            {"name": tile, "variant": variant, "orientation": orientation, "positions": result})

            w = img.shape[1]
            h = img.shape[0]
            minX = w
            maxX = 0
            minY = h
            maxY = 0
            for tile in tiles:
                variant = tile["variant"]
                name = tile["name"].split("-")[0]
                orientation = tile["orientation"]
                id = f"{name}{orientation}{variant}"
                tileInfo = tileInfos[id]
                if tileInfo is not None:
                    for result in tile["positions"]:
                        x = result["position"]["x"]
                        y = result["position"]["y"]
                        minX = min(minX, max(x + tileInfo["minX"], 0))
                        maxX = max(maxX, min(x + tileInfo["maxX"], w))
                        minY = min(minY, max(y + tileInfo["minY"], 0))
                        maxY = max(maxY, min(y + tileInfo["maxY"], h))

            if parseLayouts:
                if pageHasLayout:
                    found = len(scenarioData["layout"]
                                ) if "layout" in scenarioData else 0
                    if len(mapTiles) > found:
                        scenarioData["layout"] = mapTiles

            if len(tiles) > 0:
                if verbose:
                    print(f"Lookup Area : ({minX},{minY}) -> ({maxX}, {maxY})")

                cv.rectangle(out, (minX, minY), (maxX, maxY), (255, 0, 0), 2)
                img = img[minY:maxY, minX:maxX]

                for monster in scenario['monsters']:
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

                for overlay in scenario['overlays']:
                    name = overlay['name']
                    orientations = ["", "-0", "-60", "-90", "-120",
                                    "-150", "-180", "-240", "-270", "-300"]
                    found = False
                    for orientation in orientations:
                        variants = ["", "-1", "-2", "-3"]
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
                    if not found:
                        print(
                            f"{bcolors.WARNING}Missing overlay template {name} at {overlayFile}{bcolors.ENDC}")

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
            cv.imwrite(f"out/{nb}-{t}{page['page']}.png", out)
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

    with open(f"out/{nb}.json", "w") as outfile:
        json.dump(scenarioData, outfile, indent=3, cls=NpEncoder)
