function findLocalObject(localPosition, type, tag, name)
    return findGlobalObject(self.positionToWorld(localPosition), type, tag, name)
end

function findGlobalObject(position, type, tag, name)
    type = type or ""
    tag = tag or ""
    name = name or ""
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
                if type == "" or type == obj.tag then
                    if tag == "" or obj.hasTag(tag) then
                        if name == "" or name == obj.getName() then
                            return obj
                        end
                    end
                end
            end
        end
    end
    return nil
end

function setAtLocalPosition(object, position, flipped)
    flipped = flipped or false
    local finalPosition = {position.x, position.y+1.5, position.z}
    object.setPosition(self.positionToWorld(finalPosition))
    local zRot = 0
    if flipped then
        zRot = 180
    end
    object.setRotation({0, 0, zRot})
end
