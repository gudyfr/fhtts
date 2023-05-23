require('cards')

Drawn = {}
DrawnReturnTimer = nil

function shiftUp(position, offset)
    offset = offset or 0.5
    return { position.x, position.y + offset, position.z }
end

function draw(source, drawDeck, discardDeck, internal)
    internal = internal or false
    local absoluteTarget
    if internal then
        absoluteTarget = self.positionToWorld(shiftUp(discardDeck))
    else
        local target = { x = -2.7, y = 0.7, z = -9.2 }
        local scenarioMat = getObjectFromGUID('4aa570')
        absoluteTarget = scenarioMat.positionToWorld(target)
    end

    local hitlist = Physics.cast({
        origin       = self.positionToWorld(drawDeck),
        direction    = { 0, 1, 0 },
        type         = 2,
        size         = { 1, 1, 1 },
        max_distance = 0,
        debug        = true
    })

    if not internal then
        if DrawnReturnTimer ~= nil then
            Wait.stop(DrawnReturnTimer)
        end
        DrawnReturnTimer = Wait.time(returnDrawnCards, 5.0)
        absoluteTarget.x = absoluteTarget.x - #Drawn * 1.5
    end

    for i, j in pairs(hitlist) do
        if j.hit_object.tag == "Deck" then
            local card = j.hit_object.takeObject({
                position = absoluteTarget,
                flip     = true
            })
            Global.call("showDrawnCard", { source = source, card = card })
            if not internal then
                table.insert(Drawn, { card = card, returnPosition = discardDeck })
            end
            return card
        elseif j.hit_object.tag == "Card" then
            local card = j.hit_object
            card.setPosition(absoluteTarget)
            card.flip()
            Global.call("showDrawnCard", { source = source, card = card })
            if not internal then
                table.insert(Drawn, { card = card, returnPosition = discardDeck })
            end
            return card
        end
    end
end

function returnDrawnCards(immediate)
    immediate = immediate or false
    for _, info in ipairs(Drawn) do
        if info.card.hasTag("return") then
            returnCardToScenarioMat(info.card)
        else
            if immediate then
                addCardToDeckAt(info.card, info.returnPosition)
            else
                info.card.setPositionSmooth(self.positionToWorld(shiftUp(info.returnPosition)))
            end
        end
    end
    Drawn = {}
    if DrawnReturnTimer ~= nil then
        Wait.stop(DrawnReturnTimer)
        DrawnReturnTimer = nil
    end
end

function shuffleIfNeeded(drawDeck, discardDeck)
    local discard = getDiscard(discardDeck)
    local shuffleCount = forEachInDeckOrCardIf(discard, nil,
        function(entry)
            for _, tag in ipairs(entry.tags) do if tag == "shuffle" then return true end end
            return false
        end)

    if shuffleCount > 0 then
        shuffle(drawDeck, discardDeck)
    end
end

function shuffle(drawDeck, discardDeck)
    -- We need to retun cards first
    returnDrawnCards(true)
    returnCardsFromDiscard(discardDeck)
    Wait.time(function()
        local discard = getDiscard(discardDeck)
        local draw = getDeckOrCardAt(drawDeck)
        if draw == nil then
            draw = discard
            if draw ~= nil then
                draw.setRotationSmooth({ x = 0, y = 0, z = 180 })
                draw.setPositionSmooth(shiftUp(self.positionToWorld(drawDeck)))
            end
        else
            forEachInDeckOrCard(discard, function(card)
                card.setRotation({ x = 0, y = 0, z = 180 })
                draw.putObject(card)
            end)
        end
        if draw ~= nil then
            draw.shuffle()
        end
    end, 0.2)
end

function getDiscard(discardDeck)
    return getDeckOrCardAt(discardDeck)
end

function returnCardsFromDiscard(discardDeck)
    local discard = getDiscard(discardDeck)
    forEachInDeckOrCardIf(discard, returnCardToScenarioMat,
        function(entry)
            for _, tag in ipairs(entry.tags) do if tag == "return" then return true end end
            return false
        end)
end

function cleanupAttackModifiers(drawDeck, discardDeck)
    shuffle(drawDeck, discardDeck)
    local deck = getDeckOrCardAt(drawDeck)
    forEachInDeckOrCardIf(deck, returnCardToScenarioMat,
        function(entry)
            for _, tag in ipairs(entry.tags) do if tag == "return" or tag == "player minus 1" then return true end end
            return false
        end)
end

function returnCardToScenarioMat(card)
    local scenarioMat = Global.call("getScenarioMat")
    if scenarioMat ~= nil then
        scenarioMat.call("returnCard", { card })
    end
end

function endTurnCleanup(drawDeck, discardDeck)
    returnCardsFromDiscard(discardDeck)
    local discard = getDiscard(discardDeck)
    if discard ~= nil then
        if discard.tag == "Card" then
            -- Card
            if discard.hasTag("shuffle") then
                shuffle(drawDeck, discardDeck)
                return
            end
        else
            -- Deck
            local deck = discard.getObjects()
            for i, card in pairs(deck) do
                for _, tag in ipairs(card.tags) do
                    if tag == "shuffle" then
                        shuffle(drawDeck, discardDeck)
                        return
                    end
                end
            end
        end
    end
end
