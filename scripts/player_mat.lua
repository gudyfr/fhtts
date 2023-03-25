function onLoad()
  buttonPositions = {}
  cardLocations = {}
  locateBoardElementsFromTags()

  if buttonPositions["draw"] ~= nil then
    local pos = buttonPositions["draw"]
    local button_parameters = {
      function_owner = self,
      click_function = "draw",
      label          = "Draw",
      position       = { -pos.x, pos.y, pos.z },
      width          = 200,
      height         = 200,
      font_size      = 50,
      color          = { 1, 1, 1, 0 },
      scale          = { 1, 1, 0.3 },
      font_color     = { 1, 1, 1, 0 },
      tooltip        = "Draw an attack modifier card",
    }

    self.createButton(button_parameters)
  end

  if buttonPositions["shuffle"] ~= nil then
    local pos = buttonPositions["shuffle"]
    button_parameters = {
      function_owner = self,
      click_function = "shuffle",
      label          = "Shuffle",
      position       = { -pos.x, pos.y, pos.z },
      width          = 200,
      height         = 200,
      font_size      = 50,
      color          = { 1, 1, 1, 0 },
      scale          = { 1, 1, 0.3 },
      font_color     = { 1, 1, 1, 0 },
      tooltip        = "Shuffle the attack modifier deck",
    }

    self.createButton(button_parameters)

    Global.call("registerForCollision", self)
  end

  setDecals()
end

function onObjectCollisionEnter(params)
  local obj = params[2].collision_object
  if obj.hasTag("character mat") then
    Global.call("getScenarioMat").call("updateCharacters")
  end
end

function locateBoardElementsFromTags()
  local persistPositions = {}
  for _, point in ipairs(self.getSnapPoints()) do
    local tagsMap = {}
    for _, tag in ipairs(point.tags) do
      tagsMap[tag] = true
    end

    if tagsMap["deck"] ~= nil then
      if tagsMap["attack modifier"] ~= nil then
        if tagsMap["draw"] ~= nil then
          drawLocation = point.position
        elseif tagsMap["discard"] ~= nil then
          discardLocation = point.position
        end
      end
    end
    if tagsMap["ability card"] ~= nil then
      if tagsMap["discard"] ~= nil then
        cardLocations["discard"] = point.position
      elseif tagsMap["lost"] ~= nil then
        cardLocations["lost"] = point.position
      elseif tagsMap["persist"] ~= nil then
        table.insert(persistPositions, point.position)
      end
    end
    if tagsMap["button"] ~= nil then
      if tagsMap["draw"] ~= nil then
        buttonPositions["draw"] = point.position
      elseif tagsMap["shuffle"] ~= nil then
        buttonPositions["shuffle"] = point.position
      end
    end
    if tagsMap["character mat"] ~= nil then
      CharacterMatPosition = point.position
    end
  end
  table.sort(persistPositions, compareX)
  cardLocations["persist"] = persistPositions
end

function shiftUp(position, offset)
  if offset == nil then
    offset = 0.06
  end
  return { position.x, position.y + offset, position.z }
end

function compareX(obj1, obj2)
  if obj1.x > obj2.x then
    return true
  else
    return false
  end
end

function draw()
  local hitlist = Physics.cast({
    origin       = self.positionToWorld(drawLocation),
    direction    = { 0, 1, 0 },
    type         = 2,
    size         = { 1, 1, 1 },
    max_distance = 0,
    debug        = true
  })   -- returns {{Vector point, Vector normal, float distance, Object hit_object}, ...}

  for i, j in pairs(hitlist) do
    if j.hit_object.tag == "Deck" then
      local card = j.hit_object.takeObject({
        position = self.positionToWorld(shiftUp(discardLocation, 0.5)),
        flip     = true
      })
      Global.call("showDrawnCard", card)
      return card
    elseif j.hit_object.tag == "Card" then
      j.hit_object.setPosition(self.positionToWorld(shiftUp(discardLocation, 0.5)))
      j.hit_object.flip()
      Global.call("showDrawnCard", j.hit_object)
      return j.hit_object
    end
  end
end

function getCharacterName()
  if CharacterMatPosition ~= nil then
    local hitlist = Physics.cast({
      origin       = self.positionToWorld(CharacterMatPosition),
      direction    = { 0, 1, 0 },
      type         = 2,
      size         = { 1, 1, 1 },
      max_distance = 0,
      debug        = false
    })

    if hitlist ~= nil then
      for i, j in pairs(hitlist) do
        for _, tag in ipairs(j.hit_object.getTags()) do
          if tag == "character mat" then
            return j.hit_object.getName()
          end
        end
      end
    end
  end

  return nil
end

function shuffle()
  local hitlist = Physics.cast({
    origin       = self.positionToWorld(discardLocation),
    direction    = { 0, 1, 0 },
    type         = 2,
    size         = { 1, 1, 1 },
    max_distance = 0,
    debug        = true
  })   -- returns {{Vector point, Vector normal, float distance, Object hit_object}, ...}

  for i, j in pairs(hitlist) do
    if j.hit_object.tag == "Deck" or j.hit_object.tag == "Card" then
      deck = Physics.cast({
        origin       = self.positionToWorld(drawLocation),
        direction    = { 0, 1, 0 },
        type         = 2,
        size         = { 1, 1, 1 },
        max_distance = 0,
        debug        = false
      })   -- returns {{Vector point, Vector normal, float distance, Object hit_object}, ...}
      local shuffled = false
      for u, v in pairs(deck) do
        if v.hit_object.tag == "Deck" then
          v.hit_object.putObject(j.hit_object)
          v.hit_object.shuffle()
          v.hit_object.shuffle()
          shuffled = true
        end
      end
      if not shuffled then
        j.hit_object.setPosition(self.positionToWorld(shiftUp(drawLocation, 0.5)))
        j.hit_object.flip()
        j.hit_object.shuffle()
        j.hit_object.shuffle()
      end
      return
    end
  end
end

function getDiscard()
  local hitlist = Physics.cast({
    origin       = self.positionToWorld(discardLocation),
    direction    = { 0, 1, 0 },
    type         = 2,
    size         = { 1, 1, 1 },
    max_distance = 0,
    debug        = false
  })   -- returns {{Vector point, Vector normal, float distance, Object hit_object}, ...}

  for i, j in pairs(hitlist) do
    if j.hit_object.tag == "Deck" or j.hit_object.tag == "Card" then
      return j.hit_object
    end
  end
end

function returnCard(params)
  card = params[1]
  state = params[2]
  if state == 0 then
    discardCard(card)
  elseif state == 1 then
    persistCard(card)
  else
    loseCard(card)
  end
end

function discardCard(card)
  card.setPosition(self.positionToWorld(shiftUp(cardLocations["discard"])))
end

function loseCard(card)
  card.setPosition(self.positionToWorld(shiftUp(cardLocations["lost"])))
end

function persistCard(card)
  for _, pos in ipairs(cardLocations["persist"]) do
    local location = self.positionToWorld(pos)
    local hitlist = Physics.cast({
      origin       = location,
      direction    = { 0, 1, 0 },
      type         = 2,
      size         = { 1, 1, 1 },
      max_distance = 0,
      debug        = false
    })

    local found = false
    for i, j in pairs(hitlist) do
      if j.hit_object.tag == "Card" then
        found = true
      end
    end

    if not found then
      card.setPosition(shiftUp(location))
      return
    end
  end
end

function endTurn()
  returnCardsFromDiscard()
  local discard = getDiscard()
  if discard ~= nil then
    if discard.tag == "Card" then
      -- Card
      if discard.hasTag("shuffle") then
        shuffle()
        return
      end
    else
      -- Deck
      deck = discard.getObjects()
      for i, card in pairs(deck) do
        for _, tag in ipairs(card.tags) do
          if tag == "shuffle" then
            shuffle()
            return
          end
        end
      end
    end
  end
end

function returnCardsFromDiscard()
  local discard = getDiscard()
  if discard ~= nil then
    if discard.tag == "Card" then
      -- Card
      if discard.hasTag("return") then
        returnCardToScenarioMat(discard)
      end
    else
      -- Deck
      deck = discard.getObjects()
      for i, card in pairs(deck) do
        local target = card
        for _, tag in ipairs(target.tags) do
          if tag == "return" then
            local toReturn
            if discard.remainder ~= nil then
              toReturn = discard.remainder
            else
              toReturn = discard.takeObject({ guid = card.guid, smooth = false })
            end
            returnCardToScenarioMat(toReturn)
          end
        end
      end
    end
  end
end

function cleanup()
  shuffle()
  local hitlist = Physics.cast({
    origin       = self.positionToWorld(drawLocation),
    direction    = { 0, 1, 0 },
    type         = 2,
    size         = { 1, 1, 1 },
    max_distance = 0,
    debug        = true
  })

  for _,hit in pairs(hitlist) do
    if hit.hit_object.tag == "Deck" then
      local deck = hit.hit_object
      local cards = deck.getObjects()
      for _,card in ipairs(cards) do
        for _,tag in ipairs(card.tags) do
          if tag == "player minus 1" or tag == "player curse" or tag == "bless" then
            local card = deck.takeObject({guid=card.guid})
            returnCardToScenarioMat(card)
          end
        end
      end
    end
  end
end

function returnCardToScenarioMat(card)
  scenarioMat = Global.call("getScenarioMat")
  if scenarioMat ~= nil then
    scenarioMat.call("returnCard", { card })
  end
end

function setDecals()
  decals = {}
  for i, point in pairs(self.getSnapPoints()) do
    for j, tag in ipairs(point.tags) do
      if tag == "item" then
        table.insert(decals, getDecal(point.position))
        fName = "toggle_item_" .. i
        self.setVar(fName, function() toggleItem(point.position) end)
        position = getDecalPosition(point.position)
        position[1] = -position[1]
        params = {
          function_owner = self,
          click_function = fName,
          label          = "Use",
          position       = position,
          width          = 200,
          height         = 200,
          font_size      = 50,
          color          = { 1, 1, 1, 0 },
          scale          = { .3, .3, .3 },
          font_color     = { 1, 1, 1, 0 },
          tooltip        = "Flip the item used / unused",
        }
        self.createButton(params)
      end
    end
  end
  self.setDecals(decals)
end

function toggleItem(position)
  local location = self.positionToWorld(position)
  local hitlist = Physics.cast({
    origin       = location,
    direction    = { 0, 1, 0 },
    type         = 2,
    size         = { 1, 1, 1 },
    max_distance = 0,
    debug        = false
  })     -- returns {{Vector point, Vector normal, float distance, Object hit_object}, ...}

  local found = false
  for i, j in pairs(hitlist) do
    if j.hit_object.tag == "Card" then
      card = j.hit_object
      rot = card.getRotation()[2]
      if rot > 179 and rot < 181 then
        if card.hasTag("lost") then
          card.flip()
        else
          card.setRotationSmooth({ 0, 270, 0 }, false, false)
        end
      else
        card.setRotationSmooth({ 0, 180, 0 }, false, false)
      end
    end
  end
end

decalOffset = { -.22, 0.01, 0.22 }
function getDecal(position)
  decalPosition = getDecalPosition(position)
  --position[1] = -position[1]
  return {
    name = "use",
    url = "http://cloud-3.steamusercontent.com/ugc/2015962364024290735/DE772393E13501BA7D490876C5FF70E672B082D1/",
    position = decalPosition,
    rotation = { 90, 180, 0 },
    scale = { 0.065, 0.060, 0.060 }
  }
end

function getDecalPosition(position)
  return {
    position[1] + decalOffset[1],
    position[2] + decalOffset[2],
    position[3] + decalOffset[3]
  }
end

function addCardToAttackModifiers(params)
  card = params[1]

  hitlist = Physics.cast({
    origin       = self.positionToWorld(drawLocation),
    direction    = { 0, 1, 0 },
    type         = 2,
    size         = { 1, 1, 1 },
    max_distance = 0,
    debug        = false
  })
  for i, j in pairs(hitlist) do
    if j.hit_object.tag == "Deck" or j.hit_object.tag == "Card" then
      deck = j.hit_object.putObject(card)
      deck.shuffle()
      return
    end
  end
  card.setPosition(self.positionToWorld(drawLocation))
end
