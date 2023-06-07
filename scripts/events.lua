require("savable")
require("deck_save_helpers")
require("constants")
require('cards')

-- TODO Fetch Personal Quests Cards from Player mats

Categories = {}
Categories["Road Events"] = { "Boat", "Summer", "Winter" }
Categories["Outpost Events"] = { "Personal Quests", "Summer", "Winter" }
Statuses = { "Inactive", "Active", "Removed" }
Reset = {}
Reset["Road Events"] = {}
Reset["Road Events"]["Summer"] = {}
Reset["Road Events"]["Summer"]["Inactive"] = { 21, 52 }
Reset["Road Events"]["Summer"]["Active"] = { 1, 20 }
Reset["Road Events"]["Winter"] = {}
Reset["Road Events"]["Winter"]["Inactive"] = { 21, 49 }
Reset["Road Events"]["Winter"]["Active"] = { 1, 20 }

Reset["Outpost Events"] = {}
Reset["Outpost Events"]["Summer"] = {}
Reset["Outpost Events"]["Summer"]["Inactive"] = { 21, 65 }
Reset["Outpost Events"]["Summer"]["Active"] = { 1, 20 }

Reset["Outpost Events"]["Winter"] = {}
Reset["Outpost Events"]["Winter"]["Inactive"] = { 21, 81 }
Reset["Outpost Events"]["Winter"]["Active"] = { 1, 20 }
Reset["Outpost Events"]["Personal Quests"] = {}
Reset["Outpost Events"]["Personal Quests"]["Active"] = { 1, 10 }

CardPrefixes = {}
CardPrefixes["Road Events"] = {}
CardPrefixes["Road Events"]["Summer"] = "SR-"
CardPrefixes["Road Events"]["Winter"] = "WR-"
CardPrefixes["Road Events"]["Boat"] = "B-"
CardPrefixes["Outpost Events"] = {}
CardPrefixes["Outpost Events"]["Summer"] = "SO-"
CardPrefixes["Outpost Events"]["Winter"] = "WO-"
CardPrefixes["Outpost Events"]["Personal Quests"] = "PQ-"

function createEmptyState()
    local categories = Categories[Name]
    local state = {}
    for _, category in ipairs(categories) do
        state[category] = {}
        for _, status in ipairs(Statuses) do
            state[category][status] = {}
            if Reset[Name][category] ~= nil then
                local resetData = Reset[Name][category][status]
                if resetData ~= nil then
                    local cardPrefix = CardPrefixes[Name][category]
                    for i = resetData[1], resetData[2] do
                        local filler = ""
                        if i < 10 then
                            filler = "0"
                        end
                        table.insert(state[category][status], cardPrefix .. filler .. i)
                    end
                end
            end
        end
    end
    state["Search"] = {}
    state["Active"] = {}
    state.players = {}
    return state
end

function getState()
    local state = {}
    -- Find all locations
    table.sort(searchPositions, function(a, b) return 10 * (a.z - b.z) + (b.x - a.x) < 0 end)
    local categories = Categories[Name]
    local i = 1
    for _, category in ipairs(categories) do
        state[category] = {}
        for _, status in ipairs(Statuses) do
            state[category][status] = getCardList(searchPositions[i])
            i = i + 1
        end
    end
    state["Search"] = getCardList(resultPosition)
    state["Active"] = getCardList(activePosition)

    state.players = {}
    if Name == "Outpost Events" then
        for _, player in ipairs(PlayerColors) do
            local playerMat = Global.call("getPlayerMatExt", { player })
            if playerMat ~= nil then
                local personalQuestCardPosition = JSON.decode(playerMat.call("getPersonalQuestCardPosition"))
                state.players[player] = getCardList(self.positionToLocal(personalQuestCardPosition))
            end
        end
    end
    return state
end

function onStateUpdate(state)
    table.sort(searchPositions, function(a, b) return 10 * (a.z - b.z) + (b.x - a.x) < 0 end)
    local categories = Categories[Name]
    local i = 1

    -- Get our restore deck
    local deck, cardGuids = getRestoreDeck(Name)
    if deck ~= nil then
        -- Use the deck to move card/decks into the right locations
        for _, category in ipairs(categories) do
            for _, status in ipairs(Statuses) do
                deck = rebuildDeck(deck, cardGuids, state[category][status], searchPositions[i],
                    status == "Removed" or category == "Personal Quests")
                i = i + 1
            end
        end
        deck = rebuildDeck(deck, cardGuids, state["Search"], resultPosition)
        deck = rebuildDeck(deck, cardGuids, state["Active"], activePosition)
        if Name == "Outpost Events" then
            for _, player in ipairs(PlayerColors) do
                local playerMat = Global.call("getPlayerMatExt", { player })
                if playerMat ~= nil then
                    local personalQuestCardPosition = JSON.decode(playerMat.call("getPersonalQuestCardPosition"))
                    deck = rebuildDeck(deck, cardGuids, state.players[player] or {},
                        self.positionToLocal(personalQuestCardPosition))
                end
            end
        end
        if deck ~= nil and not deck.isDestroyed() then
            destroyObject(deck)
        end
    end
end

function onLoad(save)
    Name = self.getName()
    searchPositions = {}
    for _, point in pairs(self.getSnapPoints()) do
        local tagged = false
        local tags = {}
        for _, tag in ipairs(point.tags) do
            tags[tag] = 1
        end
        local position = point.position
        -- print(JSON.encode(tags))

        if tags["input"] ~= nil then
            createInput(point.position)
            tagged = true
        elseif tags["button"] ~= nil then
            if tags["search"] ~= nil then
                createSearchButton(point.position)
            elseif tags["audio play"] ~= nil then
                if tags["a"] ~= nil then
                    createPlayAButton(point.position)
                elseif tags["b"] ~= nil then
                    createPlayBButton(point.position)
                else
                    createPlayButton(point.position)
                end
            elseif tags["return"] then
                createReturnButton(point.position)
            end
            tagged = true
        elseif tags["result"] then
            resultPosition = point.position
            tagged = true
        elseif tags["active"] then
            activePosition = point.position
            tagged = true
        end

        if not tagged then
            table.insert(searchPositions, point.position)
        end
    end
    table.sort(searchPositions, function(a, b) return (a.z - b.z) * 10 + b.x - a.x < 0 end)
    registerSavable(Name)
end

searchText = ""

function createInput(position)
    local params = {
        input_function = "onTextEdit",
        function_owner = self,
        position = { -position[1], position[2], position[3] },
        scale = { .2, 1, .2 },
        width = 1500,
        height = 250,
        font_size = 200,
        color = { 1, 1, 1, 0 },
        font_color = { 0, 0, 0, 100 },
        alignment = 3
    }
    self.createInput(params)
end

function onTextEdit(obj, color, text, selected)
    local len = string.len(text)
    lastChar = string.sub(text, len, len)
    if lastChar == "\n" then
        searchText = string.sub(text, 1, len - 1)
        obj.setValue(searchText)
        search()
    else
        searchText = text
    end
end

function createPlayButton(position)
    createButton(position, "playCard", "Play")
end

function createPlayAButton(position)
    createButton(position, "playCard_A", "Option A")
end

function createPlayBButton(position)
    createButton(position, "playCard_B", "Option B")
end

function createReturnButton(position)
    createButton(position, "returnCard", "Return")
end

function createSearchButton(position)
    createButton(position, "search", "Search")
end

function createButton(position, fName, tooltip)
    -- print("Creating button " .. tooltip)
    params = {
        function_owner = self,
        click_function = fName,
        tooltip        = tooltip,
        position       = { -position[1], position[2], position[3] },
        width          = 200,
        height         = 200,
        font_size      = 50,
        color          = { 1, 1, 1, 0 },
        scale          = { .3, .3, .3 },
        font_color     = { 1, 1, 1, 0 },
    }
    self.createButton(params)
end

function search()
    if searchText == nil or resultPosition == nil then
        return
    end
    for _, position in ipairs(searchPositions) do
        local hitlist = Physics.cast({
            origin       = self.positionToWorld(position),
            direction    = { 0, 1, 0 },
            type         = 2,
            size         = { 1, 1, 1 },
            max_distance = 0,
            debug        = false
        })

        for _, result in ipairs(hitlist) do
            if result.hit_object.tag == "Deck" then
                for _, obj in ipairs(result.hit_object.getObjects()) do
                    if obj.name == searchText then
                        result.hit_object.takeObject({ guid = obj.guid, position = self.positionToWorld(resultPosition) })
                        result.hit_object.highlightOn({ r = 0, g = 1, b = 0 }, 2)
                    end
                end
            elseif result.hit_object.tag == "Card" then
                if result.hit_object.getName() == searchText then
                    result.hit_object.setPosition(resultPosition)
                end
            end
        end
    end
end

function getActiveCard()
    if activePosition ~= nil then
        local hitlist = Physics.cast({
            origin       = self.positionToWorld(activePosition),
            direction    = { 0, 1, 0 },
            type         = 2,
            size         = { 1, 1, 1 },
            max_distance = 0,
            debug        = false
        })
        for _, h in ipairs(hitlist) do
            if h.hit_object.tag == "Card" then
                return h.hit_object
            end
        end
    end
    return nil
end

function returnCard()
    local activeCard = getActiveCard()
    if activeCard ~= nil then
        -- We need to determine the appropriate deck to return this card to
        local type = string.sub(activeCard.getName(), 1, 1)
        if type == 'S' then
            -- Summer event card
            addCardToDeckAt(activeCard, searchPositions[5], { atBottom = true })
        elseif type == 'W' then
            -- Winter event card
            addCardToDeckAt(activeCard, searchPositions[8], { atBottom = true })
        elseif type == 'B' or type == 'P' then
            -- Boat or Personal Quest
            addCardToDeckAt(activeCard, searchPositions[2], { atBottom = true })
        end
    end
end

function getPersonalQuestInactivePosition()
    return JSON.encode(self.positionToWorld(searchPositions[1]))
end

function playCard()
    local activeCard = getActiveCard()
    if activeCard ~= nil then
        local name = activeCard.getName()
        Global.call("playNarration", { "events", name })
    end
end

function playCard_A()
    local activeCard = getActiveCard()
    if activeCard ~= nil then
        local name = activeCard.getName()
        Global.call("playNarration", { "events", name .. "_A" })
    end
end

function playCard_B()
    local activeCard = getActiveCard()
    if activeCard ~= nil then
        local name = activeCard.getName()
        Global.call("playNarration", { "events", name .. "_B" })
    end
end
