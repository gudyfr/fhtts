import os
import math
import cv2 as cv
import numpy as np
from matplotlib import pyplot as plt

def distance(pt1, pt2):
     dX = pt1[0] - pt2[0]
     dY = pt1[1] - pt2[1]
     return math.sqrt(dX*dX+dY*dY)

def identify(out, img, templateFile):
    template = cv.imread(templateFile, flags=cv.IMREAD_UNCHANGED)
    assert template is not None, "template file could not be read, check with os.path.exists()"
    template_gray = cv.cvtColor(template, cv.COLOR_RGBA2GRAY)
    _, _, _, a_channel = cv.split(template)
    _, mask = cv.threshold(a_channel, thresh=254,
                           maxval=255, type=cv.THRESH_BINARY)
    # cv.imwrite(os.path.join("out",os.path.basename(templateFile)), mask)
    w, h = mask.shape[::-1]
    iw, ih = img.shape[::-1]
    if w > iw or h > ih:
        return
    res = cv.matchTemplate(img, template_gray, cv.TM_CCOEFF_NORMED, mask=mask)
    loc = np.where((res >= 0.90) & (res <= 1.01))
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
    for pt in result:
        print("Found {} at ({}, {}) {}".format(
            templateFile, pt[0], pt[1], res[pt[1]][pt[0]]))
        cv.rectangle(out, pt, (pt[0] + w, pt[1] + h), (0, 0, 255), 1)


maps = os.listdir('assets/layouts/')
for map in maps:
    print("Identifying elements in {}".format(map))
    img = cv.imread(os.path.join('assets/layouts/', map),
                    flags=cv.IMREAD_UNCHANGED)
    assert img is not None, "image file could not be read, check with os.path.exists()"
    out = cv.cvtColor(img, cv.COLOR_RGBA2RGB)
    img_gray = cv.cvtColor(img, cv.COLOR_RGBA2GRAY)

    entries = os.listdir('assets/layout items/')
    for entry in entries:
        identify(out, img_gray, os.path.join('assets/layout items/', entry))

    cv.imwrite(os.path.join("out", map), out)
