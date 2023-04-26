function searchCard(name, searchPositions, resultPosition)
    if name == nil or searchPositions == nil or resultPosition == nil then
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
                    if obj.name == name then
                        result.hit_object.takeObject({guid=obj.guid, position=self.positionToWorld(resultPosition)})
                        result.hit_object.highlightOn({r=0,g=1,b=0},2) 
                    end
                end
            elseif result.hit_object.tag == "Card" then
                if result.hit_object.name == name then
                    result.hit_object.setPosition(resultPosition)        
                end
            end
        end
    end
end