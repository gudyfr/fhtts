require('constants')

function onLoad(save)
    if save ~= nil then
        local state = JSON.decode(save) or {}
        Minimized = state.minimized
        if Minimized == nil then
            Minimized = true
        end
    end

    locateElementsFromSnapPoints()

    updateUI()
end

function onSave()
    return JSON.encode({minimized=Minimized})
end

function locateElementsFromSnapPoints()
    ButtonPositions = {}
    for _, point in ipairs(self.getSnapPoints()) do
        local tagsMap = {}
        for _,tag in ipairs(point.tags) do
            tagsMap[tag] = 1
        end

        if tagsMap["button"] ~= nil then
            table.insert(ButtonPositions, point.position)
        end
    end

    table.sort(ButtonPositions, function(a,b) return a.z - b.z < 0 end)
end

function toggleVisibility()
    if Minimized then
        show()
    else
        hide()
    end
end

function show()
    Minimized = false
    updateUI()
    self.setLock(true)
    self.setRotation({x=45, y=0, z=0})
    self.setPositionSmooth({-17.30, 2.26, 14.11})
end

function hide()
    Minimized = true
    updateUI()
    self.setLock(true)
    self.setRotation({x=45, y=0, z=0})
    self.setPositionSmooth({-17.30, 0.29, 16.07})
end

function updateUI()
    self.clearButtons()
    if not Minimized then
        -- Create all 3 buttons
        if #ButtonPositions == 3 then
            self.createButton(makeButton(ButtonPositions[1], "onCompleted"))
            self.createButton(makeButton(ButtonPositions[2], "onRetry"))
            self.createButton(makeButton(ButtonPositions[3], "onReturnToFrosthaven"))
            
        end
    end
end

function makeButton(position, callback)
    return {
        function_owner = self,
        click_function = callback,
        label          = "",
        position       = { -position.x, position.y, position.z },
        width          = 2000,
        height         = 800,
        font_size      = 50,
        color          = { 1, 1, 1, 0 },
        scale          = { 1, 1, 0.3 },
        font_color     = { 1, 1, 1, 0 },
        tooltip        = "",
    }
end

function onCompleted()
    local scenarioMat = getObjectFromGUID(ScenarioMatGuid)
    if scenarioMat ~= nil then
        scenarioMat.call('onScenarioCompleted')
    end
end

function onRetry()
    local scenarioMat = getObjectFromGUID(ScenarioMatGuid)
    if scenarioMat ~= nil then
        scenarioMat.call('onScenarioRetry')
    end
end

function onReturnToFrosthaven()
    local scenarioMat = getObjectFromGUID(ScenarioMatGuid)
    if scenarioMat ~= nil then
        if scenarioMat ~= nil then
            scenarioMat.call('onScenarioLost')
        end
    end
end