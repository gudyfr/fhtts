function onLoad(save)
    Global.call("registerForCollision", self)

    if save == nil then
        save = ""
    end

    CurrentName = save

    -- input text
    local params = {
        input_function = "onNameChanged",
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
end

function onSave()
    return CurrentName
end

function onObjectCollisionEnter()
    name()
end

function onNameChanged(obj, color, text, selected)
    CurrentName = text
end

outputPosition = { -1.371845, 0.05, -0.049024 }
inputPosition = { 1.365238, 0.05, -0.05016 }
textPosition = { 0.002327, 0.05, 1.004958 }

function name()
    if CurrentName ~= nil then
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

        local i = 0
        for _, j in pairs(hitlist) do
            if j.hit_object.guid == self.guid or j.hit_object.guid == 'a25ab2' then
                -- ignore ourselves and the table
            elseif j.hit_object.tag == "Card" then
                local card = j.hit_object
                card.setPosition(destination)
                updateName(card, CurrentName, i, 1)
                i = i + 1
            elseif j.hit_object.tag == "Deck" then
                cards = j.hit_object.getObjects()
                local nbCards = #cards
                for _, obj in pairs(cards) do
                    guid = obj.guid
                    if j.hit_object.remainder == nil then
                        card = j.hit_object.takeObject({ guid = obj.guid, position = destination, smooth = false })
                    else
                        card = j.hit_object.remainder
                        card.setPosition(destination)
                    end
                    destination.y = destination.y + 0.1
                    updateName(card, CurrentName, i, nbCards)
                    i = i + 1
                end
            else
                print("Unknown type : ".. j.hit_object.tag)
            end
        end
    end
end

function updateName(obj,baseName,i,nbCards)
    local direction = 1
    local offset = 0
    if string.sub(baseName, 1,1) == "-" then
        baseName = string.sub(baseName, 2)
        direction = -1
        offset = nbCards - 1
    end
    local start = tonumber(baseName)
    obj.setName(string.format("%d", start+direction*(offset-i)))
end