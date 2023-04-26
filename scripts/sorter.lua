function sort(inputPosition, outputPosition, compareFunction)
    compareFunction = compareFunction or compareName
    local location = self.positionToWorld(inputPosition)
    local destination = self.positionToWorld(outputPosition)
    local hitlist = Physics.cast({
        origin       = location,
        direction    = { 0, 1, 0 },
        type         = 2,
        size         = { 1, 1, 1 },
        max_distance = 0,
        debug        = false
    })

    for i, j in pairs(hitlist) do
        if j.hit_object.tag == "Card" then
            local card = j.hit_object
            card.setPosition(destination)
        elseif j.hit_object.tag == "Deck" then
            local cards = j.hit_object.getObjects()
            table.sort(cards, compareName)
            for _, obj in ipairs(cards) do
                if j.hit_object.remainder == nil then                
                    card = j.hit_object.takeObject({ guid = obj.guid, position = destination, smooth=false })
                else
                    card = j.hit_object.remainder
                    card.setPosition(destination)
                end
                destination.y = destination.y + 0.1
            end
        end
    end
end

function compareName(obj1, obj2)
    return obj1.name < obj2.name
end