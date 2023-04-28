-- A set of scripts to load / save / reset state

Savable = {}

function registerSavable(name)
    Savable.name = name
    Global.call("registerSavable", self)
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
    if self.getVar("onGameSave") ~= nil then
        itemSave["GameState"] = self.call("onGameSave")
    end
    partialSave[Savable.name] = itemSave
    local result = JSON.encode(partialSave)
    return result
end

function loadSave(serialized)
    local itemSave = JSON.decode(serialized)
    if itemSave.GameState ~= nil and self.getVar('onGameLoad') ~= nil then
        self.call("onGameLoad", itemSave.GameState)
    end
    self.call("onStateUpdate", itemSave.State)
end
