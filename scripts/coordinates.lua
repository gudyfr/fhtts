function rotateHexCoordinates(x, y, orientation)
    if x == 0 and y == 0 then
        return x, y
    end
    if orientation == 0 then
        return x, y
    elseif orientation == 60 then
        return -y, x + y
    elseif orientation == 120 then
        return -x - y, x
    elseif orientation == 180 then
        return -x, -y
    elseif orientation == 240 then
        return y, -x - y
    elseif orientation == 300 then
        return x + y, -x
    end
end

function getWorldPositionFromHexPosition(x, y)
    return 0.43 + 1.15 * x + y * 0.575, y + 5.29
end

function getHexPositionFromWorldPosition(position)
    local px = position.x
    local py = position.z
    local hy = math.floor(py - 5.29 + 0.5)
    -- px = 0.43 + 1.15 * hx + hy * 0.575
    -- px - 0.43 - 0.575 * hy = 1.15 * hx
    local hx = math.floor(0.5 + (px - hy * 0.575 - 0.43) / 1.15)
    return hx, hy
end

AdditionalRotation = {
    ["03-A"] = 30,
    ["03-B"] = -90,
    ["06-A"] = 90,
    ["06-B"] = -90,
    ["07-A"] = -90,
    ["07-B"] = 90,
    ["10-A"] = 90,
    ["10-B"] = -90,
    ["11-A"] = -60,
    ["16-A"] = 90,
    ["16-B"] = -90
}

function getTileNameFromObject(tile)
    local name = tile.getName()
    if tile.getRotation().z > 160 and tile.getRotation().z < 200 then
        return string.sub(name, 1, 3) .. string.sub(name, 5, 5)
    else
        return string.sub(name, 1, 4)
    end
end
