require("json")
require("savable")
require('data/map_decals')

MapImages = {
    map         = 'http://cloud-3.steamusercontent.com/ugc/2028354869645264961/26F5991D9CF784EF2A3FC0284D52ED64306BABF3/',
    map_w       = 'http://cloud-3.steamusercontent.com/ugc/2028354869645265086/89684AB440A99382FA31176A67F214EA527D7E5F/',
    map_w_x     = 'http://cloud-3.steamusercontent.com/ugc/2028354869645265242/0CBFAB4D1F25E62521056ABF0FAE953905D587EB/',
    map_w_z     = 'http://cloud-3.steamusercontent.com/ugc/2028354869645265720/99A1E452A5E79BBE6412951EDA5939814A3C318C/',
    map_w_x_y   = 'http://cloud-3.steamusercontent.com/ugc/2028354869645265369/4DA218CBC0620C285B8F2442E5F7D89527EF9190/',
    map_w_x_z   = 'http://cloud-3.steamusercontent.com/ugc/2028354869645265593/993D3CFF858022801C66682721B025A14A91E973/',
    map_w_x_y_z = 'http://cloud-3.steamusercontent.com/ugc/2028354869645265479/729EDCBA368C46736ABF9A5604ACABF1E2F3E7F3/',
}

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
    if Map_decals ~= nil and Map_decals.scenarios ~= nil then
        for _, entry in ipairs(Map_decals.scenarios) do
            if entry.name == "map_z" then
                createToggleButton(entry)
            end
        end
    end
    if Map_decals ~= nil and Map_decals.outpost ~= nil then
        local outpostData = Map_decals.outpost
        if outpostData.others ~= nil then
            for _, entry in pairs(outpostData.others) do
                createToggleButton(entry)
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

function createToggleButton(entry)
    local fName = "toggle_" .. entry.name
    self.setVar(fName, function() toggle(entry) end)
    local name
    local tooltip
    name = ""
    tooltip = "Toggle " .. (entry.display or string.sub(entry.name, 4, 5))

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

BuildingNames = {
    ["05"] = "Mining Camp",
    ["12"] = "Hunting Lodge",
    ["17"] = "Logging Camp",
    ["21"] = "Inn",
    ["24"] = "Garden",
    ["34"] = "Craftsman",
    ["35"] = "Alchemist",
    ["37"] = "Trading Post",
    ["39"] = "Jeweler",
    ["42"] = "Temple of the Great Oak",
    ["44"] = "Enhancer",
    ["65"] = "Metal Depot",
    ["67"] = "Lumber Depot",
    ["72"] = "Hide Depot",
    ["74"] = "Tavern",
    ["81"] = "Hall of Revelry",
    ["83"] = "Library",
    ["84"] = "Workshop",
    ["85"] = "Carpenter",
    ["88"] = "Stables",
    ["90"] = "Town Hall",
    ["98"] = "Barracks",
}

function setBuildingLevel(params)
    local nr = params[1]
    local level = params[2]
    local previousLevel = State.buildings[nr]
    if (previousLevel == nil or previousLevel == -1) and level == 0 then
        local name = BuildingNames[nr] or "unknown"
        broadcastToAll("Building " .. nr .. "(" .. name ..  ") is now available to build", { 0, 0.75, 0 })
    end
    State.buildings[nr] = level
    refreshDecals()
end

FakeLevel0Stickers = {
    ["05"] = "http://cloud-3.steamusercontent.com/ugc/2026103703078249014/19DEC6290699F65A5559E8289D412515C68ABA45/",
    ["12"] = "http://cloud-3.steamusercontent.com/ugc/2026103703078249070/1E820EFA32C60A20F280989098B2106985D496FD/",
    ["17"] = "http://cloud-3.steamusercontent.com/ugc/2026103703078249134/1F921F7A72C3194F36660EAB4C473FF70773C01F/"
}

function getLevel0BuildingDecal(params)
    local nr = params[1]
    if FakeLevel0Stickers[nr] ~= nil then
        return {
            url = FakeLevel0Stickers[nr],
            scale = {
            x = 0.189,
            y = 0.108,
            z = 0.668,
            },
            rotation = { 90, 180, 0 },
            position = { 0, 0, 0 },
            name = nr .. "_lvl0"
        }
    end
    local decals = Map_decals.outpost.buildings[nr].decals
    local decal = decals[1]
    return decal
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
    -- Determine the map image to use
    local mapName = 'map'
    if State.enabledDecals['map_w'] then
        mapName = mapName .. '_w'
    end
    if State.enabledDecals['map_x'] then
        mapName = mapName .. '_x'
    end
    if State.enabledDecals['map_y'] then
        mapName = mapName .. '_y'
    end
    if State.enabledDecals['map_z'] then
        mapName = mapName .. '_z'
    end
    local mapUrl = MapImages[mapName]
    if mapUrl ~= nil then
        local customObject = self.getCustomObject()
        local currentMapImage = customObject.image
        if currentMapImage ~= mapUrl then
            customObject.image = mapUrl
            self.setCustomObject(customObject)
            -- as many map updates are scripted and come from the campaign tracker
            -- we tend to update more than simply the map image, and we need the CT to dispatch those
            -- messages to the current object, so delaying the map reload by 1 frame.
            Wait.frames(function()
                self.script_state = onSave()
                self.reload()
            end, 1)
        end
    end
    if Map_decals ~= nil then
        stickers = {}
        -- Scenario decals
        if Map_decals.scenarios ~= nil then
            for _, entry in ipairs(Map_decals.scenarios) do
                if entry.name:sub(1, 4) ~= "map_" then
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

function clearButtons()
    for _, button in ipairs(self.getButtons()) do
        self.removeButton(button.index)
    end
end
