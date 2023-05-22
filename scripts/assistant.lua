require('json')

function onLoad(save)
    if save ~= nil then
        UIState = JSON.decode(save)
    end
    if UIState == nil then
        UIState = { minimized = true }
    end
    if UIState.minimized == nil then
        UIState.minimized = true
    end
    self.setLock(true)
    self.interactable = false
    Global.call('registerDataUpdatable', self)
    ButtonPositions = {}
    for _, point in ipairs(self.getSnapPoints()) do
        table.insert(ButtonPositions, point.position)
    end
    table.sort(ButtonPositions, XZSorter)
    -- Minimize & Maximize buttons
    addButton(ButtonPositions[1], "minimize", "Hide Round Tracker")
    addButton(ButtonPositions[2], "maximize", "Show Round Tracker")
    if UIState.minimized then
        minimize()
    end
    self.setDecals({})
end

function onSave()
    return JSON.encode(UIState)
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

function updateData(baseUrl)
    WebRequest.get(baseUrl .. "characterInitiatives.json", updateCharacterInitiatives)
    WebRequest.get(baseUrl .. "monsterStats.json", updateMonsterStats)
    WebRequest.get(baseUrl .. "monsterAbilities.json", updateMonsterAbilities)
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

PreviousNotes = ""
function updateInternal()
    self.clearButtons()
    -- Let's show one note at this time
    if State ~= nil then
        if State.notes ~= nil and #State.notes > 0 then
            if State.notes[1] ~= PreviousNotes then
                PreviousNotes = State.notes[1]
                broadcastToAll(PreviousNotes)
            end
        end
    end
    if not UIState.minimized and State ~= nil and CharacterInitiatives ~= nil and MonsterStats ~= nil and MonsterAbilities ~= nil then
        local decals = {}
        local currentX = 2.775
        local currentZ = -.5
        local lastActive = 0
        for i, entry in ipairs(State.entries) do
            if entry.active or false then
                lastActive = i
            end
        end
        for i, entry in ipairs(State.entries) do
            local name = entry.name
            local type = entry.type
            local turnState = entry.turnState

            if type == "monster" then
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
            elseif type == "character" then
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
                    -- cancel the upcoming position change, as this is a 'fake' character
                    currentX = currentX + 1.85
                end

                -- Render controls to override a player turn order, if the round has started
                if State.round.state == 1 then
                    if i ~= 1 then
                        -- Add a button to lower the player initiative
                        local url =
                        "http://cloud-3.steamusercontent.com/ugc/2035105157823185573/8BABEE86FE1085D5C001E6DD4EE1F1E040BF6D1D/"
                        table.insert(decals, getDecal(name .. "_faster", url, currentX + 0.55, currentZ, .1, .05))

                        local fName = "changeInitiative_down_" .. name
                        self.setVar(fName, function() changeInitiative(name, -1) end)
                        self.createButton(getButton(fName, currentX + 0.55, currentZ, 350, 350))
                    end
                    if i ~= lastActive then
                        -- Add a button to increase the player intitiative
                        local url =
                        "http://cloud-3.steamusercontent.com/ugc/2035105157823185619/529E35C0294D03A666C9EA9C924105F40F07697F/"
                        table.insert(decals, getDecal(name .. "_slower", url, currentX - 0.55, currentZ, .1, .05))

                        local fName = "changeInitiative_up_" .. name
                        self.setVar(fName, function() changeInitiative(name, 1) end)
                        self.createButton(getButton(fName, currentX - 0.55, currentZ, 350, 350))
                    end
                end
            end

            if turnState == 1 then
                local url =
                "http://cloud-3.steamusercontent.com/ugc/2036234357198527450/F51CB2841C00E8ACF74FA5E00D59A018B6FA93F2/"
                table.insert(decals, getDecal("current", url, currentX, currentZ + .25, 2.3, .05))
            end

            -- Add a button to change the turn state, if the round has started
            if State.round.state == 1 then
                local fName = "setCurrent_" .. i
                self.setVar(fName, function() setCurrent(name) end)
                self.createButton(getButton(fName, currentX, currentZ, 350, 350))
            end

            -- Vertical layout
            -- currentZ = currentZ + 0.55
            -- if currentZ > 1 then
            --     currentX = currentX - 1.85
            --     currentZ = -0.5
            -- end

            -- Horizontal layout
            currentX = currentX - 1.85
            if currentX < -3 then
                currentX = 2.775
                currentZ = currentZ + 0.55
            end
        end
        self.setDecals(decals)
    end
    -- Minimize & Maximize buttons
    addButton(ButtonPositions[1], "minimize", "Hide Round Tracker")
    addButton(ButtonPositions[2], "maximize", "Show Round Tracker")
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

function getButton(fName, x, z, w, h)
    return {
        label          = "",
        function_owner = self,
        click_function = fName,
        position       = { -x, 0.06, z },
        width          = w,
        height         = h,
        font_size      = 40,
        color          = { 1, 1, 1, 0 },
        scale          = { 0.5, 0.5, 0.5 },
        font_color     = { 0, 0, 0, 1 },
        tooltip        = ""
    }
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
