require('savable')
require('controls')
require('constants')
require('coordinates')

function createEmptyState()
    return {
        state = {
            ["use-dev-assets"] = false
        },
        description = ""
    }
end

function getExpectedEntries()
    return {
        { "use-dev-assets", "checkbox" },
        { "getTileLayout",  "button" }
    }
end

function getTileLayout()
    local objects = getObjectFromGUID(ScenarioMatZoneGuid).getObjects(true)
    local result = {}
    for _, obj in ipairs(objects) do
        if obj.hasTag("tile") then
            -- Tile name
            local name = getTileNameFromObject(obj)
            local tile = { name = name }

            -- Tile center
            local position = obj.getPosition()
            local hx, hy = getHexPositionFromWorldPosition(position)
            tile.center = { x = hx, y = hy }

            -- Flipped or not ?
            local flipped = (Flipped[string.sub(name,4,4)] or 0) == 1

            -- Tile orientation
            local orientation = obj.getRotation().y
            local mappedName = string.sub(name,1,3)
            if flipped then
                mappedName = mappedName .. "B"
            else
                mappedName = mappedName .. "A"
            end
            orientation = math.floor(0.5 - orientation - (AdditionalRotation[mappedName] or 0))
            if orientation == 360 then orientation = 0 end
            if orientation < 0 then orientation = orientation + 360 end
            tile.orientation = orientation

            -- Tile origin
            local tileNumber = string.sub(name, 1, 2)
            local tileInfo = TileInfos[tileNumber]
            local origin = tileInfo.origin
            if flipped then
                origin = tileInfo.originFlipped or origin
            end

            print(JSON.encode(tile))
            local ox,oy = rotateHexCoordinates(origin.x, origin.y, orientation - (tileInfo.angle or 0))
            tile.origin = {x=ox+hx, y=oy+hy}

            table.insert(result, tile)
        end
    end
    print(JSON.encode(result))
end

Flipped = {
    B=1,D=1,F=1,H=1,J=1,L=1
}

TileInfos =
{
    ["01"] = {
        origin = {
            x = 2,
            y = 0
        },
    },
    ["02"] = {
        origin = {
            x = 2,
            y = -2
        },
    },
    ["03"] = {
        origin = {
            x = 3,
            y = -2
        }
    },
    ["04"] = {
        origin = {
            x = 2,
            y = -2
        },

    },
    ["05"] = {
        origin = {
            x = 2,
            y = -2
        },
        originFlipped = {
            x = 3,
            y = -2
        }
    },
    ["06"] = {
        origin = {
            x = 3,
            y = -4
        },
        originFlipped = {
            x = 3,
            y = -4
        }
    },
    ["07"] = {
        origin = {
            x = 4,
            y = -1
        },
    },
    ["08"] = {
        origin = {
            x = 2,
            y = -2
        },
        originFlipped = {
            x = 3,
            y = -2
        }
    },
    ["09"] = {
        origin = {
            x = 2,
            y = -3
        }
    },
    ["10"] = {
        origin = {
            x = 4,
            y = -2
        },
        originFlipped = {
            x = 3,
            y = -2
        }
    },
    ["11"] = {
        origin = {
            x = 5,
            y = -3
        },
    },
    ["12"] = {
        origin = {
            x = 4,
            y = -2
        }
    },
    ["13"] = {
        origin = {
            x = 3,
            y = -3
        },
        originFlipped = {
            x = 4,
            y = -3
        },
    },
    ["14"] = {
        originFlipped = {
            x = 4,
            y = 1
        },
        origin = {
            x = -1,
            y = -4
        },
        angle = 30
    },
    ["15"] = {
        origin = {
            x = 3,
            y = -3
        }
    },
    ["16"] = {
        origin = {
            x = 5,
            y = -3
        }
    }
}
