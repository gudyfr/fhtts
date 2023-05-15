require('sorter')
require('search')
require('savable')
require('deck_save_helpers')
require('constants')

function createEmptyState()
    return {
        craftable = {},
        purchasable = {},
        other = {},
        players = {}
    }
end

function getState()
    local result = {}
    for category, model in pairs(AvailableDecks) do
        result[category] = getCardList(model.deck)
    end
    result["scenario discard"] = getCardList(DiscardedRandomScenarioPosition)
    result["players"] = {}
    for _, player in ipairs(PlayerColors) do
        local playerMat = Global.call("getPlayerMatExt", { player })
        if playerMat ~= nil then
            result.players[player] = {}
            local playerItemCardPositions = JSON.decode(playerMat.call("getItemCardPositions"))
            -- print(JSON.encode(playerItemCardPositions))
            for name, position in pairs(playerItemCardPositions) do
                result.players[player][name] = getCardList(self.positionToLocal(position))
            end
        end
    end
    -- print(JSON.encode(result.players))
    return result
end

function onStateUpdate(state)
    -- Get the items deck out of the save container
    deck, cardGuids = getRestoreDeck("Items")
    if deck ~= nil then
        -- First we can rebuild our craftable, purchasable and other decks
        for category, model in pairs(AvailableDecks) do
            local cards = state[category]
            table.sort(cards, function(a, b) return a < b end)
            rebuildDeck(deck, cardGuids, cards, model.deck)
        end
        rebuildDeck(deck, cardGuids, state["scenario discard"] or {}, DiscardedRandomScenarioPosition)

        -- Then restore player items
        for color, playerMatGuid in pairs(PlayerMats) do
            local playerMat = getObjectFromGUID(playerMatGuid)
            if playerMat ~= nil then
                -- print(color .. " player mat found, to restore : " .. JSON.encode(state.players[color]))
                local positionsJson = playerMat.call("getItemCardPositions")
                -- print("At : " .. positionsJson)
                local playerItemCardPositions = JSON.decode(positionsJson)
                local playerCards = state.players[color] or {}
                for name, position in pairs(playerItemCardPositions) do
                    local cardNames = playerCards[name] or {}
                    rebuildDeck(deck, cardGuids, cardNames, self.positionToLocal(position))
                end
            end
        end

        -- Now we should rebuild all the other decks
        table.sort(ItemPositions, function(a, b) return 30 * (a.z - b.z) + b.x - a.x < 0 end)
        local slots = { 0, 10, 15, 20, 25, 30, 35, 40, 45, 50, 58, 65, 82, 119, 128, 137, 146, 155, 159, 163, 167, 192,
            247, 264 }
        for i = 1, #slots - 1 do
            local cardNames = {}
            for c = slots[i] + 1, slots[i + 1] do
                local cardName = "" .. c
                if c < 10 then
                    cardName = "0" .. cardName
                end
                if c < 100 then
                    cardName = "0" .. cardName
                end
                -- Most cards appear twice, and if they don't the 2nd will just be ignored
                table.insert(cardNames, cardName)
                table.insert(cardNames, cardName)
                if c == 245 then
                    -- There are 4 items # 245
                    table.insert(cardNames, cardName)
                    table.insert(cardNames, cardName)
                end
            end
            table.sort(cardNames, function(a, b) return a > b end)
            rebuildDeck(deck, cardGuids, cardNames, ItemPositions[i], true)
        end

        -- And finally, we can move the remaining cards, if any, to their place\
        -- At this point they should all be random scenarios
        deleteCardsAt(ItemPositions[#slots])
        if deck ~= nil then
            if not deck.isDestroyed() then
                if deck.remainder ~= nil then
                    deck.remainder.setPosition(self.positionToWorld(shiftUp(ItemPositions[#slots])))
                    deck.remainder.setRotation({ 0, 180, 180 })
                else
                    deck.setPosition(self.positionToWorld(shiftUp(ItemPositions[#slots])))
                    deck.setRotation({ 0, 180, 180 })
                end
            end
        end
    end
end

function onLoad(save)
    locateBoardElementsFromTags()
    Global.call("registerForCollision", self)
    createControls()
    registerSavable("Items")
end

function onSave()
end

ItemPositions = {}
SearchResultPosition = {}
SearchInputPosition = {}
SearchButtonPosition = {}
SortInputPosition = {}
SortResultPosition = {}
DiscardedRandomScenarioPosition = {}

AvailableDecks = {
    craftable = {
        deck = {},
        button = {}
    },
    purchasable = {
        deck = {},
        button = {}
    },
    other = {
        deck = {},
        button = {}
    }
}

function onObjectCollisionEnter()
    sort(SortInputPosition, SortResultPosition)
end

function locateBoardElementsFromTags()
    for _, snapPoint in ipairs(self.getSnapPoints()) do
        local tagsMap = {}
        local position = snapPoint.position
        for _, tag in ipairs(snapPoint.tags) do
            tagsMap[tag] = true
        end

        if tagsMap['deck'] ~= nil then
            if tagsMap['item'] ~= nil then
                table.insert(ItemPositions, position)
                for _, key in ipairs({ 'craftable', 'purchasable', 'other' }) do
                    if tagsMap[key] ~= nil then
                        AvailableDecks[key].deck = position
                    end
                end
                if tagsMap['discard'] ~= nil then
                    DiscardedRandomScenarioPosition = position
                end
            end
        end

        if tagsMap['button'] ~= nil then
            if tagsMap['search'] ~= nil then
                SearchButtonPosition = position
            end
            if tagsMap['layout'] ~= nil then
                for _, key in ipairs({ 'craftable', 'purchasable', 'other' }) do
                    if tagsMap[key] ~= nil then
                        AvailableDecks[key].button = position
                    end
                end
            end
        end

        if tagsMap['input'] ~= nil then
            if tagsMap['search'] ~= nil then
                SearchInputPosition = position
            end
            if tagsMap['sort'] ~= nil then
                SortInputPosition = position
            end
        end

        if tagsMap['result'] ~= nil then
            if tagsMap['search'] ~= nil then
                SearchResultPosition = position
            end
            if tagsMap['sort'] ~= nil then
                SortResultPosition = position
            end
        end
    end
end

function createControls()
    for key, value in pairs(AvailableDecks) do
        createGridLayoutButton(key, value.button)
    end
    createSearchButton(SearchButtonPosition)
    createSearchInput(SearchInputPosition)
end

function createGridLayoutButton(category, position)
    fName = "onLayout_" .. category
    self.setVar(fName, function() onLayout(category) end)
    createButton(position, fName, "Layout items on the scenario mat")
end

function createSearchButton(position)
    createButton(position, "onSearch", "Search")
end

function createButton(position, fName, tooltip)
    local label = ""
    local params = {
        function_owner = self,
        click_function = fName,
        label          = label,
        position       = { -(position.x), position.y, position.z },
        width          = 200,
        height         = 200,
        font_size      = 300,
        color          = { 1, 1, 1, 0 },
        scale          = { .25, .25, .25 },
        font_color     = { .2, .24, 0.28, 100 },
        tooltip        = tooltip
    }
    self.createButton(params)
end

function createSearchInput(position)
    local params = {
        input_function = "onSearchTextEdit",
        function_owner = self,
        position = { -(position.x), position.y, position.z },
        scale = { .25, .25, .25 },
        width = 600,
        height = 150,
        font_size = 120,
        color = { 1, 1, 1, 0 },
        font_color = { .2, .24, 0.28, 100 },
        alignment = 3,
        value = ""
    }
    self.createInput(params)
end

SearchText = ""

function onSearchTextEdit(obj, color, text, selected)
    if not selected then
        SearchText = clean(text)
        onSearch()
    else
        if text[#text] == "\n" then
            SearchText = clean(text)
            onSearch()
        end
    end
end

function clean(str)
    str = string.gsub(str, "\r", "")
    return string.gsub(str, "\n", "")
end

function onLayout(category)
    -- print('onLayout : ' .. category)
    -- Let's see if we have a deck at the source
    local deck = findDeck(AvailableDecks[category].deck)
    if deck == nil then
        -- We may have layout our deck on the scenario mat, let's get the cards back now
        local cards = findCardsInLayoutArea(category)
        if #cards > 0 then
            table.sort(cards, function(a, b) return a.getName() < b.getName() end)
            -- Bring those cards back into a deck
            local deck = nil
            for _, card in ipairs(cards) do
                if deck ~= nil then
                    deck = deck.putObject(card)
                else
                    deck = card
                end
            end
            -- Adding a delay before moving the deck, as it seems that sometimes cards struggle to get in the deck.
            Wait.time(
                function()
                    deck.setPosition(self.positionToWorld(shiftUp(AvailableDecks[category].deck)))
                end,
                0.5)
        end
    else
        -- Let's make sure there is nothing in the layout area
        if isLayoutAreaEmpty() then
            local x = 0
            local z = 0
            local w = 1.5
            local h = 2.25
            local cardsToLayout = deck.getObjects()
            table.sort(cardsToLayout, function(a, b) return a.name < b.name end)

            local cardCount = #cardsToLayout
            local width = math.ceil(math.sqrt(cardCount * 1.5))
            local center = getCenterOfLayoutArea()
            local xOffset = width / 2
            local zOffset = width / 3

            for _, obj in ipairs(cardsToLayout) do
                local position = { (x - xOffset) * w + center.x, 1.5, (zOffset - z) * h + center.z }
                x = x + 1
                if x == width then
                    x = 0
                    z = z + 1
                end
                if deck.remainder ~= nil then
                    deck.remainder.setPosition(position)
                else
                    deck.takeObject({ guid = obj.guid, position = position, smooth = false })
                end
            end
        else
            broadcastToAll("Can't layout items, scenario mat is not empty")
        end
    end
end

function shiftUp(position)
    return { x = position.x, y = position.y + 0.05, z = position.z }
end

function getCenterOfLayoutArea()
    local zone = getObjectFromGUID(ScenarioMatZoneGuid)
    local bounds = zone.getBounds()
    return bounds.center
end

function findCardsInLayoutArea(category)
    local result = {}
    local zone = getObjectFromGUID(ScenarioMatZoneGuid)
    -- Iterate through object occupying the zone
    for _, occupyingObject in ipairs(zone.getObjects(true)) do
        if occupyingObject.hasTag("item") then
            if category == nil or occupyingObject.hasTag(category) then
                table.insert(result, occupyingObject)
            end
        end
    end
    return result
end

function isLayoutAreaEmpty()
    return Global.call("isLayoutAreaEmpty")
end

function onSearch()
    -- print('onSearch : ' .. SearchText)
    searchCard(SearchText, ItemPositions, SearchResultPosition)
end

function findDeck(position)
    local hitlist = Physics.cast({
        origin       = self.positionToWorld(position),
        direction    = { 0, 1, 0 },
        type         = 2,
        size         = { 1, 1, 1 },
        max_distance = 0,
        debug        = false
    })
    for _, hit in ipairs(hitlist) do
        if hit.hit_object.tag == "Deck" then
            return hit.hit_object
        end
    end
end

function getItemsDrawPiles()
    local positions = {}
    for name,info in pairs(AvailableDecks) do
        local position = self.positionToWorld(info.deck)
        positions[name] = position
    end
    return JSON.encode(positions)
end