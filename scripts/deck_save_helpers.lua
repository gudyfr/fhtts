function shiftUp(p)
    return { p.x, p.y + 0.5, p.z }
end

function XZSorter(a, b)
    return 30 * (a.z - b.z) - a.x + b.x < 0
end

function rebuildDeck(clone, cardGuids, cardNames, position, flip, otherDeck, otherGuids, cardTransformFunction)
    if clone == nil then
        return nil
    end
    cardNames = cardNames or {}
    deleteCardsAt(position)
    local deck = nil
    local used = false
    local _used = false
    for _, card in ipairs(cardNames) do
        deck, _used = rebuildCardFrom(deck, card, clone, cardGuids, cardTransformFunction)
        used = used or _used
        if otherDeck ~= nil and otherGuids ~= nil then
            deck, _used = rebuildCardFrom(deck, card, otherDeck, otherGuids, cardTransformFunction)
            used = used or _used
        end
    end
    -- We've rebuilt the deck, move it to the right place
    if deck ~= nil then
        deck.setPosition(self.positionToWorld(shiftUp(position)))
        local zRot = 0
        if flip or false then
            zRot = 180
        end
        deck.setRotation({ 0, 0, zRot })
    end

    if clone.tag == "Deck" then
        if clone.remainder ~= nil then
            return clone.remainder
        else
            return clone
        end
    else
        if used then
            return nil
        else
            return clone
        end
    end
end

function rebuildCardFrom(deck, card, clone, cardGuids, cardTransformFunction)
    local guids = cardGuids[card]
    local used = false
    if guids ~= nil then
        if #guids > 0 then
            local guid = guids[1]
            table.remove(guids, 1)
            local cardObject
            if clone.tag == "Card" then
                -- We can't test for guid here, as the guid might have changed from when the card was still in the deck
                -- So we need to assume that the last remaining card is the one we're looking for
                cardObject = clone
            elseif clone.remainder == nil then
                cardObject = clone.takeObject({
                    guid = guid,
                    smooth = false,
                    callback_function = destroyTakenIfStillThere,
                    position = { 0, 2, 0 }
                })
            else
                if clone.remainder.guid == guid then
                    cardObject = clone.remainder
                end
            end
            if cardObject ~= nil then
                used = true
                if cardTransformFunction ~= nil then
                    cardTransformFunction(cardObject)
                end
                if deck == nil then
                    deck = cardObject
                else
                    -- preserve order, card should be above deck
                    local pos = deck.getPosition()
                    cardObject.setPosition({ pos.x, pos.y + 0.1, pos.z })
                    deck = deck.putObject(cardObject)
                end
            end
        end
    end
    return deck, used
end

function destroyTakenIfStillThere(obj)
    if not obj.isDestroyed() then
        local position = obj.getPosition()
        if position.x == 0 and position.z == 0 then
            destroyObject(obj)
        end
    end
end

function getCardListInZone(guid)
    local results = {}
    local zone = getObjectFromGUID(guid)
    if zone ~= nil then
        for _, obj in ipairs(zone.getObjects()) do
            if obj.tag == "Card" then
                if obj.hasTag("ability card") then
                    table.insert(results, obj.getName() or obj.getDescription())
                end
            end
        end
    end
    return results
end

function deleteCardsInZone(guid)
    local zone = getObjectFromGUID(guid)
    if zone ~= nil then
        for _, obj in ipairs(zone.getObjects()) do
            if obj.tag == "Card" then
                if obj.hasTag("ability card") and not obj.isDestroyed() then
                    destroyObject(obj)
                end
            end
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
    waitms(25)
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
                local object = container.takeObject({ guid = obj.guid, smooth = false, position = { 0, 3, 0 } })
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

function getDecalsFromDeck(deckPosition, results)
    local deck = getDeckOrCardAt(deckPosition)
    local newDeck = {}
    forEachInDeckOrCard(deck, function(card)
        local decals = card.getDecals() or {}
        if #decals > 0 then
            results[card.getName() or card.getDescription()] = decals
        end
        if newDeck[1] == nil then
            newDeck[1] = card
        else
            local newDeckPosition = newDeck[1].getPosition()
            card.setPosition({ newDeckPosition.x, newDeckPosition.y - 0.1, newDeckPosition.z })
            newDeck[1] = newDeck[1].putObject(card)
        end
        Wait.frames(function() if not card.isDestroyed() then destroyObject(card) end end, 1)
    end)
    if newDeck[1] ~= nil then
        Wait.frames(function()
            newDeck[1].setPosition(shiftUp(self.positionToWorld(deckPosition)))
        end, 1)
    end
end

function reapplyDecalsAndMoveTo(deck, decals, position, options)
    forEachInDeckOrCard(deck, function(card)
        local cardDecals = decals[card.getName() or card.getDescription()] or {}
        if #cardDecals > 0 then
            card.setDecals(cardDecals)
        end
        addCardToDeckAt(card, position, options)
    end)
end
