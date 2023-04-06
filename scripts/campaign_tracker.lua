require("json")

function load(state, url)
    if state ~= nil then
        scenariosState = JSON.decode(state)
    end

    if scenariosState == nil then
        scenariosState = {}
    end
    WebRequest.get(url, processDecals)
end

function save()
    return JSON.encode(scenariosState)
end

function ensureState(scenario)
    if scenariosState[scenario] == nil then
        scenariosState[scenario] = {
            unlocked = false,
            completed = false,
            blocked = false,
        }
    end
    return scenariosState[scenario]
end

function isUnlocked(scenario)
    return ensureState(scenario)["unlocked"]
end

function isCompleted(scenario)
    return ensureState(scenario)["completed"]
end

function isBlocked(scenario)
    return ensureState(scenario)["blocked"]
end

scenarioData = {}

function getToggleFunctionName(scenario, field)
    return "toggle_" .. field .. "_" .. scenario .. "_"
end

function processDecals(request)
    if request.text ~= nil then
        data = jsonDecode(request.text)
        if data ~= nil then
            for _, entry in pairs(data) do
                local scenario = entry.name
                scenarioData[scenario] = entry
                self.setVar(getToggleFunctionName("unlocked", scenario), function() toggle(scenario, "unlocked") end)
                self.setVar(getToggleFunctionName("blocked", scenario), function() toggle(scenario, "blocked") end)
                self.setVar(getToggleFunctionName("completed", scenario), function() toggle(scenario, "completed") end)
                self.setVar("load_" .. scenario .. "_", function() loadScenario(scenario) end)
                addButtons(scenario)
            end
            refreshDecals()
        end
    end
end

function removeButtons(scenario)
    local offset = 0
    for _, button in ipairs(self.getButtons()) do
        local fName = button.click_function
        if string.find(fName, "_" .. scenario .. "_") then
            self.removeButton(button.index - offset)
        end
    end
end

function addButtons(scenario)
    local entry = scenarioData[scenario]
    local fName = getToggleFunctionName("unlocked", scenario)
    local unlocked, zOffset, tooltip, scale, xOffset
    if isUnlocked(scenario) then
        unlocked = true
        zOffset = -0.1
        tooltip = "Hide this scenario"
        scale = { .2, .2, .1 }
    else
        unlocked = false
        zOffset = 0
        tooltip = "Unlock Scenario"
        scale = { .2, .2, .2 }
    end
    local params = {
        function_owner = self,
        click_function = fName,
        label          = "",
        position       = { -(entry.position.x), entry.position.y, entry.position.z + zOffset },
        width          = 200,
        height         = 200,
        font_size      = 50,
        color          = { 1, 1, 1, 0 },
        scale          = scale,
        font_color     = { 1, 1, 1, 0 },
        tooltip        = tooltip
    }
    self.createButton(params)

    if unlocked then
        -- Add the block button
        if entry.lockable ~= nil and entry.lockable then
            fName = getToggleFunctionName("blocked", scenario)
            zOffset = 0.025
            if isBlocked(scenario) then
                tooltip = "Unblock the scenario"
            else
                tooltip = "Block the scenario"
            end
            params = {
                function_owner = self,
                click_function = fName,
                label          = "",
                position       = { -(entry.position.x), entry.position.y + 0.01, entry.position.z + zOffset },
                width          = 200,
                height         = 200,
                font_size      = 50,
                color          = { 1, 1, 1, 0 },
                scale          = { .2, .2, .2 },
                font_color     = { 1, 1, 1, 0 },
                tooltip        = tooltip
            }
            self.createButton(params)
        end

        -- Completed button
        local label = ""
        if isCompleted(scenario) then
            tooltip = "Mark as incomplete"
            label = "\u{2717}"
        else
            tooltip = "Mark as complete"
        end
        fName = getToggleFunctionName("completed", scenario)
        zOffset = -(0.043 + (entry.zOffset or 0))
        xOffset = 0.116
        local size = entry.size or 1
        if size == 2 then
            xOffset = 0.14
        elseif size == 0 then
            xOffset = 0.092
        elseif size == 3 then
            xOffset = 0.176
        end
        params = {
            function_owner = self,
            click_function = fName,
            label          = label,
            position       = { -(entry.position.x + xOffset), entry.position.y + 0.01, entry.position.z + zOffset },
            width          = 200,
            height         = 200,
            font_size      = 200,
            color          = { 1, 1, 1, 0 },
            scale          = { .05, .05, .05 },
            font_color     = { 0, 0, 0, 100 },
            tooltip        = tooltip
        }
        self.createButton(params)
        -- Load Scenario Button
        tooltip = "Load the scenario"
        params = {
            function_owner = self,
            click_function = "load_" .. scenario .. "_",
            label          = "",
            position       = { -(entry.position.x), entry.position.y + 0.01, entry.position.z + zOffset },
            width          = 200,
            height         = 200,
            font_size      = 50,
            color          = { 1, 1, 1, 0 },
            scale          = { .45, .05, .05 },
            font_color     = { 0, 0, 0, 1 },
            tooltip        = tooltip
        }
        self.createButton(params)
    end
end

function toggleCompleted(params)
    -- print(JSON.encode(params))
    local scenario = "ct" .. params[1]
    local completed = params[2]
    -- Check that this scenario is handled on this tracker instance
    if scenarioData ~= nil and scenarioData[scenario] ~= nil then
        local state = ensureState(scenario)
        if state["completed"] ~= completed then
            toggle(scenario, "completed")
        end
    end
end

function toggle(scenario, field)
    print('toggle ' .. scenario .. " / " .. field)
    if ensureState(scenario)[field] then
        scenariosState[scenario][field] = false
    else
        scenariosState[scenario][field] = true
    end

    refreshDecals()
    removeButtons(scenario)
    addButtons(scenario)

    if field == "unlocked" or field == "completed" then
        local params = { scenario, isUnlocked(scenario), isCompleted(scenario) }

        -- notify the map
        getObjectFromGUID('d17d72').call("toggleDecal", params)

        -- notify the books for completed change
        if field == "completed" then
            getObjectFromGUID('2a1fbe').call("toggleCompleted", params)
        end
    end

    if field == "completed" then
        if scenarioData[scenario].trigger ~= nil then
            -- Add some map overlays upon completion of certain scenarios
            local params = { scenarioData[scenario].trigger, isCompleted(scenario) }
            getObjectFromGUID('d17d72').call("toggleDecal", params)
        end
    end

    -- Always notify the scenario picker of scenario changes
    local scenarioState = scenariosState[scenario] or {}
    getObjectFromGUID('596fc4').call("updateScenario", {
        string.sub(scenario,3),
        scenarioState.unlocked or false,
        scenarioState.blocked or false,
        scenarioState.completed or false })
end

function refreshDecals()
    if data ~= nil then
        stickers = {}
        for _, entry in pairs(data) do
            scenario = entry.name
            if isUnlocked(scenario) then
                table.insert(stickers, entry)
                if isBlocked(scenario) then
                    local blockedEntry = {
                        name = "blocked",
                        position = { entry.position.x, entry.position.y + 0.01, entry.position.z + 0.025 },
                        rotation = entry.rotation,
                        scale = { .07, .07, .07 },
                        url =
                        "http://cloud-3.steamusercontent.com/ugc/2035103293438183450/6B46499301873CC68D0CE6926E9EA419CCED7A07/",
                    }
                    table.insert(stickers, blockedEntry)
                end
            end
        end
        self.setDecals(stickers)
    end
end

function loadScenario(scenario)
    local name = string.sub(scenario, 3)
    Global.call("prepareFrosthavenScenario", name)
end
