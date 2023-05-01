function shiftUp(p)
    return { p.x, p.y + 0.5, p.z }
end

function XZSorter(a, b)
    return 30 * (a.z - b.z) - a.x + b.x < 0
end

function rebuildDeck(clone, cardGuids, cardNames, position, flip, otherDeck, otherGuids, cardTransformFunction)
    cardNames = cardNames or {}
    deleteCardsAt(position)
    local deck = nil
    for _, card in ipairs(cardNames) do
        deck = rebuildCardFrom(deck, card, clone, cardGuids)
        if otherDeck ~= nil and otherGuids ~= nil then
            deck = rebuildCardFrom(deck, card, otherDeck, otherGuids, cardTransformFunction)
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

function rebuildCardFrom(deck, card, clone, cardGuids, cardTransformFunction)
    local guids = cardGuids[card]
    if guids ~= nil then
        if #guids > 0 then
            local guid = guids[1]
            table.remove(guids, 1)
            local cardObject
            if clone.remainder == nil then
                cardObject = clone.takeObject({
                    guid = guid,
                    smooth = false,
                    callback_function = destroyTakenIfStillThere,
                    position = { 0, 2, 0 }
                })
            else
                cardObject = clone.remainder
            end            
            if cardObject ~= nil then
                if cardTransformFunction ~= nil then
                    cardTransformFunction(cardObject)
                end
                if deck == nil then
                    deck = cardObject
                else
                    deck = deck.putObject(cardObject)
                end
            end
        end
    end
    return deck
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
                local name = obj.name
                if name == "Card" then
                    name = obj.description
                end                
                table.insert(results, name)
            end
        elseif result.hit_object.tag == "Card" then
            local name = result.hit_object.getName()
            if name == "Card" or name == "" then
                name = result.hit_object.getDescription()
            end
            table.insert(results, name)
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
    return getRestoreDeckIn(saveElementBox, name, true)
end

function getRestoreDeckIn(container, name, preserveOriginal)
    local object = getRestoreObjectIn(container, name, preserveOriginal)
    if object ~= nil then
        -- Build a map of card name to guid, for faster retrieval
        local cardGuids = {}
        for _, card in ipairs(object.getObjects()) do
            local name = card.name
            if name == "Card" then
                name = card.description
            end
            local guids = cardGuids[name] or {}
            table.insert(guids, card.guid)
            cardGuids[name] = guids
        end
        return object, cardGuids
    end
end

function getRestoreObjectIn(container, name, preserveOriginal)
    preserveOriginal = preserveOriginal or false
    if container ~= nil then
        -- Find the right deck
        for _, obj in ipairs(container.getObjects()) do
            if obj.name == name then
                -- Clone it and return it to the box
                local object = container.takeObject({ guid = obj.guid, smooth = false, position = {0,3,0}})
                if preserveOriginal then
                    local clone = object.clone()
                    container.putObject(object)
                    object = clone
                end
                return object
            end
        end
    end
end
