require("savable")
require("deck_save_helpers")
require("utils")
require("fhlog")
require('player_mat_data')
require('cards')
require('am_draw')
require('constants')

function getState()
  local state = {}
  state.characterName = getCharacterName()
  if state.characterName ~= nil then
    -- We won't save anything unless we have a character loaded on the mat
    -- We need to store all ability cards, all attack modifier decks, and the character sheet

    -- Ability Cards
    table.sort(AbilityCardPositions, XZSorter)
    local abilityCards = {}
    abilityCards.discard = getCardList(cardLocations["discard"])
    abilityCards.lost = getCardList(cardLocations["lost"])
    local persistCards = {}
    for _, position in ipairs(cardLocations["persist"]) do
      table.insert(persistCards, getCardList(position))
    end
    abilityCards.persist = persistCards
    abilityCards.supply = getCardList(cardLocations['supply'])
    local playerHand = getPlayerHand()
    if playerHand ~= nil then
      abilityCards.hand = getCardListInZone(playerHand)
    end
    state.abilityCards = abilityCards

    -- Attack Modifiers
    attackModifiers = {}
    attackModifiers.draw = getCardList(AttackModifiersDrawPosition)
    attackModifiers.discard = getCardList(AttackModifiersDiscardPosition)
    attackModifiers.supply = getCardList(AttackModifiersSupplyPosition)
    state.attackModifiers = attackModifiers

    -- Perks
    perks = {}
    table.sort(PerksPositions, XZSorter)
    for _, position in ipairs(PerksPositions) do
      table.insert(perks, getCardList(position))
    end
    state.perks = perks

    -- Character sheet
    local characterSheet = getCharacterSheet()
    if characterSheet ~= nil then
      local sheetState = JSON.decode(characterSheet.call("forceSave"))
      state.characterSheet = sheetState
    end
  end

  return state
end

function onStateUpdate(state)
  -- print(JSON.encode(state))
  if state.characterName ~= nil then
    local characterName = state.characterName
    -- Get a new character box
    local characterBagGuid = CharacterBags[characterName]
    if characterBagGuid ~= nil then
      local characterBag = getObjectFromGUID(characterBagGuid)
      if characterBag ~= nil then
        local position = self.getPosition()
        position.z = position.z - 8
        position.y = position.y + 3
        LoadingCharacterBox = true
        characterBag.takeObject({
          position = position,
          rotation = { 0, 180, 0 },
          smooth = false,
          callback_function =
              function(characterBox)
                local fName = '_loadCharacterBox'
                self.setVar(fName, function()
                  loadCharacterBox(characterBox, state)
                  return 1
                end
                )
                startLuaCoroutine(self, fName)
              end
        })
        while LoadingCharacterBox do
          waitms(100)
        end
      end
    end
  else
    -- We need to clear it all
    clearBoard(true)
  end
end

function applyEnhancementsToCard(card)
  -- Delegate to enhancer
  getObjectFromGUID(EnhancerMatGuid).call('applyEnhancementsToCard', card)
end

function loadCharacterBox(characterBox, state)
  table.sort(UntaggedPositions, XZSorter)
  table.sort(TokenPositions, XZSorter)
  table.sort(PerksPositions, XZSorter)

  local playerNumber = getPlayerNumber()
  local characterName = state.characterName
  -- Ability Cards
  table.sort(AbilityCardPositions, XZSorter)
  local deck, guids = getRestoreDeckIn(characterBox, "Ability Cards", false)
  if deck ~= nil then
    local abilityCards = state.abilityCards
    if abilityCards ~= nil then
      deck = rebuildDeck(deck, guids, abilityCards.discard, cardLocations["discard"], false, nil, nil,
        applyEnhancementsToCard)
      deck = rebuildDeck(deck, guids, abilityCards.lost, cardLocations["lost"], false, nil, nil, applyEnhancementsToCard)
      for i, cards in ipairs(abilityCards.persist) do
        deck = rebuildDeck(deck, guids, cards, cardLocations["persist"][i], false, nil, nil, applyEnhancementsToCard)
      end
      deck = rebuildDeck(deck, guids, abilityCards.supply, cardLocations["supply"], false, nil, nil,
        applyEnhancementsToCard)

      local playerColor = getPlayerColor()
      local playerHand = getPlayerHand()
      if playerColor ~= nil and playerHand ~= nil then
        deleteCardsInZone(playerHand)
        --Handle cards which where in each player's hand
        if abilityCards.hand ~= nil then
          forEachInDeckOrCardIf(deck, function(card) card.deal(1, playerColor) end,
            function(e)
              for _, handCard in ipairs(abilityCards.hand) do
                if handCard == e.name or handCard == e.description then return true end
              end
              return false
            end)
        end
      end
      -- Move the remaining deck to the side
      if deck ~= nil and not deck.isDestroyed() then
        deck.setPosition(deck.getPosition() + Vector(5, 0, 0))
      end
    else
      local remaining = {}
      for _, obj in ipairs(deck.getObjects()) do
        table.insert(remaining, obj.name)
      end
      deck = rebuildDeck(deck, guids, remaining, cardLocations["supply"], false, nil, nil, applyEnhancementsToCard)
    end
  end

  -- Attack Modifiers
  local deck, guids = getRestoreDeckIn(characterBox, "Attack Modifiers", false)
  local baseDeck, baseGuids = getRestoreDeck("Attack Modifiers " .. playerNumber)
  local attackModifiers = state.attackModifiers
  if attackModifiers ~= nil then
    deck,baseDeck = rebuildDeck(deck, guids, attackModifiers.draw, AttackModifiersDrawPosition, true, baseDeck, baseGuids)
    deck,baseDeck = rebuildDeck(deck, guids, attackModifiers.discard, AttackModifiersDiscardPosition, false, baseDeck,
      baseGuids)
    deck,baseDeck = rebuildDeck(deck, guids, attackModifiers.supply, AttackModifiersSupplyPosition, false, baseDeck,
      baseGuids)
    -- Detroy remaining cards from base deck
    if baseDeck ~= nil and not baseDeck.isDestroyed() then
      destroyObject(baseDeck)
    end
  else
    setAtLocalPosition(baseDeck, AttackModifiersDrawPosition, true)
    setAtLocalPosition(deck, AttackModifiersSupplyPosition)
  end

  -- Perks
  local perks = state.perks
  local deck, guids = getRestoreDeckIn(characterBox, "Perks", false)
  deck.addTag("perk")
  if perks ~= nil then
    -- print(JSON.encode(perks))
    if deck ~= nil then
      for i, position in ipairs(PerksPositions) do
        -- print(deck)
        -- print(deck.tag)
        deck = rebuildDeck(deck, guids, perks[i], position, i == 3, nil, nil, function(e) e.addTag("perk") end)
      end
    end
  else
    setAtLocalPosition(deck, PerksPositions[#PerksPositions])
  end

  -- Clear the non card positions
  clearBoard(false)

  -- Character sheet
  local characterSheet = getRestoreObjectIn(characterBox, "CharacterSheet_" .. characterName, false)
  if characterSheet ~= nil then
    local sheetState = state.characterSheet
    if sheetState ~= nil then
      -- might be hacky
      characterSheet.script_state = JSON.encode(sheetState)
    end
    setAtLocalPosition(characterSheet, CharacterSheetPosition)
    -- characterSheet.setLock(true)
  end

  -- Character Mat & figurine (and potential 2nd figurine for the Geminate)
  local currentUntagged = 1
  for i = 1, 3 do
    local characterObject = getRestoreObjectIn(characterBox, characterName, false)
    if characterObject ~= nil then
      if characterObject.tag == "Tile" then
        setAtLocalPosition(characterObject, CharacterMatPosition)
        -- characterObject.setLock(true)
      else
        setAtLocalPosition(characterObject, UntaggedPositions[currentUntagged])
        currentUntagged = currentUntagged + 1
      end
    end
  end

  -- Finish emptying the box
  local currentToken = 1
  local zShift = 0
  for _, obj in ipairs(characterBox.getObjects()) do
    local isToken = false
    for _, tag in ipairs(obj.tags) do
      if tag == "token" then
        isToken = true
      end
    end
    -- Always take out tokens, but only take out other objects (Standees) if we have room
    local destination, rotation
    if isToken then
      destination = TokenPositions[currentToken]
      currentToken = currentToken + 1
      rotation = { 0, 0, 180 }
    else
      destination = UntaggedPositions[currentUntagged]
      destination.z = destination.z + zShift
      currentUntagged = currentUntagged + 1
      if currentUntagged > #UntaggedPositions then
        currentUntagged = 1
        zShift = zShift - 0.2
      end
      rotation = { 0, 0, 0 }
    end
    destination.y = destination.y + 1.5
    characterBox.takeObject({
      guid = obj.guid,
      position = self.positionToWorld(destination),
      rotation = rotation,
      smooth = false
    })
  end

  -- detroy the box
  if not characterBox.isDestroyed() then
    destroyObject(characterBox)
  end

  LoadingCharacterBox = false
end

function clearBoard(includeDecks)
  includeDecks = includeDecks or false
  local positionsToClear = { CharacterSheetPosition, CharacterMatPosition }
  for _, position in ipairs(TokenPositions) do
    table.insert(positionsToClear, position)
  end
  for _, position in ipairs(UntaggedPositions) do
    table.insert(positionsToClear, position)
  end

  if includeDecks then
    table.insert(positionsToClear, AttackModifiersDrawPosition)
    table.insert(positionsToClear, AttackModifiersDiscardPosition)
    table.insert(positionsToClear, AttackModifiersSupplyPosition)
    for name, position in pairs(cardLocations) do
      if name == "persist" then
        for _, pos in ipairs(position) do
          table.insert(positionsToClear, pos)
        end
      else
        table.insert(positionsToClear, position)
      end
    end
    for _, position in ipairs(PerksPositions) do
      table.insert(positionsToClear, position)
    end
  end

  for _, position in ipairs(positionsToClear) do
    if position ~= nil then
      local obj = findLocalObject(position)
      if obj ~= nil then
        if not obj.isDestroyed() then
          destroyObject(obj)
        end
      end
    end
  end

  local playerHand = getPlayerHand()
  deleteCardsInZone(playerHand)
end

function getPlayerNumber()
  for i = 1, 5 do
    if self.getName() == PlayerColors[i] .. " Player Mat" then
      return i
    end
  end
  return -1
end

function getPlayerColor()
  return PlayerColors[getPlayerNumber()]
end

function getPlayerHand()
  return PlayerHands[getPlayerColor()]
end

ItemCardPositions = {}

function onLoad()
  TAG = self.getDescription()
  fhLogInit()
  buttonPositions = {}
  cardLocations = {}
  locateBoardElementsFromTags()

  if buttonPositions["draw"] ~= nil then
    local pos = buttonPositions["draw"]
    local button_parameters = {
      function_owner = self,
      click_function = "drawAttackModifier",
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
    local button_parameters = {
      function_owner = self,
      click_function = "shuffleAttackModifiers",
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
    self.addContextMenuItem("Pack Character", packCharacter)
  end

  setDecals()
  registerSavable(self.getName())
end

function packCharacter()
  local characterName = getCharacterName()
  if characterName == nil then
    broadcastToAll("No character to pack")
    return
  end
  local level = getCharacterLevel()
  local character = getState()
  local items = {}
  -- We also need to store which items the character has
  local itemPositions = getItemCardPositionsInternal()
  for name, position in pairs(itemPositions) do
    items[name] = getCardList(position)
  end
  local quests = getCardList(PersonalQuestCardPosition)
  local save = { character = character, items = items, quests = quests }
  fhlog(DEBUG, TAG, "Packing Character : %s", save)
  local originalBag = getObjectFromGUID(CharacterBags[characterName])
  if originalBag ~= nil then
    local customObject = originalBag.getCustomObject()
    local dropPosition = self.getPosition()
    dropPosition.z = dropPosition.z + 8
    dropPosition.y = dropPosition.y + 1
    local box = spawnObject({
      type = "Custom_Model",
      position = dropPosition,
      scale = { .5, .5, .5 },
      sound = false
    })
    box.setCustomObject({
      mesh = customObject.mesh,
      type = 0,
      material = 3,
      diffuse = customObject.diffuse,
    })
    box.setName("Level " .. level .. " " .. characterName)
    box.addTag("Saved Character")
    box.setGMNotes(JSON.encode(save))

    -- Get return locations from items mat
    local cardReturnPositions = JSON.decode(getObjectFromGUID('bbcede').call("getItemsDrawPiles"))
    -- Return all item cards to their location
    for name, position in pairs(itemPositions) do
      local deck = getDeckOrCardAt(position)
      -- fhlog(DEBUG, TAG, "At item position %s found %s", position, deck ~= nil)
      local returnCard = function(card)
        fhlog(DEBUG, TAG, "Moving %s back to the supply", card.getName())
        if card.hasTag("craftable") then
          addCardToDeckAtWorldPosition(card, cardReturnPositions['craftable'])
        elseif card.hasTag("purchasable") then
          addCardToDeckAtWorldPosition(card, cardReturnPositions['purchasable'])
        elseif card.hasTag("other") then
          addCardToDeckAtWorldPosition(card, cardReturnPositions['other'])
        end
      end
      forEachInDeckOrCard(deck, returnCard)
    end

    -- Return personal quest card to the "inactive" personal quest pile
    local pqPosition = JSON.decode(getObjectFromGUID('0fa145').call('getPersonalQuestInactivePosition'))
    local deck = getDeckOrCardAt(PersonalQuestCardPosition)
    forEachInDeckOrCard(deck, function(card) addCardToDeckAtWorldPosition(card, pqPosition) end)

    clearBoard(true)
  end
end

function onObjectCollisionEnter(params)
  local obj = params[2].collision_object
  if obj.hasTag("character mat") then
    Global.call("getScenarioMat").call("updateCharacters")
  elseif obj.hasTag("character box") then
    -- move the container out of the mat to avoid conflicts with unpacking it
    local pos = self.getPosition()
    pos.y = pos.y + 3
    pos.z = pos.z - 10
    obj.setPosition(pos)
    local fName = "_loadCharacterBox"
    self.setVar(fName, function()
      loadCharacterBox(obj, { characterName = obj.getName() })
      return 1
    end)
    startLuaCoroutine(self, fName)
  elseif obj.hasTag("Saved Character") then
    local gmNotes = obj.getGMNotes()
    destroyObject(obj)
    local fName = "_loadSavedCharacter"
    self.setVar(fName, function()
      local save = JSON.decode(gmNotes)
      loadSavedCharacter(save)
      return 1
    end)
    startLuaCoroutine(self, fName)
  end
end

function loadSavedCharacter(save)
  onStateUpdate(save.character)
  loadItems(save.items)
  loadPersonalQuest(save.quests)
end

function onObjectCollisionExit(params)
  local obj = params[2].collision_object
  if obj.hasTag("character mat") then
    -- Let's give it a bit of time for the character mat to be lifted
    Wait.time(function() Global.call("getScenarioMat").call("updateCharacters") end, 1)
  end
end

function loadItems(items)
  local itemPositions = getItemCardPositionsInternal()
  local cardSupplyPositions = JSON.decode(getObjectFromGUID('bbcede').call("getItemsDrawPiles"))

  for positionName, itemsAtPosition in pairs(items) do
    for _, item in ipairs(itemsAtPosition) do
      fhlog(DEBUG, TAG, "Moving item %s from the supply back to board (%s position)", item, positionName)
      local candidates = { "purchasable", "craftable", "other" }
      local found = 0
      for _, candidate in ipairs(candidates) do
        local deck = getDeckOrCardAtWorldPosition(cardSupplyPositions[candidate])
        if deck ~= nil then
          found = found +
              forEachInDeckOrCardIf(deck, function(card) addCardToDeckAt(card, itemPositions[positionName]) end,
                function(entry) return entry.name == item end)
        end
      end
      if found == 0 then
        broadcastToAll(string.format("Item #%d was not found in any of the supplies. %s item was not restored", item,
          positionName))
      end
    end
  end
end

function loadPersonalQuest(quests)
  for _, quest in ipairs(quests) do
    local pqPosition = JSON.decode(getObjectFromGUID('0fa145').call('getPersonalQuestInactivePosition'))
    local deck = getDeckOrCardAtWorldPosition(pqPosition)
    forEachInDeckOrCardIf(deck, function(card) addCardToDeckAt(card, PersonalQuestCardPosition) end,
      function(entry) return entry.name == quest end)
  end
end

TokenPositions = {}
CharacterSheetPosition = {}
AbilityCardPositions = {}
AttackModifiersSupplyPosition = {}
PerksPositions = {}
UntaggedPositions = {}

function locateBoardElementsFromTags()
  local persistPositions = {}
  for _, point in ipairs(self.getSnapPoints()) do
    local tagsMap = {}
    local nbTags = 0
    local position = point.position
    for _, tag in ipairs(point.tags) do
      tagsMap[tag] = true
      nbTags = nbTags + 1
    end

    if tagsMap["deck"] ~= nil then
      if tagsMap["attack modifier"] ~= nil then
        if tagsMap["draw"] ~= nil then
          AttackModifiersDrawPosition = position
        elseif tagsMap["discard"] ~= nil then
          AttackModifiersDiscardPosition = position
        elseif tagsMap['supply'] ~= nil then
          AttackModifiersSupplyPosition = position
        end
      end
    end
    if tagsMap["ability card"] ~= nil then
      if tagsMap["discard"] ~= nil then
        cardLocations["discard"] = position
      elseif tagsMap["lost"] ~= nil then
        cardLocations["lost"] = position
      elseif tagsMap["persist"] ~= nil then
        table.insert(persistPositions, position)
      elseif tagsMap['supply'] ~= nil then
        cardLocations["supply"] = position
      end
    end
    if tagsMap["button"] ~= nil then
      if tagsMap["draw"] ~= nil then
        buttonPositions["draw"] = position
      elseif tagsMap["shuffle"] ~= nil then
        buttonPositions["shuffle"] = position
      end
    end
    if tagsMap["character mat"] ~= nil then
      CharacterMatPosition = position
    end
    if tagsMap["character sheet"] ~= nil then
      CharacterSheetPosition = position
    end
    if tagsMap["perk"] ~= nil then
      table.insert(PerksPositions, position)
    end
    if tagsMap["token"] ~= nil then
      table.insert(TokenPositions, position)
    end
    if tagsMap["item"] ~= nil then
      table.insert(ItemCardPositions, position)
    end
    if tagsMap["personal quest"] ~= nil then
      PersonalQuestCardPosition = position
    end
    if nbTags == 0 then
      table.insert(UntaggedPositions, position)
    end
  end
  table.sort(persistPositions, compareX)
  cardLocations["persist"] = persistPositions
end

function getItemCardPositions()
  return JSON.encode(getItemCardPositionsInternal(true))
end

function getItemCardPositionsInternal(mapToWorld)
  mapToWorld = mapToWorld or false
  table.sort(ItemCardPositions, function(a, b) return 30 * (a.z - b.z) + b.x - a.x < 0 end)
  local itemNames = { "hand1", "head", "hand2", "chest", "item1", "feet", "item2", "item3", "item4", "item5" }

  local results = {}
  for i, name in ipairs(itemNames) do
    if mapToWorld then
      results[name] = self.positionToWorld(ItemCardPositions[i])
    else
      results[name] = ItemCardPositions[i]
    end
  end

  return results
end

function getPersonalQuestCardPosition()
  return JSON.encode(self.positionToWorld(PersonalQuestCardPosition))
end

function shiftUp(position, offset)
  offset = offset or 0.5
  return { position.x, position.y + offset, position.z }
end

function compareX(obj1, obj2)
  if obj1.x > obj2.x then
    return true
  else
    return false
  end
end

function drawAttackModifier(external)
  if external ~= true then
    external = false
  end
  draw({ type = "player", player = getPlayerNumber() }, AttackModifiersDrawPosition, AttackModifiersDiscardPosition,
    not external)
end

function shuffleAttackModifiers()
  shuffle(AttackModifiersDrawPosition, AttackModifiersDiscardPosition)
end

function getCharacterName()
  if CharacterMatPosition ~= nil then
    local characterMat = findLocalObject(CharacterMatPosition, "", "character mat")
    if characterMat ~= nil then
      local worldPos = self.positionToWorld(CharacterMatPosition)
      -- print(characterMat.getPosition().y .. " <-> " .. worldPos.y )
      if characterMat.getPosition().y <= worldPos.y + 0.15 then
        return characterMat.getName()
      end
    end
  end
  return nil
end

function getCharacterLevel()
  local characterSheet = getCharacterSheet()
  if characterSheet ~= nil then
    return characterSheet.call("getCharacterLevel")
  end
  return nil
end

function getCharacterSheet()
  if CharacterSheetPosition ~= nil then
    return findLocalObject(CharacterSheetPosition, "", "character sheet")
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
  card.setPosition(self.positionToWorld(shiftUp(cardLocations["discard"], 0.1)))
end

function loseCard(card)
  card.setPosition(self.positionToWorld(shiftUp(cardLocations["lost"], 0.1)))
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
      card.setPosition(shiftUp(location, 0.1))
      return
    end
  end
end

function endTurn()
  returnCardsFromDiscard(AttackModifiersDiscardPosition)
  shuffleIfNeeded(AttackModifiersDrawPosition, AttackModifiersDiscardPosition)
end

function cleanup()
  cleanupAttackModifiers(AttackModifiersDrawPosition, AttackModifiersDiscardPosition)

  -- Restore items
  for _, position in ipairs(ItemCardPositions) do
    local deckOrCard = getDeckOrCardAt(position)
    if deckOrCard ~= nil then
      deckOrCard.setRotationSmooth({ 0, 0, 0 })
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
  }) -- returns {{Vector point, Vector normal, float distance, Object hit_object}, ...}

  local found = false
  for i, j in pairs(hitlist) do
    if j.hit_object.tag == "Card" then
      card = j.hit_object
      rot = card.getRotation()[2]
      if rot > -1 and rot < 1 then
        if card.hasTag("lost") then
          card.flip()
        else
          card.setRotationSmooth({ 0, 90, 0 }, false, false)
        end
      else
        card.setRotationSmooth({ 0, 0, 0 }, false, false)
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
  local card = params[1]
  addCardToDeckAt(card, AttackModifiersDrawPosition, { shuffle = true })
end

function endScenario(payload)
  cleanup()
  local xp = payload.xp
  local loot = payload.loot
  local characterSheet = getCharacterSheet()
  if characterSheet ~= nil then
    characterSheet.call("addEx", { name = 'xp', amount = xp })
    for name, value in pairs(loot) do
      characterSheet.call("addEx", { name = name, amount = value })
    end
  end
end
