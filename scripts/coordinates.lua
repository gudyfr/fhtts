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

X0Offset = -0.15
Y0Offset =  0.30
XXDisplacement = -1.15
YXDisplacement = -0.58
YYDisplacement = -1

function getWorldPositionFromHexPosition(x, y)
    return X0Offset + XXDisplacement * x + YXDisplacement * y, YYDisplacement * y + Y0Offset
end

function getHexPositionFromWorldPosition(position)
    local px = position.x
    local py = position.z
    -- py = YYDisplacement * hy + Y0Offset
    local hy = math.floor((py  - Y0Offset) / YYDisplacement + 0.5)
    -- px = X0Offset + XXDisplacement * hx + YXDisplacement * hy
    -- px - X0Offset - YXDisplacement * hy = XXDisplacement * hx
    local hx = math.floor(0.5 + (px - hy * YXDisplacement - X0Offset) / XXDisplacement)
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
