require("json")
require("savable")
require('data/map_decals')

-- Savable functions
function getState()
    return State
end

function onStateUpdate(state)
    State = state
    refreshDecals()
end

function createEmptyState()
    return { enabledDecals = {}, buildings = {}, completedDecals = {} }
end

function onLoad(save)
    if save ~= nil then
        State = JSON.decode(save)
    end
    if State == nil then
        State = createEmptyState()
    end

    createButtons()

    registerSavable("World Map")
    Global.call('registerDataUpdatable', self)
end

function onSave()
    return JSON.encode(State)
end

function updateData(params)
    local baseUrl = params.baseUrl
    local first = params.first
    if baseUrl ~= "https://gudyfr.github.io/fhtts/" or not first then
        WebRequest.get(baseUrl .. "map_decals.json", processDecalInfo)
    end
end

function compareX(obj1, obj2)
    if obj1.x < obj2.x then
        return true
    else
        return false
    end
end

function printLocations()
    local decals = self.getDecals()
    print(JSON.encode(decals))
end

function processDecalInfo(request)
    Map_decals = jsonDecode(request.text)
    createButtons()
end

function createButtons()
    if Map_decals ~= nil and Map_decals.outpost ~= nil then
        local outpostData = Map_decals.outpost
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
                    if State.buildings[name] == nil then
                        State.buildings[name] = info.min
                    end
                    -- Create a button with the location of the first decal in the list of decals for that building
                    local fName = "change_building_" .. name
                    self.setVar(fName, function(obj, player, alt) change_building(name, alt) end)

                    local tooltip
                    if State.buildings[name] == -1 then
                        tooltip = "Unlock " .. name
                    else
                        if State.buildings[name] == 0 then
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
    if State.enabledDecals[entry.name] ~= nil and State.enabledDecals[entry.name] then
        State.enabledDecals[entry.name] = false
    else
        State.enabledDecals[entry.name] = true
    end
    refreshDecals()
end

function complete(entry)
    if State.completedDecals[entry.name] or false then
        State.completedDecals[entry.name] = false
    else
        State.completedDecals[entry.name] = true
    end
end

function change_building(name, alt)
    local info = Map_decals.outpost.buildings[name]
    local level = State.buildings[name]
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
    State.buildings[name] = level
    refreshDecals()
    local outpost = getObjectFromGUID('756956')
    outpost.call("setBuildingLevel", { name, level })
end

function setBuildingLevel(params)
    local name = params[1]
    local level = params[2]
    State.buildings[name] = level
    refreshDecals()
end

function toggleDecal(params)
    local name = params[1]
    local on = params[2]
    local completed = params[3] or false
    if name:sub(1, 4) == "map_" and on and not (State.enabledDecals[name] or false) then
        broadcastToAll("Adding sticker " .. name:sub(5):upper() .. " to the map")
    end
    State.enabledDecals[name] = on
    State.completedDecals[name] = completed
    refreshDecals()
end

function refreshDecals()
    if devMode then
        stickers = {}
        self.setDecals(stickers)
        clearButtons()
    else
        if Map_decals ~= nil then
            stickers = {}
            -- Scenario decals
            if Map_decals.scenarios ~= nil then
                for _, entry in ipairs(Map_decals.scenarios) do
                    if State.enabledDecals[entry.name] or false then
                        if State.completedDecals[entry.name] or false then
                            entry.url = entry.completed
                        else
                            entry.url = entry.revealed
                        end
                        table.insert(stickers, entry)
                    end
                end
            end

            -- Outpost decals
            if Map_decals.outpost ~= nil then
                -- Buildings
                if Map_decals.outpost.buildings ~= nil then
                    for building, info in pairs(Map_decals.outpost.buildings) do
                        if State.buildings[building] == nil then
                            State.buildings[building] = info.min
                        end
                        local index
                        if State.buildings[building] ~= info.min then
                            index = State.buildings[building] - info.min
                        end
                        local decal = info.decals[index]
                        if decal ~= nil then
                            table.insert(stickers, decal)
                        end
                    end
                end
                -- Others
                if Map_decals.outpost.others ~= nil then
                    for _, entry in ipairs(Map_decals.outpost.others) do
                        if State.enabledDecals[entry.name] ~= nil and State.enabledDecals[entry.name] then
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
