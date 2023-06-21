require('text_utils')

function getState()
    return { state = State }
end

function onStateUpdate(save)
    State = save.state
    refreshControls()
end

function onLoad(save)
    if save ~= nil then
        State = JSON.decode(save)
    end
    if State == nil then
        State = createEmptyState()
    else
        -- if we have introduced new values, then let's make sure we use their default value
        local emptyState = createEmptyState()
        for k, v in pairs(emptyState.state) do
            if State[k] == nil then
                State[k] = v
            end
        end
    end
    registerSavable(self.getName())
    refreshControls()
end

function refreshControls()
    local success, scale = pcall(getRelativeScale)
    if success then
        RelativeScale = scale
    else
        RelativeScale = 1
    end
    self.clearButtons()
    self.clearInputs()

    -- for _, button in ipairs(self.getButtons() or {}) do
    --     self.removeButton(button.index)
    -- end
    -- for _, input in ipairs(self.getInputs() or {}) do
    --     self.removeInput(input.index)
    -- end

    local points = {}
    for _, point in ipairs(self.getSnapPoints()) do
        table.insert(points, point.position)
    end
    table.sort(points, compareZ)

    local expectedEntries = getExpectedEntries()

    Callbacks = {}
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

            if entry[3] ~= nil then
                Callbacks[entry[1]] = entry[3]
            end
        end
    end
end

function compareZ(obj1, obj2)
    return (obj1.z - obj2.z) * 20 + (obj2.x - obj1.x) < 0
end

function createInput(point, name)
    local fName = "onTextEdit_" .. name
    self.setVar(fName, function(obj, color, text, selected) onTextEdit(name, obj, color, text, selected) end)
    local params = {
        input_function = fName,
        function_owner = self,
        position = { -(point.x), point.y, point.z },
        scale = { .5 * RelativeScale, .5 * RelativeScale, .5 * RelativeScale },
        width = 2200,
        height = 220,
        font_size = 180,
        color = { 1, 1, 1, 0 },
        font_color = { .2, .24, 0.28, 100 },
        alignment = 3,
        value = State[name] or ""
    }
    self.createInput(params)
end

function createCheckbox(point, name)
    local fName = "onToggle_" .. name
    self.setVar(fName, function(obj, color, alt) onToggle(name) end)
    local label = ""
    if State[name] or false then
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
        color          = { 1, 1, 1, 0 },
        scale          = { .5 * RelativeScale, .5 * RelativeScale, .5 * RelativeScale },
        font_color     = { .2, .24, 0.28, 100 },
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
        color          = { 1, 1, 1, 0 },
        scale          = { .5 * RelativeScale, .5 * RelativeScale, .5 * RelativeScale },
        font_color     = { .2, .24, 0.28, 100 },
        tooltip        = ""
    }
    self.createButton(params)
end

function onTextEdit(name, obj, color, text, selected)
    State[name] = trim(text)
    if not selected then
        local callback = Callbacks[name]
        if callback ~= nil then
            callback()
        end
    end
end

function onToggle(name)
    State[name] = not State[name]
    for _, button in ipairs(self.getButtons()) do
        if button.click_function == "onToggle_" .. name then
            local label = ""
            if State[name] then
                label = "\u{2717}"
            end
            button.label = label
            self.editButton(button)
        end
    end

    local callback = Callbacks[name]
    if callback ~= nil then
        callback(State[name])
    end
end

function onSave()
    return JSON.encode(State)
end

function getSettings()
    return JSON.encode(State or {})
end
