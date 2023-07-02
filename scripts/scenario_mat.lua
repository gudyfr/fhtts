require("json")
require("number_decals")
require("savable")
require("deck_save_helpers")
require("utils")
require('fhlog')
require('standees')
require('constants')
require('game_state')
require('cards')
require('data/gameData')

TAG = "ScenarioMat"
CURRENT_ASSISTANT_VERSION = 6
TAG_5_PLAYERS = "5 players"

function getState()
    local results = {}
    -- Challenge Cards
    local challenges = {}
    for name, position in pairs(ChallengesDestinations) do
        challenges[name] = getCardList(position)
    end
    challenges["Draw"] = getCardList(DrawDecks["Challenges"])
    results.challenges = challenges
    return results
end

function onStateUpdate(state)
    -- Challenge Cards
    local challenges = state.challenges or {}
    local hasChallenges = false
    for _, cards in pairs(challenges) do
        if #cards > 0 then
            hasChallenges = true
        end
    end
    if hasChallenges then
        local deck, guids = getRestoreDeck("Challenges")
        if deck ~= nil then
            for name, position in pairs(ChallengesDestinations) do
                deck = rebuildDeck(deck, guids, challenges[name], position, false)
            end
        end
        deck = rebuildDeck(deck, guids, challenges["Draw"], DrawDecks["Challenges"], true)
        -- All cards should have been used, so keep on the scenario mat the unused ones
        -- destroyObject(deck)
    else
        -- We don't need to bring the deck out, but we should clear the cards if they are on the board
        for name, position in pairs(ChallengesDestinations) do
            deleteCardsAt(position)
        end
        deleteCardsAt(DrawDecks["Challenges"])
    end

    -- Minus Ones, Blesses and Curses decks
    for name, position in pairs(deckPositions) do
        -- print(name .. " : " .. JSON.encode(position))
        local deck, guids = getRestoreDeck(name)
        if deck ~= nil then
            deleteCardsAt(position)
            setAtLocalPosition(deck, position)
        end
    end

    -- Battle Goals
    local deck, guids = getRestoreDeck("Battle Goals")
    if deck ~= nil then
        deleteCardsAt(DrawDecks["Battle Goals"])
        setAtLocalPosition(deck, DrawDecks["Battle Goals"], true)
    end

    CurrentGameState:resetAllState()
    updateCurrentState(true)
end

-- scenario mat
hidden_buttons = 1
relativeStateButtonLocations = {
    persist = { 0.5, 0.01, -1.7 },
    lost = { 0.9, 0.01, -1.7 },
    fast = { -0.4, 0.01, -1.7 },
    slow = { -0.4, 0.01, -1.7 }
}

colors = { "Green", "Red", "White", "Blue", "Yellow" }

stateValues = {
    none = 0,
    persist = 1,
    lost = 2
}

function onSave()
    return JSON.encode({
        trackedGuids = trackedGuids,
        cardStates = cardStates,
        elementStates = elementStates,
        characterStates = characterStates,
        initiativeTypes = initiativeTypes,
        characters = Characters,
        characterLevels = CharacterLevels,
        currentScenario = CurrentScenario,
        gameState = CurrentGameState:save()
    })
end

function onLoad(state)
    fhLogInit()
    self.interactable = false


    if state ~= nil then
        local json = JSON.decode(state)
        if json ~= nil then
            if json.trackedGuids ~= nil then
                trackedGuids = json.trackedGuids
            end
            if json.cardStates ~= nil then
                cardStates = json.cardStates
            end
            if json.elementStates ~= nil then
                elementStates = json.elementStates
            end
            if json.characterStates ~= nil then
                characterStates = json.characterStates
            end
            if json.characters ~= nil then
                Characters = json.characters
            end
            if json.characterLevels ~= nil then
                CharacterLevels = json.characterLevels
            end
            SavedGameState = json.gameState
            CurrentScenario = json.currentScenario or {}
            initiativeTypes = json.initiativeTypes or {}
        end
    end

    if trackedGuids == nil then
        trackedGuids = {}
    end
    if elementStates == nil then
        elementStates = { fire = 0, ice = 0, air = 0, earth = 0, light = 0, dark = 0 }
    end
    if characterStates == nil then
        characterStates = {}
    end
    if initiativeTypes == nil then
        initiativeTypes = {}
    end
    if Characters == nil then
        Characters = {}
    end
    if CharacterLevels == nil then
        CharacterLevels = {}
    end

    updateUpdateRunning()

    for _, guid in ipairs(trackedGuids) do
        local obj = getObjectFromGUID(guid)
        if obj ~= nil then
            obj.removeTag("lootable")
            onStandeeRegistered(obj)
        end
    end

    if cardStates == nil then
        cardStates = {
            Green = { 0, 0, 0 },
            Red = { 0, 0, 0 },
            White = { 0, 0, 0 },
            Blue = { 0, 0, 0 }
        }
    end

    if self.hasTag(TAG_5_PLAYERS) then
        cardStates["Yellow"] = { 0, 0, 0 }
    else
        cardStates["Yellow"] = nil
    end

    deckPositions = {}

    locateBoardElementsFromTags()

    -- toggle buttons for the various cards played
    for color, locations in pairs(cardLocations) do
        for i, location in pairs(locations) do
            for _, state in ipairs({ "persist", "lost" }) do
                -- local offset = relativeStateButtonLocations[offset]
                local fName = "toggleClick_" .. color .. "_" .. i .. "_" .. state
                local position = getStatePosition(color, i, state)
                position[1] = -position[1]
                button_parameters = getButtonParams(fName, "", position)
                self.setVar(fName, function() clickedToggle(color, i, state) end)
                self.createButton(button_parameters)
            end
        end
    end

    -- toggle buttons for the elements
    for element, position in pairs(elementsLocations) do
        local fName = "toggleElement_" .. element
        local buttonPosition = { -position.x, position.y + 0.02, position.z }
        local params = getButtonParams(fName, "Toggle " .. element, buttonPosition, 300, 300)
        self.setVar(fName, function(obj, color, alt) toggleElement(element, alt) end)
        self.createButton(params)
    end

    -- attack modifier draw buttons

    for color, position in pairs(AttackModifierButtons) do
        local fName = "drawAttackModifier_" .. color
        local buttonPosition = { -position.x, position.y + 0.02, position.z }
        local params = getButtonParams(fName, "Draw Attack Modifier\n(right click to shuffle)", buttonPosition, 600, 400)
        self.setVar(fName, function(obj, playerColor, alt) drawAttackModifier(color, alt) end)
        self.createButton(params)
    end

    -- Hp and Xp buttons
    local buttonsToCreate = { "increment", "decrement" }
    for color, categories in pairs(hpAndXpLocations) do
        for category, positions in pairs(categories) do
            for _, action in ipairs(buttonsToCreate) do
                local position = positions[action]
                if position ~= nil then
                    local fName = "onButton_" .. color .. "_" .. category .. "_" .. action
                    local buttonPosition = { -position.x, position.y + 0.02, position.z }
                    self.setVar(fName, function() onButtonClicked(color, category, action) end)
                    local params = getButtonParams(fName, action .. " " .. category, buttonPosition, 150, 150)
                    self.createButton(params)
                end
            end
        end
    end

    -- round actions
    button_parameters = getButtonParams("onStart", "Start Round", flipX(ScenarioButtons["start"]), 1150, 400)
    self.createButton(button_parameters)

    button_parameters = getButtonParams("onEnd", "End Round", flipX(ScenarioButtons["end"]), 1150, 400)
    self.createButton(button_parameters)

    button_parameters = getButtonParams("onCleanup", "Right click to cleanup",
        flipX(ScenarioButtons["cleanup"]), 1100, 400)
    self.createButton(button_parameters)

    -- tag based actions
    for _, point in pairs(self.getSnapPoints()) do
        local tags = point.tags
        local mTags = {}
        for _, tag in ipairs(tags) do
            mTags[tag] = true
        end

        local isDeck = mTags["deck"] ~= nil
        local isCurse = mTags["player curse"] ~= nil
        local isBless = mTags["bless"] ~= nil
        local isPlayerMinus1 = mTags["player minus 1"] ~= nil
        local isMonsterCurse = mTags["monster curse"] ~= nil
        local isGreen = mTags["Green"] ~= nil
        local isRed = mTags["Red"] ~= nil
        local isWhite = mTags["White"] ~= nil
        local isBlue = mTags["Blue"] ~= nil
        local isYellow = mTags["Yellow"] ~= nil

        local color = nil
        if isGreen then
            color = "Green"
        elseif isRed then
            color = "Red"
        elseif isWhite then
            color = "White"
        elseif isBlue then
            color = "Blue"
        elseif isYellow then
            color = "Yellow"
        end


        if isDeck then
            if isCurse then
                deckPositions["Player Curses"] = point.position
            elseif isBless then
                deckPositions["Blesses"] = point.position
            elseif isPlayerMinus1 then
                deckPositions["Player Minus Ones"] = point.position
            elseif isMonsterCurse then
                deckPositions["Monster Curses"] = point.position
            end
        else
            if color ~= nil then
                if isBless then
                    createActionButton("Bless", color, point.position)
                elseif isCurse then
                    createActionButton("Curse", color, point.position)
                elseif isPlayerMinus1 then
                    createActionButton("Minus1", color, point.position)
                end
            end
        end
    end

    -- Deck buttons
    if DrawButtons["Battle Goals"] ~= nil and DrawDecks["Battle Goals"] ~= nil then
        local pos = DrawButtons["Battle Goals"]
        local params = getButtonParams("drawBattleGoal", "Shuffle and deal 3 to all players",
            { -pos.x, pos.y + 0.02, pos.z })
        self.createButton(params)
    end

    if DrawButtons["Challenges"] ~= nil and DrawDecks["Challenges"] ~= nil then
        local pos = DrawButtons["Challenges"]
        local params = getButtonParams("drawChallenge", "Draw", { -pos.x, pos.y + 0.02, pos.z })
        self.createButton(params)
    end


    -- print(JSON.encode(BackButtons))

    for name, pos in pairs(BackButtons) do
        local fName = "returnChallenge_" .. name
        self.setVar(fName, function() returnChallenge(name) end)
        local params = getButtonParams(fName, "Return to bottom of draw deck", { -pos.x, pos.y + 0.02, pos.z })
        self.createButton(params)
    end

    updateGameStateWithGameData(GameData)
    updateCharacters()
    registerSavable("Scenario Mat")
    Global.call("registerDataUpdatable", self)
end

function updateData(params)
    local baseUrl = params.baseUrl
    local first = params.first
    if baseUrl ~= "https://gudyfr.github.io/fhtts/" or not first then
        local url = baseUrl .. "gameData.json"
        WebRequest.get(url, updateGameData)
    end
end

function updateGameData(request)
    local gameData = jsonDecode(request.text)
    updateGameStateWithGameData(gameData)
end

function updateGameStateWithGameData(gameData)
    if CurrentGameState ~= nil then
        CurrentGameState:updateGameData(gameData)
    else
        if SavedGameState ~= nil then
            CurrentGameState = GameState.newFromSave(gameData, SavedGameState)
            updateCurrentState()
        else
            CurrentGameState = GameState.new(gameData)
        end
    end
end

function flipX(position)
    return { x = -position.x, y = position.y, z = position.z }
end

function getButtonParams(fName, tooltip, pos, width, height)
    return {
        function_owner = self,
        click_function = fName,
        label = "",
        tooltip = tooltip,
        position = pos,
        width = width or 200,
        height = height or 200,
        font_size = 50,
        color = { 1, 1, 1, 1 - hidden_buttons },
        scale = { 1, 1, 1 },
        font_color = { 0, 0, 0, 1 }
    }
end

function drawBattleGoal()
    fhlog(INFO, TAG, "drawBattleGoal()")
    -- Locate the deck
    local hitlist = Physics.cast({
        origin       = self.positionToWorld(DrawDecks["Battle Goals"]),
        direction    = { 0, 1, 0 },
        type         = 2,
        size         = { 1, 1, 1 },
        max_distance = 0,
        debug        = false
    })

    for i, j in pairs(hitlist) do
        if j.hit_object.tag == "Deck" then
            j.hit_object.shuffle()
            j.hit_object.deal(3)
        end
    end
end

function drawChallenge()
    fhlog(INFO, TAG, "drawChallenge()")
    -- find a destination
    local destination = findChallengeDestination()
    -- print(JSON.encode(destination))
    if destination ~= nil then
        local destinationPos = self.positionToWorld(ChallengesDestinations[destination])
        -- Locate the deck
        local hitlist = Physics.cast({
            origin       = self.positionToWorld(DrawDecks["Challenges"]),
            direction    = { 0, 1, 0 },
            type         = 2,
            size         = { 1, 1, 1 },
            max_distance = 0,
            debug        = false
        })
        for i, j in pairs(hitlist) do
            if j.hit_object.tag == "Card" then
                obj = j.hit_object
                obj.setPosition(shiftUp(destinationPos))
                obj.flip()
            elseif j.hit_object.tag == "Deck" then
                j.hit_object.takeObject({ position = shiftUp(destinationPos), flip = true })
            end
        end
    else
        broadcastToAll("No Challenge spot available")
    end
end

function returnChallenge(source)
    fhlog(INFO, TAG, "returnChallenge(%s)", source)
    local destination = getChallengeDeck()

    local hitlist = getHitlist(ChallengesDestinations[source])
    for _, hit in pairs(hitlist) do
        if hit.hit_object.tag == "Card" then
            if destination == nil then
                hit.hit_object.setPosition(self.positionToWorld(DrawDecks["Challenges"]))
                hit.hit_object.flip()
            else
                destination.putObject(hit.hit_object)
            end
        end
    end
end

function getChallengeDeck()
    local hitlist = getHitlist(DrawDecks["Challenges"])
    for _, hit in pairs(hitlist) do
        if hit.hit_object.tag == "Card" or hit.hit_object.tag == "Deck" then
            return hit.hit_object
        end
    end
    return nil
end

function shiftUp(pos, amount)
    amount = amount or 0.05
    return { pos[1], pos[2] + amount, pos[3] }
end

function getHitlist(relativePosition)
    return Physics.cast({
        origin       = self.positionToWorld(relativePosition),
        direction    = { 0, 1, 0 },
        type         = 2,
        size         = { 1, 1, 1 },
        max_distance = 0,
        debug        = false
    })
end

function findChallengeDestination()
    for _, candidate in ipairs({ "Active1", "Active2", "Active3" }) do
        local hl2 = Physics.cast({
            origin       = self.positionToWorld(ChallengesDestinations[candidate]),
            direction    = { 0, 1, 0 },
            type         = 2,
            size         = { 1, 1, 1 },
            max_distance = 0,
            debug        = false
        })
        local used = false
        for _, h in pairs(hl2) do
            if h.hit_object.tag == "Card" or h.hit_object.tag == "Deck" then
                used = true
            end
        end
        if not used then
            return candidate
        end
    end
    return nil
end

function onButtonClicked(color, category, action)
    local playerMat = Global.call("getPlayerMatExt", { color })
    local characterName = playerMat.call("getCharacterName")
    if characterName ~= nil then
        local current = characterStates[characterName][category]
        if current ~= nil then
            local change = 0
            if action == "increment" then
                change = 1
            elseif action == "decrement" then
                change = -1
            end
            current = current + change
            if current < 0 then current = 0 end
            if current > 30 then current = 30 end
            characterStates[characterName][category] = current
            refreshDecals()
            updateAssistant("POST", "change", { target = characterName, what = category, change = change }, updateState)
        end
    end
end

function toggleElement(element, alt)
    if alt then
        elementStates[element] = 1
    elseif elementStates[element] ~= 0 then
        elementStates[element] = 0
    else
        elementStates[element] = 2
    end
    updateAssistant("POST", "setElement", { element = element, state = elementStates[element] })
    refreshDecals()
end

function createActionButton(action, color, position)
    --print("create " .. action .. " Button for ".. color)
    fName = "on" .. action .. "_" .. color
    self.setVar(fName, function() onAction(action, color) end)
    local pos = { -position[1], position[2], position[3] }
    params = {
        function_owner = self,
        click_function = fName,
        label = action,
        position = pos,
        width = 200,
        height = 200,
        font_size = 50,
        color = { 1, 1, 1, 1 - hidden_buttons },
        scale = { 1, 1, 1 },
        font_color = { 0, 0, 0, 1 - hidden_buttons }
    }
    self.createButton(params)
end

function onBless(color)
    moveCardFromTo("Blesses", color)
end

function onCurse(color)
    moveCardFromTo("Player Curses", color)
end

function onMinus1(color)
    moveCardFromTo("Player Minus Ones", color)
end

function moveCardFromTo(deck, color)
    local deckPosition = deckPositions[deck]
    if deckPosition ~= nil then
        local deck = getDeckOrCardAt(deckPosition)
        local card = takeCardFrom(deck)
        if card ~= nil then
            card.flip()
            sendCardTo(card, color)
        end
    end
end

function getDeckPosition(params)
    local position = self.positionToWorld(deckPositions[params.name])
    return { x = position.x, y = position.y, z = position.z }
end

function getPlayerMat(color)
    return Global.call("getPlayerMatExt", { color })
end

function sendCardTo(card, color)
    playerMat = getPlayerMat(color)
    if playerMat ~= nil then
        playerMat.call("addCardToAttackModifiers", { card })
    end
end

function returnCard(params)
    card = params[1]
    if card.hasTag("bless") then
        returnCardTo(card, deckPositions["Blesses"])
    elseif card.hasTag("player curse") then
        returnCardTo(card, deckPositions["Player Curses"])
    elseif card.hasTag("player minus 1") then
        returnCardTo(card, deckPositions["Player Minus Ones"])
    elseif card.hasTag("monster curse") then
        returnCardTo(card, deckPositions["Monster Curses"])
    end
end

function returnCardTo(card, position)
    local hitlist = Physics.cast({
        origin       = self.positionToWorld(position),
        direction    = { 0, 1, 0 },
        type         = 2,
        size         = { 1, 1, 1 },
        max_distance = 0,
        debug        = false
    }) -- returns {{Vector point, Vector normal, float distance, Object hit_object}, ...}

    if hitlist ~= nil then
        for i, j in pairs(hitlist) do
            if j.hit_object.tag == "Card" or j.hit_object.tag == "Deck" then
                j.hit_object.putObject(card)
                return
            end
        end
    end

    card.setPosition(self.positionToWorld(position))
end

function onAction(action, color)
    if action == "Bless" then
        onBless(color)
    elseif action == "Curse" then
        onCurse(color)
    elseif action == "Minus1" then
        onMinus1(color)
    end
end

function clickedToggle(color, card, name)
    --print("Clicked : " .. color .. "," .. card .. "," .. name)
    toggleState(color, card, stateValues[name])
end

function toggleState(color, card, state)
    currentState = cardStates[color][card]
    if currentState == state then
        setState(color, card, 0)
    else
        setState(color, card, state)
    end
end

function setState(color, card, state)
    cardStates[color][card] = state
    refreshDecals()
end

elementDecals = {
    fire = {
        "http://cloud-3.steamusercontent.com/ugc/2035103391730512339/983E473A83A1AE04151B470C4A0FBEFCDCCFAB05/",
        "http://cloud-3.steamusercontent.com/ugc/2035103391730231513/89FF10904ED889EB286C3EDFD59B8067A11CB914/",
        "http://cloud-3.steamusercontent.com/ugc/2035103391730231412/6B2719A39BEB7A4C43A29FCA3F4E4901EAACEF59/"
    },
    ice = {
        "http://cloud-3.steamusercontent.com/ugc/2035103391730512382/C238D61BBC2DF90EF82E6CED4814ADD44EF4A172/",
        "http://cloud-3.steamusercontent.com/ugc/2035103391730231612/ED743B202900553C6933FEB33045B6D67967C948/",
        "http://cloud-3.steamusercontent.com/ugc/2035103391730231568/38CEC6783DE0A6ED19D2A66A27DFB79F1B027FEC/",
    },
    air = {
        "http://cloud-3.steamusercontent.com/ugc/2035103391730512158/67D5198F0CFA0F42B05911A90FF61BEB5262137E/",
        "http://cloud-3.steamusercontent.com/ugc/2035103391730231889/659AF7BAD9A30322F8D75BF6DA2D7BADF3DA10A6/",
        "http://cloud-3.steamusercontent.com/ugc/2035103391730231017/CC169840C883C5354646AAC8FFBBB48C838619E5/",
    },
    earth = {
        "http://cloud-3.steamusercontent.com/ugc/2035103391730512282/D65A42A7797FAB3026DF480B581A81A831B57AA8/",
        "http://cloud-3.steamusercontent.com/ugc/2035103391730231316/E4EDCCB9A2D4BFBA4F758CD4A14C60A17F694555/",
        "http://cloud-3.steamusercontent.com/ugc/2035103391730231263/6BC4BDC7B2C57593DC43BA17A1ECCD977267F1DD/",
    },
    light = {
        "http://cloud-3.steamusercontent.com/ugc/2035103391730512435/885B9EB3B3A026E2AEA838DE08FAFCE416065645/",
        "http://cloud-3.steamusercontent.com/ugc/2035103391730231786/71EC8FDA0994605A82224B9158FB5271236A8DFE/",
        "http://cloud-3.steamusercontent.com/ugc/2035103391730231732/528533357276C83458B259BCEB464B10B4B4E807/",
    },
    dark = {
        "http://cloud-3.steamusercontent.com/ugc/2035103391730512201/A2ACA4BA06389A4D3824D9C174AD272451C3F487/",
        "http://cloud-3.steamusercontent.com/ugc/2035103391730231186/51B9CB0AB5F4DAF4B32682671BD9523AD800304A/",
        "http://cloud-3.steamusercontent.com/ugc/2035103391730231152/59157221D1B6F617643E9A948A626A119C6DD939/",
    }
}

function cacheDecals(decals)
    cacheDecalList(decals, cardActionDecals)
    cacheDecalList(decals, NumberDecals)
    cacheDecalList(decals, conditionStickerUrls)
end

function cacheDecalList(decals, list)
    for _, url in ipairs(list) do
        cacheDecal(decals, url)
    end
end

function cacheDecal(decals, url)
    local decal = {
        position = { 0, -0.1, 0 },
        name = url,
        url = url,
        scale = { 1, 1, 1 },
        rotation = { 90, 0, 0 },
    }
    table.insert(decals, decal)
end

function maybeAddInitiativeToggleButton(color)
    local buttons = self.getButtons()
    for _, button in ipairs(buttons) do
        if button.click_function == "toggle_initiative_" .. color then
            -- Found it, no need to create a button
            return
        end
    end

    self.setVar("toggle_initiative_" .. color, function() toggleInitiative(color) end)
    local pos = getStatePosition(color, 1, "fast")
    local buttonPosition = { -pos[1], pos[2] + 0.02, pos[3] }
    local params = {
        function_owner = self,
        click_function = "toggle_initiative_" .. color,
        label = "",
        tooltip = "Switch between Fast and Slow",
        position = buttonPosition,
        width = 400,
        height = 200,
        font_size = 50,
        color = { 1, 1, 1, 1 - hidden_buttons },
        scale = { 1, 1, 1 },
        font_color = { 0, 0, 0, 1 - hidden_buttons }
    }
    self.createButton(params)
end

function toggleInitiative(color)
    fhlog(DEBUG, TAG, "Toggle initiative ", color)
    if initiativeTypes[color] == nil or initiativeTypes[color] == "Fast" then
        initiativeTypes[color] = "Slow"
    else
        initiativeTypes[color] = "Fast"
    end
    refreshDecals()
end

function maybeRemoveInitiativeToggleButton(color)
    local buttons = self.getButtons()
    for _, button in ipairs(buttons) do
        if button.click_function == "toggle_initiative_" .. color then
            self.removeButton(button.index)
        end
    end
end

function updateCharacters()
    fhlog(INFO, TAG, "updateCharacters()")
    local settings = getSettings()
    local scenarioPicker = getObjectFromGUID('596fc4')
    local hasChanged = false
    for _, color in ipairs(colors) do
        local playerMat = getPlayerMat(color)
        if playerMat ~= nil then
            local characterName = playerMat.call("getCharacterName")
            -- print(color .. " : " .. (characterName or "nil"))
            if Characters[color] ~= characterName then
                hasChanged = true
                if Characters[color] ~= nil then
                    if settings['enable-automatic-characters'] or false then
                        updateAssistant("POST", "removeCharacter", { character = Characters[color] }, updateState)
                    end
                    scenarioPicker.call('removeSoloFor', Characters[color])
                end
                if settings['enable-automatic-characters'] or false then
                    if characterName ~= nil then
                        updateAssistant("POST", "addCharacter", { character = characterName }, updateState)
                    end
                end
                Characters[color] = characterName
                -- Force a reset of the character level
                CharacterLevels[color] = 0
            end
            if characterName ~= nil then
                if characterName == "Blinkblade" then
                    if initiativeTypes[color] == nil or initiativeTypes[color] == "Normal" then
                        initiativeTypes[color] = "Fast"
                    end
                    maybeAddInitiativeToggleButton(color)
                else
                    initiativeTypes[color] = "Normal"
                    maybeRemoveInitiativeToggleButton(color)
                end
                local level = playerMat.call("getCharacterLevel")
                if level ~= nil then
                    if level ~= CharacterLevels[color] then
                        hasChanged = true
                        CharacterLevels[color] = level
                        if settings['enable-automatic-characters'] or false then
                            updateAssistant("POST", "change", { target = characterName, what = "level", change = level })
                        end
                    end
                    if level < 5 then
                        scenarioPicker.call('removeSoloFor', characterName)
                    else
                        scenarioPicker.call('addSoloFor', characterName)
                    end
                end
            end
        else
            log("Could not find player mat " .. color)
        end
    end
    if hasChanged then
        updateDifficulty({ difficulty = settings.difficulty or 0, soloMode = settings['enable-solo'] or false })
    end
    refreshDecals()
end

function refreshDecals()
    local decals = {}
    cacheDecals(decals)

    for color, states in pairs(cardStates) do
        for i, state in ipairs(states) do
            if state == 1 then
                table.insert(decals, getPersistDecal(color, i))
                table.insert(decals, getInactiveLostDecal(color, i))
            elseif state == 2 then
                table.insert(decals, getInactivePersistDecal(color, i))
                table.insert(decals, getLostDecal(color, i))
            else
                table.insert(decals, getInactivePersistDecal(color, i))
                table.insert(decals, getInactiveLostDecal(color, i))
            end
        end
    end

    for color, categories in pairs(hpAndXpLocations) do
        local playerMat = getPlayerMat(color)
        if playerMat == nil then
            log("Could not find player mat for " .. color)
        else
            local characterName = playerMat.call("getCharacterName")
            if characterName ~= nil then
                local state = characterStates[characterName]
                -- print("refreshing decals")
                for category, positions in pairs(categories) do
                    local labelPosition = positions["label"]
                    if labelPosition ~= nil then
                        local value = 0
                        if state ~= nil then
                            value = state[category] or 0
                        end
                        local url = NumberDecals[value + 1]
                        if url ~= nil then
                            local decal = {
                                name = color .. "_" .. category .. "_" .. value,
                                url = url,
                                position = { labelPosition.x, labelPosition.y + 0.02, labelPosition.z },
                                rotation = { 90, 0, 0 },
                                scale = { 1, 1, 1 }
                            }
                            table.insert(decals, decal)
                        end
                    end
                end

                if initiativeTypes[color] ~= nil then
                    if initiativeTypes[color] == "Slow" then
                        local decal = getSlowDecal(color, 1)
                        decal.scale[1] = .5
                        table.insert(decals, decal)
                    elseif initiativeTypes[color] == "Fast" then
                        local decal = getFastDecal(color, 1)
                        decal.scale[1] = .5
                        table.insert(decals, decal)
                    end
                end
            end
        end
    end

    for element, elementState in pairs(elementStates) do
        local position = elementsLocations[element]
        if position ~= nil then
            local url = elementDecals[element][elementState + 1]
            if url ~= nil then
                local decal = {
                    name = element .. "_" .. elementState + 1,
                    url = url,
                    position = { position.x, position.y + 0.02, position.z },
                    rotation = { 90, 0, 0 },
                    scale = { .63, .63, .63 }
                }
                table.insert(decals, decal)
            end
        end
    end
    self.setDecals(decals)
end

cardActionDecals = {
    persit = "http://cloud-3.steamusercontent.com/ugc/2035103391730503108/916EF57D3AD98448D71B5A8E2C331E83A39F71D6/",
    lost = "http://cloud-3.steamusercontent.com/ugc/2035103391730503053/BBF9E517AC088D3D2EEEF0D40316210EDF39A8AE/",
    fast = "http://cloud-3.steamusercontent.com/ugc/2035104110936914421/C0373AA2715F00A0C68F2C59567A3D0A57A83DF2/",
    slow = "http://cloud-3.steamusercontent.com/ugc/2035104110936914522/C96BBBFB2392CCA611BCFB34E6A3B73A76F15AD8/",
    inactive_persist =
    "http://cloud-3.steamusercontent.com/ugc/2035103391730393072/A84E53160C7B92D6AFCFD25F9E9AFA7B29816FB7/",
    inactive_lost =
    "http://cloud-3.steamusercontent.com/ugc/2035103391730393295/CAA4420FEA5C40153A004F22A8465101A600F5A1/",
}

function getPersistDecal(color, card)
    return getDecal(color, card, "persist", cardActionDecals.persit)
end

function getLostDecal(color, card)
    return getDecal(color, card, "lost", cardActionDecals.lost)
end

function getFastDecal(color, card)
    return getDecal(color, card, "fast", cardActionDecals.fast)
end

function getSlowDecal(color, card)
    return getDecal(color, card, "slow", cardActionDecals.slow)
end

function getInactivePersistDecal(color, card)
    return getDecal(color, card, "persist", cardActionDecals.inactive_persist)
end

function getInactiveLostDecal(color, card)
    return getDecal(color, card, "lost", cardActionDecals.inactive_lost)
end

function getDecal(color, card, state, image)
    local position = getStatePosition(color, card, state)
    --position[1] = -position[1]
    return {
        name = state,
        url = image,
        position = position,
        rotation = { 90, 0, 0 },
        scale = { .25, .25, .25 }
    }
end

function getStatePosition(color, card, state)
    local cardPosition = cardLocations[color][card]
    local offset = relativeStateButtonLocations[state]
    return {
        cardPosition[1] + offset[1],
        cardPosition[2] + offset[2],
        cardPosition[3] + offset[3],
    }
end

function onStart()
    -- flip all cards
    for color, cards in pairs(cardLocations) do
        for n, card in pairs(cards) do
            local hitlist = Physics.cast({
                origin       = self.positionToWorld(card),
                direction    = { 0, 1, 0 },
                type         = 2,
                size         = { 1, 1, 1 },
                max_distance = 0,
                debug        = false
            }) -- returns {{Vector point, Vector normal, float distance, Object hit_object}, ...}

            for i, j in pairs(hitlist) do
                if j.hit_object.tag == "Card" then
                    j.hit_object.flip()
                end
            end
        end
    end

    if isXHavenEnabled() then
        local initiatives = {}
        for color, cards in pairs(cardLocations) do
            playerMat = getPlayerMat(color)
            if playerMat ~= nil then
                characterName = playerMat.call("getCharacterName")
                if characterName ~= nil then
                    -- find the initiative card
                    for cardNumber = 1, 2 do
                        local card = getDeckOrCardAt(cardLocations[color][cardNumber])
                        if card ~= nil and card.tag == "Card" then
                            local cardName = card.getName()
                            if cardName ~= nil then
                                local speed
                                local initiativeType = initiativeTypes[color] or "Normal"
                                if initiativeType == "Normal" or initiativeType == "Fast" then
                                    speed = tonumber(string.sub(cardName, 1, 2))
                                else
                                    speed = tonumber(string.sub(cardName, 4, 5))
                                end
                                if cardNumber == 1 then
                                    initiatives[characterName] = speed
                                else
                                    initiatives[characterName .. ".2"] = speed
                                end
                            end
                        end
                    end

                    if initiatives[characterName] == nil then
                        initiatives[characterName] = 99
                    end
                end
            else
                log("Could not find player mat for " .. color)
            end
        end
        -- initiatives.secondCards = secondCards
        updateAssistant("POST", "startRound", initiatives)
    end
end

function onEnd()
    -- return cards to their respective mats
    for color, cards in pairs(cardLocations) do
        local playerMat = getPlayerMat(color)
        if playerMat ~= nil then
            for n, card in pairs(cards) do
                local object = getDeckOrCardAt(card)
                forEachInDeckOrCard(object, function(c) playerMat.call("returnCard", { c, cardStates[color][n] }) end)
            end
            -- send endTurn to Player Mats
            playerMat.call("endTurn")
        end
    end

    getObjectFromGUID(BattleInterfaceMat).call("onEndTurn")

    -- clearStates
    for color, cards in pairs(cardStates) do
        for i, card in ipairs(cards) do
            cardStates[color][i] = 0
        end
    end
    refreshDecals()

    -- clear drawn card
    Global.call("resetDrawnCard")

    updateAssistant("POST", "endRound")
end

function setScenario(params)
    CurrentScenario = params
    updateAssistant("POST", "setScenario", params)
end

function spawned(params)
    local monster = params['monster']
    if isXHavenEnabled() then
        local isBoss = params['isBoss']
        local query = {
            monster = monster.getName(),
            isBoss = isBoss
        }
        updateAssistant(
            "POST",
            "addMonster",
            query,
            function(re)
                if re.response_code == 200 and re.text ~= nil and re.text ~= "" then
                    local inputs = monster.getInputs()
                    if inputs ~= nil then
                        local input = inputs[1]
                        monster.editInput({ index = input.index, value = re.text })
                    end
                    if NeedsToSwitch[monster.guid] ~= nil then
                        toggled(monster)
                        NeedsToSwitch[monster.guid] = nil
                    end
                    if NeedsToUpdateNr[monster.guid] ~= nil then
                        updateStandeeNr({ monster, NeedsToUpdateNr[monster.guid] })
                        NeedsToUpdateNr[monster.guid] = nil
                    end
                else
                    fhlog(ERROR, TAG, "Could not fetch Standee number : %s", (re.text or "<empty response>"))
                end
            end
        )
    end
    registerStandee(monster)
end

NeedsToSwitch = {}
NeedsToUpdateNr = {}

function getStandeeNrInput(standee)
    local inputs = standee.getInputs() or {}
    if #inputs > 0 then
        return inputs[1]
    end
end

function getStandeeNr(standee)
    local input = getStandeeNrInput(standee)
    if input ~= nil then
        return input.value
    end
end

function toggled(monster)
    local nr = getStandeeNr(monster)
    if nr ~= nil then
        updateAssistant("POST", "switchMonster", {
            monster = monster.getName(),
            nr = nr
        })
    else
        -- We haven't received the standee number for this monster yet, so postpone switching to elite
        if isXHavenEnabled() then
            NeedsToSwitch[monster.guid] = true
        end
    end
end

function updateStandeeNr(params)
    print(params)
    local standee = params[1]
    local newNr = params[2]
    local nr = getStandeeNr(standee)
    if nr ~= nil and nr ~= "" then
        updateAssistant("POST", "updateStandeeNr", {
            name = standee.getName(),
            nr = nr,
            newNr = newNr
        })
        local input = getStandeeNrInput(standee)
        if input ~= nil then
            input.value = newNr
            standee.editInput(input)
        end
    else
        -- We haven't received the standee number for this monster yet, so postpone switching its number
        if isXHavenEnabled() then
            NeedsToUpdateNr[standee.guid] = newNr
        end
    end
end

function locateBoardElementsFromTags()
    cardLocations = {
        Green = { {}, {}, {} },
        Red = { {}, {}, {} },
        White = { {}, {}, {} },
        Blue = { {}, {}, {} },
    }

    elementsLocations = {
        air = {},
        earth = {},
        ice = {},
        fire = {},
        dark = {},
        light = {}
    }

    hpAndXpLocations = {
        Green = {
            hp = { decrement = {}, label = {}, increment = {} },
            xp = { decrement = {}, label = {}, increment = {} }
        },
        Red = {
            hp = { decrement = {}, label = {}, increment = {} },
            xp = { decrement = {}, label = {}, increment = {} }
        },
        White = {
            hp = { decrement = {}, label = {}, increment = {} },
            xp = { decrement = {}, label = {}, increment = {} }
        },
        Blue = {
            hp = { decrement = {}, label = {}, increment = {} },
            xp = { decrement = {}, label = {}, increment = {} }
        }
    }

    if self.hasTag(TAG_5_PLAYERS) then
        cardLocations["Yellow"] = { {}, {}, {} }
        hpAndXpLocations["Yellow"] = {
            hp = { decrement = {}, label = {}, increment = {} },
            xp = { decrement = {}, label = {}, increment = {} }
        }
    end

    scenarioElementPositions = {}

    DrawButtons = {}

    DrawDecks = {}

    ChallengesDestinations = {}

    BackButtons = {}

    ScenarioButtons = {}

    AttackModifierButtons = {}

    for _, point in ipairs(self.getSnapPoints()) do
        local position = point.position
        local tagsMap = {}
        local tagCount = 0
        for _, tag in ipairs(point.tags) do
            tagsMap[tag] = true
            tagCount = tagCount + 1
        end
        if tagsMap["ability card"] ~= nil then
            local color = getColorFromTags(tagsMap)
            if color ~= nil then
                local locations = cardLocations[color]
                local cardNr = 1
                if tagsMap["a1"] ~= nil then
                    cardNr = 1
                elseif tagsMap["a2"] ~= nil then
                    cardNr = 2
                else
                    cardNr = 3
                end
                locations[cardNr] = position
            end
        end
        if tagsMap["button"] ~= nil then
            if tagsMap["fire"] ~= nil then
                elementsLocations.fire = position
            elseif tagsMap["air"] ~= nil then
                elementsLocations.air = position
            elseif tagsMap["ice"] ~= nil then
                elementsLocations.ice = position
            elseif tagsMap["earth"] ~= nil then
                elementsLocations.earth = position
            elseif tagsMap["dark"] ~= nil then
                elementsLocations.dark = position
            elseif tagsMap["light"] ~= nil then
                elementsLocations.light = position
            elseif tagsMap["draw"] ~= nil then
                if tagsMap["challenges"] ~= nil then
                    DrawButtons["Challenges"] = position
                elseif tagsMap["battle goals"] ~= nil then
                    DrawButtons["Battle Goals"] = position
                end
            elseif tagsMap["back"] ~= nil and tagsMap["challenges"] ~= nil then
                if tagsMap["active1"] ~= nil then
                    BackButtons["Active1"] = position
                elseif tagsMap["active2"] ~= nil then
                    BackButtons["Active2"] = position
                elseif tagsMap["active3"] ~= nil then
                    BackButtons["Active3"] = position
                end
            elseif tagsMap["start"] ~= nil then
                ScenarioButtons["start"] = position
            elseif tagsMap["end"] ~= nil then
                ScenarioButtons["end"] = position
            elseif tagsMap["cleanup"] ~= nil then
                ScenarioButtons["cleanup"] = position
            elseif tagsMap["attack modifier"] ~= nil then
                local color = getColorFromTags(tagsMap)
                if color ~= nil then
                    AttackModifierButtons[color] = position
                end
            end
        end
        if tagsMap["deck"] ~= nil then
            if tagsMap["draw"] ~= nil then
                if tagsMap["battle goals"] ~= nil then
                    DrawDecks["Battle Goals"] = position
                elseif tagsMap["challenges"] ~= nil then
                    DrawDecks["Challenges"] = position
                end
            else
                if tagsMap["challenges"] ~= nil then
                    if tagsMap["active1"] ~= nil then
                        ChallengesDestinations["Active1"] = position
                    elseif tagsMap["active2"] ~= nil then
                        ChallengesDestinations["Active2"] = position
                    elseif tagsMap["active3"] ~= nil then
                        ChallengesDestinations["Active3"] = position
                    elseif tagsMap["discard"] ~= nil then
                        ChallengesDestinations["Discard"] = position
                    end
                end
            end
        end

        local color = getColorFromTags(tagsMap)
        if color ~= nil then
            local categories = { "hp", "xp" }
            for _, category in ipairs(categories) do
                if tagsMap[category] ~= nil then
                    if tagsMap["button"] ~= nil then
                        if tagsMap["minus"] ~= nil then
                            hpAndXpLocations[color][category]["decrement"] = position
                        elseif tagsMap["plus"] ~= nil then
                            hpAndXpLocations[color][category]["increment"] = position
                        end
                    elseif tagsMap["label"] ~= nil then
                        hpAndXpLocations[color][category]["label"] = position
                    end
                end
            end
        end

        if tagsMap["scenarioElement"] ~= nil then
            table.insert(scenarioElementPositions, position)
        end

        if tagsMap["errata"] ~= nil then
            ErrataPosition = position
        end
    end

    table.sort(scenarioElementPositions, function(a, b) return a.z - b.z < 0 end)
    for i, position in ipairs(scenarioElementPositions) do
        scenarioElementPositions[i] = self.positionToWorld(position)
    end
end

function getScenarioElementPositions()
    return scenarioElementPositions
end

function getColorFromTags(tagsMap)
    for _, color in ipairs(colors) do
        if tagsMap[color] ~= nil then
            return color
        end
    end
    if tagsMap['ally'] ~= nil then return 'ally' end
    if tagsMap['monster'] ~= nil then return 'monster' end
    return nil
end

function getPlayer(color)
    for _, player in ipairs(Player.getPlayers()) do
        if player.color == color then
            return player
        end
    end
end

function sendCard(params)
    local color = params[1]
    local card = params[2]
    local index = params[3]
    local destination = self.positionToWorld(cardLocations[color][index])
    local orientation = card.getRotation()
    -- Find out if this card is in a player hand (it then needs to be moved a bit)
    local player = getPlayer(color)
    if player ~= nil then
        for _, obj in ipairs(player.getHandObjects()) do
            if obj.guid == card.guid then
                local position = card.getPosition()
                -- Move the card up to avoid the hand zone grabbing it again
                card.setPosition(position + Vector(0, 4, 0))
                card.setLock(true)
                break
            end
        end
    end
    Wait.time(function()
        card.setLock(false)
        card.setPositionSmooth(shiftUp(destination, 0.5))
        -- Make sure the card is visible to everyone (sometimes it's not)
        card.setInvisibleTo({})
        if orientation.z < 10 and orientation.z > -10 then
            card.setRotationSmooth({ 0, 0, 180 });
        end
    end, 0.1)
end

function onCleanup(obj, color, alt)
    if alt then
        Global.call("cleanup")
    else
        toggleEndScenarioUI()
    end
end

function onCleanedUp()
    updateAssistant("POST", "endScenario", {}, updateState)
end

function toggleEndScenarioUI()
    local endScenarioBoard = getObjectFromGUID('0d92fb')
    if endScenarioBoard ~= nil then
        endScenarioBoard.call("toggleVisibility")
    end
end

-- Standee functions
function registerStandee(standee)
    standee.addTag("tracked")
    onStandeeRegistered(standee)
    table.insert(trackedGuids, standee.guid)
    updateUpdateRunning()
    if isInternalGameStateEnabled() then
        updateCurrentState()
    end
    -- We can't rely on the last update anymore, as we have a new standee to update
    previousHash = ""
end

function onStandeeRegistered(standee)
    -- print("Tracking " .. standee.getName())

    -- We need to wait a bit to register for Collisions
    -- probably as the object isn't fully loaded yet?
    Wait.frames(function() standee.registerCollisions() end, 10)
end

function onStandeeUnregistered(standee)
    -- print("Untracking " .. standee.getName())
    standee.removeTag("tracked")
    standee.removeTag("lootable")
    standee.unregisterCollisions()
    standee.clearContextMenu()
    standee.clearButtons()
end

function changeStandeeHp(params)
    local standee = params.standee
    local amount = params.amount
    if standee ~= nil and amount ~= nil then
        local name = standee.getName()
        local nr = 0
        local inputs = standee.getInputs()
        if inputs ~= nil then
            nr = tonumber(inputs[1].value)
        end
        updateAssistant("POST", "change",
            { target = name, nr = nr, what = params.changeMax and "maxHp" or "hp", change = amount }, updateState)
    end
end

function damageStandee(standee, color, alt)
    changeStandeeHp({ standee = standee, amount = -1, changeMax = alt })
end

function undamageStandee(standee, color, alt)
    changeStandeeHp({ standee = standee, amount = 1, changeMax = alt })
end

function unregisterStandee(standee)
    for idx, guid in ipairs(trackedGuids) do
        if guid == standee.guid then
            table.remove(trackedGuids, idx)
            clearStandee(standee)
        end
    end
    standeeStates[standee.guid] = nil
    onStandeeUnregistered(standee)
    updateUpdateRunning()
end

UpdaterID = nil

function updateUpdateRunning()
    if UpdaterID ~= nil then
        if #trackedGuids == 0 then
            fhlog(DEBUG, TAG, "Stopping X-haven updates : %s", UpdaterID)
            Wait.stop(UpdaterID)
            UpdaterID = nil
        end
    else
        if #trackedGuids > 0 then
            UpdaterID = Wait.time(refreshState, 0.5, -1)
            fhlog(DEBUG, TAG, "Started X-haven updates : %s", UpdaterID)
            return
        end
    end
end

function refreshState()
    updateAssistant("GET", "state", {}, updateState)
end

previousHash = ""
hasTrackedChanged = false
ConsecutiveErrors = 0
function updateState(request)
    -- print("Updating state")
    if request.is_done and not request.is_error then
        if math.floor(request.response_code / 100) == 2 then
            ConsecutiveErrors = 0
            local hash = request.getResponseHeader("hash")
            if hash ~= nil and hash == previousHash then
                return
            end
            previousHash = hash
            -- Parse and process the response
            local fullState = jsonDecode(request.text)
            processState(fullState)
        else
            fhlog(WARNING, TAG, "Error Fetching State (%s) : %s", request.response_code, request.text)
        end
    else
        fhlog(WARNING, TAG, "Error Fetching State : %s", request.error)
        ConsecutiveErrors = ConsecutiveErrors + 1
        if ConsecutiveErrors % 10 == 9 then
            broadcastToAll("Error connecting to X-Haven assistant. Is it running with the server enabled?",
                {
                    r = 1,
                    g = 0,
                    b = 0
                })
        end
    end
end

CurrentRound = {
    round = -1,
    state = -1
}

VersionMessageCount = 0

function processState(state)
    local version = state.version or 0
    if version < CURRENT_ASSISTANT_VERSION then
        if VersionMessageCount % 10 == 0 then
            broadcastToAll(
                "The Assistant is outdated. Please download the latest version of the Assistant to enable all features.",
                { 1, 0, 0 })
        end
        VersionMessageCount = VersionMessageCount + 1
    end
    local newState = {}
    newState.round = {
        round = state.round,
        state = state.roundState
    }
    if state.roundState ~= CurrentRound.state or CurrentRound.round ~= state.round then
        CurrentRound.round = state.round
        CurrentRound.state = state.roundState
        Global.call("roundUpdate", JSON.encode(CurrentRound))
    end

    local charactersStatus = {}
    local monstersStatus = {}
    local assistantData = {}

    for _, entry in ipairs(state.currentList) do
        local id = entry.id
        local originalId = id
        -- We need to get rid of some of the (FH) and scenario specific monster names
        local searches = { ' (', ' Scenario ' }
        for _, s in ipairs(searches) do
            local search = string.find(id, s, 1, true)
            if search ~= nil then
                id = string.sub(id, 1, search - 1)
            end
        end

        newState[id] = entry
        -- Handle summons separately
        if entry.characterState ~= nil then
            for _, summon in ipairs(entry.characterState.summonList or {}) do
                local summonName = summon.name
                if summonName == "Shambling Skeleton" then
                    summonName = summonName .. " " .. summon.standeeNr
                end
                newState[summonName] = { characterState = summon }
            end
            characterStates[entry.id] = { hp = entry.characterState.health, xp = entry.characterState.xp }
            table.insert(assistantData,
                {
                    name = originalId,
                    type = "character",
                    turnState = entry.turnState,
                    active = entry.active or entry.characterState.health > 0,
                    noUi = entry.noUi or false,
                    initiative = entry.characterState.initiative,
                    npc = entry.npc or false
                })
        else
            local instances = entry.monsterInstances
            if instances ~= nil then
                for _, instance in ipairs(instances) do
                    monstersStatus[id .. " " .. instance.standeeNr] = {
                        current = instance.health,
                        max = instance
                            .maxHealth
                    }
                end
                table.insert(assistantData,
                    {
                        name = originalId,
                        type = "monster",
                        turnState = entry.turnState,
                        level = entry.level,
                        card = entry.currentCard,
                        active = entry.active or #instances > 0,
                    })
            end
        end
    end

    local assistantMat = getObjectFromGUID('c64592')
    if assistantMat ~= nil then
        assistantMat.call("updateState", { entries = assistantData, round = newState.round, notes = state.notes or {} })
    end

    local elements = state.elements
    if elements ~= nil then
        for element, value in pairs(elements) do
            elementStates[element] = value
        end
        refreshDecals();
    end
    refreshStandees(newState)

    charactersStatus.monsters = monstersStatus
    Global.call("onEnemiesUpdate", JSON.encode(charactersStatus))
end

function refreshStandees(state)
    for _, guid in ipairs(trackedGuids) do
        local standee = getObjectFromGUID(guid)
        if standee ~= nil then
            local found = false
            local name = standee.getName()
            local standeeNr = 1
            if name:sub(#name - 1, #name - 1) == " " and name:sub(#name, #name):find("%d") ~= nil then
                standeeNr = tonumber(name:sub(#name)) or 1
                name = name:sub(1, #name - 2)
            end
            -- log(name, standeeNr)
            -- We can't always assume there is a standeeNr, as bosses do not have one
            local inputs = standee.getInputs()
            if inputs ~= nil and inputs[1] ~= nil then
                standeeNr = tonumber(inputs[1].value) or 1
            end

            local typeState = state[name] or state[name .. " " .. standeeNr]

            if typeState ~= nil then
                local instances = typeState.monsterInstances
                if instances ~= nil then
                    for _, instance in ipairs(instances) do
                        if instance.standeeNr == standeeNr then
                            -- copy the turn state from the type
                            instance.turnState = typeState.turnState
                            refreshStandee(standee, instance)
                            --print("Matched Standee, health : " .. instance.health .. " / " .. instance.maxHealth)
                            found = true
                        end
                    end
                else
                    -- Characters and Summons
                    local characterState = typeState.characterState
                    if characterState ~= nil then
                        -- copy the turn state from the type
                        characterState.turnState = typeState.turnState
                        refreshStandee(standee, characterState)
                        --print("Matched Standee, health : " .. instance.health .. " / " .. instance.maxHealth)
                        found = characterState.health > 0
                    end
                end
            end
            if not found and standee.hasTag("deletable") and standee.hasTag("lootable") then
                local position = standee.getPosition()
                local lootAsBody = standee.hasTag("loot as body")
                local lootAsRubble = standee.hasTag("loot as rubble")
                local noLoot = standee.hasTag("no loot")
                local name = standee.getName()
                local container = getObjectFromGUID(getGMNotes(standee).container or '')
                standee.destroyObject()
                -- loot
                if noLoot then
                    -- do nothing
                elseif lootAsBody then
                    if container ~= nil then
                        -- Spawn a "body" token
                        local obj = spawnObject({
                            type = "Custom_Model",
                            position = position,
                            scale = { .7, 1, .7 },
                            sound = false
                        })
                        obj.setCustomObject({
                            mesh = container.getCustomObject().mesh,
                            type = 0,
                            material = 3,
                            diffuse = container.getCustomObject().diffuse,
                        })
                        obj.addTag("deletable")
                    end
                elseif lootAsRubble then
                    -- Turn into Rubble
                    local zone = getObjectFromGUID('1f0c29')
                    local objects = zone.getObjects(true)
                    local foundRubble = false
                    for _, obj in ipairs(objects) do
                        if not foundRubble and obj.getName() == "Rubble" then
                            obj.setPosition(position)
                            foundRubble = true
                        end
                    end
                else
                    -- Normal loot
                    getObjectFromGUID('5e0624').takeObject({ position = position, smooth = false })
                end
            end
            if not found and (standee.hasTag("trackable") or standee.hasTag("tracked")) then
                local notes = standee.getGMNotes()
                if notes ~= nil then
                    local notesObj = JSON.decode(notes)
                    if notesObj ~= nil then
                        local onDeath = notesObj.onDeath
                        if onDeath ~= nil then
                            Global.call("triggered", onDeath)
                        end
                    end
                end

                if standee.hasTag("summon") then
                    local buttons = standee.getButtons() or {}
                    if #buttons ~= 1 then
                        clearStandee(standee)
                        addSummonButton(standee)
                    end
                else
                    clearStandee(standee)
                end
            end
        end
    end
end

function noop()
end

function addSummonButton(standee)
    local baseYRot = standee.getRotation().y
    local flip = (baseYRot > 90 and baseYRot < 270)
    if flip then
        baseYRot = 0
    else
        baseYRot = 180
    end
    local vec = mapToStandeeInfoArea(0.025, 0, -0.005, 1.1, 1.1, flip, 0.95)
    local rot = Vector(1, 0, 0)
    if flip then
        rot:rotateOver('y', 180):normalize()
    end

    local buttonParams = {
        function_owner = self,
        click_function = "addSummon",
        label = "Summon",
        position = { x = vec.x, y = vec.y, z = vec.z },
        -- Hacky rotation calculations ... might need to figure out what's going on ...
        rotation = { -55 * rot.x, 540 - baseYRot, 55 * rot.z },
        width = 700,
        height = 200,
        font_size = 160,
        color = { 1, 1, 1, 1 },
        scale = { .44, .44, .44 },
        font_color = { 0, 0, 0, 1 }
        --font_color = { 0,0,0,1 }
    }
    standee.createButton(buttonParams)
end

function addSummon(standee)
    local name = standee.getName()
    -- remove all buttons on the standee (to get rid of the summon button)
    standee.clearButtons()
    updateAssistant("POST", "addSummon", { name = name }, updateState)
end

HeightByFigurine = {
    Drifter = 1.7,
    Geminate = 1.2,
    Deathwalker = 1.6,
    Boneshaper = 1.8,
    Blinkblade = 1.2,
    ["Banner Spear"] = 1.7,
}

standeeStates = {}

function refreshStandee(standee, instance)
    local height = 0.95
    local xScaleFactor = 1.1
    local yScaleFactor = 1.1
    if standee.hasTag("token") then
        -- tokens are smaller and need an additional scale
        xScaleFactor = 4
        yScaleFactor = 1.3
        height = 0.2
    elseif standee.hasTag("overlay") then
        xScaleFactor = 0.6
        yScaleFactor = 0.7
        height = 0.2
    elseif standee.hasTag("model") then
        xScaleFactor = 2.0
        yScaleFactor = 2.0
        height = 2.0
        local customHeight = HeightByFigurine[standee.getName()]
        if customHeight ~= nil then
            height = customHeight
        end
    end
    if instance.health == 0 then
        clearStandee(standee)
        return
    end
    local baseYRot = standee.getRotation().y
    local flip = (baseYRot > 90 and baseYRot < 270)
    if flip then
        baseYRot = 0
    else
        baseYRot = 180
    end
    standee.addTag("lootable")
    local stickers = {}

    local inputs = standee.getInputs()
    if inputs ~= nil then
        local nr = tonumber(inputs[1].value or 0)
        if nr >= 1 and nr <= 10 then
            -- Apply the standeeNr sticker
            local position = StandeeNrPositions[standee.getName()] or { x = -0.2, y = 0.5, z = -0.05 }
            height = position.y + 0.35
            local standeeNumbers = StandeeNumbers
            if instance.type == 1 then
                standeeNumbers = EliteStandeeNumbers
            end
            local sticker = {
                position = position,
                rotation = { 0, baseYRot, 0 },
                scale = { 0.2, 0.2, 0.2 },
                url = standeeNumbers[nr],
                name = standee.guid .. "_nr_" .. nr
            }
            table.insert(stickers, sticker)
        end
    end

    local hp = math.ceil(instance.health * 24 / instance.maxHealth)
    local vec = mapToStandeeInfoArea(0.05, 0, 0, xScaleFactor, yScaleFactor, flip, height)
    local hpSticker = {
        position = { vec.x, vec.y, vec.z },
        rotation = { 35, baseYRot, 0 },
        scale = { 1 * xScaleFactor, 0.16 * yScaleFactor, 0.1 },
        url = conditionStickerUrls["hp" .. hp],
        name = standee.guid .. "_hp_" .. hp
    }
    table.insert(stickers, hpSticker)

    local xPosition = -0.53
    if (instance.baseShield or 0) > 0 then
        vec = mapToStandeeInfoArea(xPosition, 0, 0, xScaleFactor, yScaleFactor, flip, height)
        local shieldIconSticker = {
            position = { vec.x, vec.y, vec.z },
            rotation = { 35, baseYRot, 0 },
            scale = { 0.15 * xScaleFactor, 0.16 * yScaleFactor, 0.2 },
            url = conditionStickerUrls["shield" .. instance.baseShield],
            name = standee.guid .. "_shield_" .. instance.baseShield
        }
        table.insert(stickers, shieldIconSticker)
        xPosition = xPosition - 0.15
    end

    if (instance.baseRetaliate or 0) > 0 then
        vec = mapToStandeeInfoArea(xPosition, 0, 0, xScaleFactor, yScaleFactor, flip, height)
        local retaliateIconSticker = {
            position = { vec.x, vec.y, vec.z },
            rotation = { 35, baseYRot, 0 },
            scale = { 0.15 * xScaleFactor, 0.16 * yScaleFactor, 0.2 },
            url = conditionStickerUrls["retaliate" .. instance.baseRetaliate],
            name = standee.guid .. "_retaliate_" .. instance.baseRetaliate
        }
        table.insert(stickers, retaliateIconSticker)
        xPosition = xPosition - 0.1
    end

    -- if (instance.pierce or 0) > 0 then
    --     vec = mapToStandeeInfoArea(xPosition, 0, 0, xScaleFactor, yScaleFactor, flip)
    --     local retaliateIconSticker =  {
    --         position = { vec.x, vec.y, vec.z },
    --         rotation = { 35, baseYRot, 0 },
    --         scale = { 1 * xScaleFactor, 0.16 * yScaleFactor, 0.1 },
    --         url = conditionStickerUrls["pierce" .. instance.pierce],
    --         name = standee.guid .. "_pierce_" .. instance.pierce
    --     }
    --     table.insert(stickers, retaliateIconSticker)
    --     xPosition = xPosition + 0.1
    -- end

    local btnWidth = 0
    -- Create / Update a button for the HP
    local buttons = standee.getButtons()
    local buttonIdx = -1
    if buttons ~= nil then
        for _, button in ipairs(buttons) do
            if button.width == btnWidth then
                buttonIdx = button.index
            end
        end
    end
    vec = mapToStandeeInfoArea(0.025, 0, -0.005, xScaleFactor, yScaleFactor, flip, height)
    local rot = Vector(1, 0, 0)
    if flip then
        rot:rotateOver('y', 180):normalize()
    end
    local buttonParams = {
        function_owner = self,
        click_function = "noop",
        label = instance.health .. " / " .. instance.maxHealth,
        position = { x = vec.x, y = vec.y, z = vec.z },
        -- Hacky rotation calculations ... might need to figure out what's going on ...
        rotation = { -55 * rot.x, 540 - baseYRot, 55 * rot.z },
        width = btnWidth,
        height = 0,
        font_size = 160,
        color = { 1, 1, 1, 0 },
        scale = { .4 * xScaleFactor, .4 * yScaleFactor, .4 * yScaleFactor },
        font_color = { 1, 1, 1, 100 }
        --font_color = { 0,0,0,1 }
    }

    if buttonIdx == -1 then
        standee.createButton(buttonParams)
        -- Also create hp - and hp + buttons
        buttonParams.label = "-"
        buttonParams.tooltip = "Right click to change max"
        buttonParams.click_function = "damageStandee"
        buttonParams.position.x = vec.x - 0.35 * xScaleFactor
        buttonParams.width = 200
        buttonParams.height = 200
        standee.createButton(buttonParams)

        buttonParams.label = "+"
        buttonParams.click_function = "undamageStandee"
        buttonParams.position.x = vec.x + 0.35 * xScaleFactor
        standee.createButton(buttonParams)
        buttonIdx = 1
    else
        buttonParams.index = buttonIdx
        standee.editButton(buttonParams)
    end

    -- Remove all buttons after buttonIdx + 2 (hp - and hp +)
    local allButtons = standee.getButtons()
    if allButtons ~= nil then
        for i = #allButtons, 1, -1 do
            if allButtons[i].index > buttonIdx + 2 then
                standee.removeButton(allButtons[i].index)
            end
        end
    end

    local nbConditions = 0
    local conditions = {}
    for _, idx in ipairs(instance.conditions or {}) do
        local condition = conditionsOrder[idx + 1]
        if condition ~= nil then
            table.insert(conditions, condition)
            nbConditions = nbConditions + 1
        end
    end

    -- Special casing for looting (when going from turnState 1 to 2)
    if standee.hasTag("looter") and isEndOfRoundLootingEnabled() then
        if standeeStates[standee.guid] ~= nil and
            standeeStates[standee.guid].turnState ~= nil and
            standeeStates[standee.guid].turnState == 1 and
            instance.turnState == 2 then
            fhlog(DEBUG, TAG, "End of round looting for %s", standee.getName())
            local position = standee.getPosition()
            local hitlist = Physics.cast({
                origin       = { position.x, position.y + 1, position.z },
                direction    = { 0, -1, 0 },
                type         = 1,
                max_distance = 4,
                debug        = false
            })
            local nbLoot = 0
            for _, item in pairs(hitlist) do
                if item.hit_object.getName() == "Loot" then
                    fhlog(DEBUG, TAG, "Found loot")
                    -- log(item.hit_object)
                    nbLoot = nbLoot + 1
                    destroyObject(item.hit_object)
                end
            end

            if nbLoot > 0 then
                doLoot({ target_name = standee.getName(), count = nbLoot })
            end
        end
    end

    standeeStates[standee.guid] = {
        hp = instance.health,
        maxHp = instance.maxHealth,
        conditons = conditions,
        turnState = instance.turnState
    }
    if nbConditions > 0 then
        local xOffset = 0.13 * (nbConditions - 1) * xScaleFactor
        for _, condition in ipairs(conditions) do
            local url = conditionStickerUrls[condition]
            if url ~= nil then
                vec = mapToStandeeInfoArea(xOffset, 0.23, 0, xScaleFactor, yScaleFactor, flip, height)
                local sticker = {
                    position = { vec.x, vec.y, vec.z },
                    rotation = { 35, -baseYRot, 0 },
                    scale = { .23 * xScaleFactor, 0.23 * yScaleFactor, 0.23 },
                    url = url,
                    name = standee.guid .. "_" .. condition
                }
                table.insert(stickers, sticker)
                local fName = "remove_" .. standee.guid .. "_" .. condition
                self.setVar(fName, function() toggleCondition(standee.guid, condition) end)
                local removeButton = {
                    function_owner = self,
                    position = { -vec.x, vec.y, vec.z },
                    rotation = { -35, -baseYRot, 0 },
                    scale = { .23 * xScaleFactor, 0.23 * yScaleFactor, 0.23 },
                    click_function = fName,
                    width = 250,
                    height = 250,
                    color = { 1, 1, 1, 0 },
                    tooltip = "Click to remove " .. condition
                }
                standee.createButton(removeButton)
                xOffset = xOffset - 0.26 * xScaleFactor
            end
        end
    end
    standee.setDecals(stickers)

    if instance.turnState ~= nil then
        if instance.turnState == 1 and isHighlightCurrentFiguresEnabled() then
            standee.highlightOn({ 1, 1, 1, 5 })
        elseif instance.turnState == 2 and isHighlightPastFiguresEnabled() then
            standee.highlightOn({ .4, .4, .4, 5 })
        else
            highlightOff(standee)
        end
    else
        highlightOff(standee)
    end
end

function onLootDrawn(params)
    if isInternalGameStateEnabled() then
        local card = params.card
        local color = params.color
        local enhancements = params.enhancements or 0
        local character = Characters[color]
        if character ~= nil and card ~= nil then
            print(card)
            local lootInfo = CurrentGameState:setCardLooted(card, character, enhancements)
            if lootInfo.type ~= "special" then
                broadcastToAll(character .. " looted " .. lootInfo.value .. " " .. lootInfo.type,
                    { r = 0.2, g = 1, b = 0.2 })
            else
                broadcastToAll(character .. " looted a special card. Refer to loot card.", { r = 0.2, g = 1, b = 0.2 })
            end
        else
            print(string.format("card: %s, color: %s, character: %s", card or "nil", color or "nil", character or "nil"))
            broadcastToAll("Unknown looter, loot card will not be accounted for at the end of the scenario",
                { r = 1, g = 0, b = 0 })
        end
    end
end

function highlightOff(standee)
    standee.highlightOff()
    local gmNotes = getGMNotes(standee)
    local settings = getSettings()
    if gmNotes.highlight ~= nil and (settings["enable-highlight-tiles-by-type"] or false) then
        standee.highlightOn(gmNotes.highlight)
    end
end

function mapToStandeeInfoArea(x, y, z, scaleX, scaleY, flip, height)
    -- base position in x/y plane
    local vec = Vector(x * scaleX, y * scaleY, z)
    -- incline the plane by 35 degrees
    vec:rotateOver('x', -35)
    -- go up towards the standee top
    vec:add(Vector(0, height * scaleY, 0))
    -- counter the standee rotation
    if flip then
        vec:rotateOver('y', 180)
    end

    return vec
end

function clearStandee(standee)
    local stickers = {}
    standee.setDecals(stickers)
    standee.clearButtons()
end

function toggleCondition(guid, condition)
    local standee = getObjectFromGUID(guid)
    applyCondition { standee, condition }
end

function applyCondition(params)
    local standee = params[1]
    local condition = params[2]
    if standee ~= nil then
        local name = standee.getName()
        local nr = 0
        local inputs = standee.getInputs()
        if inputs ~= nil then
            nr = tonumber(inputs[1].value)
        end
        updateAssistant("POST", "applyCondition", { target = name, nr = nr, condition = condition }, updateState)
    end
end

LastSettingsUpdateTime = 0
Settings = {}
function updateSettings()
    if Time.time > LastSettingsUpdateTime + 1 then
        Settings = JSON.decode(Global.call("getSettings"))
        LastSettingsUpdateTime = Time.time
    end
end

function getSettings()
    updateSettings()
    return Settings or {}
end

function isEndOfRoundLootingEnabled()
    return getSettings()["enable-end-of-round-looting"] or false
end

function isHighlightCurrentFiguresEnabled()
    return getSettings()["enable-highlight-current-figurines"] or false
end

function isHighlightPastFiguresEnabled()
    return getSettings()["enable-highlight-past-figurines"] or false
end

function isXHavenEnabled()
    return getSettings()["enable-x-haven"] or false
end

function isInternalGameStateEnabled()
    return getSettings()["enable-internal-game-state"] or false
end

function hash(str)
    local h = 5381

    for c in str:gmatch "." do
        h = (bit.lshift(h, 5) + h) + string.byte(c)
    end
    return h
end

StateUpdaterTimer = nil
function updateCurrentState(forced)
    forced = forced or false
    if isInternalGameStateEnabled() or forced then
        -- Queue the update for next frame, that way we can avoid doing too many updates in the same frame
        if StateUpdaterTimer ~= nil then
            Wait.stop(StateUpdaterTimer)
        end
        StateUpdaterTimer = Wait.frames(function() processState(CurrentGameState:toState()) end)
    end
end

function updateAssistant(method, command, params, callback)
    local handled = false
    if isInternalGameStateEnabled() then
        if method == "GET" then
            if command == "state" then
                -- ignore recurring state updates whne embedding the assistant, no state change
                -- can happen without our input
                --returnCurrentState(callback)
                handled = true
            elseif command == "getLoot" then
                local result = CurrentGameState:getLoot()
                processLoot(result, params.mode)
                handled = true
            end
        elseif method == "POST" then
            if command == "addCharacter" then
                CurrentGameState:addCharacter(params.character)
                updateCurrentState()
                handled = true
            elseif command == "removeCharacter" then
                CurrentGameState:removeCharacter(params.character)
                updateCurrentState()
                handled = true
            elseif command == "setScenario" then
                local result = CurrentGameState:prepareScenario(params.scenario)
                local battleInterfaceMat = getObjectFromGUID(BattleInterfaceMat)
                battleInterfaceMat.call('setLootDeck', CurrentGameState.loot)
                for color, guid in ipairs(PlayerMats) do
                    local mat = getObjectFromGUID(guid)
                    if mat ~= nil then
                        mat.call('shuffleAttackModifiers')
                    end
                end
                updateCurrentState()
                handled = true
            elseif command == "addMonster" then
                local instance = CurrentGameState:newMonsterInstance(params.monster, params.isBoss and "boss" or "normal")
                if instance ~= nil then
                    Wait.frames(
                        function()
                            callback({ response_code = 200, text = tostring(instance.nr) })
                            updateCurrentState()
                        end, 1)
                else
                    callback({ response_code = 404 })
                end
                handled = true
            elseif command == "change" then
                CurrentGameState:change(params.what, params.target, params.nr, params.change)
                updateCurrentState()
                handled = true
            elseif command == "startRound" then
                CurrentGameState:startRound(params)
                updateCurrentState()
                handled = true
            elseif command == "endRound" then
                CurrentGameState:endRound()
                updateCurrentState()
                handled = true
            elseif command == "applyCondition" then
                CurrentGameState:toggleCondition(params.condition, params.target, tonumber(params.nr))
                updateCurrentState()
                handled = true
            elseif command == "switchMonster" then
                CurrentGameState:switchMonster(params.monster, tonumber(params.nr))
                updateCurrentState()
                handled = true
            elseif command == "setElement" then
                CurrentGameState:setElement(params.element, params.state)
                updateCurrentState()
                handled = true
            elseif command == "endScenario" then
                CurrentGameState:endScenario()
                updateCurrentState()
                handled = true
            elseif command == 'setLevel' then
                CurrentGameState:setLevel(params.level or 0)
                updateCurrentState()
                handled = true
            elseif command == 'setCurrentTurn' then
                CurrentGameState:setCurrentTurn(params.name or "")
                updateCurrentState()
                handled = true
            elseif command == "changeInitiative" then
                CurrentGameState:changeInitiative(params.name, params.direction)
                updateCurrentState()
                handled = true
            elseif command == "setSection" then
                CurrentGameState:prepareSection(params.section or "<invalid>")
                updateCurrentState()
                handled = true
            elseif command == "loot" then
                -- Ignoring loot commands when using the internal game state
                handled = true
            elseif command == "addSummon" then
                CurrentGameState:addSummon(params.name)
                updateCurrentState()
                handled = true
            elseif command == "updateStandeeNr" then
                CurrentGameState:updateStandeeNr(params.name, params.nr, params.newNr)
                updateCurrentState()
                handled = true
            end
        end
    end
    if not handled and isXHavenEnabled() then
        local level = DEBUG
        if method == "GET" and command == "state" then
            level = INFO
        end
        fhlog(level, TAG, "updateAssistant: %s %s %s", method, command, params or "")
        local address = getSettings()["address"] or ""
        local port = getSettings()["port"] or ""
        if address ~= "" and port ~= "" then
            local url = "http://" .. address .. ":" .. port .. "/" .. command
            -- print(url)
            if method == "GET" then
                if callback ~= nil then
                    WebRequest.get(url, callback)
                else
                    -- fire and forget
                    WebRequest.get(url)
                end
            elseif method == "POST" then
                params = params or {}
                local payload = JSON.encode(params)
                -- print(command .. ":" .. payload)
                if callback ~= nil then
                    WebRequest.post(url, payload, callback)
                else
                    -- fire and forget
                    WebRequest.post(url, payload)
                end
            end
        end
    end
end

function getGMNotes(obj)
    local current = obj.getGMNotes()
    if current == nil or current == "" then
        current = {}
    else
        current = JSON.decode(current)
    end
    return current
end

function setSection(section)
    if isXHavenEnabled() then
        updateAssistant("POST", "setSection", { section = section })
    end
end

LastColorToDraw = nil
function drawAttackModifier(color, alt)
    if not alt and LastColorToDraw ~= nil and color ~= LastColorToDraw then
        Global.call("recoverAttackModifiers", LastColorToDraw)
    end
    LastColorToDraw = color
    if alt then
        Global.call("playerShuffle", { color = color })
    else
        Global.call("playerDraw", { color = color })
    end
end

function setErrata(errata)
    if ErrataPosition ~= nil then
        -- Clear possible existing errata 'button'
        for _, button in ipairs(self.getButtons() or {}) do
            if button.width == 0 and button.height == 0 then
                local buttonPosition = button.position
                local dx = buttonPosition.x + ErrataPosition.x -- x is flipped
                local dz = buttonPosition.z - ErrataPosition.z

                if dx * dx + dz * dz < 0.1 then
                    self.removeButton(button.index)
                end
            end
        end

        -- No need to add an errata button if there's nothing to show
        if errata ~= nil and errata ~= "" then
            local params = {
                function_owner = self,
                click_function = "noop",
                label = "Errata : " .. errata,
                position = { -ErrataPosition.x, ErrataPosition.y + 0.5, ErrataPosition.z },
                width = 0,
                height = 0,
                font_size = 200,
                color = { 0, 0, 0, 1 },
                scale = { 1, 1, 1 },
                font_color = { 1, 1, 1, 1 },
                rotation = { 0, 180, 0 },
            }
            self.createButton(params)
        end
    end
end

function playNarrationInAssistant(file)
    updateAssistant("GET", "play/" .. file)
end

function setCurrentTurn(name)
    updateAssistant("POST", "setCurrentTurn", { name = name }, updateState)
end

function onScenarioCompleted()
    if isXHavenEnabled() then
        -- The params are ignored by the GET, but used for the internal game state mode
        updateAssistant("GET", "getLoot", { mode = "complete" },
            function(request) onLootReceived(request, "complete") end)
    else
        broadcastToAll('X-Haven integration is off. Please collect loot, xps and inspiration manually')
    end
    Global.call("onScenarioCompleted")
end

function onScenarioLost()
    if isXHavenEnabled() then
        -- The params are ignored by the GET, but used for the internal game state mode
        updateAssistant("GET", "getLoot", { mode = "returnToFrosthaven" },
            function(request) onLootReceived(request, "returnToFrosthaven") end)
    else
        broadcastToAll('X-Haven integration is off. Please collect loot, xps and inspiration manually')
    end
end

function onScenarioRetry()
    if isXHavenEnabled() then
        -- The params are ignored by the GET, but used for the internal game state mode
        updateAssistant("GET", "getLoot", { mode = "retry" }, function(request) onLootReceived(request, "retry") end)
    else
        broadcastToAll('X-Haven integration is off. Please collect loot, xps and inspiration manually')
    end
end

function findPlayerMat(characterName)
    for color, guid in pairs(PlayerMats) do
        local mat = getObjectFromGUID(guid)
        if mat ~= nil then
            if mat.call('getCharacterName') == characterName then
                return mat
            end
        end
    end
    return nil
end

function onLootReceived(request, mode)
    if request.is_done and not request.is_error then
        if math.floor(request.response_code / 100) == 2 then
            local lootTable = JSON.decode(request.text)
            processLoot(lootTable, mode)
            return
        end
    end
    broadcastToAll("Error fetching loot from assistant")
end

function processLoot(lootTable, mode)
    local lootByCharacter = {}
    -- Filter loot based on mode
    for name, loot in pairs(lootTable.loot) do
        local actualLoot = {}
        for item, count in pairs(loot) do
            if item == "coin" or mode == "complete" or mode == "returnToFrosthaven" then
                if count > 0 then
                    actualLoot[item] = count
                end
            end
        end
        lootByCharacter[name] = actualLoot
    end

    -- print(JSON.encode(characterStates))

    for name, loot in pairs(lootByCharacter) do
        local playerMat = findPlayerMat(name)

        local message = ""
        for item, count in pairs(loot) do
            local additional = ""
            if item == "coin" then
                additional = " (" .. count * (lootTable.coinValue or 1) .. " gold)"
            end
            message = message .. count .. " " .. item .. additional .. ", "
        end
        local xp = (characterStates[name] or {})['xp'] or 0
        if mode == "complete" then
            xp = xp + lootTable.baseXp
        end
        if #loot > 0 then
            message = message .. "and "
        end
        message = message .. xp .. " xp"
        if playerMat ~= nil then
            broadcastToAll(name .. " received " .. message)
            if loot.coin ~= nil then
                loot.gold = loot.coin * (lootTable.coinValue or 1)
                loot.coin = nil
            end
            playerMat.call("endScenario", { loot = loot, xp = xp })
        else
            broadcastToAll("Could not find " .. name .. " player mat. " .. message .. " not collected")
        end
    end


    if mode == "complete" then
        -- Inpiration
        local inspiration = 4 - Global.call("getPlayerCount")
        if inspiration > 0 then
            local outpostMat = getObjectFromGUID(OutpostMatGuid)
            if outpostMat ~= nil then
                local campaignSheet = outpostMat.call("getCampaignSheet")
                if campaignSheet ~= nil then
                    broadcastToAll("Party gained " .. inspiration .. " inspiration")
                    campaignSheet.call("addEx", { name = "inspiration", amount = inspiration })
                end
            end
        end

        -- Mark scenario complete
        -- Tell the campaign tracker(s) this scenario is complete
        if CurrentScenario ~= nil and CurrentScenario.name ~= nil then
            for _, guid in ipairs(CampaignTrackerGuids) do
                local ct = getObjectFromGUID(guid)
                if ct ~= nil then
                    ct.call("setFieldOn", { field = "completed", name = CurrentScenario.name })
                end
            end
        end
    end

    -- Cleanup the assistant
    updateAssistant("POST", "endScenario", {}, updateState)

    -- Cleanup the scenario mat
    Global.call("cleanup", true)

    -- If retry, re-layout the scenario
    local oldScenario = CurrentScenario
    CurrentScenario = nil
    if mode == "retry" then
        Wait.time(function() Global.call("prepareScenarioEx", oldScenario) end, 1.0)
    end

    -- Collapse the End scenario UI
    toggleEndScenarioUI()
    return
end

function updateDifficulty(params)
    local difficulty = params.difficulty or 0
    local soloMode = params.soloMode or false
    -- determine base difficulty
    local playerCount = 0
    local playerLevelSum = 0
    for _, color in ipairs(PlayerColors) do
        local playerMat = getPlayerMat(color)
        if playerMat ~= nil then
            local character = playerMat.call("getCharacterName")
            if character ~= nil then
                playerCount = playerCount + 1
                local level = playerMat.call("getCharacterLevel") or 1
                playerLevelSum = playerLevelSum + level
            end
        end
    end
    local averageCharacters = 1
    if playerCount > 0 then
        averageCharacters = playerLevelSum / playerCount
    end
    if soloMode then
        averageCharacters = averageCharacters + 1
    end
    local baseLevel = math.ceil(averageCharacters / 2)
    local level = baseLevel + difficulty
    if level < 0 then level = 0 end
    if level > 7 then level = 7 end
    updateAssistant("POST", "setLevel", { level = level }, updateState)
end

function changeInitiative(params)
    updateAssistant("POST", "changeInitiative", params, updateState)
end

--[[
    params: {
        target_name: [character name] or nil
        player_color: [colorname] or nil
        player_number: [number] or nil
        count: [number] --number of loot to be processed
    }
]]
function doLoot(params)
    local targetName
    local targetColor
    if params.target_name ~= nil then
        targetName = params.target_name
        for color, character in pairs(Characters) do
            if character == targetName then
                targetColor = color
            end
        end
    else
        targetColor = params.player_color or PlayerColors[params.player_number]
        targetName = Characters[targetColor]
    end
    updateAssistant("POST", "loot", { target = targetName, count = params.count or 1 })
    -- update the local game state
    local battleInterfaceMat = getObjectFromGUID(BattleInterfaceMat)
    -- Who's playing this standee?
    battleInterfaceMat.call("onLootDraw", { color = targetColor })
    for n = 2, params.count or 1 do
        Wait.time(function() battleInterfaceMat.call("onLootDraw", { color = color }) end, 1,
            nbLoot - 1)
    end
end
