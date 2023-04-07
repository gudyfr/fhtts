function onLoad(save)
    Global.call("registerForCollision", self)

    if save == nil then
        save = ""
    end

    currentTag = save

    -- input text
    local params = {
        input_function = "onTagChanged",
        function_owner = self,
        position = textPosition,
        scale = { 1, 1, 1 },
        width = 1400,
        height = 150,
        font_size = 100,
        color = { 1, 1, 1, 0 },
        font_color = { 0, 0, 0, 100 },
        alignment = 3,
        value=save
    }
    self.createInput(params)

    -- for _, point in ipairs(self.getSnapPoints()) do
    --     print(point.position)
    -- end
end

function onSave()
    return currentTag
end

function onObjectCollisionEnter()
    tag()
end

function onTagChanged(obj, color, text, selected)
    currentTag = text
end

outputPosition = { -1.371845, 0.05, -0.049024 }
inputPosition = { 1.365238, 0.05, -0.05016 }
textPosition = { 0.002327, 0.05, 1.004958 }

function tag()
    if currentTag ~= nil then
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

        for _, j in pairs(hitlist) do
            if j.hit_object.guid == self.guid or j.hit_object.guid == 'a25ab2' then
                -- ignore ourselves and the table
            elseif j.hit_object.tag == "Card" then
                local card = j.hit_object
                card.setPosition(destination)
                updateTag(card)
            elseif j.hit_object.tag == "Deck" then
                cards = j.hit_object.getObjects()
                for _, obj in pairs(cards) do
                    guid = obj.guid
                    if j.hit_object.remainder == nil then
                        card = j.hit_object.takeObject({ guid = obj.guid, position = destination, smooth = false })
                    else
                        card = j.hit_object.remainder
                        card.setPosition(destination)
                    end
                    destination.y = destination.y + 0.1
                    updateTag(card)
                end
            else
                print("Unknown type : ".. j.hit_object.tag)
            end
        end
    end
end

function updateTag(obj)
    local tag = currentTag
    local mode = "add"
    if string.sub(currentTag,1,1) == "-" then
        tag = string.sub(currentTag, 2)
        mode = "remove"
    end
    if mode == "add" then
        print("Adding tag " .. tag .. " to object")
        obj.addTag(currentTag)
    elseif mode == "remove" then
        print("Removing tag " .. tag .. " from object")
        obj.removeTag(currentTag)
    end
end