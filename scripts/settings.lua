function onLoad(save)
    if save ~= nil then
        state = JSON.decode(save)
    end
    if state == nil then
        state = {}
        state["enable-x-haven"] = false
        state["address"] = ""
        state["port"] = 8080
    end

    local points = {}
    for _, point in ipairs(self.getSnapPoints()) do
        table.insert(points, point.position)
    end
    table.sort(points, compareZ)

    local expectedEntries = { 
        { "enable-x-haven", "checkbox" },
        { "address", "text" },
        { "port", "text" },
        { "enable-end-of-round-looting", "checkbox"},
        { "enable-highlight-current-figurines", "checkbox"},
        { "enable-highlight-past-figurines", "checkbox"},
        { "enable-highlight-tiles-by-type", "checkbox"},
        { "onRefreshData", "button"}
    }

    for idx, point in ipairs(points) do
        local entry = expectedEntries[idx]
        if entry ~= nil then
            if entry[2] == "checkbox" then
                createCheckbox(point, entry[1])
            elseif entry[2] == "text" then
                createInput(point, entry[1])
            elseif entry[2] == "button" then
                createButton(point, entry[1])
            end
        end
    end
end

function compareZ(obj1, obj2)
    return obj1.z < obj2.z
end

function onRefreshData()
    Global.call("refreshScenarioData")
end

function createInput(point, name)
    local fName = "onTextEdit_" .. name
    self.setVar(fName, function(obj, color, text, selected) onTextEdit(name, obj, color, text, selected) end)
    local params = {
        input_function = fName,
        function_owner = self,
        position = { -(point.x), point.y, point.z },
        scale = { .5, .5, .5 },
        width = 2200,
        height = 220,
        font_size = 180,
        color = { 1, 1, 1, 0 },
        font_color = { .2, .24, 0.28, 100 },
        alignment = 3,
        value = state[name]
    }
    self.createInput(params)
end

function createCheckbox(point, name)
    local fName = "onToggle_" .. name
    self.setVar(fName, function(obj, color, alt) onToggle(name) end)
    local label = ""
    if state[name] then
        label = "\u{2717}"
    end
    local params = {
        function_owner = self,
        click_function = fName,
        label          = label,
        position       = { -(point.x), point.y, point.z },
        width          = 200,
        height         = 200,
        font_size      = 300,
        color          = { 1,1,1, 0},
        scale          = { .5,.5,.5 },
        font_color     = { .2, .24, 0.28, 100},
        tooltip        = tooltip
    }
    self.createButton(params)
end

function createButton(point, name)
    local label = ""
    local params = {
        function_owner = self,
        click_function = name,
        label          = label,
        position       = { -(point.x), point.y, point.z },
        width          = 1000,
        height         = 200,
        font_size      = 300,
        color          = { 1,1,1, 0},
        scale          = { .5,.5,.5 },
        font_color     = { .2, .24, 0.28, 100},
        tooltip        = ""
    }
    self.createButton(params)
end

function onTextEdit(name, obj, color, text, selected)
    state[name] = text
end

function onToggle(name)
    state[name] = not state[name]
    for _, button in ipairs(self.getButtons()) do
        if button.click_function == "onToggle_" .. name then
            local label = ""
            if state[name] then
                label = "\u{2717}"
            end
            button.label = label
            self.editButton(button)
        end
    end
end

function onSave()
    return JSON.encode(state)
end


function getSettings()
    return JSON.encode(state)
end