require('fhlog')
require('number_decals')
require('cards')
require('enhancer_data')
require('savable')
require('json')
require('data/cardEnhancements')

TAG = "Enhancer"
FUZZY_MATCH_DISTANCE = 0.1

function getState()
    return ActiveEnhancements
end

function onStateUpdate(enhancements)
    for name, cardInfo in pairs(CardEnhancements) do
        local cardEnhancements = enhancements[name]
        if cardEnhancements ~= nil then
            for _, spot in ipairs(cardInfo.spots) do
                local enhancementFound = nil
                for _, enhancement in ipairs(cardEnhancements) do
                    if distance(enhancement.position, spot.position) < FUZZY_MATCH_DISTANCE then
                        enhancementFound = enhancement.name
                        -- Also update the enhancement itself for the next save
                        enhancement.position = spot.position
                    end
                end
                spot.enhancement = enhancementFound
            end
        end
    end
end

function onLoad(save)
    fhLogInit()
    Global.call('registerForCollision', self)
    Global.call('registerForPing', self)
    if save ~= nil then
        ActiveEnhancements = JSON.decode(save)
    end
    if ActiveEnhancements == nil then
        ActiveEnhancements = {}
    end
    locateBoardElementsFromTags()
    registerSavable("enhancer", 0)
    Global.call('registerDataUpdatable', self)
end

function onSave()
    return JSON.encode(ActiveEnhancements)
end

function updateData(params)
    local baseUrl = params.baseUrl
    local first = params.first
    if baseUrl ~= "https://gudyfr.github.io/fhtts/" or not first then
        local url = baseUrl .. "cardEnhancements.json"
        WebRequest.get(url, updateCardDefinitions)
    end
end

function updateCardDefinitions(request)
    CardEnhancements = jsonDecode(request.text)
    onStateUpdate(ActiveEnhancements)
end

function locateBoardElementsFromTags()
    for _, point in ipairs(self.getSnapPoints()) do
        local tagsMap = {}
        for _, tag in ipairs(point.tags) do
            tagsMap[tag] = true
        end
        if tagsMap["ability card"] ~= nil then
            CardPosition = point.position
        end
    end
end

ActiveEnhancements = {}
CurrentCard = nil
CurrentCardInfo = nil
CurrentSpot = nil
function onObjectCollisionEnter(payload)
    if CardPosition ~= nil then
        local card = getDeckOrCardAt(CardPosition)
        if card ~= nil and card.tag == "Card" then
            setCurrentCard(card)
        end
    end
end

function setCurrentCard(card)
    if CurrentCard == card then
        return
    end
    if CurrentCard ~= nil then
        CurrentCard.setDecals(getEnhancementDecals(CurrentCardInfo))
        CurrentCard.clearButtons()
        CurrentCard = nil
        CurrentCardInfo = nil
        CurrentSpot = nil
    end
    if card ~= nil then
        CurrentCard = card
        local name = CurrentCard.getName()
        if CardEnhancements[name] == nil then
            CardEnhancements[name] = { level = 1, spots = {} }
        end
        CurrentCardInfo = CardEnhancements[name]
        local logLevel = isDevMode() and DEBUG or INFO
        fhlog(logLevel, TAG, "Current card : %s, state : %s", name, CurrentCardInfo)
    end
    refreshDecals()
end

function getEnhancementDecals(cardInfo)
    cardInfo = cardInfo or {}
    local result = {}
    for _, spot in ipairs(cardInfo.spots or {}) do
        if spot.enhancement ~= nil then
            local url = EnhancementStickers[spot.enhancement]
            if url ~= nil then
                local scale = spot.enhancement == "hex" and 0.25 or 0.15
                table.insert(result,
                    {
                        position = { x = spot.position.x, y = Y_DECAL - 0.001, z = spot.position.z },
                        rotation = { 90, 180, 0 },
                        scale = { scale, scale, scale },
                        name = "enhancement_" .. spot.enhancement,
                        url = url
                    }
                )
            end
        end
    end
    return result
end

function applyEnhancementsToCard(card)
    -- fhlog(INFO,TAG, "Checking enhancements for %s", card.getName())
    local cardInfo = CardEnhancements[card.getName()]
    local stickers = getEnhancementDecals(cardInfo)
    if #stickers > 0 then
        fhlog(DEBUG, TAG, "Applying enhancements on %s", card.getName())
    end
    card.setDecals(stickers)
end

function isDevMode()
    return self.getDescription() == "dev"
end

function onObjectCollisionExit(params)
    local hitObject = params[2].collision_object
    if hitObject == CurrentCard then
        setCurrentCard(nil)
    end
end

function round(number)
    return tonumber(string.format("%.3f", number))
end

function onPing(payload)
    if not isDevMode() then
        return
    end
    local position = JSON.decode(payload)
    if CurrentCard ~= nil then
        local name = CurrentCard.getName()
        local cardPosition = CurrentCard.positionToLocal(position)
        local logLevel = isDevMode() and DEBUG or INFO
        fhlog(logLevel, TAG, "Pinged position %s", cardPosition)
        local spots = CardEnhancements[name].spots
        local removed = false
        for i = #spots, 1, -1 do
            if distance(spots[i].position, cardPosition) < FUZZY_MATCH_DISTANCE then
                fhlog(logLevel, TAG, "Removing position")
                table.remove(spots, i)
                removed = true
            end
        end
        if not removed then
            fhlog(logLevel, TAG, "Adding position")
            table.insert(spots,
                { type = "", position = { x = round(cardPosition.x), z = round(cardPosition.z) } })
        end
        fhlog(logLevel, TAG, "Current card : %s, state : %s", name, CardEnhancements[name])
        refreshDecals()
    end
end

function distance(pos1, pos2)
    local dx = pos1.x - pos2.x
    local dz = pos1.z - pos2.z
    return math.sqrt(dx * dx + dz * dz)
end

function dump()
    print(JSON.encode(CardEnhancements))
end

function refreshDecals()
    self.clearButtons()

    if isDevMode() then
        -- Add a button on the tile to dump the contents
        local params = {
            function_owner = self,
            click_function = "dump",
            position       = { 0, 0.05, -1.52 },
            width          = 1000,
            height         = 150,
            font_size      = 50,
            color          = { 1, 1, 1, 0 },
            scale          = { 1, 1, 1 },
            font_color     = { 1, 1, 1, 0 },
        }
        self.createButton(params)
    end

    local boardDecals = {}
    if CurrentCard ~= nil then
        -- Buttons
        CurrentCard.clearButtons()
        local enhancerInfo = getEnhancerInfo()
        if isDevMode() or enhancerInfo.level > 0 then
            -- Show highlights on the various spots
            local cardDecals = getEnhancementDecals(CurrentCardInfo)
            local spots = CurrentCardInfo.spots or {}
            for i, spot in ipairs(spots) do
                local highlight = {
                    rotation = { 90, 0, 0 },
                    scale = { 0.2, 0.2, 0.2 },
                    position = { spot.position.x, Y_DECAL, spot.position.z },
                    name = "highlight " .. i,
                    url =
                    "http://cloud-3.steamusercontent.com/ugc/2036234357173350181/63029F7ADA4B615AD8B7462ACFBE5692CEFB3229/"
                }
                if spot.type == '' then
                    -- Error, type is not set
                    highlight.url =
                    "http://cloud-3.steamusercontent.com/ugc/2036234357173472307/796C4B05A774DF34D17AB4DA6D2F58E9B4D6728C/"
                end
                if spot == CurrentSpot then
                    highlight.url =
                    "http://cloud-3.steamusercontent.com/ugc/2036234357173350229/1DCD8E19A4D68F2CA5586EB61D2044A0A1A2889C/"
                end
                table.insert(cardDecals, highlight)

                local fName = "selectSpot_" .. i
                self.setVar(fName, function(p, c, alt) onSpotClicked(i, alt) end)
                local params = {
                    function_owner = self,
                    click_function = fName,
                    position       = { -spot.position.x, 0.05, spot.position.z },
                    width          = 100,
                    height         = 100,
                    font_size      = 50,
                    color          = { 1, 1, 1, 0 },
                    scale          = { 1, 1, 1 },
                    font_color     = { 1, 1, 1, 0 },
                }
                CurrentCard.createButton(params)
            end
            CurrentCard.setDecals(cardDecals)

            if isDevMode() then
                -- Add controls for the card level
                addLevelDecals(boardDecals)
            end

            if CurrentSpot ~= nil then
                if isDevMode() then
                    -- Show all the type stickers
                    local currentZ = -0.8
                    local currentX = -0.3
                    for name, value in pairs(TYPES) do
                        local onOff = "off"
                        if CurrentSpot[value['field']] == name then
                            onOff = "on"
                        end
                        local position = { x = currentX, y = Y_DECAL, z = currentZ }
                        local params = {
                            rotation = { 90, 180, 0 },
                            scale = { .22, 0.2, 0.2 },
                            position = position,
                            name = "type " .. name .. onOff,
                            url = value[onOff]
                        }
                        table.insert(boardDecals, params)
                        currentZ = currentZ + 0.3
                        if currentZ >= 1.6 then
                            currentZ = -0.8
                            currentX = currentX - 0.5
                        end

                        local fName = "toggleType_" .. name
                        self.setVar(fName, function() onTypeClicked(name) end)
                        local params = {
                            function_owner = self,
                            click_function = fName,
                            position       = { -position.x, position.y, position.z },
                            width          = 150,
                            height         = 150,
                            font_size      = 50,
                            color          = { 1, 1, 1, 0 },
                            scale          = { 1, 1, 1 },
                            font_color     = { 1, 1, 1, 0 },
                        }
                        self.createButton(params)
                        if name == "h" and onOff == "on" then
                            -- Create arrows to change the base number of hexes
                            createHexControls(boardDecals, position)
                        end
                    end
                else
                    -- Determine which enhancements to show
                    local type = CurrentSpot.type
                    local action = CurrentSpot.ability or ""
                    local summon = CurrentSpot.summon or ""
                    local multi = CurrentSpot.multi or ""
                    local lost = CurrentSpot.lost or ""
                    local persist = CurrentSpot.persist or ""
                    local level = CurrentCardInfo.level or 1
                    local currentTopEnhancements, currentTopHexEnhancements, currentBottomEnhancements, currentBottomHexEnhancements =
                    countEnhancements(CurrentCardInfo)
                    local currentZ = -0.7
                    local currentX = -0.3
                    for _, t in ipairs(TypesPerType[type]) do
                        for name, info in pairs(Enhancements[t]) do
                            if (info.action == nil or info.action == action)
                                and (info.summon == nil or info.summon == summon)
                                and (CurrentSpot.enhancement == nil or CurrentSpot.enhancement == name)
                                and (name ~= "p1" or action ~= "") then
                                local position = { x = currentX, y = 0.06, z = currentZ }
                                local params = {
                                    rotation = { 90, 180, 0 },
                                    scale = { .7, 0.2, 0.2 },
                                    position = position,
                                    name = "enhancement " .. name,
                                    url = info.url
                                }
                                table.insert(boardDecals, params)
                                currentZ = currentZ + 0.3
                                if currentZ >= 1.6 then
                                    currentZ = -0.7
                                    currentX = currentX - 0.8
                                end
                                if CurrentSpot.enhancement == name then
                                    -- this spot already has an enhancement, show a remove button
                                    local params = {
                                        label          = "Remove",
                                        function_owner = self,
                                        click_function = "onEnhancementRemove",
                                        position       = { -position.x + 0.07, position.y, position.z },
                                        width          = 600,
                                        height         = 220,
                                        font_size      = 100,
                                        color          = { 1, 1, 1, 0 },
                                        scale          = { .5, .5, .5 },
                                        font_color     = { 0, 0, 0, 100 },
                                        tooltip        = "Remove enhancement"
                                    }
                                    self.createButton(params)
                                else
                                    local ability = summon .. action
                                    local cost = info.cost or info.costByAbility[ability] or 0
                                    if type == 'h' then
                                        if CurrentSpot.position[2] > 0 then
                                            cost = math.ceil(cost /
                                            (currentTopHexEnhancements + (CurrentSpot.baseHexes or 1)))
                                        else
                                            cost = math.ceil(cost /
                                            (currentBottomHexEnhancements + (CurrentSpot.baseHexes or 1)))
                                        end
                                    end
                                    if multi == "multi" and t ~= "c" then
                                        cost = cost * 2
                                    end
                                    if lost == "lost" then
                                        cost = cost / 2
                                    end
                                    if persist == "persist" then
                                        cost = cost * 3
                                    end

                                    -- the level cost changes based on enhancer level ...
                                    local levelCost = 25
                                    if enhancerInfo.level >= 3 then
                                        levelCost = 15
                                    end

                                    cost = cost + (level - 1) * levelCost

                                    -- The previous enhancement penalty changes with enhancer level
                                    local previousCost = 75
                                    if enhancerInfo.level >= 4 then
                                        previousCost = 50
                                    end
                                    if CurrentSpot.position.z > 0 then
                                        cost = cost + currentTopEnhancements * previousCost
                                    else
                                        cost = cost + currentBottomEnhancements * previousCost
                                    end

                                    -- enhancer discout
                                    if enhancerInfo.level >= 2 then
                                        cost = cost - 10
                                    end

                                    -- Purchase button with cost shown
                                    local fName = "buy_" .. name
                                    self.setVar(fName, function(player) onEnhancementBuy(player, name, cost) end)
                                    local params = {
                                        label          = cost .. " gold",
                                        function_owner = self,
                                        click_function = fName,
                                        position       = { -position.x + 0.07, position.y, position.z },
                                        width          = 600,
                                        height         = 220,
                                        font_size      = 100,
                                        color          = { 1, 1, 1, 0 },
                                        scale          = { .5, .5, .5 },
                                        font_color     = { 0, 0, 0, 100 },
                                        tooltip        = "Purchase enhancement"
                                    }
                                    self.createButton(params)
                                end
                            end
                        end
                    end
                end
            else
                if #spots > 0 then
                    -- Select a spot
                    table.insert(boardDecals, getInfoSticker("mark", SELECT_MARK_URL))
                else
                    --No available spot
                    table.insert(boardDecals, getInfoSticker("no_enhancement", NO_AVAIL_URL))
                end
            end
        else
            --No enhancer
            table.insert(boardDecals, getInfoSticker("no_enhancer", NO_ENHANCER_URL))
        end
    else
        -- Drop a card
        table.insert(boardDecals, getInfoSticker("card", DROP_CARD_URL))
    end
    self.setDecals(boardDecals)
end

function getInfoSticker(name, url)
    return {
        rotation = { 90, 180, 0 },
        scale = { 2.0, 0.8, 0.8 },
        position = { -0.85, 0.06, 0.2 },
        name = "info_" .. name,
        url = url
    }
end

function createHexControls(stickers, position)
    local baseHexes = CurrentSpot.baseHexes or 1
    if baseHexes > 1 then
        -- left arrow sticker and button
        local sticker = {
            position = { position.x + 0.2, position.y, position.z },
            scale = { .07, .05, .05 },
            rotation = { 90, 180, 0 },
            url = "http://cloud-3.steamusercontent.com/ugc/2035105157823185573/8BABEE86FE1085D5C001E6DD4EE1F1E040BF6D1D/",
            name = "hexes down",
        }
        table.insert(stickers, sticker)
        local params = {
            function_owner = self,
            click_function = "hexesDown",
            label          = "",
            position       = { -position.x - 0.2, position.y, position.z },
            width          = 200,
            height         = 220,
            font_size      = 100,
            color          = { 1, 1, 1, 0 },
            scale          = { 0.5, 1, .25 },
            font_color     = { 0, 0, 0, 100 },
        }
        self.createButton(params)
    end

    -- A button with no size to show the info
    local params = {
        label          = tostring(baseHexes),
        function_owner = self,
        click_function = "hexesUp",
        position       = { -position.x, position.y + 0.01, position.z },
        width          = 0,
        height         = 0,
        font_size      = 100,
        color          = { 1, 1, 1, 1 },
        scale          = { 0.5, 0.5, 0.5 },
        font_color     = { 0, 0, 0, 1 },
    }
    self.createButton(params)

    if baseHexes < 20 then
        -- right arrow sticker and button
        local sticker = {
            position = { position.x - 0.2, position.y, position.z },
            scale = { .07, .05, .05 },
            rotation = { 90, 180, 0 },
            url = "http://cloud-3.steamusercontent.com/ugc/2035105157823185619/529E35C0294D03A666C9EA9C924105F40F07697F/",
            name = "hexes up",
        }
        table.insert(stickers, sticker)
        local params = {
            function_owner = self,
            click_function = "hexesUp",
            label          = "",
            position       = { -position.x + 0.2, position.y, position.z },
            width          = 200,
            height         = 220,
            font_size      = 100,
            color          = { 1, 1, 1, 0 },
            scale          = { 0.5, 1, .25 },
            font_color     = { 0, 0, 0, 100 },
        }
        self.createButton(params)
    end
end

function addLevelDecals(stickers)
    -- stickers
    local yPosition = 1.685
    local level = CurrentCardInfo.level or 1
    local sticker = {
        position = { 0.95, 0.06, yPosition },
        scale = { .5, .5, .25 },
        rotation = { 90, 180, 0 },
        url = NumberDecals[level + 1],
        name = "level_" .. level,
    }
    table.insert(stickers, sticker)

    if level > 1 then
        -- left arrow sticker and button
        sticker = {
            position = { 1.25, 0.06, yPosition },
            scale = { .15, .05, .05 },
            rotation = { 90, 180, 0 },
            url = "http://cloud-3.steamusercontent.com/ugc/2035105157823185573/8BABEE86FE1085D5C001E6DD4EE1F1E040BF6D1D/",
            name = "level down",
        }
        table.insert(stickers, sticker)
        local params = {
            function_owner = self,
            click_function = "levelDown",
            label          = "",
            position       = { -1.25, 0.06, yPosition },
            width          = 200,
            height         = 220,
            font_size      = 100,
            color          = { 1, 1, 1, 0 },
            scale          = { 0.5, 1, .25 },
            font_color     = { 0, 0, 0, 100 },
        }
        self.createButton(params)
    end

    if level < 9 then
        -- right arrow sticker and button
        sticker = {
            position = { .65, 0.06, yPosition },
            scale = { .15, .05, .05 },
            rotation = { 90, 180, 0 },
            url = "http://cloud-3.steamusercontent.com/ugc/2035105157823185619/529E35C0294D03A666C9EA9C924105F40F07697F/",
            name = "level up",
        }
        table.insert(stickers, sticker)
        local params = {
            function_owner = self,
            click_function = "levelUp",
            label          = "",
            position       = { -0.65, 0.06, yPosition },
            width          = 200,
            height         = 220,
            font_size      = 100,
            color          = { 1, 1, 1, 0 },
            scale          = { 0.5, 1, .25 },
            font_color     = { 0, 0, 0, 100 },
        }
        self.createButton(params)
    end
end

function levelDown()
    if CurrentCardInfo ~= nil then
        CurrentCardInfo.level = CurrentCardInfo.level - 1
        refreshDecals()
    end
end

function levelUp()
    if CurrentCardInfo ~= nil then
        CurrentCardInfo.level = CurrentCardInfo.level + 1
        refreshDecals()
    end
end

function hexesDown()
    if CurrentSpot ~= nil then
        local baseHexes = CurrentSpot.baseHexes or 1
        CurrentSpot.baseHexes = baseHexes - 1
        refreshDecals()
    end
end

function hexesUp()
    if CurrentSpot ~= nil then
        local baseHexes = CurrentSpot.baseHexes or 1
        CurrentSpot.baseHexes = baseHexes + 1
        refreshDecals()
    end
end

function onSpotClicked(n, alt)
    if alt and isDevMode() then
        table.remove(CurrentCardInfo.spots, n)
    end
    if CurrentCard ~= nil then
        local newSpot = CurrentCardInfo.spots[n]
        if CurrentSpot == newSpot then
            CurrentSpot = nil
        else
            CurrentSpot = newSpot
        end
    end
    refreshDecals()
end

function onTypeClicked(name)
    if CurrentCard ~= nil then
        local type = TYPES[name]
        local field = type['field']
        local currentValue = CurrentSpot[field]
        if currentValue == name then
            CurrentSpot[field] = ''
        else
            CurrentSpot[field] = name
        end
        refreshDecals()
    end
end

function onEnhancementBuy(player, name, price)
    if CurrentSpot ~= nil then
        CurrentSpot.enhancement = name
        refreshDecals()
        -- Update the enhancements
        local enhancements = ActiveEnhancements[CurrentCard.getName()]
        if enhancements == nil then
            enhancements = {}
            ActiveEnhancements[CurrentCard.getName()] = enhancements
        end
        table.insert(enhancements, { name = name, position = CurrentSpot.position })
    end
end

function onEnhancementRemove(player, name)
    if CurrentSpot ~= nil then
        CurrentSpot.enhancement = nil
        refreshDecals()
        -- Update the enhancements
        local enhancements = ActiveEnhancements[CurrentCard.getName()]
        if enhancements ~= nil then
            for i = #enhancements, 1, -1 do
                if distance(CurrentSpot.position, enhancements[i].position) < FUZZY_MATCH_DISTANCE then
                    table.remove(enhancements, i)
                end
            end
        end
    end
end

function countEnhancements(card)
    local topCount = 0
    local topHexCount = 0
    local bottomCount = 0
    local bottomHexCount = 0
    for _, spot in ipairs(card.spots) do
        if spot.enhancement ~= nil then
            if spot.position.z > 0 then
                topCount = topCount + 1
                if spot.enhancement == 'hex' then
                    topHexCount = topHexCount + 1
                end
            else
                bottomCount = bottomCount + 1
                if spot.enhancement == 'hex' then
                    bottomHexCount = bottomHexCount + 1
                end
            end
        end
    end
    return topCount, topHexCount, bottomCount, bottomHexCount
end

function getEnhancerInfo()
    local outpost = getObjectFromGUID('756956')
    if outpost ~= nil then
        local info = JSON.decode(outpost.call('getBuildingInfo', "44"))
        return info
    end
    return { level = 0, wrecked = false }
end
