function findLocalObject(localPosition, type, tag)
    return findGlobalObject(self.positionToWorld(localPosition), type, tag)
end

function findGlobalObject(position, type, tag)
    type = type or ""
    tag = tag or ""
    local hitlist = Physics.cast({
        origin       = position,
        direction    = { 0, 1, 0 },
        type         = 2,
        size         = { 1, 1, 1 },
        max_distance = 0,
        debug        = false
    })

    local selfGuid = self.guid
    if hitlist ~= nil then
        for _, hit in pairs(hitlist) do
            local obj = hit.hit_object
            -- Always filter out the table and self
            if obj.guid ~= selfGuid and obj.guid ~= 'a25ab2' then
                if type == "" or type == hit.hit_object.tag then
                    if tag == "" or hit.hit_object.hasTag(tag) then
                        return hit.hit_object
                    end
                end
            end
        end
    end
    return nil
end

function setAtLocalPosition(object, position, flipped)
    flipped = flipped or false
    local finalPosition = {position.x, position.y+0.5, position.z}
    object.setPosition(self.positionToWorld(finalPosition))
    local zRot = 0
    if flipped then
        zRot = 180
    end
    object.setRotation({0, 180, zRot})
end
