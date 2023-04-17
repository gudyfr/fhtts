import os
import json
import math
import cv2 as cv
import numpy as np
from matplotlib import pyplot as plt

def distance(pt1, pt2):
     dX = pt1[0] - pt2[0]
     dY = pt1[1] - pt2[1]
     return math.sqrt(dX*dX+dY*dY)

def positionToJson(pt,score, xOffset, yOffset):
    return {
        "position" : {
           "x" : pt[0] + xOffset,
           "y" : pt[1] + yOffset
        },
        "score" : score
    }

def identify(out, img, templateFile, xOffset, yOffset):
    template = cv.imread(templateFile, flags=cv.IMREAD_UNCHANGED)
    assert template is not None, "template file could not be read, check with os.path.exists()"
    _, _, _, a_channel = cv.split(template)
    _, mask = cv.threshold(a_channel, thresh=254,
                           maxval=255, type=cv.THRESH_BINARY)
    # template_gray = cv.cvtColor(template, cv.COLOR_RGBA2GRAY)
    w, h = mask.shape[::-1]
    res = cv.matchTemplate(img, template, cv.TM_CCOEFF_NORMED, mask=mask)
    loc = np.where((res >= 0.95) & (res <= 1.01))
    result = []
    for pt in zip(*loc[::-1]):
        close = False
        for r in result:
            if distance(r,pt) < 10 :
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
        print("\t\tFound {} at ({}, {}) {}".format(
            templateFile, pt[0], pt[1], score))
        cv.rectangle(out, (pt[0] + xOffset, pt[1]+yOffset), (pt[0] + w + xOffset, pt[1] + h+yOffset), (0, 0, 255), 1)
        output.append(positionToJson(pt,score,xOffset,yOffset))

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
pagesDone = []
for nb,scenario in scenarios.items():
    results = []
    pagesToCover = []
    pagesToCover.append(scenario['page'])
    if 'otherPages' in scenario:
        for otherPage in scenario['otherPages']:
            pagesToCover.append(otherPage)
    # Possibly try the next page if we didn't find anything in the first one
    for page in pagesToCover:
        if not page in pagesDone:
            imgFile = os.path.join("assets/images/p{}.png".format(page))
            if os.path.exists(imgFile):        
                print(f"{bcolors.OKBLUE}Identifying elements in {imgFile}{bcolors.ENDC}")
                img = cv.imread(imgFile, flags=cv.IMREAD_UNCHANGED)
                assert img is not None, "image file could not be read, check with os.path.exists()"
                out = cv.cvtColor(img, cv.COLOR_RGBA2RGB)
                img_gray = cv.cvtColor(img, cv.COLOR_RGBA2GRAY)

                tiles = []
                if 'tiles' in scenario:
                    for tile in scenario['tiles']:
                        orientations = ["-0","-60","-90","-120","-180","-240","-270","-300"]
                        found = False
                        for orientation in orientations:        
                            tileFile = 'assets/tiles/maps/{}{}.png'.format(tile,orientation)
                            if os.path.exists(tileFile):                            
                                print("\tLooking for Tile {}{}".format(tile, orientation))     
                                result = identify(out, img, tileFile, 0, 0)
                                if len(result) > 0:
                                    found = True
                                    results.append({"name" : tile, "type": "tile", "results" : result, "orientation" : orientation})
                                    tiles.append({"name" : f"{tile}{orientation}", "positions" : result})    
                        if not found:
                            print(f"{bcolors.WARNING}Couldn't find tile {tile}{bcolors.ENDC}")

                w = img.shape[1]
                h = img.shape[0]
                minX = w
                maxX = 0
                minY = h
                maxY = 0
                for tile in tiles:
                    id = "-".join(tile["name"].split("-")[::2])
                    tileInfo = tileInfos[id]
                    if tileInfo is not None:
                        for result in tile["positions"]:
                            x = result["position"]["x"]
                            y = result["position"]["y"]
                            minX = min(minX, max(x + tileInfo["minX"] ,0))
                            maxX = max(maxX, min(x + tileInfo["maxX"], w))
                            minY = min(minY, max(y + tileInfo["minY"], 0))
                            maxY = max(maxY, min(y + tileInfo["maxY"], h))

                if len(tiles) > 0:
                    print(f"Lookup Area : ({minX},{minY}) -> ({maxX}, {maxY})")

                    cv.rectangle(out, (minX,minY), (maxX, maxY), (0, 0, 255), 2)
                    img = img[minY:maxY, minX:maxX]

                    for monster in scenario['monsters']:
                        name = monster['name']
                        variants = ['', ' Small']
                        for variant in variants:        
                            monsterFile = f'assets/tiles/monsters/{name}{variant}.png'
                            if os.path.exists(monsterFile):
                                print(f"\tLooking for monster {name}{variant}") 
                                result = identify(out, img, monsterFile, minX, minY)
                                if len(result) > 0:         
                                    results.append({"name" : name, "type": "monster", "results" : result})                            
                    
                    for overlay in scenario['overlays']:
                        name = overlay['name']
                        orientations = ["","-0","-60","-90","-120","-180","-240","-270","-300"]
                        found = False
                        for orientation in orientations:        
                            overlayFile = 'assets/tiles/overlays/{}{}.png'.format(name,orientation)
                            if os.path.exists(overlayFile):
                                found = True
                                print(f"\tLooking for overlay {name} ({orientation})")     
                                result = identify(out, img, overlayFile, minX, minY)
                                if len(result) > 0:         
                                    results.append({"name" : name, "type": "overlay", "results" : result})                    
                        if not found:
                            print(f"{bcolors.WARNING}Missing overlay template {name} at {overlayFile}{bcolors.ENDC}") 

                    entries = os.listdir('assets/tiles/all')
                    for entry in entries:
                        subEntries = os.listdir(os.path.join('assets/tiles/all/', entry))        
                        for subEntry in subEntries:
                            print("\tLooking for {}".format(subEntry))
                            result = identify(out, img, os.path.join('assets/tiles/all/', entry, subEntry), minX, minY)
                            if len(result) > 0:         
                                results.append({"name" : subEntry, "type": entry, "results" : result})

                    cv.imwrite("out/p{}.png".format(page), out)
                    with open("out/p{}.json".format(page), "w") as outfile:
                        json.dump({"page" : page, "results":results}, outfile, indent=3, cls=NpEncoder)
                else:
                    print(f"{bcolors.WARNING}No tile found on page {page}, skipping analysis{bcolors.ENDC}")