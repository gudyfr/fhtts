require("json")
require("savable")
require('constants')
require('text_utils')
require('data/checkmarks')
require('data/rules')

availableBooks = { "scenario book", "section book", "rulebook" }
bookModels = {}
bookModels["rulebook"] = {
    { from = 1, to = 84, guid = '0ea82e' }
}
bookModels["scenario book"] = {
    { from = 1,   to = 21,  guid = '5cd351' },
    { from = 22,  to = 41,  guid = '4c885d' },
    { from = 42,  to = 61,  guid = 'ce179a' },
    { from = 62,  to = 81,  guid = '38be3c' },
    { from = 82,  to = 101, guid = '4cbbfe' },
    { from = 102, to = 121, guid = '597115' },
    { from = 122, to = 141, guid = 'a4973e' },
    { from = 142, to = 168, guid = '8eda36' },
    { from = 169, to = 192, guid = '4c3364' }
}

bookModels["section book"] = {
    { from = 1,   to = 21,  guid = '345167' },
    { from = 22,  to = 41,  guid = 'b65e37' },
    { from = 42,  to = 61,  guid = '41208f' },
    { from = 62,  to = 81,  guid = 'c9f39e' },
    { from = 82,  to = 101, guid = 'e65264' },
    { from = 102, to = 121, guid = 'b54fdd' },
    { from = 122, to = 141, guid = '0f081f' },
    { from = 142, to = 161, guid = 'a835cf' },
    { from = 162, to = 181, guid = '03cc93' },
    { from = 182, to = 198, guid = 'a30a42' },
}

buttonTargets = {
    ["index"] = 80,
    ["quick reference"] = 84
}

function onSave()
    local state = JSON.encode(State)
    -- print(state)
    return state
end

function onLoad(save)
    registerSavable("booksMat")
    if save ~= nil then
        State = JSON.decode(save)
    end
    if State == nil then
        State = createEmptyState()
    end

    for book, bookState in pairs(State) do
        goToPage(book, bookState.history[bookState.historyPosition])
    end

    for _, point in ipairs(self.getSnapPoints()) do
        local tags = point.tags
        local tagsMap = {}
        for _, tag in ipairs(tags) do
            tagsMap[tag] = true
        end
        if tagsMap.input ~= nil then
            addInput(point, tagsMap)
        end
        if tagsMap.button ~= nil then
            addButton(point, tagsMap)
        end
    end
    Global.call('registerDataUpdatable', self)
end

function updateData(params)
    local baseUrl = params.baseUrl
    local first = params.first
    if baseUrl ~= "https://gudyfr.github.io/fhtts/" or not first then
        WebRequest.get(baseUrl .. "rules.json", processRules)
        WebRequest.get(baseUrl .. "checkmarks.json", processCheckmarks)
    end
end

-- Savable functions
function createEmptyState()
    local state = {}
    for _, book in ipairs(availableBooks) do
        state[book] = {
            history = { 1 },
            historyPosition = 1,
            historySize = 1,
            decals = {},
            checkmarks = {},
        }
    end
    -- Set the scenario to the 2nd page
    state["scenario book"].history[1] = 2
    return state
end

function getState()
    return State
end

function onStateUpdate(state)
    State = state
    for book, bookState in pairs(state) do
        goToPage(book, bookState.history[bookState.historyPosition])
        waitms(LOAD_WAIT_MS)
    end
    refreshDecals()
end

function processRules(request)
    if request.text ~= nil then
        Rules = jsonDecode(request.text)
        refreshDecals()
    else
        Rules = {}
    end
end

function processCheckmarks(request)
    if request.text ~= nil then
        Checkmarks = jsonDecode(request.text)
        refreshDecals()
    else
        Checkmarks = {}
    end
end

function refreshDecals()
    if Rules == nil then
        Rules = {}
    end
    if Checkmarks == nil then
        Checkmarks = {}
    end
    for name, bookModel in pairs(bookModels) do
        for _, subBook in ipairs(bookModel) do
            local obj = getObjectFromGUID(subBook.guid)
            if obj ~= nil then
                local decals = {}
                local page = subBook.from + obj.Book.getPage()
                -- print("page : " .. page)
                local enabledDecals = State[name].decals or {}
                -- print(JSON.encode(enabledDecals))
                -- rulebook only for the decals
                if name == "rulebook" then
                    for _, decalInfo in ipairs(Rules) do
                        if decalInfo.page == page then
                            if enabledDecals[decalInfo.name] or false then
                                table.insert(decals, decalInfo)
                            end
                        end
                    end
                end
                -- print("Decals:")
                -- print(JSON.encode(decals))
                obj.setDecals(decals)
                -- Create the buttons
                obj.clearButtons()
                -- local buttons = obj.getButtons()
                -- if buttons ~= nil then
                --     for _, btn in ipairs(buttons) do
                --         obj.removeButton(btn.index)
                --     end
                -- end
                if name == "rulebook" then
                    for _, decalInfo in ipairs(Rules) do
                        if decalInfo.page == page then
                            -- print(JSON.encode(decalInfo))
                            local fName = "toggle_decal_" .. decalInfo.name
                            self.setVar(fName, function() toggleDecal(decalInfo.name) end)

                            local pos = decalInfo.position
                            -- print(JSON.encode(pos))

                            local params = {
                                function_owner = self,
                                click_function = fName,
                                label          = "",
                                position       = { -pos.x, pos.y + 0.05, pos.z },
                                width          = 500 * decalInfo.scale.x,
                                height         = 500 * decalInfo.scale.y,
                                font_size      = 50,
                                color          = { 1, 1, 1, 0 },
                                scale          = { 1, 1, 1 },
                                font_color     = { 0, 0, 0, 0 },
                                tooltip        = "",
                            }
                            obj.createButton(params)
                        end
                    end
                end
                local bookCheckmarks = Checkmarks[name] or {}
                local pageCheckmarks = bookCheckmarks["" .. page] or {}
                -- print(JSON.encode(State[name].checkmarks))
                for i, checkmark in ipairs(pageCheckmarks) do
                    local checkmarkName = getCheckmarkName(checkmark)
                    local checked = ((State[name].checkmarks or {})["" .. page] or {})[checkmarkName] or false
                    local label = ""
                    if checked then
                        label = "\u{2717}"
                    end
                    local fName = "toggle_checkmark_" .. i
                    self.setVar(fName, function() toggleCheckmark(name, page, checkmarkName) end)
                    local pos = checkmark.position
                    local params = {
                        function_owner = self,
                        click_function = fName,
                        label          = label,
                        position       = { -pos.x, pos.y + 0.05, pos.z },
                        width          = 150 * (checkmark.size or 1),
                        height         = 150 * (checkmark.size or 1),
                        font_size      = 100 * (checkmark.size or 1),
                        color          = { 1, 1, 1, 0 },
                        scale          = { .20, .20, .20 },
                        font_color     = { 0, 0, 0, 100 },
                        tooltip        = "",
                    }
                    obj.createButton(params)
                end
            end
        end
    end
end

function onPageChanged()
    refreshDecals()
end

function addRulebookSticker(params)
    local page = params[1]
    local name = "fh-rule-sticker-" .. params[2]
    local decals = State["rulebook"].decals
    if decals == nil then
        decals = {}
        State["rulebook"].decals = decals
    end
    decals[name] = true
    changePage("rulebook", page)
    refreshDecals()
end

function toggleDecal(name)
    local decals = State["rulebook"].decals
    if decals == nil then
        decals = {}
        State["rulebook"].decals = decals
    end
    -- print(JSON.encode(decals))
    local currentValue = decals[name] or false
    local newValue = not currentValue
    decals[name] = newValue
    refreshDecals()
end

function getCheckmarkName(checkmark)
    if checkmark.name or false then
        return checkmark.name
    else
        return checkmark.position.x .. "," .. checkmark.position.z
    end
end

function toggleCompleted(params)
    local scenario = string.sub(params[1], 3)
    local completed = params[3]

    -- Locate the appropriate checkmark
    if Checkmarks ~= nil then
        for page, entries in pairs(Checkmarks["scenario book"]) do
            for _, entry in ipairs(entries) do
                if entry.name == scenario then
                    -- get the current State
                    local State = ((State["scenario book"] or {})["checkmarks"] or {})[page] or {}
                    local checked = State[scenario] or false
                    if checked ~= completed then
                        toggleCheckmark("scenario book", page, scenario)
                    end
                end
            end
        end
    end
end

function toggleCheckmark(book, page, name)
    local pageName = "" .. page
    local checkmarksState = State[book].checkmarks
    if checkmarksState == nil then
        checkmarksState = {}
        State[book].checkmarks = checkmarksState
    end
    local pageState = checkmarksState[pageName]
    if pageState == nil then
        pageState = {}
        checkmarksState[pageName] = pageState
    end

    local checkmarkState = pageState[name] or false
    pageState[name] = not checkmarkState

    if book == "scenario book" then
        local scenarioNumber = tonumber(name)
        if scenarioNumber ~= nil then
            -- Tell the campaign tracker(s) this scenario is complete
            for _, guid in ipairs(CampaignTrackerGuids) do
                local ct = getObjectFromGUID(guid)
                if ct ~= nil then
                    ct.call("toggleCompleted", { name, not checkmarkState })
                end
            end
            if scenarioNumber > 137 then
                -- Solo scenarios are NOT handled by any campaign tracker, and so we need to let the scenario picker know
                -- about the change.
                local picker = getObjectFromGUID('596fc4')
                picker.call('updateSoloScenario', { name, not checkmarkState })
            end
        end
    end

    refreshDecals()
end

function addInput(point, tagsMap)
    local target = getTarget(tagsMap, availableBooks)
    if target ~= nil then
        local fName = "onTextEdit_" .. target
        self.setVar(fName, function(obj, color, value, selected) onEdit(target, obj, color, value, selected) end)
        local position = { -point.position.x, point.position.y, point.position.z }
        local params = {
            function_owner = self,
            input_function = fName,
            position = position,
            scale = { .3, .3, .3 },
            width = 900,
            height = 150,
            font_size = 100,
            color = { 1, 1, 1, 0 },
            font_color = { 0, 0, 0, 100 },
            alignment = 3
        }
        self.createInput(params)
    end
end

function addButton(point, tagsMap)
    local target = getTarget(tagsMap, availableBooks)
    local action = getTarget(tagsMap, { "index", "quick reference" })
    if target ~= nil and action ~= nil then
        local fName = "onClick_" .. target .. "_" .. action
        self.setVar(fName, function(obj, color, alt) onClick(target, action, obj, color, alt) end)
        local position = { -point.position.x, point.position.y, point.position.z }
        local params = {
            function_owner = self,
            click_function = fName,
            label          = "",
            position       = position,
            width          = 600,
            height         = 200,
            font_size      = 50,
            color          = { 1, 1, 1, 0 },
            scale          = { .3, .3, .3 },
            font_color     = { 1, 1, 1, 0 },
            tooltip        = "",
        }
        self.createButton(params)
        return
    end
    local specialAction = getTarget(tagsMap, { "rewind", "forward", "audio play" })
    if target ~= nil and specialAction ~= nil then
        local fName = "onClick_" .. target .. "_" .. specialAction
        self.setVar(fName, function(obj, color, alt) onClick(target, specialAction, obj, color, alt) end)
        local position = { -point.position.x, point.position.y, point.position.z }
        local params = {
            function_owner = self,
            click_function = fName,
            label          = "",
            position       = position,
            width          = 140,
            height         = 140,
            font_size      = 50,
            color          = { 1, 1, 1, 0 },
            scale          = { .3, .3, .3 },
            font_color     = { 1, 1, 1, 0 },
            tooltip        = "",
        }
        self.createButton(params)
        return
    end
end

function getTarget(tagsMap, candidates)
    for _, candidate in ipairs(candidates) do
        if tagsMap[candidate] ~= nil then return candidate end
    end
    return nil
end

function onEdit(target, obj, color, value, selected)
    local cleanValue = trim(value)
    if not selected then
        local page = tonumber(cleanValue)
        if page ~= nil then
            changePage(target, page, cleanValue)
        end
    else
        local len = string.len(value)
        local lastChar = string.sub(value, len, len)
        if lastChar == "\n" then
            local page = tonumber(cleanValue)
            if page ~= nil then
                changePage(target, page, cleanValue)
            end
        end
    end
end

function rewind(target)
    local bookState = State[target]
    if bookState ~= nil then
        if bookState.historyPosition > 1 then
            bookState.historyPosition = bookState.historyPosition - 1
            goToPage(target, bookState.history[bookState.historyPosition])
        end
    end
end

function forward(target)
    local bookState = State[target]
    if bookState ~= nil then
        if bookState.historyPosition < bookState.historySize then
            bookState.historyPosition = bookState.historyPosition + 1
            goToPage(target, bookState.history[bookState.historyPosition])
        end
    end
end

function changePage(target, page, value)
    local bookState = State[target]
    if bookState ~= nil then
        -- avoid updating the history if we end up loading the same page
        if page ~= bookState.history[bookState.historyPosition] then
            -- remove from history anything after historyPosition and before historySize
            for i = bookState.historyPosition + 1, bookState.historySize do
                table.remove(bookState.history, bookState.historyPosition + 1)
            end
            bookState.historySize = bookState.historyPosition

            -- keep at most 10 entries in the history
            if bookState.historyPosition == 10 then
                table.remove(bookState.history, 1)
                bookState.historyPosition = 9
                bookState.historySize = 9
            end

            -- increment the current page forward
            bookState.historyPosition = bookState.historyPosition + 1
            bookState.historySize = bookState.historySize + 1
            table.insert(bookState.history, page)
        else
            -- Debug for now, print the stickers
            local model = bookModels[target]
            local currentState = findObject(model)
            -- print(JSON.encode(currentState.getSnapPoints()))
        end
        -- still load the page though, just in case ...
        goToPage(target, page, value)
    end
end

function goToPage(target, page, value)
    local pageFloor = math.floor(page)
    local model = bookModels[target]
    if model ~= nil then
        -- First we need to locate the book
        local currentState = findObject(model)
        if currentState ~= nil then
            -- Now we need to find the target object / State
            for idx, entry in ipairs(model) do
                if pageFloor >= entry.from and pageFloor <= entry.to then
                    -- Switch State if needed
                    if currentState.guid ~= entry.guid then
                        currentState = currentState.setState(idx)
                        getObjectFromGUID(entry.guid).setLuaScript(
                            "function onLoad() Wait.time(function() self.Book.setPage(" ..
                            (page - entry.from) ..
                            ") end, 0.1, 5) getObjectFromGUID('" .. self.guid .. "').call('refreshDecals') end")
                    else
                        currentState.Book.setPage(page - entry.from)
                    end
                end
            end
        end
    end
    if target == "section book" and value ~= nil then
        LoadedSection = value
    end
    if target == "scenario book" and page == 2 then
        LoadedScenarioType = "scenarios"
        LoadedScenarioNumber = "Welcome To Frosthaven"
    end
end

function findObject(model)
    for _, entry in ipairs(model) do
        local candidate = getObjectFromGUID(entry.guid)
        if candidate ~= nil then
            return candidate
        end
    end
    return nil
end

function onClick(target, action, obj, color, alt)
    if action == "forward" then
        forward(target)
    elseif action == "rewind" then
        rewind(target)
    elseif action == "audio play" then
        audioPlay(target)
    else
        local page = buttonTargets[action]
        if page ~= nil then
            goToPage(target, page)
        end
    end
end

function setScenarioPage(params)
    local page = params[1]
    LoadedScenarioNumber = params[2]
    LoadedScenarioType = params[3] or "scenarios"
    changePage("scenario book", page, value)
    maybePlayAudio("scenario book")
end

function setSection(section)
    local page = math.floor(section)
    LoadedSection = section
    changePage("section book", page, section)
    maybePlayAudio("section book")
end

function maybePlayAudio(target)
    local settings = JSON.decode(Global.call("getSettings"))
    if settings['enable-automatic-narration'] or false then
        audioPlay(target)
    end
end

function audioPlay(target)
    if target == "scenario book" and LoadedScenarioNumber ~= nil and LoadedScenarioType ~= nil then
        Global.call("playNarration", { LoadedScenarioType, LoadedScenarioNumber })
    elseif target == "section book" and LoadedSection ~= nil then
        Global.call("playNarration", { "sections", LoadedSection })
    end
end
