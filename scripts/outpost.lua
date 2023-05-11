require("garden_stickers")
require("savable")
require("deck_save_helpers")

function getState()
    local result = {}
    result.state = State
    result.buildings = {}
    for nr, position in pairs(BuildingElements.buildings) do
        result.buildings[nr] = getCardList(position)
    end
    result.buildingDeck = getCardList(BuildingElements.deck)
    result.townGuards = {}
    for name, position in pairs(TownGuardElements.decks) do
        result.townGuards[name] = getCardList(position)
    end
    -- print(JSON.encode(result))
    return result
end

function onStateUpdate(state)
    -- Recover buildings
    local deck, cardGuids = getRestoreDeck("Buildings")
    if deck ~= nil then
        for nr, position in pairs(BuildingElements.buildings) do
            rebuildDeck(deck, cardGuids, state.buildings[nr] or {}, position)
        end
        rebuildDeck(deck, cardGuids, state.buildingDeck, BuildingElements.deck, true)
        destroyObject(deck)
    end

    --Recover Town Guards
    local deck, cardGuids = getRestoreDeck("Town Guards")
    if deck ~= nil then
        for name, position in pairs(TownGuardElements.decks) do
            rebuildDeck(deck, cardGuids, state.townGuards[name] or {}, position, name == "draw" or name == "supply")
        end
        -- We should have moved all town guards cards, so leave the remaining ones on the scenario mat
    end
    updateGardenButtons()
    refreshDecals()
end

function createEmptyState()
    local result = {}
    result.state = {}
    result.buildings = {}
    result.buildings["34"] = { "34 - Craftsman - Lvl. 1" }
    result.buildings["35"] = { "35 - Alchemist - Lvl. 1" }
    result.buildings["84"] = { "84 - Workshop - Lvl. 1" }
    result.buildings["98"] = { "98 - Barracks - Lvl. 1" }
    result.buildingDeck = {
        "98 - Barracks - Lvl. 4",
        "98 - Barracks - Lvl. 3",
        "98 - Barracks - Lvl. 2",
        "35 - Alchemist - Lvl. 3",
        "35 - Alchemist - Lvl. 2",
        "34 - Craftsman - Lvl. 9",
        "34 - Craftsman - Lvl. 8",
        "34 - Craftsman - Lvl. 7",
        "34 - Craftsman - Lvl. 6",
        "34 - Craftsman - Lvl. 5",
        "34 - Craftsman - Lvl. 4",
        "34 - Craftsman - Lvl. 3",
        "34 - Craftsman - Lvl. 2",
        "17 - Logging Camp - Lvl. 4",
        "17 - Logging Camp - Lvl. 3",
        "17 - Logging Camp - Lvl. 2",
        "17 - Logging Camp - Lvl. 1",
        "12 - Hunting Lodge - Lvl. 4",
        "12 - Hunting Lodge - Lvl. 3",
        "12 - Hunting Lodge - Lvl. 2",
        "12 - Hunting Lodge - Lvl. 1",
        "05 - Mining Camp - Lvl. 4",
        "05 - Mining Camp - Lvl. 3",
        "05 - Mining Camp - Lvl. 2",
        "05 - Mining Camp - Lvl. 1",
        "05 - Mining Camp - Lvl. 1" }
    local baseTownGuards = {}
    for tg = 1420, 1439 do
        table.insert(baseTownGuards, "" .. tg)
    end
    result.townGuards = {}
    result.townGuards.draw = baseTownGuards
    local supplyTownGuards = {}
    for tg = 1440, 1474 do
        table.insert(supplyTownGuards, "" .. tg)
    end
    result.townGuards.supply = supplyTownGuards
    return result
end

function onLoad(save)
    State = JSON.decode(save) or {}
    locateElementsFromTags()
    -- print(JSON.encode(BuildingElements))

    -- Town guard buttons
    if TownGuardElements["buttons"]["draw"] ~= nil then
        local pos = TownGuardElements["buttons"]["draw"]
        local params = {
            function_owner = self,
            click_function = "drawTownGuard",
            label = "",
            tooltip = "Draw a Town Guard attack modifier card",
            position = { -pos.x, pos.y + 0.01, pos.z },
            width = 200,
            height = 200,
            font_size = 50,
            color = { 1, 1, 1, 0 },
            scale = { .3, 1, .08 },
            font_color = { 0, 0, 0, 1 }
        }
        self.createButton(params)
    end
    if TownGuardElements["buttons"]["shuffle"] ~= nil then
        local pos = TownGuardElements["buttons"]["shuffle"]
        local params = {
            function_owner = self,
            click_function = "shuffleTownGuard",
            label = "",
            tooltip = "Shuffle the Town Guard attack modifier deck",
            position = { -pos.x, pos.y + 0.01, pos.z },
            width = 200,
            height = 200,
            font_size = 50,
            color = { 1, 1, 1, 0 },
            scale = { .3, 1, .08 },
            font_color = { 0, 0, 0, 1 }
        }
        self.createButton(params)
    end

    -- Building build/upgrade actions
    for nr, pos in pairs(BuildingElements["buildings"]) do
        local fName = "change_building_" .. nr
        self.setVar(fName, function(obj, player, alt) changeBuilding(nr, alt) end)
        local params = {
            function_owner = self,
            click_function = fName,
            label = "",
            tooltip = "Build / Upgrade building " .. nr .. " (right click to undo)",
            position = { -pos.x - 0.15, pos.y + 0.05, pos.z + 0.13 },
            width = 150,
            height = 150,
            font_size = 50,
            color = { 1, 1, 1, 0 },
            scale = { .1, 1, .1 },
            font_color = { 0, 0, 0, 1 }
        }
        self.createButton(params)
    end

    updateGardenButtons()
    registerSavable("Outpost")
end

function onSave()
    return JSON.encode(State)
end

TownGuardElements = {
    buttons = {},
    decks = {}
}
BuildingElements = {
    deck = {},
    buildings = {}
}
function locateElementsFromTags()
    local buildingLocations = {}
    for _, point in ipairs(self.getSnapPoints()) do
        local position = point.position
        local tagsMap = {}
        for _, tag in ipairs(point.tags) do
            tagsMap[tag] = true
        end

        if tagsMap["town guard"] ~= nil then
            if tagsMap["button"] ~= nil then
                if tagsMap["draw"] ~= nil then
                    TownGuardElements["buttons"]["draw"] = position
                elseif tagsMap["shuffle"] ~= nil then
                    TownGuardElements["buttons"]["shuffle"] = position
                end
            elseif tagsMap["deck"] ~= nil then
                if tagsMap["draw"] ~= nil then
                    TownGuardElements["decks"]["draw"] = position
                elseif tagsMap["discard"] ~= nil then
                    TownGuardElements["decks"]["discard"] = position
                elseif tagsMap["removed"] ~= nil then
                    TownGuardElements["decks"]["removed"] = position
                elseif tagsMap["supply"] ~= nil then
                    TownGuardElements["decks"]["supply"] = position
                end
            end
        end
        if tagsMap["building"] ~= nil then
            if tagsMap["deck"] ~= nil then
                BuildingElements["deck"] = position
            else
                table.insert(buildingLocations, position)
            end
        end
    end
    -- We have two rows of buildings, sort by Z first
    table.sort(buildingLocations, function(p1, p2) return p1.z < p2.z end)
    first, second = split_table(buildingLocations, 11)
    table.sort(first, function(p1, p2) return p1.x > p2.x end)
    table.sort(second, function(p1, p2) return p1.x > p2.x end)
    buildingLocations = concatenate_tables(first, second)
    local buildingNumbers = {
        "05", "12", "17", "21", "24", "34", "35", "37", "39", "42", "44",
        "65", "67", "72", "74", "81", "83", "84", "85", "88", "90", "98" }
    for i, nr in ipairs(buildingNumbers) do
        BuildingElements["buildings"][nr] = buildingLocations[i]
    end
end

function split_table(t, index)
    local t1 = {}
    local t2 = {}
    for i, v in ipairs(t) do
        if i <= index then
            table.insert(t1, v)
        else
            table.insert(t2, v)
        end
    end
    return t1, t2
end

function concatenate_tables(t1, t2)
    local result = {}
    for i, v in ipairs(t1) do
        table.insert(result, v)
    end
    for i, v in ipairs(t2) do
        table.insert(result, v)
    end
    return result
end

function drawTownGuard()
    local hitlist = Physics.cast({
        origin    = self.positionToWorld(TownGuardElements["decks"]["draw"]),
        direction = { 0, 1, 0 },
        type      = 2,
        debug     = false
    })
    for _, h in ipairs(hitlist) do
        if h.hit_object.tag == "Deck" then
            h.hit_object.takeObject({
                position = self.positionToWorld(shiftUp(TownGuardElements["decks"]["discard"])),
                smooth = true,
                flip = true,
            })
        elseif h.hit_object.tag == "Card" then
            local card = h.hit_object
            card.flip()
            card.setPositionSmooth(self.positionToWorld(shiftUp(TownGuardElements["decks"]["discard"])))
        end
    end
end

function shuffleTownGuard()
    -- Determine what's in the destination (nothing, card, deck)
    local hitlist = Physics.cast({
        origin    = self.positionToWorld(TownGuardElements["decks"]["draw"]),
        direction = { 0, 1, 0 },
        type      = 2,
        debug     = true
    })
    local destination = nil
    for _, h in ipairs(hitlist) do
        if h.hit_object.tag == "Deck" or h.hit_object == "Card" then
            destination = h.hit_object
        end
    end

    -- Move all cards back to the draw deck
    hitlist = Physics.cast({
        origin    = self.positionToWorld(TownGuardElements["decks"]["discard"]),
        direction = { 0, 1, 0 },
        type      = 2,
        debug     = true
    })
    for _, h in ipairs(hitlist) do
        if h.hit_object.tag == "Deck" then
            local deck = h.hit_object
            for _, obj in ipairs(deck.getObjects()) do
                if deck.remainder ~= nil then
                    -- At this point destination should not be nil
                    destination.putObject(deck.remainder)
                else
                    local card = deck.takeObject({ guid = obj.guid, smooth = false })
                    if destination ~= nil then
                        destination = destination.putObject(card)
                    else
                        destination = card
                        card.setRotation({ 180, 0, 0 })
                        card.setPosition(self.positionToWorld(TownGuardElements["decks"]["draw"]))
                    end
                end
            end
        elseif h.hit_object.tag == "Card" then
            -- destination should already be a deck
            destination.putObject(h.hit_object)
        end
    end

    -- Now we need to shuffle the destination
    destination.shuffle()
end

function shiftUp(position)
    return { x = position.x, y = position.y + 0.6, z = position.z }
end

function getBuildingLevel(name)
    local last_number = name:match(".*(%d+)")
    if last_number then
        return tonumber(last_number)
    else
        return 0
    end
end

function getBuildingNumber(name)
    local first_number = name:match("(%d+)")
    if first_number then
        return first_number
    else
        return nil
    end
end

function getBuildingName(name)
    local parts = {}
    for part in name:gmatch("[^%-]+") do
        table.insert(parts, part:match("^%s*(.-)%s*$"))
    end
    return parts[2]
end

function getBuildingDeck()
    local hitlist = Physics.cast({
        origin    = self.positionToWorld(BuildingElements["deck"]),
        direction = { 0, 1, 0 },
        type      = 2,
        debug     = false
    })
    for _, h in ipairs(hitlist) do
        if h.hit_object.tag == "Deck" then
            return h.hit_object
        end
    end
    return nil
end

function findBuildingByNumberAndLevel(deck, nr, lvl)
    for _, obj in ipairs(deck.getObjects()) do
        local cardName = obj.name
        local cardNr = getBuildingNumber(cardName)
        if nr == cardNr then
            if getBuildingLevel(cardName) == lvl then
                return obj.guid
            end
        end
    end
    return nil
end

MinBuildingLevels = {}
MinBuildingLevels["34"] = 1
MinBuildingLevels["35"] = 1
MinBuildingLevels["84"] = 1
MinBuildingLevels["98"] = 1

function getCurrentCardAndLevel(buildingPosition)
    -- Determine current level
    local hitlist = Physics.cast({
        origin    = buildingPosition,
        direction = { 0, 1, 0 },
        type      = 2,
        debug     = false
    })
    local currentCard
    local level = 0
    for _, h in ipairs(hitlist) do
        local hit = h.hit_object
        if hit.tag == "Card" and hit.hasTag("building") then
            currentCard = hit
            level = getBuildingLevel(hit.getName())
        end
    end

    return currentCard, level
end

function changeBuilding(nr, alt)
    local buildingPosition = self.positionToWorld(BuildingElements["buildings"][nr])

    -- Determine current level
    local currentCard, level = getCurrentCardAndLevel(buildingPosition)

    -- Determine the target level
    local targetLevel
    if alt then
        targetLevel = level - 1
    else
        targetLevel = level + 1
    end
    changeBuildingLevel(buildingPosition, currentCard, nr, targetLevel, alt)
end

function changeBuildingLevel(buildingPosition, currentCard, nr, targetLevel, down)
    local minbuildingLevel = MinBuildingLevels[nr] or 0

    -- See if we can find the target card in the deck
    local deck = getBuildingDeck()
    local guid = findBuildingByNumberAndLevel(deck, nr, targetLevel)
    if guid ~= nil or (targetLevel == minbuildingLevel and currentCard ~= nil) then
        -- Let's swap cards
        if currentCard ~= nil then
            deck.putObject(currentCard)
        end
        if guid ~= nil then
            deck.takeObject({ guid = guid, position = shiftUp(buildingPosition), smooth = true, flip = true })
        end

        -- Update the map
        local map = getObjectFromGUID('d17d72')
        map.call("setBuildingLevel", { nr, targetLevel })
    else
        if down then
            broadcastToAll("Building " .. nr .. " is at minimum level")
        else
            broadcastToAll("Building " .. nr .. " has reached max level")
        end
    end

    -- A bit of special casing for the garden
    if nr == "24" then
        -- Make sure State.gardenFields is created
        if State.gardenFields == nil then
            State.gardenFields = {}
        end
        State.gardenLevel = targetLevel
        updateGardenButtons()
        refreshDecals()
    end
end

function setBuildingLevel(params)
    local nr = params[1]
    local lvl = params[2]
    local buildingPosition = self.positionToWorld(BuildingElements["buildings"][nr])

    -- Determine current level
    local currentCard, currentLevel = getCurrentCardAndLevel(buildingPosition)
    if currentLevel ~= lvl then
        changeBuildingLevel(buildingPosition, currentCard, nr, lvl)
    end
end

GardenLocationOffsets = {
    { x = 0.000, y = 0.051, z = 0.012 },
    { x = 0.037, y = 0.051, z = -0.029 },
    { x = 0.012, y = 0.051, z = -0.05 }
}

function updateGardenButtons()
    -- Clear current garden buttons
    for _, btn in ipairs(self.getButtons()) do
        local fName = btn.click_function
        if starts_with(fName, "cycleGarden_") then
            self.removeButton(btn.index)
        end
    end

    -- Add garden buttons depending on garden level
    local gardenLevel = State.gardenLevel or 0
    local pos = BuildingElements["buildings"]["24"]
    if gardenLevel >= 1 then
        createGardenButton(1, pos)
        if gardenLevel >= 2 then
            createGardenButton(2, pos)
            if gardenLevel >= 4 then
                createGardenButton(3, pos)
            end
        end
    end
end

function createGardenButton(index, pos)
    -- print("createGardenButton " .. index .. " at " .. JSON.encode(pos))
    -- Not super clean, but let's make sure we have an empty field
    if State.gardenFields[index] == nil then
        State.gardenFields[index] = "empty"
    end
    local offset = GardenLocationOffsets[index] or { 0, 0, 0 }
    local fName = "cycleGarden_" .. index
    self.setVar(fName, function(obj, player, alt) cycleGarden(index, alt) end)
    local params = {
        function_owner = self,
        click_function = fName,
        label = "",
        tooltip = "Cycle through possible planted fields (right click to clear)",
        position = { -(pos.x + offset.x), pos.y + offset.y, pos.z + offset.z },
        width = 150,
        height = 150,
        font_size = 50,
        color = { 1, 1, 1, 0 },
        scale = { .1, .1, .1 },
        font_color = { 0, 0, 0, 1 }
    }
    self.createButton(params)
end

function cycleGarden(index, alt)
    local current = State.gardenFields[index] or "empty"
    local next
    local found = false
    for name, url in pairs(GardenStickers) do
        if found then
            next = name
        end
        found = (name == current)
    end
    if next == nil or alt then next = "empty" end
    State.gardenFields[index] = next
    refreshDecals()
end

function starts_with(str, start)
    return str:sub(1, #start) == start
end

function refreshDecals()
    local stickers = {}
    -- Garden stickers
    local gardenLevel = State.gardenLevel or 0
    local pos = BuildingElements["buildings"]["24"]
    if gardenLevel >= 1 then
        createGardenDecal(stickers, 1, pos)
        if gardenLevel >= 2 then
            createGardenDecal(stickers, 2, pos)
            if gardenLevel >= 4 then
                createGardenDecal(stickers, 3, pos)
            end
        end
    end

    self.setDecals(stickers)
end

function createGardenDecal(stickers, index, pos)
    local current = State.gardenFields[index] or "empty"
    local offset = GardenLocationOffsets[index] or { 0, 0, 0 }
    local sticker = {
        url = GardenStickers[current],
        position = { pos.x + offset.x, pos.y + offset.y, pos.z + offset.z },
        rotation = { 90, 175, 0 },
        name = "garden_" .. index .. "_" .. current,
        scale = { 0.05, 0.05, 0.05 },
    }
    table.insert(stickers, sticker)
end

function getBuildingInfo(buildingNumber)
    local buildingPosition = self.positionToWorld(BuildingElements["buildings"][buildingNumber])

    -- Determine current level
    local currentCard, level = getCurrentCardAndLevel(buildingPosition)

    local wrecked = false
    if currentCard ~= nil then
        local zRot = currentCard.getRotation().z
        if zRot > 160 and zRot < 200 then
            wrecked = true
        end
    end

    return JSON.encode({level=level, wrecked=wrecked})
end
