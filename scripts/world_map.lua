require("json")

devMode = false

function onLoad(save)
    decalInfoUrl =
    "https://gudyfr.github.io/fhtts/map_decals.json"
    if save ~= nil then
        state = JSON.decode(save)
        if state ~= nil and state.enabledDecals == nil then
            -- migrate from previous schema
            local tmp = {}
            tmp.enabledDecals = state
            tmp.buildings = {}
            state = tmp
        end
    end
    if state == nil then
        state = { enabledDecals = {}, buildings = {}, completedDecals = {} }
    end
    if state.completedDecals == nil then
        state.completedDecals = {}
    end

    -- Create dev buttons
    if devMode then
        local positions = {}
        for _, point in ipairs(self.getSnapPoints()) do
            table.insert(positions, point.position)
        end
        table.sort(positions, compareX)
        if positions[1] ~= nil then
            local position = positions[1]
            local params   = {
                function_owner = self,
                click_function = "toggleDevMode",
                label          = "Dev Mode",
                position       = { -(position.x), position.y, position.z },
                width          = 200,
                height         = 200,
                font_size      = 50,
                color          = { 1, 1, 1, 1 },
                scale          = { .3, .3, .3 },
                font_color     = { 0, 0, 0, 1 },
                tooltip        = ""
            }
            self.createButton(params)
        end
        if positions[2] ~= nil then
            local position = positions[2]
            local params   = {
                function_owner = self,
                click_function = "printLocations",
                label          = "Print",
                position       = { -(position.x), position.y, position.z },
                width          = 200,
                height         = 200,
                font_size      = 50,
                color          = { 1, 1, 1, 1 },
                scale          = { .3, .3, .3 },
                font_color     = { 0, 0, 0, 1 },
                tooltip        = ""
            }
            self.createButton(params)
        end
    else
        WebRequest.get(decalInfoUrl, processDecalInfo)
    end
end

function onSave()
    return JSON.encode(state)
end

function compareX(obj1, obj2)
    if obj1.x < obj2.x then
        return true
    else
        return false
    end
end

function toggleDevMode()
    if devMode then
        clearButtons()
    else
        createButtons()
    end
    devMode = not devMode
    refreshDecals()
end

function printLocations()
    local decals = self.getDecals()
    print(JSON.encode(decals))
end

function processDecalInfo(request)
    -- print("Parsing Map")
    decalInfos = jsonDecode(request.text)
    createButtons()
end

function createButtons()
    if decalInfos ~= nil and decalInfos.outpost ~= nil then
        local outpostData = decalInfos.outpost
        if outpostData.others ~= nil then
            for _, entry in pairs(outpostData.others) do
                local fName = "toggle_" .. entry.name
                self.setVar(fName, function() toggle(entry) end)
                local name
                local tooltip
                name = ""
                tooltip = "Toggle " .. string.sub(entry.name, 4, 5)

                local params = {
                    function_owner = self,
                    click_function = fName,
                    label          = name,
                    position       = { -(entry.position.x), entry.position.y, entry.position.z },
                    width          = 200,
                    height         = 200,
                    font_size      = 50,
                    color          = { 1, 1, 1, 0 },
                    scale          = { .3, .3, .3 },
                    font_color     = { 1, 1, 1, 0 },
                    tooltip        = tooltip
                }
                self.createButton(params)
            end
        end
        if outpostData.buildings ~= nil then
            for name, info in pairs(outpostData.buildings) do
                if info ~= nil then
                    if state.buildings[name] == nil then
                        state.buildings[name] = info.min
                    end
                    -- Create a button with the location of the first decal in the list of decals for that building
                    local fName = "change_building_" .. name
                    self.setVar(fName, function(obj, player, alt) change_building(name, alt) end)

                    local tooltip
                    if state.buildings[name] == -1 then
                        tooltip = "Unlock " .. name
                    else
                        if state.buildings[name] == 0 then
                            tooltip = "Build " .. name .. " (right click to lock)"
                        else
                            tooltip = "Upgrade " .. name .. " (right click to Degrade)"
                        end
                    end

                    local entry = info.decals[1]

                    local params = {
                        function_owner = self,
                        click_function = fName,
                        label          = name,
                        position       = { -(entry.position.x), entry.position.y, entry.position.z },
                        width          = 200,
                        height         = 200,
                        font_size      = 50,
                        color          = { 1, 1, 1, 0 },
                        scale          = { .3, .3, .3 },
                        font_color     = { 1, 1, 1, 0 },
                        tooltip        = tooltip
                    }
                    self.createButton(params)
                end
            end
        end
    end
    refreshDecals()
end

function toggle(entry)
    if state.enabledDecals[entry.name] ~= nil and state.enabledDecals[entry.name] then
        state.enabledDecals[entry.name] = false
    else
        state.enabledDecals[entry.name] = true
    end
    refreshDecals()
end

function complete(entry)
    if state.completedDecals[entry.name] or false then
        state.completedDecals[entry.name] = false
    else
        state.completedDecals[entry.name] = true
    end
end

function change_building(name, alt)
    local info = decalInfos.outpost.buildings[name]
    local level = state.buildings[name]
    local decals = info.decals
    local change
    if alt then
        change = -1
    else
        change = 1
    end
    level = level + change
    if level < info.min then
        level = info.min
    elseif level - info.min > #decals then
        level = #decals + info.min
    end
    state.buildings[name] = level
    --print(JSON.encode(state.buildings))
    refreshDecals()
end

function toggleDecal(params)
    local name = params[1]
    local on = params[2]
    local completed = params[3] or false
    state.enabledDecals[name] = on
    state.completedDecals[name] = completed
    refreshDecals()
end

function refreshDecals()
    if devMode then
        stickers = {}
        self.setDecals(stickers)
        clearButtons()
    else
        if decalInfos ~= nil then
            stickers = {}
            -- Scenario decals
            if decalInfos.scenarios ~= nil then
                for _, entry in ipairs(decalInfos.scenarios) do
                    if state.enabledDecals[entry.name] or false then
                        if state.completedDecals[entry.name] or false then
                            entry.url = entry.completed
                        else
                            entry.url = entry.revealed
                        end
                        table.insert(stickers, entry)
                    end
                end
            end

            -- Outpost decals
            if decalInfos.outpost ~= nil then
                -- Buildings
                if decalInfos.outpost.buildings ~= nil then
                    for building, info in pairs(decalInfos.outpost.buildings) do
                        if state.buildings[building] == nil then
                            state.buildings[building] = info.min
                        end
                        local index
                        if state.buildings[building] ~= info.min then
                            index = state.buildings[building] - info.min
                        end
                        local decal = info.decals[index]
                        if decal ~= nil then
                            table.insert(stickers, decal)
                        end
                    end
                end
                -- Others
                if decalInfos.outpost.others ~= nil then
                    for _, entry in ipairs(decalInfos.outpost.others) do
                        if state.enabledDecals[entry.name] ~= nil and state.enabledDecals[entry.name] then
                            table.insert(stickers, entry)
                        end
                    end
                end
            end
            self.setDecals(stickers)
        end
    end
end

function clearButtons()
    for _, button in ipairs(self.getButtons()) do
        self.removeButton(button.index)
    end
end
