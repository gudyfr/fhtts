require('savable')
require('controls')
require('constants')
require('json')
require('settings_data')

function createEmptyState()
    return {
        state = {
            ["enable-x-haven"] = false,
            address = "localhost",
            port = "8080",
            ["alt-zoom-fix"] = true,
            ["play-narration-in-assistant"] = true,
            ["enable-end-of-round-looting"] = true,
            ["enable-highlight-current-figurines"] = true,
            ["enable-highlight-tiles-by-type"] = true,
            ["enable-automatic-scenario-layout"] = true,
            ["enable-automatic-narration"] = false,
            ["enable-automatic-characters"] = true,
            ["enable-am-ui-overlay"] = false,
            ["enable-internal-game-state"] = false,
            ["enable-solo"] = false,
            ["enable-5p"] = false,
            ["difficulty-easy"] = false,
            ["difficulty-normal"] = true,
            ["difficulty-hard"] = false,
            ["difficulty-insane"] = false,
            difficulty = 0
        }
    }
end

function getExpectedEntries()
    return {
        { "enable-x-haven",                     "checkbox" },
        { "enable-5p",                          "checkbox", on5pToggled },
        { "address",                            "text" },
        { "port",                               "text" },
        { "enable-solo",                        "checkbox", onSoloToggled },
        { "play-narration-in-assistant",        "checkbox" },
        { "alt-zoom-fix",                       "checkbox", onAltZoomToggled },
        { "enable-end-of-round-looting",        "checkbox" },
        { "enable-highlight-current-figurines", "checkbox" },
        { "enable-internal-game-state",         "checkbox" },
        { "enable-highlight-tiles-by-type",     "checkbox" },
        { "enable-automatic-characters",        "checkbox" },
        { "difficulty-easy",                    "checkbox", onDifficultyEasy },
        { "difficulty-normal",                  "checkbox", onDifficultyNormal },
        { "difficulty-hard",                    "checkbox", onDifficultyHard },
        { "difficulty-insane",                  "checkbox", onDifficultyInsane },
        { "enable-automatic-scenario-layout",   "checkbox" },
        { "enable-automatic-narration",         "checkbox" },
        { "enable-am-ui-overlay",               "checkbox", onUIOverlayChanged },
    }
end

function getRelativeScale()
    return 0.5
end

function on5pToggled()
    local enabled = State["enable-5p"]
    local yellowMatGuid = PlayerMats["Yellow"]
    if yellowMatGuid ~= nil then
        local yellowMat = getObjectFromGUID(yellowMatGuid)
        yellowMat.setLock(true)
        if enabled then
            -- Show the 5th player mat
            yellowMat.setPosition({ -65, 1.35, 34.22 })
        else
            -- Hide the 5th player mat
            yellowMat.setPosition({ -65, 0, 34.22 })
        end
    end

    local scenarioMat = getObjectFromGUID(ScenarioMatGuid)
    local customObject = scenarioMat.getCustomObject()
    local snapPoints
    if enabled then
        customObject.diffuse = ScenarioMat5P
        snapPoints = SnapPoints5P
        scenarioMat.addTag("5 players")
    else
        customObject.diffuse = ScenarioMat4P
        snapPoints = SnapPoints4P
        scenarioMat.removeTag("5 players")
    end
    scenarioMat.setCustomObject(customObject)
    scenarioMat.setSnapPoints(snapPoints)
    scenarioMat.reload()

    Global.call("updateHotkeys", { enabled = State["enable-solo"], fivePlayers = State["enable-5p"] })
end

function onAltZoomToggled()
    local enabled = State["alt-zoom-fix"]
    local handZoneGuids = { "2cc705", "5caab9", "34a6bf", "b6e49e", "fcfb8f" }
    for _, guid in ipairs(handZoneGuids) do
        local zone = getObjectFromGUID(guid)
        local position = zone.getPosition()
        zone.setPosition({ position.x, position.y, enabled and -36 or 50 })
    end
end

function onSoloToggled()
    Global.call("updateHotkeys", { enabled = State["enable-solo"], fivePlayers = State["enable-5p"] })
    local scenarioMat = getObjectFromGUID(ScenarioMatGuid)

    scenarioMat.call('updateDifficulty', { difficulty = State["difficulty"], solo = State["enable-solo"] })
end

function onDifficultyEasy(set)
    if set then
        setDifficulty("easy")
    end
end

function onDifficultyNormal(set)
    if set then
        setDifficulty("normal")
    end
end

function onDifficultyHard(set)
    if set then
        setDifficulty("hard")
    end
end

function onDifficultyInsane(set)
    if set then
        setDifficulty("insane")
    end
end

function onUIOverlayChanged(set)
    UI.setAttribute("layout", "active", set)
end

function setDifficulty(level)
    local entries = { "easy", "normal", "hard", "insane" }
    for _, button in ipairs(self.getButtons()) do
        for _, entry in ipairs(entries) do
            if entry ~= level then
                local name = "difficulty-" .. entry
                State[name] = false
                if button.click_function == "onToggle_" .. name then
                    local label = ""
                    button.label = label
                    self.editButton(button)
                end
            end
        end
    end
    local difficulty = 0
    if level == "easy" then
        difficulty = -1
    elseif level == "hard" then
        difficulty = 1
    elseif level == "insane" then
        difficulty = 2
    end
    State.difficulty = difficulty

    local scenarioMat = getObjectFromGUID(ScenarioMatGuid)
    scenarioMat.call('updateDifficulty', { difficulty = difficulty, solo = State["enable-solo"] })
end
