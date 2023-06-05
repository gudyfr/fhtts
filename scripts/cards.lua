--- Finds a deck or card at a specific position using local coordinates.
---@param position any a table with x, y, z coordinates in the coordinate system of an object.
---@return any the deck or card at the position, or nil if there is none.
function getDeckOrCardAt(position)
    return getDeckOrCardAtWorldPosition(self.positionToWorld(position))
end

--- Finds a deck or card at a specific position using world coordinates.
---@param position any a table with x, y, z coordinates.
---@return any the deck or card at the position, or nil if there is none.
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

--- Iterates over all cards in a deck, card or nil. For each entry in the container, it will call entryTest, and if that returns true, will take the card, and apply the transform function to it.
---@param deck any the deck, card or nil object to apply the cardTransform function to each card contained in it.
---@param cardTransform any the transform function to apply to each card. The function is called with the card as the first argument.
---@param entryTest any the test function to apply to each entry in the deck. The function is called with the entry (a table containing {name, description and tags} from the card) as the first argument. If the function returns true, the card is taken and the transform function is applied to it. 
---@return number the number of cards that were taken and transformed.
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

--- Iterates over all cards in a deck (or card) and applies the cardTransform function to each. The function will 'take' each card from the deck.
---@param deck any the deck, card or nil object to apply the cardTransform function to each card contained in it.
---@param cardTransform any the function to apply to each card. The function is called with the card as the first argument.
---@return number the number of cards that were taken and transformed.
function forEachInDeckOrCard(deck, cardTransform)
    return forEachInDeckOrCardIf(deck, cardTransform, function(entry) return true end)
end

--- Add a card to deck at a given position using local coordinates. @see addCardToDeckAtWorldPosition for details
---@param card any
---@param position any
---@param options any
function addCardToDeckAt(card, position, options)
    addCardToDeckAtWorldPosition(card, self.positionToWorld(position), options)
end

--- Add a card to a deck at a given position using world coordinates. If there is no deck at that position, the card is simply moved there. If there is a deck, the card is put on top of the deck. If the card is nil or the position is nil, nothing happens.
---@param card any the card object to be moved to the deck
---@param position any the position in world coordinates where the card should be moved to (a table containing x, y, z values)
---@param options any a table containing options for the operation or nil. Possible options are: atBottom : boolean - if true, the card is put at the bottom of the deck, otherwise it is put on top. shuffle : boolean - if true, the deck is shuffled after the card is added. smooth : boolean - if true, the card is moved smoothly to the deck, otherwise it is moved instantly. noPut : boolean - if true, the card is not put on the deck, but only moved above it. flip : boolean - if true, the card is flipped.
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
            card.setRotation({ 0, 0, 180 })
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
            card.setRotation({ 0, 0, 180 })
        end
        if not noPut then
            current.putObject(card)
        end

        if shuffle then
            current.shuffle()
        end
    end
end

--- Takes a card from a deck or a card and returns it. If the parameter is a deck, the top card is taken, if it is a card, the card itself is returned. if deckOrCard is nil, nil is returned.
---@param deckOrCard any either a deck, a card, or nil
---@return any either a card or nil
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
