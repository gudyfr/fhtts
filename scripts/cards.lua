function getDeckOrCardAt(position)
    return getDeckOrCardAtWorldPosition(self.positionToWorld(position))
end

function getDeckOrCardAtWorldPosition(position)
    if position ~= nil then
        local hitlist = Physics.cast({
            origin       = position,
            direction    = { 0, 1, 0 },
            type         = 2,
            size         = { 1, 1, 1 },
            max_distance = 0,
            debug        = false
        })
        for _, h in ipairs(hitlist) do
            if h.hit_object.tag == "Deck" then
                return h.hit_object
            end
            if h.hit_object.tag == "Card" then
                return h.hit_object
            end
        end
    end
    return nil
end

function forEachInDeckOrCardIf(deck, cardTransform, entryTest)
    if deck == nil then
        return 0
    end
    local count = 0
    if deck.tag == "Deck" then
        local cards = deck.getObjects()
        for _, entry in ipairs(cards) do
            -- Check if we need to handle the last remaining card in the deck
            if deck.remainder ~= nil then
                local card = deck.remainder
                local tester = { name = card.getName(), tags = card.getTags(), description = card.getDescription() }
                if entryTest(tester) then
                    if cardTransform ~= nil then
                        cardTransform(deck.remainder)
                    end
                    count = count + 1
                end
            else
                if entryTest(entry) then
                    if cardTransform ~= nil then
                        local obj = deck.takeObject({ guid = entry.guid })
                        cardTransform(obj)
                    end
                    count = count + 1
                end
            end
        end
    elseif deck.tag == "Card" then
        local card = deck
        local tester = { name = card.getName(), tags = card.getTags(), description = card.getDescription() }
        if entryTest(tester) then
            cardTransform(card)
            count = count + 1
        end
    end
    return count
end

function forEachInDeckOrCard(deck, cardTransform)
    return forEachInDeckOrCardIf(deck, cardTransform, function(entry) return true end)
end

function addCardToDeckAt(card, position, options)
    addCardToDeckAtWorldPosition(card, self.positionToWorld(position), options)
end

function addCardToDeckAtWorldPosition(card, position, options)
    if card == nil or position == nil then
        return
    end
    options = options or {}
    local atBottom = options.atBottom or false
    local shuffle = options.shuffle or false
    local smooth = options.smooth or false
    local noPut = options.noPut or false
    local flip = options.flip or false
    local current = getDeckOrCardAtWorldPosition(position)
    if current == nil then
        -- There is currently nothing at that location, simply move the card there (shifted up)
        local globalPosition = position
        globalPosition.y = globalPosition.y + 0.5
        if smooth then
            card.setPositionSmooth(globalPosition)
        else
            card.setPosition(globalPosition)
        end
        if flip then
            card.setRotation({0,0,180})
        end
    else
        -- Move the card above or below the deck depending on where we want it to go
        local deckPosition = current.getPosition()
        if atBottom then
            deckPosition.y = deckPosition.y - 0.1
        else
            deckPosition.y = deckPosition.y + 0.1
        end
        if smooth then
            card.setPositionSmooth(deckPosition)
        else
            card.setPosition(deckPosition)
        end
        if flip then
            card.setRotation({0,0,180})
        end
        if not noPut then
            current.putObject(card)
        end

        if shuffle then
            current.shuffle()
        end
    end
end

function takeCardFrom(deckOrCard)
    if deckOrCard ~= nil then
        if deckOrCard.tag == "Card" then
            return deckOrCard
        elseif deckOrCard.tag == "Deck" then
            return deckOrCard.takeObject({})
        end
    end
    return nil
end
