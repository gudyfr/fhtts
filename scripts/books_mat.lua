require("json")

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

buttonTargets = {}
buttonTargets["index"] = 80
buttonTargets["quick reference"] = 84

function onSave()
    return JSON.encode(state)
end

function onLoad(save)
    if save ~= nil then
        -- print(save)
        state = JSON.decode(save)
    end
    if state == nil then
        state = {}
        for _, book in ipairs(availableBooks) do
            state[book] = {
                history = { 1 },
                historyPosition = 1,
                historySize = 1,
                decals = {},
                checkmarks = {},
            }
        end
    end

    for book, bookState in pairs(state) do
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

    WebRequest.get("https://raw.githubusercontent.com/gudyfr/fhtts/main/rules.json", processDecals)
    WebRequest.get("https://raw.githubusercontent.com/gudyfr/fhtts/main/checkmarks.json", processCheckmarks)
end

function processDecals(request)
    if request.text ~= nil then
        decalInfos = jsonDecode(request.text)
        refreshDecals()
    else
        decalInfos = {}
    end
end

function processCheckmarks(request)
    if request.text ~= nil then
        checkmarkInfos = jsonDecode(request.text)
        refreshDecals()
    else
        checkmarkInfos = {}
    end
end
 

function refreshDecals()
    if decalInfos == nil then
        decalInfos = {}
    end
    if checkmarkInfos == nil then
        checkmarkInfos = {}
    end
    for name, bookModel in pairs(bookModels) do
        for _, subBook in ipairs(bookModel) do
            local obj = getObjectFromGUID(subBook.guid)
            if obj ~= nil then
                local decals = {}
                local page = subBook.from + obj.Book.getPage()
                -- print("page : " .. page)
                local enabledDecals = state[name].decals or {}
                -- print(JSON.encode(enabledDecals))
                -- rulebook only for the decals
                if name == "rulebook" then
                    for _, decalInfo in ipairs(decalInfos) do
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
                local buttons = obj.getButtons()
                if buttons ~= nil then
                    for _, btn in ipairs(buttons) do
                        obj.removeButton(btn.index)
                    end
                end
                if name == "rulebook" then
                    for _, decalInfo in ipairs(decalInfos) do
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
                local bookCheckmarks = checkmarkInfos[name] or {}
                local pageCheckmarks = bookCheckmarks["".. page] or {}
                -- print(JSON.encode(state[name].checkmarks))
                for i,checkmark in ipairs(pageCheckmarks) do
                    local checkmarkName = getCheckmarkName(checkmark) 
                    local checked = ((state[name].checkmarks or {})["" .. page] or {})[checkmarkName] or false
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
                                width          = 150*(checkmark.size or 1),
                                height         = 150*(checkmark.size or 1),
                                font_size      = 100*(checkmark.size or 1),
                                color          = { 1, 1, 1, 0 },
                                scale          = { .20,.20,.20 },
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

function toggleDecal(name)
    local decals = state["rulebook"].decals
    if decals == nil then
        decals = {}
        state["rulebook"].decals = decals
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
        return checkmark.position.x .. "," ..checkmark.position.z
    end
end

function toggleCompleted(params)
    print(JSON.encode(params))
    local scenario = string.sub(params[1], 3)
    local completed = params[3]

    -- Locate the appropriate checkmark
    if checkmarkInfos ~= nil then
        for page, entries in pairs(checkmarkInfos["scenario book"]) do
            for _,entry in ipairs(entries) do
                if entry.name == scenario then
                    -- get the current state
                    local state = ((state["scenario book"] or {})["checkmarks"] or {})[page] or {}
                    local checked = state[scenario] or false
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
    local checkmarksState = state[book].checkmarks
    if checkmarksState == nil then
        checkmarksState = {}
        state[book].checkmarks = checkmarksState
    end
    local pageState = checkmarksState[pageName]
    if pageState == nil then
        pageState = {}
        checkmarksState[pageName] = pageState
    end

    local checkmarkState = pageState[name] or false
    pageState[name] = not checkmarkState

    if book == "scenario book" then
        -- Tell the campaign tracker(s) this scenario is complete
        local ctGuids = {'029e08','631fbe','7f539b','31de67','e145fb'}
        for _, guid in ipairs(ctGuids) do
            local ct = getObjectFromGUID(guid)
            if ct ~= nil then
                ct.call("toggleCompleted", {name, not checkmarkState})
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
    local specialAction = getTarget(tagsMap, { "rewind", "forward" })
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
    if not selected then
        local page = tonumber(value)
        if page ~= nil then
            changePage(target, page)
        end
    else
        local len = string.len(value)
        lastChar = string.sub(value, len, len)
        if lastChar == "\n" then
            searchValue = string.sub(value, 1, len - 1)
            -- for _, input in ipairs(self.getInputs()) do
            --     if input.value == value then
            --         self.editInput({index=input.index, value=searchValue})
            --     end
            -- end
            local page = tonumber(value)
            if page ~= nil then
                changePage(target, page)
            end
        end
    end
end

function rewind(target)
    local bookState = state[target]
    if bookState ~= nil then
        if bookState.historyPosition > 1 then
            bookState.historyPosition = bookState.historyPosition - 1
            goToPage(target, bookState.history[bookState.historyPosition])
        end
    end
end

function forward(target)
    local bookState = state[target]
    if bookState ~= nil then
        if bookState.historyPosition < bookState.historySize then
            bookState.historyPosition = bookState.historyPosition + 1
            goToPage(target, bookState.history[bookState.historyPosition])
        end
    end
end

function changePage(target, page)
    local bookState = state[target]
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
            print(JSON.encode(currentState.getSnapPoints()))
        end
        -- still load the page though, just in case ...
        goToPage(target, page)
    end
end

function goToPage(target, page)
    local model = bookModels[target]
    if model ~= nil then
        -- First we need to locate the book
        local currentState = findObject(model)
        if currentState ~= nil then
            -- Now we need to find the target object / state
            for idx, entry in ipairs(model) do
                if page >= entry.from and page <= entry.to then
                    -- Switch state if needed
                    if currentState.guid ~= entry.guid then
                        currentState = currentState.setState(idx)
                        Wait.time(function() currentState.Book.setPage(page - entry.from) end, 0.5)
                    else
                        currentState.Book.setPage(page - entry.from)
                    end
                end
            end
        end
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
    else
        local page = buttonTargets[action]
        if page ~= nil then
            goToPage(target, page)
        end
    end
end

function setScenarioPage(page)
    goToPage("scenario book", page)
end
