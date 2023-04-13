function onLoad()
    searchPositions = {}
    for _,point in pairs(self.getSnapPoints()) do
        local tagged = false
        local tags = {}
        for _,tag in ipairs(point.tags) do
            tags[tag] = 1
        end
        -- print(JSON.encode(tags))

        if tags["input"] ~= nil then
                createInput(point.position)
                tagged = true
        elseif tags["button"] ~= nil then
            if tags["search"] ~= nil then
                createSearchButton(point.position)
            elseif tags["audio play"] ~= nil then
                if tags["a"] ~= nil then
                    createPlayAButton(point.position)
                elseif tags["b"] ~= nil then
                    createPlayBButton(point.position)
                else
                    createPlayButton(point.position)
                end                
            elseif tags["return"] then
                createReturnButton(point.position)
            end
            tagged = true
        elseif tags["result"] then
            resultPosition = point.position
            tagged = true
        elseif tags["active"] then
            activePosition = point.position
            tagged = true
        end

        if not tagged then
            table.insert(searchPositions, point.position)
        end
    end
end
searchText = ""

function createInput(position)
    local params = {
        input_function = "onTextEdit",
        function_owner = self,
        position = {-position[1],position[2],position[3]},
        scale = { .2, 1, .2 },
        width = 1500,
        height = 250,
        font_size = 200,
        color = { 1, 1, 1, 0 },
        font_color = { 0, 0, 0, 100 },
        alignment = 3
    }
    self.createInput(params)
end

function onTextEdit(obj, color, text, selected)
    local len = string.len(text)
    lastChar = string.sub(text,len,len)
    if lastChar == "\n" then
       searchText = string.sub(text, 1, len-1)
       obj.setValue(searchText)
       search()
    else
        searchText = text
    end
end

function createPlayButton(position)
    createButton(position, "playCard" , "Play")
end

function createPlayAButton(position)
    createButton(position, "playCard_A" , "Option A")
end

function createPlayBButton(position)
    createButton(position, "playCard_B" , "Option B")
end

function createReturnButton(position)
    createButton(position, "returnCard", "Return")
end

function createSearchButton(position)
   createButton(position, "search", "Search")
end

function createButton(position, fName, tooltip)
    -- print("Creating button " .. tooltip)
    params = {
        function_owner = self,
        click_function = fName,
        tooltip        = tooltip,
        position       = {-position[1],position[2],position[3]},
        width          = 200,
        height         = 200,
        font_size      = 50,
        color          = {1,1,1,0},
        scale          = {.3, .3, .3},
        font_color     = {1, 1, 1, 0},
      }
      self.createButton(params)
end

function search()
    if searchText == nil or resultPosition == nil then
        return
    end
    for _,position in ipairs(searchPositions) do
        local hitlist = Physics.cast({
            origin       = self.positionToWorld(position),
            direction    = {0,1,0},
            type         = 2,
            size         = {1,1,1},
            max_distance = 0,
            debug        = false })

        for _,result in ipairs(hitlist) do
            if result.hit_object.tag == "Deck" then
                for _,obj in ipairs(result.hit_object.getObjects()) do
                    if obj.name == searchText then
                        result.hit_object.takeObject({guid=obj.guid, position=self.positionToWorld(resultPosition)})
                        result.hit_object.highlightOn({r=0,g=1,b=0},2) 
                    end
                end
            elseif result.hit_object.tag == "Card" then
                if result.hit_object.name == searchText then
                    result.hit_object.setPosition(resultPosition)        
                end
            end
        end
    end
end

function getActiveCard()
    if activePosition ~= nil then
        local hitlist = Physics.cast({
            origin       = self.positionToWorld(activePosition),
            direction    = {0,1,0},
            type         = 2,
            size         = {1,1,1},
            max_distance = 0,
            debug        = false})
            for _,h in ipairs(hitlist) do
                if h.hit_object.tag == "Card" then
                    return h.hit_object
                end
            end
    end
    return nil
end

function returnCard()
    local activeCard = getActiveCard()
    if activeCard ~= nil then
        -- We need to determine the appropriate deck to return this card to
        local type = string.sub(activeCard.getName(), 1, 1)
        if type == 'S' then

        elseif type == 'W' then

        elseif type == 'B' then
            
        end
    end
end

function playCard()
    local activeCard = getActiveCard()
    if activeCard ~= nil then
        local name = activeCard.getName()
        Global.call("playNarration",{"Events",name})
    end
end

function playCard_A()
    local activeCard = getActiveCard()
    if activeCard ~= nil then
        local name = activeCard.getName()
        Global.call("playNarration",{"Events",name .. "_A"})
    end
end

function playCard_B()
    local activeCard = getActiveCard()
    if activeCard ~= nil then
        local name = activeCard.getName()
        Global.call("playNarration",{"Events",name .. "_B"})
    end
end