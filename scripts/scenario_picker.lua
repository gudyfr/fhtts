require("number_decals")
require("savable")

DevMatGuid = '91d8f9'
IsDevMat = false

-- Savable functions
function getState()
    return State
end

function onStateUpdate(state)
    State = state
    updateStickers()
end

function createEmptyState()
    local state = {
        active = "available",
        page = 1,
        scenarios = {},
        soloCompletion = {},
    }
    if IsDevMat then
        -- Development scenario picker
        for i=0,153 do
            state.scenarios[tostring(i)] = {
                available = true,
                locked = false,
                completed = false,
                solo = i > 137
            }
        end
    end

    return state
end

function onLoad(save)
    IsDevMat = self.guid == DevMatGuid
    
    if save ~= nil then
        State = JSON.decode(save)
    end

    if State == nil then
        State = createEmptyState()
    end

    if State.soloCompletion == nil then
        State.soloCompletion = {}
    end

    updateStickers()
    registerSavable("Scenario Picker")
end

function onSave()
    return JSON.encode(State)
end

function updateStickers()
    -- Remove all Buttons
    local btns = self.getButtons() or {}
    for _, btn in ipairs(btns) do
        self.removeButton(btn.index)
    end

    local stickers = {}
    -- Update tabs
    if not IsDevMat then
        local active = State.active or "available"
        local tabs = { "available", "completed", "all" }
        for index, tab in ipairs(tabs) do
            addTabSticker(stickers, index, tab, active)
            addTabButton(index, tab, active)
        end
    end

    -- Update scenarios
    local scenarios = getActiveScenarios()
    table.sort(scenarios, compareNameAsNumber)
    local perPage = 11
    if IsDevMat then
        perPage = 12
    end
    local pages = math.floor((#scenarios + perPage - 1) / perPage)
    local index = 1
    local startIndex = ((State.page or 1) - 1) * perPage + 1
    local endIndex = startIndex + perPage - 1
    for _, scenario in ipairs(scenarios) do
        if index >= startIndex and index <= endIndex then
            addScenarioSticker(stickers, index - startIndex + 1, scenario)
            addScenarioButton(index - startIndex + 1, scenario)
        end
        index = index + 1
    end

    addPagesStickersAndButtons(stickers, State.page, pages)

    self.setDecals(stickers)
end

function compareNameAsNumber(obj1, obj2)
    return tonumber(obj1) < tonumber(obj2)
end

TabPositions = { 1.2, 0, -1.2 }
TabUrls = {
    available = {
        "http://cloud-3.steamusercontent.com/ugc/2035105157823188234/64E5E4B8C391B2F4A1A891835A5CC70A3E83A17A/",
        "http://cloud-3.steamusercontent.com/ugc/2035105157823188104/1F91FAE60DA82460FEFD95754DF871AA4FA058DA/" },
    completed = {
        "http://cloud-3.steamusercontent.com/ugc/2035105157823188190/2342C867E3081E4D2B2582FB537770F54435D1C2/",
        "http://cloud-3.steamusercontent.com/ugc/2035105157823188067/D3ADFFD0C54558A0B3E674800C3A7269295E2E3D/" },
    all = {
        "http://cloud-3.steamusercontent.com/ugc/2035105157823188142/C2AE33FE105BB70DD9E412DF2E1C9BD328A25BA6/",
        "http://cloud-3.steamusercontent.com/ugc/2035105157823188026/BDE7153394ACE22B33889541873779682ED3C765/"
    }
}
function addTabSticker(stickers, position, name, active)
    local index
    if name == active then
        index = 2
    else
        index = 1
    end
    local sticker = {
        position = { TabPositions[position], 0.06, -1.435 },
        scale = { 1, .25, .15 },
        rotation = { 90, 180, 0 },
        url = TabUrls[name][index],
        name = name .. "_" .. index,
    }
    table.insert(stickers, sticker)
end

function addScenarioSticker(stickers, position, name)
    local url = "https://gudyfr.github.io/fhtts/images/stickers/scenario%20picker/" .. name .. ".png"
    local minZ = -1.40
    if IsDevMat then
        minZ = -1.65
    end

    local sticker = {
        position = { 0, 0.06, minZ+ position * 0.25 },
        scale = { 3.6, .25, .15 },
        rotation = { 90, 180, 0 },
        url = url,
        name = "scenario_" .. name,
    }
    table.insert(stickers, sticker)
end

function addPagesStickersAndButtons(stickers, page, pages)
    -- stickers
    -- http://cloud-3.steamusercontent.com/ugc/2035105157823185671/49A5CAF0B4E8567D99DBB6736E739F6514244518/
    local yPosition = 1.725

    local sticker = {
        position = { 0.1, 0.06, yPosition },
        scale = { .25, .25, .15 },
        rotation = { 90, 180, 0 },
        url = NumberDecals[page + 1],
        name = "page_" .. page,
    }
    table.insert(stickers, sticker)
    sticker = {
        position = { 0, 0.06, yPosition },
        scale = { .25, .25, .15 },
        rotation = { 90, 180, 0 },
        url = "http://cloud-3.steamusercontent.com/ugc/2035105157823185671/49A5CAF0B4E8567D99DBB6736E739F6514244518/",
        name = "slash",
    }
    table.insert(stickers, sticker)
    sticker = {
        position = { -0.1, 0.06, yPosition },
        scale = { .25, .25, .15 },
        rotation = { 90, 180, 0 },
        url = NumberDecals[pages + 1],
        name = "pages_" .. pages,
    }
    table.insert(stickers, sticker)

    if page ~= 1 then
        -- left arrow sticker and button
        sticker = {
            position = { 0.3, 0.06, yPosition },
            scale = { .15, .05, .05 },
            rotation = { 90, 180, 0 },
            url = "http://cloud-3.steamusercontent.com/ugc/2035105157823185573/8BABEE86FE1085D5C001E6DD4EE1F1E040BF6D1D/",
            name = "previous",
        }
        table.insert(stickers, sticker)
        local params = {
            function_owner = self,
            click_function = "prevPage",
            label          = "",
            position       = { -0.3, 0.06, yPosition },
            width          = 200,
            height         = 220,
            font_size      = 100,
            color          = { 1, 1, 1, 0 },
            scale          = { 0.5, 1, .25 },
            font_color     = { 0, 0, 0, 100 },
        }
        self.createButton(params)
    end

    if page ~= pages then
        -- right arrow sticker and button
        sticker = {
            position = { -0.3, 0.06, yPosition },
            scale = { .15, .05, .05 },
            rotation = { 90, 180, 0 },
            url = "http://cloud-3.steamusercontent.com/ugc/2035105157823185619/529E35C0294D03A666C9EA9C924105F40F07697F/",
            name = "previous",
        }
        table.insert(stickers, sticker)
        local params = {
            function_owner = self,
            click_function = "nextPage",
            label          = "",
            position       = { 0.3, 0.06, yPosition },
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

function prevPage()
    State.page = State.page - 1
    updateStickers()
end

function nextPage()
    State.page = State.page + 1
    updateStickers()
end

function addTabButton(index, tab, active)
    if active ~= tab then
        local fName = "toggle_tab_" .. tab
        self.setVar(fName, function() toggleTab(tab) end)
        local params = {
            function_owner = self,
            click_function = fName,
            label          = "",
            position       = { -TabPositions[index], 0.06, -1.435 },
            width          = 500,
            height         = 220,
            font_size      = 100,
            color          = { 1, 1, 1, 0 },
            scale          = { 1, 1, .5 },
            font_color     = { 0, 0, 0, 100 },
        }
        self.createButton(params)
    end
end

function addScenarioButton(index, scenario)
    local fName = "loadScenario_" .. scenario
    self.setVar(fName, function() loadScenario(scenario) end)
    local minZ = -1.40
    if IsDevMat then
        minZ = -1.65
    end
    local params = {
        function_owner = self,
        click_function = fName,
        label          = "",
        position       = { 0, 0.06, minZ + index * 0.25 },
        width          = 1600,
        height         = 220,
        font_size      = 100,
        color          = { 1, 1, 1, 0 },
        scale          = { 1, 1, .5 },
        font_color     = { 0, 0, 0, 100 },
    }
    self.createButton(params)
end

function loadScenario(scenario)
    if State.scenarios[scenario].solo or false then
        Global.call("prepareSoloScenario", scenario)
    else
        Global.call("prepareFrosthavenScenario", scenario)
    end
end

function toggleTab(tab)
    State.active = tab
    State.page = 1
    updateStickers()
end

function updateScenario(params)
    local scenario = params[1]
    local available = params[2] or false
    local locked = params[3] or false
    local completed = params[4] or false
    local scenarios = State.scenarios
    if scenarios == nil then
        scenarios = {}
        State.scenarios = scenarios
    end
    if scenario ~= nil then
        scenarios[scenario] = {
            available = available,
            locked = locked,
            completed = completed
        }
        updateStickers()
    end
end

function updateSoloScenario(params)
    local name = params[1]
    local completed = params[2]
    State.soloCompletion[name] = completed
    local scenario = State.scenarios[name]
    if scenario ~= nil then
        scenario.completed = params
        updateStickers()
    end
end

function getActiveScenarios()
    local result = {}
    local active = State.active or "available"
    for name, scenarioState in pairs(State.scenarios or {}) do
        if scenarioState.available or false then
            if scenarioState.locked or false then
                -- Only add locked scenarios to "All" tab
                if active == "all" then
                    table.insert(result, name)
                end
            elseif scenarioState.completed or false then
                -- Only add completed scenarios to "All" and "Completed" tabs
                if active == "all" or active == "completed" then
                    table.insert(result, name)
                end
            else
                -- Only add non completed scenarios to "All" and "Available" tabs
                if active == "all" or active == "available" then
                    table.insert(result, name)
                end
            end
        end
    end

    return result
end

local CharacterNamesToSoloScenario = {
    Drifter = "138",
    Blinkblade = "139",
    ["Banner Spear"] = "140",
    Deathwalker = "141",
    Boneshaper = "142",
    Geminate = "143",
    Infuser = "144",
    Pyroclast = "145",
    Shattersong = "146",
    Trapper = "147",
    ['Pain Conduit'] = "148",
    Snowdancer = "149",
    ['Frozen Fist'] = "150",
    ['H.I.V.E.'] = "151",
    ['Metal Mosaic'] = "152",
    Deepwraith = "153",
    ['Crashing Tide'] = "154",
}

function addSoloFor(characterName)
    local scenario = CharacterNamesToSoloScenario[characterName]
    if scenario ~= nil then
        local scenarios = State.scenarios
        if scenarios == nil then
            scenarios = {}
            State.scenarios = scenarios
        end
        scenarios[scenario] = {
            available = true,
            locked = false,
            completed = State.soloCompletion[scenario] or false,
            solo = true
        }
        updateStickers()
    end
end

function removeSoloFor(characterName)
    local scenario = CharacterNamesToSoloScenario[characterName]
    if scenario ~= nil then
        local scenarios = State.scenarios
        if scenarios == nil then
            scenarios = {}
            State.scenarios = scenarios
        end
        scenarios[scenario] = {
            available = false,
            locked = false,
            completed = false,
            solo = true,
        }
        updateStickers()
    end
end
