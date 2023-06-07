-- A set of scripts to load / save / reset state

Savable = {}

function registerSavable(name, priority)
    priority = priority or 1
    Savable.name = name
    Global.call("registerSavable", { savable = self, priority = priority })
end

function getName()
    return Savable.name
end

function emptyStateConstrutor()
    return {}
end

function reset()
    broadcastToAll("Resetting " .. Savable.name)
    local cleanState
    if self.getVar("createEmptyState") ~= nil then
        cleanState = self.call("createEmptyState")
    else
        cleanState = emptyStateConstrutor()
    end
    savableSetState(cleanState)
end

function isStateUpdating()
    return StateIsResetting
end

function savableSetState(state)
    StateIsResetting = true
    self.setVar('_savableSetState', function()
        onStateUpdate(state)
        StateIsResetting = false
        return 1
    end)
    startLuaCoroutine(self, '_savableSetState')
end

function getSave()
    local partialSave = {}
    local itemSave = {}
    itemSave["State"] = self.call("getState")
    partialSave[Savable.name] = itemSave
    local result = JSON.encode(partialSave)
    return result
end

function loadSave(params)
    local itemSave = params[1]
    broadcastToAll("Loading " .. Savable.name)
    savableSetState(itemSave.State)
end

LOAD_WAIT_MS = 100

function waitms(ms)
    local start = os.time()
    while os.time() < start + ms / 1000 do
        coroutine.yield(0)
    end
end
