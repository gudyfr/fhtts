function shiftUp(p)
    return { p.x, p.y + 0.5, p.z }
end

function rebuildDeck(clone, cardGuids, cardNames, position, flip)
    deleteCardsAt(position)
    local deck = nil
    for _, card in ipairs(cardNames) do
        local guids = cardGuids[card]
        if guids ~= nil then
            if #guids > 0 then
                local guid = guids[1]
                table.remove(guids, 1)
                local cardObject
                if clone.remainder == nil then
                    cardObject = clone.takeObject({ guid = guid, smooth = false,
                        callback_function = destroyTakenIfStillThere, position = { 0, 2, 0 } })
                else
                    cardObject = clone.remainder
                end
                if cardObject ~= nil then
                    if deck == nil then
                        deck = cardObject
                    else
                        deck = deck.putObject(cardObject)
                    end
                end
            end
        end
    end
    -- We've rebuilt the deck, move it to the right place
    if deck ~= nil then
        deck.setPosition(self.positionToWorld(shiftUp(position)))
        local zRot = 0
        if flip or false then
            zRot = 180
        end
        deck.setRotation({ 0, 180, zRot })
    end
end

function destroyTakenIfStillThere(obj)
    if not obj.isDestroyed() then
        local position = obj.getPosition()
        if position.x == 0 and position.z == 0 then
            destroyObject(obj)
        end
    end
end

function getCardList(position)
    local results = {}
    local hitlist = Physics.cast({
        origin       = self.positionToWorld(position),
        direction    = { 0, 1, 0 },
        type         = 2,
        size         = { 1, 1, 1 },
        max_distance = 0,
        debug        = true
    })

    for _, result in ipairs(hitlist) do
        if result.hit_object.tag == "Deck" then
            for _, obj in ipairs(result.hit_object.getObjects()) do
                table.insert(results, obj.name)
            end
        elseif result.hit_object.tag == "Card" then
            table.insert(results, result.hit_object.getName())
        end
    end
    return results
end

function deleteCardsAt(position)
    local hitlist = Physics.cast({
        origin       = self.positionToWorld(position),
        direction    = { 0, 1, 0 },
        type         = 2,
        size         = { 1, 1, 1 },
        max_distance = 0,
        debug        = true
    })

    for _, result in ipairs(hitlist) do
        if result.hit_object.tag == "Deck" then
            destroyObject(result.hit_object)
        elseif result.hit_object.tag == "Card" then
            destroyObject(result.hit_object)
        end
    end
end

function getRestoreDeck(name)
    local saveElementBox = getObjectFromGUID('a5c948')
    if saveElementBox ~= nil then
        -- Find the right deck
        for _, obj in ipairs(saveElementBox.getObjects()) do
            if obj.name == name then
                -- Clone it and return it to the box
                local deck = saveElementBox.takeObject({ guid = obj.guid, smooth = false })
                local clone = deck.clone()
                saveElementBox.putObject(deck)
                -- Build a map of card name to guid, for faster retrieval
                local cardGuids = {}
                for _, card in ipairs(clone.getObjects()) do
                    local guids = cardGuids[card.name] or {}
                    table.insert(guids, card.guid)
                    cardGuids[card.name] = guids
                end
                return clone, cardGuids
            end
        end
    end
end
