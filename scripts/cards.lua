function getDeckOrCardAt(position)
    if position ~= nil then
        local hitlist = Physics.cast({
            origin       = self.positionToWorld(position),
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

function addCardToDeckAt(card, position, atBottom)
    if card == nil then
        return
    end
    atBottom = atBottom or false
    local current = getDeckOrCardAt(position)
    if current == nil then
        -- There is currently nothing at that location, simply move the card there (shifted up)
        local globalPosition = self.positionToWorld(position)
        globalPosition.y = globalPosition.y + 0.5
        card.setPosition(globalPosition)
    else
        -- Move the card above or below the deck depending on where we want it to go
        local deckPosition = current.getPosition()
        if atBottom then
            deckPosition.y = deckPosition.y - 0.5
        else
            deckPosition.y = deckPosition.y + 0.5
        end
        card.setPosition(deckPosition)
        current.putObject(card)
    end
end