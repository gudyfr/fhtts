require('json')

function onLoad()
    self.interactable = false
    Global.call('registerDataUpdatable', self)
    local buttonPositions = {}
    for _,point in ipairs(self.getSnapPoints()) do
        table.insert(buttonPositions, point.position)
    end
    table.sort(buttonPositions, XZSorter)
    -- Minimize button
    addButton(buttonPositions[1], "minimize", "Hide Round Tracker")
    addButton(buttonPositions[2], "maximize", "Show Round Tracker")
    self.setDecals({})
end

function maximize()
    self.setPositionSmooth({0.5,5.4,22.50}, false, false)
    self.setRotationSmooth({66,180,0})
end

function minimize()
    self.setPositionSmooth({0.5,-1.83,19.28}, false, false)
    self.setRotationSmooth({66,180,0})
end

function XZSorter(a, b)
    return 30 * (a.z - b.z) - a.x + b.x < 0
end

function updateData(baseUrl)
    WebRequest.get(baseUrl .. "characterInitiatives.json", updateCharacterInitiatives)
    WebRequest.get(baseUrl .. "monsterStats.json", updateMonsterStats)
    WebRequest.get(baseUrl .. "monsterAbilities.json", updateMonsterAbilities)
end

function updateCharacterInitiatives(request)
    CharacterInitiatives = jsonDecode(request.text)
    updateInternal()
end

function updateMonsterStats(request)
    MonsterStats = jsonDecode(request.text)
    updateInternal()
end

function updateMonsterAbilities(request)
    MonsterAbilities = jsonDecode(request.text)
    updateInternal()
end

function updateState(state)
    print(state)
    State = JSON.decode(state)
    updateInternal()
end

function updateInternal()
    if State ~= nil and CharacterInitiatives ~= nil and MonsterStats ~= nil and MonsterAbilities ~= nil then
        local decals = {}
        local currentX = 2.75
        local currentZ = -.5
        for _, entry in ipairs(State) do
            local name = entry.name
            local type = entry.type
            local turnState = entry.turnState

            if type == "monster" then
                -- Render the monster image
                local grey = ""
                if turnState == 2 then
                    grey = ".grey"
                end
                local url = MonsterStats[name .. grey]
                if url ~= nil then
                    table.insert(decals, getDecal(name, url, currentX + .65, currentZ, .44, .5))
                end

                -- Render the monster stats
                local level = entry.level
                local url = MonsterStats[name .. "_" .. level]
                if url ~= nil then
                    table.insert(decals, getDecal(name, url, currentX + 0.1, currentZ, .887, .5))
                end

                -- Render the ability card
                local cardNumber = entry.card or 0
                if cardNumber > 0 then
                    local url = MonsterAbilities[name .. "_" .. level .. "_" .. cardNumber]
                    if url ~= nil then
                        table.insert(decals, getDecal(name, url, currentX - 0.6, currentZ, .887, .5))
                    end
                end
            elseif type == "character" then
                -- Render the character initiative token
                local grey = ""
                if turnState == 2 then
                    grey = ".grey"
                end
                local url = CharacterInitiatives[name .. grey]
                if url ~= nil then
                    table.insert(decals, getDecal(name, url, currentX, currentZ, .7, .25))
                end
            end
            currentZ = currentZ + 0.6
            if currentZ > 1 then
                currentX = currentX -   2
                currentZ = -0.5
            end
        end
        self.setDecals(decals)
    end
end

function getDecal(name, url, x, z, w, h)
    return {
        name = name,
        position = { x, 0.06, z },
        rotation = { 90, 180, 0 },
        url = url,
        scale = { w * .8, h * .8, h * .8 }
    }
end


function addButton(position, callback, tooltip)
    local params = {
        label          = "",
        function_owner = self,
        click_function = callback,
        position       = { -position.x, position.y + 0.01, position.z },
        width          = 100,
        height         = 100,
        font_size      = 40,
        color          = { 1, 1, 1, 0 },
        scale          = { 0.5, 0.5, 0.5 },
        font_color     = { 0, 0, 0, 1 },
        tooltip = tooltip
    }
    self.createButton(params)
end