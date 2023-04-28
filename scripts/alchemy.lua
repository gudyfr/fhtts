require("savable")
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
    WebRequest.get("http://cloud-3.steamusercontent.com/ugc/2035103391713278252/90283ABBEDE9189C23EA0937021379A784F1C348/", processDecals)
    registerSavable("Alchemy")
end

function onSave()
    return JSON.encode(enabledDecals)
end

function processDecals(request)
 if request.text ~= nil then
    -- print("Parsing Alch")
    data = JSON.decode(request.text)
    if data ~= nil then
        for _,entry in pairs(data) do            
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
                position       = {-(entry.position.x),entry.position.y,entry.position.z},
                width          = 200,
                height         = 200,
                font_size      = 50,
                color          = {1,1,1,0},
                scale          = {.3, .3, .3},
                font_color     = {1, 1, 1, 0},
                tooltip        = tooltip
            }
            self.createButton(params)
        end
        refreshDecals()
    end
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
    if data ~= nil then
        stickers = {}
        for _,entry in pairs(data) do            
            if enabledDecals[entry.name] ~= nil and enabledDecals[entry.name] then
                table.insert(stickers,entry)
            end
        end
        self.setDecals(stickers)
    end
end