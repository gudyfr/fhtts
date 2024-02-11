local deck_helper = {}

local function shiftUp(position, shift)
    return { x = position.x, y = position.y + shift, z = position.z }
  end

--- Finds a deck or card at a specific position using world coordinates.
---@param position any a table with x, y, z coordinates.
---@return any the deck or card at the position, or nil if there is none.
local function getDeckOrCardAtWorldPosition(position)
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
end

--- Draw a card from the deck and put it into the discard
---@param drawDeckPosition any a table with x, y, z coordinates.
---@param discardDeckPosition any a table with x, y, z coordinates.
---@return any card a card object
function deck_helper.draw(drawDeckPosition, discardDeckPosition)
    local absoluteTarget = self.positionToWorld(shiftUp(discardDeckPosition, 0.1))
    local hitlist = Physics.cast({
        origin       = self.positionToWorld(drawDeckPosition),
        direction    = { 0, 1, 0 },
        type         = 2,
        size         = { 1, 1, 1 },
        max_distance = 0,
        debug        = true
    })
    for _, j in pairs(hitlist) do
        if j.hit_object.tag == "Deck" then
            local card = j.hit_object.takeObject({
                position = absoluteTarget,
                flip     = true
            })
            return card
        elseif j.hit_object.tag == "Card" then
            local card = j.hit_object
            card.setPosition(absoluteTarget)
            card.flip()
        end
        return card
    end
end

local function returnDiscardToDraw(drawDeckPosition, discardDeckPosition)
    local discardDeck = getDeckOrCardAtWorldPosition(self.positionToWorld(discardDeckPosition))
    local target = self.positionToWorld(shiftUp(drawDeckPosition, 0.1))
    if discardDeck ~= nil then
        discardDeck.setRotation({ x = 0, y = 0, z = 180 })
        discardDeck.setPosition(target)
    end
end

--- Put the discard into the deck and shuffle it
---@param drawDeckPosition any a table with x, y, z coordinates.
---@param discardDeckPosition any a table with x, y, z coordinates.
function deck_helper.shuffle(drawDeckPosition, discardDeckPosition)
    -- We need to retun cards first
    returnDiscardToDraw(drawDeckPosition, discardDeckPosition)
    local drawDeck = getDeckOrCardAtWorldPosition(self.positionToWorld(drawDeckPosition))
    drawDeck.shuffle()
end

return deck_helper