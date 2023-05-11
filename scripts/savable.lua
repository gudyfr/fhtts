-- A set of scripts to load / save / reset state

Savable = {}

function registerSavable(name, priority)
    priority = priority or 1
    Savable.name = name
    Global.call("registerSavable", {savable=self,priority=priority})
end

function getName()
    return Savable.name
end

function emptyStateConstrutor()
    return {}
end

function reset()
    local cleanState
    if self.getVar("createEmptyState") ~= nil then
        cleanState = self.call("createEmptyState")
    else
        cleanState = emptyStateConstrutor()
    end
    self.call("onStateUpdate", cleanState)
end

function getSave()
    local partialSave = {}
    local itemSave = {}
    itemSave["State"] = self.call("getState")
    partialSave[Savable.name] = itemSave
    local result = JSON.encode(partialSave)
    return result
end

function loadSave(serialized)
    local itemSave = JSON.decode(serialized)
    self.call("onStateUpdate", itemSave.State)
end
