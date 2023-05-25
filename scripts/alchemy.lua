require("savable")
require('data/alchemy_decals')

-- Savable functions
function getState()
    return enabledDecals
end

function onStateUpdate(state)
    enabledDecals = state
    refreshDecals()
end

function onLoad(state)
    if state ~= nil then
        enabledDecals = JSON.decode(state)
    end

    if enabledDecals == nil then
        enabledDecals = {}
    end

    refreshUI()

    Global.call('registerDataUpdatable', self)
    registerSavable("Alchemy")
end

function onSave()
    return JSON.encode(enabledDecals)
end

function updateData(params)
    local baseUrl = params.baseUrl
    local first = params.first
    if baseUrl ~= "https://gudyfr.github.io/fhtts/" or not first then
        WebRequest.get(baseUrl .. "alchemy_decals.json", processDecals)
    end
end

function processDecals(request)
    if request.text ~= nil then
        -- print("Parsing Alch")
        Alchemy_decals = JSON.decode(request.text)
        refreshUI()
    end
end

function refreshUI()
    if Alchemy_decals ~= nil then
        self.clearButtons()
        for _, entry in pairs(Alchemy_decals) do
            local revealed
            if enabledDecals[entry.name] ~= nil and enabledDecals[entry.name] then
                revealed = true
            else
                revelead = false
            end
            local fName = "toggle_" .. entry.name
            self.setVar(fName, function() toggle(entry) end)
            local name
            local tooltip
            name = ""
            tooltip = "Toggle the potion visibility"

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
        refreshDecals()
    end
end

function toggle(entry)
    if enabledDecals[entry.name] ~= nil and enabledDecals[entry.name] then
        enabledDecals[entry.name] = false
    else
        enabledDecals[entry.name] = true
    end

    refreshDecals()
end

function refreshDecals()
    if Alchemy_decals ~= nil then
        stickers = {}
        for _, entry in pairs(Alchemy_decals) do
            if enabledDecals[entry.name] ~= nil and enabledDecals[entry.name] then
                table.insert(stickers, entry)
            end
        end
        self.setDecals(stickers)
    end
end
