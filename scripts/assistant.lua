require('json')
require('cards')
require('fhlog')
require('am_draw')
require('constants')
require("savable")
require("deck_save_helpers")
require('utils')
require('data/monsterStats')
require('data/monsterAbilities')
require('data/characterInitiatives')

TAG = "BattleInterface"

function getState()
    local decals = {}
    -- Save stickers on the loot cards
    for _, deckPosition in ipairs({ Loot.ActiveDeck, Loot.DrawDeck, Loot.DiscardDeck }) do
        getDecalsFromDeck(deckPosition, decals)
    end
    return { decals = decals, buttonState = ButtonState }
end

function onStateUpdate(state)
    -- Attack Modifier decks
    for _, type in ipairs({ "Monster", "Ally" }) do
        local deck, guids = getRestoreDeck(type .. " Attack Modifiers")
        deleteCardsAt(AttackModifiers[type].DiscardDeck)
        deleteCardsAt(AttackModifiers[type].DrawDeck)
        setAtLocalPosition(deck, AttackModifiers[type].DrawDeck, true)
    end

    --Loot deck
    local deck, guids = getRestoreDeck("Loot Deck")
    deleteCardsAt(Loot.DiscardDeck)
    deleteCardsAt(Loot.DrawDeck)
    deleteCardsAt(Loot.ActiveDeck)

    local decals = state.decals or {}
    reapplyDecalsAndMoveTo(deck, decals, Loot.ActiveDeck, { flip = true, atBottom = true })

    ButtonState = state.buttonState or {}
    updateInternal()
end

function onLoad(save)
    self.setLock(true)
    fhLogInit()

    self.interactable = false
    if save ~= nil then
        local savedState = JSON.decode(save)
        ButtonState = savedState.buttonState
    end

    if ButtonState == nil then
        ButtonState = {}
    end

    locateBoardElementsFromTags()
    createBoardElementsControls()

    Global.call('registerDataUpdatable', self)
    self.setDecals({})
    registerSavable("BattleMat")
end

function onSave()
    return JSON.encode({ buttonState = ButtonState })
end

function locateBoardElementsFromTags()
    AttackModifiers = {
        Ally = {},
        Monster = {}
    }

    Loot = {
        Checkboxes = {}
    }

    for _, point in ipairs(self.getSnapPoints()) do
        local tags = {}
        for _, tag in ipairs(point.tags) do
            tags[tag] = true
        end

        local position = point.position

        if tags['attack modifier'] or false then
            if tags['deck'] or false then
                if tags['draw'] or false then
                    if tags['monster'] or false then
                        AttackModifiers.Monster.DrawDeck = position
                    elseif tags['ally'] or false then
                        AttackModifiers.Ally.DrawDeck = position
                    end
                elseif tags['discard'] or false then
                    if tags['monster'] or false then
                        AttackModifiers.Monster.DiscardDeck = position
                    elseif tags['ally'] or false then
                        AttackModifiers.Ally.DiscardDeck = position
                    end
                end
            elseif tags['button'] or false then
                if tags['draw'] or false then
                    if tags['monster'] or false then
                        AttackModifiers.Monster.DrawButton = position
                    elseif tags['ally'] or false then
                        AttackModifiers.Ally.DrawButton = position
                    end
                elseif tags['shuffle'] or false then
                    if tags['monster'] or false then
                        AttackModifiers.Monster.ShuffleButton = position
                    elseif tags['ally'] or false then
                        AttackModifiers.Ally.ShuffleButton = position
                    end
                end
            end
        elseif tags['loot'] or false then
            if tags['deck'] or false then
                if tags['draw'] or false then
                    Loot.DrawDeck = position
                elseif tags['discard'] or false then
                    Loot.DiscardDeck = position
                elseif tags['active'] or false then
                    Loot.ActiveDeck = position
                end
            elseif tags['button'] or false then
                if tags['draw'] or false then
                    Loot.DrawButton = position
                end
            elseif tags['checkbox'] or false then
                table.insert(Loot.Checkboxes, position)
            end
        elseif tags['button'] or false then
            if tags['bless'] or false then
                if tags['monster'] or false then
                    AttackModifiers.Monster.BlessButton = position
                elseif tags['ally'] or false then
                    AttackModifiers.Ally.BlessButton = position
                end
            elseif tags['monster curse'] or false then
                AttackModifiers.Monster.CurseButton = position
            elseif tags['player curse'] or false then
                AttackModifiers.Ally.CurseButton = position
            end
        end
    end

    -- Sort the two checkboxes to know which is which
    -- 1418 on top, 1419 below
    table.sort(Loot.Checkboxes, function(a, b) return a.z < b.z end)

    fhlog(INFO, TAG, "Element positions : AttackModifiers:%s, Loot:%s", AttackModifiers, Loot)
end

function maximize()
    self.setPositionSmooth({ 0, 5.48, -17.33 }, false, false)
    self.setRotationSmooth({ 66, 0, 0 })
    UIState.minimized = false
    updateInternal()
end

function minimize()
    self.setPositionSmooth({ 0, -2, -14 }, false, false)
    self.setRotationSmooth({ 66, 0, 0 })
    UIState.minimized = true
    updateInternal()
end

function XZSorter(a, b)
    return 30 * (a.z - b.z) - a.x + b.x < 0
end

function updateData(params)
    local baseUrl = params.baseUrl
    local first = params.first
    if baseUrl ~= "https://gudyfr.github.io/fhtts/" or not first then
        WebRequest.get(baseUrl .. "characterInitiatives.json", updateCharacterInitiatives)
        WebRequest.get(baseUrl .. "monsterStats.json", updateMonsterStats)
        WebRequest.get(baseUrl .. "monsterAbilities.json", updateMonsterAbilities)
    end
end

function updateCharacterInitiatives(request)
    CharacterInitiatives = jsonDecode(request.text)
    updateInternal()
end

function updateMonsterStats(request)
    MonsterStats = jsonDecode(request.text)
    updateInternal()
end

function updateMonsterAbilities(request)
    MonsterAbilities = jsonDecode(request.text)
    updateInternal()
end

function updateState(state)
    State = state
    updateInternal()
end

AlreadyShownNotes = {}
DismissedNotes = {}
function updateInternal()
    self.clearButtons()
    -- Let's show one note at this time
    if State ~= nil then
        if State.notes ~= nil then
            for _, note in ipairs(State.notes) do
                if AlreadyShownNotes[note.id] ~= note.round then
                    AlreadyShownNotes[note.id] = note.round
                    broadcastToAll(note.text)
                end
            end
        end
    end
    if State ~= nil and CharacterInitiatives ~= nil and MonsterStats ~= nil and MonsterAbilities ~= nil then
        local decals = {}
        local currentX = 0
        local currentZ = -3
        local lastActive = 0
        local height = 0
        for i, entry in ipairs(State.entries) do
            if entry.active or false then
                lastActive = i
            end
            if not (entry.noUi or false) then
                if entry.type == "monster" then
                    height = height + 0.55
                else
                    height = height + 0.20
                end
            end
        end
        currentZ = -0.5 - height / 2
        for i, entry in ipairs(State.entries) do
            local name = entry.name
            local type = entry.type
            local turnState = entry.turnState
            local npc = entry.npc or false
            local itemHeight = 0

            if not (entry.noUi or false) then
                local itemZ = 0
                if type == "monster" then
                    itemHeight = .55
                    currentZ = currentZ + itemHeight / 2
                    itemZ = currentZ

                    -- Render the monster image
                    local grey = ""
                    if turnState == 2 or not entry.active then
                        grey = ".grey"
                    end
                    local decalName = name .. grey
                    local url = MonsterStats[decalName]
                    if url ~= nil then
                        table.insert(decals, getDecal(decalName, url, currentX, currentZ, .44, .5))
                    end

                    -- Render the monster stats
                    local level = entry.level
                    local decalName = name .. "_" .. level
                    local url = MonsterStats[decalName]
                    if url ~= nil then
                        table.insert(decals, getDecal(decalName, url, currentX - 0.55, currentZ, .887, .55))
                    end

                    -- Render the ability card
                    local cardNumber = entry.card or 0
                    if cardNumber > 0 then
                        local decalName = name .. "_" .. level .. "_" .. cardNumber
                        local url = MonsterAbilities[decalName]
                        if url ~= nil then
                            table.insert(decals, getDecal(decalName, url, currentX + 0.55, currentZ, .887, .55))
                        end
                    else
                        local url =
                        "http://cloud-3.steamusercontent.com/ugc/2036234357198483076/21FC5F0477C27012058B3AC2BFD381ED5C07C04C/"
                        table.insert(decals, getDecal("back", url, currentX + 0.55, currentZ, .887, .55))
                    end
                    currentZ = currentZ + itemHeight / 2
                elseif type == "character" then
                    itemHeight = 0.25
                    currentZ = currentZ + itemHeight / 2
                    itemZ = currentZ

                    -- Render the character initiative token
                    local grey = ""
                    if turnState == 2 then
                        grey = ".grey"
                    end
                    local decalName = name .. grey
                    local url = CharacterInitiatives[decalName]
                    if url ~= nil then
                        table.insert(decals, getDecal(decalName, url, currentX, currentZ, .7, .25))
                    else
                        -- We dont' have an image to show, but we can show the entry's name
                        self.createButton(getLabel((name or entry.id or ""),
                            currentX, currentZ))
                    end

                    -- Render controls to override a player turn order, if the round has started
                    if State.round.state == 1 then
                        if not npc then
                            if i ~= 1 then
                                -- Add a button to lower the player initiative
                                local url =
                                "http://cloud-3.steamusercontent.com/ugc/2035105157823185573/8BABEE86FE1085D5C001E6DD4EE1F1E040BF6D1D/"
                                table.insert(decals, getDecal(name .. "_faster", url, currentX + 0.55, currentZ, .1, .05))

                                local fName = "changeInitiative_down_" .. name
                                self.setVar(fName, function() changeInitiative(name, -1) end)
                                self.createButton(getButton(fName, currentX + 0.55, currentZ, 700, 250))
                            end
                            if i ~= lastActive then
                                -- Add a button to increase the player intitiative
                                local url =
                                "http://cloud-3.steamusercontent.com/ugc/2035105157823185619/529E35C0294D03A666C9EA9C924105F40F07697F/"
                                table.insert(decals, getDecal(name .. "_slower", url, currentX - 0.55, currentZ, .1, .05))

                                local fName = "changeInitiative_up_" .. name
                                self.setVar(fName, function() changeInitiative(name, 1) end)
                                self.createButton(getButton(fName, currentX - 0.55, currentZ, 700, 250))
                            end
                        end
                        -- Also render the player initiative
                        self.createButton(getLabel((entry.initiative or ""), currentX + 0.8, currentZ))
                    end
                    currentZ = currentZ + itemHeight / 2
                end

                if turnState == 1 then
                    local url =
                    "http://cloud-3.steamusercontent.com/ugc/2036234357198527450/F51CB2841C00E8ACF74FA5E00D59A018B6FA93F2/"
                    table.insert(decals, getDecal("current", url, currentX, itemZ + itemHeight / 2 + 0.001, 2.3, .05))
                end

                -- Add a button to change the turn state, if the round has started
                if State.round.state == 1 then
                    local fName = "setCurrent_" .. i
                    self.setVar(fName, function() setCurrent(name) end)
                    self.createButton(getButton(fName, currentX, itemZ, 700, 1000 * itemHeight))
                end
            end
        end

        -- Handle notes
        if State.notes ~= nil then
            currentZ = 2
            for _, note in ipairs(State.notes) do
                local noteId = note.id
                local noteRound = note.round
                if DismissedNotes[noteId] ~= noteRound then
                    local fName = "dimissNote_" .. noteId
                    self.setVar(fName, function() dismissNote(noteId, noteRound) end)
                    self.createButton(getDismissableLabel(fName, note.text, currentX, currentZ))
                    currentZ = currentZ - 0.20
                end
            end
        end

        self.setDecals(decals)
    end
    createBoardElementsControls()
end

function dismissNote(noteId, noteRound)
    DismissedNotes[noteId] = noteRound
    updateInternal()
end

function getDecal(name, url, x, z, w, h)
    return {
        name = name,
        position = { x, 0.06, z },
        rotation = { 90, 180, 0 },
        url = url,
        scale = { w * .8, h * .8, h * .8 }
    }
end

function getButton(fName, x, z, w, h, visible)
    visible = visible or false
    return {
        label          = "",
        function_owner = self,
        click_function = fName,
        position       = { -x, 0.06, z },
        width          = w,
        height         = h,
        font_size      = h * 8 / 10,
        color          = { 1, 1, 1, visible and 1 or 0 },
        scale          = { 0.25, 0.25, 0.25 },
        font_color     = { 0, 0, 0, visible and 1 or 100 },
        tooltip        = ""
    }
end

function getCheckbox(stateName, x, z, w, h, visible)
    local fName = 'toggle_' .. stateName
    self.setVar(fName, function() toggleButtonState(stateName) end)
    local params = getButton(fName, x, z, w, h, visible)
    if ButtonState[stateName] or false then
        params.label = '\u{2717}'
    end
    return params
end

function nop()
end

function getDismissableLabel(fName, name, x, z)
    local params = getButton(fName, x, z, 3000, 400, false)
    params.font_color = { 1, 1, 1, 100 }
    params.label = name:gsub("%. ", ".\n")
    params.font_size = 150
    params.tooltip = "Click to dismiss"
    return params
end

function getLabel(name, x, z)
    local params = getButton("nop", x, z, 0, 0, true)
    params.font_color = { 1, 1, 1, 1 }
    params.label = name
    params.font_size = 200
    return params
end

function toggleButtonState(name)
    ButtonState[name] = not (ButtonState[name] or false)
    updateInternal()
end

function addButton(position, callback, tooltip)
    local params = {
        label          = "",
        function_owner = self,
        click_function = callback,
        position       = { -position.x, position.y + 0.01, position.z },
        width          = 100,
        height         = 100,
        font_size      = 40,
        color          = { 1, 1, 1, 0 },
        scale          = { 0.5, 0.5, 0.5 },
        font_color     = { 0, 0, 0, 1 },
        tooltip        = tooltip
    }
    self.createButton(params)
end

function createBoardElementsControls()
    for _, category in ipairs({ 'Ally', 'Monster' }) do
        -- Curse & Bless Buttons
        for i, type in ipairs({ 'Bless', 'Curse', 'Draw', 'Shuffle' }) do
            local position = AttackModifiers[category][type .. 'Button']
            if position ~= nil then
                local width = i <= 2 and 100 or 400
                local height = i <= 2 and 100 or 50
                self.createButton(getButton('on' .. category .. type, position.x, position.z, width, height))
            end
        end
    end
    -- Loot button
    local position = Loot.DrawButton
    self.createButton(getButton('onLootDrawInternal', position.x, position.z, 400, 50))
    -- Loot checkmarks
    for i, position in ipairs(Loot.Checkboxes) do
        self.createButton(getCheckbox('lootCard' .. i, position.x, position.z, 150, 150))
    end
end

function setCurrent(name)
    local scenarioMat = getObjectFromGUID('4aa570')
    if scenarioMat ~= nil then
        scenarioMat.call("setCurrentTurn", name)
    end
end

function changeInitiative(name, direction)
    local scenarioMat = getObjectFromGUID('4aa570')
    if scenarioMat ~= nil then
        scenarioMat.call("changeInitiative", { name = name, direction = direction })
    end
end

function onMonsterDraw(external)
    if external ~= true then
        external = false
    end
    draw({ type = "monster" }, AttackModifiers.Monster.DrawDeck, AttackModifiers.Monster.DiscardDeck, not external)
end

function onMonsterShuffle()
    shuffle(AttackModifiers.Monster.DrawDeck, AttackModifiers.Monster.DiscardDeck)
end

function onAllyDraw(external)
    if external ~= true then
        external = false
    end
    draw({ type = "ally" }, AttackModifiers.Ally.DrawDeck, AttackModifiers.Ally.DiscardDeck, not external)
end

function onAllyShuffle()
    shuffle(AttackModifiers.Ally.DrawDeck, AttackModifiers.Ally.DiscardDeck)
end

function onAllyCurse()
    moveCardFromTo('Player Curses', AttackModifiers.Ally.DrawDeck)
end

function onAllyBless()
    moveCardFromTo('Blesses', AttackModifiers.Ally.DrawDeck)
end

function onMonsterCurse()
    moveCardFromTo('Monster Curses', AttackModifiers.Monster.DrawDeck)
end

function onMonsterBless()
    moveCardFromTo('Blesses', AttackModifiers.Monster.DrawDeck)
end

function moveCardFromTo(deckName, destination)
    local scenarioMat = getObjectFromGUID(ScenarioMatGuid)
    if scenarioMat ~= nil then
        local deckPosition = scenarioMat.call('getDeckPosition', { name = deckName })
        local deck = getDeckOrCardAtWorldPosition(deckPosition)
        local card = takeCardFrom(deck)
        if card ~= nil then
            card.setRotation({ x = 0, y = 0, z = 180 })
            addCardToDeckAt(card, destination, { shuffle = true })
        end
    end
end

function onEndTurn()
    endTurnCleanup(AttackModifiers.Ally.DrawDeck, AttackModifiers.Ally.DiscardDeck)
    endTurnCleanup(AttackModifiers.Monster.DrawDeck, AttackModifiers.Monster.DiscardDeck)
end

function cleanup()
    cleanupAttackModifiers(AttackModifiers.Ally.DrawDeck, AttackModifiers.Ally.DiscardDeck)
    cleanupAttackModifiers(AttackModifiers.Monster.DrawDeck, AttackModifiers.Monster.DiscardDeck)
    cleanLootDeck()
    AlreadyShownNotes = {}
    DismissedNotes = {}
end

function onLootDrawInternal(obj, player, alt)
    onLootDraw({ color = player })
end

function onLootDraw(params)
    local color = params.color
    local deck = getDeckOrCardAt(Loot.DrawDeck)
    local card = takeCardFrom(deck)
    if card ~= nil then
        local name = card.getName()
        card.flip()
        addCardToDeckAt(card, Loot.DiscardDeck, { smooth = true, noPut = true })
        local scenarioMat = getObjectFromGUID(ScenarioMatGuid)
        local enhancements = 0
        for _, decal in ipairs(card.getDecals() or {}) do
            if decal.name == "+1" then
                enhancements = enhancements + 1
            end
        end
        scenarioMat.call('onLootDrawn', { color = color, card = name, enhancements = enhancements })
    end
end

function cleanLootDeck()
    forEachInDeckOrCard(getDeckOrCardAt(Loot.DiscardDeck), function(card) addCardToDeckAt(card, Loot.ActiveDeck) end)
    forEachInDeckOrCard(getDeckOrCardAt(Loot.DrawDeck), function(card) addCardToDeckAt(card, Loot.ActiveDeck) end)
end

function setLootDeck(cards)
    -- Cleanup first
    cleanup()

    -- Setup loot deck
    if ButtonState['lootCard1'] == true then
        table.insert(cards, '1418')
    end
    if ButtonState['lootCard2'] == true then
        table.insert(cards, '1419')
    end
    
    local sourceDeck = getDeckOrCardAt(Loot.ActiveDeck)
    for _, card in ipairs(cards) do
        forEachInDeckOrCardIf(sourceDeck, function(card) addCardToDeckAt(card, Loot.DrawDeck) end,
            function(e) return e.name == card end)
    end
    local lootDeck = getDeckOrCardAt(Loot.DrawDeck)
    if lootDeck ~= nil then
        lootDeck.shuffle()
    end
end
