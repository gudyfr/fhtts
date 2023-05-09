require('json')
require('constants')
require('coordinates')
require('fhlog')

TAG = "Global"

scenarioBagId = 'cd31b5'
ruleBookId = '0ea82e'
monsterStandeesBagId = '454465'
characterStandeesBagId = '09c686'
bossStandeesBagId = '69b1fc'
scenarioBookId = '5cd351'
mapTilesBagId = '9cbcab'

--[[ The onLoad event is called after the game save finishes loading. --]]
function onLoad(save)
   fhLogInit()
   addHotkey("Play Initiative Card",
      function(player_color, hovered_object, pointer, key_up) playCard(player_color, 1) end)
   addHotkey("Play Second Card", function(player_color, hovered_object, pointer, key_up) playCard(player_color, 2) end)
   addHotkey("Play Third Card", function(player_color, hovered_object, pointer, key_up) playCard(player_color, 3) end)
   addHotkey("Draw Card", function(player_color, hovered_object, point, key_up) drawCard(player_color) end)
   addHotkey("Sort Hand by initiative", function(player_color, hovered_object, point, key_up) sortHand(player_color) end)

   -- Restore the triggers
   local state = JSON.decode(save or {}) or {}
   if state.activeScenario ~= nil then
      CurrentScenario = state.activeScenario
      local scenarioTriggers = CurrentScenario.triggers or {}
      --We need to re-create the potential action buttons
      for guid, triggerIds in pairs(scenarioTriggers.byObjectGuid or {}) do
         local obj = getObjectFromGUID(guid)
         if obj ~= nil then
            for _, triggerId in ipairs(triggerIds) do
               local trigger = scenarioTriggers.triggersById[triggerId]
               -- No need to update the trigger in the scenarioTriggers
               attachTriggerToElement(trigger, obj, CurrentScenario.id, 1, true)
            end
         end
      end
      local id = CurrentScenario.id
      if id ~= nil then
         self.setVar("triggerClicked_" .. id,
            function(obj, color, alt)
               onTriggerClicked(id, obj.guid, alt)
            end)
      end
      local registeredForCollitions = CurrentScenario.registeredForCollision or {}
      for _, guid in ipairs(registeredForCollitions) do
         local object = getObjectFromGUID(guid)
         if object ~= nil then
            object.registerCollisions()
         end
      end
   else
      CurrentScenario = {}
   end

   CurrentScenarioObjects = getScenarioElementObjects()

   Wait.frames(updateData, 1)
   Wait.frames(fhLogSettingsUpdated, 1)
end

function onSave()
   local state = { activeScenario = CurrentScenario }
   return JSON.encode(state)
end

function getBaseUrl()
   local devSettings = JSON.decode(getDevSettings())
   if devSettings['use-dev-assets'] or false then
      local settings = JSON.decode(getSettings())
      local address = settings.address
      local port = settings.port
      if address ~= nil and port ~= nil then
         return "http://" .. address .. ":" .. port .. "/out/"
      end
   end

   return "https://gudyfr.github.io/fhtts/"
end

function refreshScenarioData(baseUrl)
   broadcastToAll("Loading Scenario Data")
   WebRequest.get(baseUrl .. "scenarios.json", processScenarioData)
   WebRequest.get(baseUrl .. "processedScenarios2.json",
      processAdditionalScenarioData)
end

function processScenarioData(request)
   -- print("Parsing Scenario Data")
   scenarios = json.parse(request.text)
   fhlog(DEBUG, TAG, "Scenario Data loaded")
end

function processAdditionalScenarioData(request)
   ScenarioInfos = jsonDecode(request.text)
   fhlog(DEBUG, TAG,"Scenario Layout Data loaded")
end

letterConfigs = {
   A = {
      tile = "AB",
      flip = false
   },
   B = {
      tile = "AB",
      flip = true
   },
   C = {
      tile = "CD",
      flip = false
   },
   D = {
      tile = "CD",
      flip = true
   },
   E = {
      tile = "EF",
      flip = false
   },
   F = {
      tile = "EF",
      flip = true
   },
   G = {
      tile = "GH",
      flip = false
   },
   H = {
      tile = "GH",
      flip = true
   },
   I = {
      tile = "IJ",
      flip = false
   },
   J = {
      tile = "IJ",
      flip = true
   },
   K = {
      tile = "KL",
      flip = false
   },
   L = {
      tile = "KL",
      flip = true
   },
}

TileLetterMappings = {
   A = "A",
   B = "B",
   C = "A",
   D = "B",
   E = "A",
   F = "B",
   G = "A",
   H = "B",
   I = "A",
   J = "B",
   K = "A",
   L = "B"
}

function getMapTile(mapName, layout)
   nameLen = string.len(mapName)
   letter = string.sub(mapName, nameLen)
   config = letterConfigs[letter]
   mapTileName = string.sub(mapName, 1, nameLen - 1) .. config.tile
   mapBag = getObjectFromGUID(mapTilesBagId)
   for _, tile in pairs(mapBag.getObjects()) do
      if tile.name == mapTileName then
         mapTile = mapBag.takeObject({ guid = tile.guid })
         clone = mapTile.clone()
         mapBag.putObject(mapTile)
         local targetZRot = 0
         if config.flip then
            targetZRot = 180
         else
            targetZRot = 0
         end
         clone.addTag("deletable")
         clone.addTag("tile")
         local handled = false
         if layout ~= nil then
            for _, tileLayout in ipairs(layout) do
               if not handled and tileLayout.name == mapName then
                  -- print(JSON.encode(tileLayout))
                  local center = tileLayout.center

                  -- Hacky Fixes, we should fix the assets themselves instead
                  local tileNumber = string.sub(mapName, 1, 2)
                  local tileLetter = string.sub(mapName, 4, 4)
                  local mappedTileLetter = TileLetterMappings[tileLetter]
                  local orientation = (tonumber(tileLayout.orientation) or 0)
                  orientation = orientation + (AdditionalRotation[tileNumber] or 0)
                  orientation = orientation + (AdditionalRotation[tileNumber .. "-" .. mappedTileLetter] or 0)

                  if orientation > 180 then
                     orientation = orientation - 360
                  end

                  clone.setRotation({ 0, -orientation, targetZRot })
                  local hx, hz = getWorldPositionFromHexPosition(center.x, center.y)
                  clone.setPosition({ hx, 1.39, hz })
                  clone.setLock(true)
                  handled = true
                  clone.registerCollisions()
                  table.insert(CurrentScenario.registeredForCollision, clone.guid)
                  local tileGuids = CurrentScenario.tileGuids or {}
                  tileGuids[mapName] = clone.guid
               end
            end
         end
         if not handled then
            getObjectFromGUID(scenarioBagId).putObject(clone)
         end
         return
      end
   end
end

function getMonster(monster, scenarioElementPositions, currentScenarioElementPosition)
   local name = monster.name
   bagIds = { monsterStandeesBagId, characterStandeesBagId, bossStandeesBagId }
   for id, bagId in ipairs(bagIds) do
      monsterBag = getObjectFromGUID(bagId)
      for id, candidate in pairs(monsterBag.getObjects()) do
         if candidate.name == name then
            local position = scenarioElementPositions[currentScenarioElementPosition]
            local monsterStandees = monsterBag.takeObject({ guid = candidate.guid, smooth = false })
            local clone = monsterStandees.clone()
            monsterBag.putObject(monsterStandees)
            clone.addTag("deletable")
            clone.addTag("scenarioElement")
            clone.addTag("spawner")
            if bagId == bossStandeesBagId or (monster.boss or false) then
               clone.addTag("boss")
            end

            if monster.as ~= nil then
               -- We need to get a monster out of the bag, reset the bag and put the monster back in the bag.
               -- And rename both
               local obj = clone.takeObject()
               obj.setName(monster.as)
               clone.setName(monster.as)
               clone.reset()
               clone.putObject(obj)
            end

            if monster.loot ~= nil then
               if monster.loot == "as body" then
                  clone.addTag("loot as body")
               elseif monster.loot == "none" then
                  clone.addTag("no loot")
               elseif monster.loot == "as rubble" then
                  clone.addTag("loot as rubble")
               end
            end

            if position ~= nil then
               local pos = { position.x, position.y + 1.4, position.z }
               --clone.setLock(true)
               clone.setPosition(pos)
               -- clone.setRotation({ 0, 180, 0 })
            else
               getObjectFromGUID(scenarioBagId).putObject(clone)
            end
         end
      end
   end
end

tokenBagsGuids = {
   n1 = '89f48c',
   n2 = '166ec3',
   n3 = '767548',
   n4 = 'e0d378',
   n5 = '91d577',
   n6 = 'af78de',
   n7 = '979463',
   n8 = 'c4946a',
   n9 = '94824b',
   n10 = 'e93174',
   n11 = 'aa55af',
   n12 = 'd593a3',
   a = '346c96',
   b = '4d2a7b',
   c = '52c747',
   d = '35fef4',
   e = '7a1e07',
   f = 'd0aec7',
   g = 'ca5ccf',
   h = 'da4781',
   i = 'b9ead6',
   j = '7da71f',
   k = '196642',
   m = '45fdef',
   start = '0511b3',
   loot = '5e0624'
}

function getToken(token, position)
   local bagId = tokenBagsGuids[token.name]
   if bagId == nil then
      bagId = tokenBagsGuids["n" .. token.name]
   end
   if bagId ~= nil then
      local bag = getObjectFromGUID(bagId)
      if bag ~= nil then
         local count = token.count or 1
         for i = 1, count do
            local obj
            if position ~= nil then
               local pos = { position.x, position.y + i / 10, position.z }
               obj = bag.takeObject({ position = pos, smooth = false })
            else
               obj = bag.takeObject()
            end

            obj.setRotation({ 0, 180, 0 })
            obj.addTag("token")
            obj.addTag("scenarioElement")
            if token.tags ~= nil then
               for _, tag in ipairs(token.tags) do
                  obj.addTag(tag)
               end
            end

            if token.as ~= nil then
               obj.setName(token.as)
            end

            if token.renamed ~= nil then
               if token.renamed == "by nr" then
                  local start_nr = token.start_nr or 1
                  obj.setName(obj.getName() .. " " .. (start_nr + count - i))
               end
            end

            if token.trackable or false then
               obj.addTag("trackable")
            end

            if position == nil then
               -- No more room, let's add to the scenario bag
               getObjectFromGUID(scenarioBagId).putObject(obj)
            else
               return obj
            end
         end
      end
   end
end

function spawnNElementsIn(count, trackables, name, info, destination, scenarioElementPositions,
                          currentScenarioElementPosition)
   destination = getObjectFromGUID('cd31b5')
   bag = getObjectFromGUID('5cd812')
   bag.setLock(false)
   bags = bag.getObjects()
   local tracked = trackables[name]
   for id, overlayBag in pairs(bags) do
      if overlayBag.name == name then
         container = bag.takeObject({ guid = overlayBag.guid })
         for i = 1, count do
            local obj
            local addedToScenarioMat = false
            if scenarioElementPositions ~= nil then
               local position = scenarioElementPositions[currentScenarioElementPosition]
               if position ~= nil then
                  local pos = { position.x, position.y + i / 10, position.z }
                  obj = container.takeObject({ position = pos, smooth = false })
                  addedToScenarioMat = true
               end
            end

            if not addedToScenarioMat then
               obj = container.takeObject({})
            end

            if obj ~= nil then
               obj.addTag("overlay")
               obj.addTag("deletable")
               obj.addTag("scenarioElement")
               obj.registerCollisions()
               table.insert(CurrentScenario.registeredForCollision, obj.guid)
               if (info.trackable or false) then
                  obj.addTag("trackable")
                  -- For sizing of the overlays
                  obj.addTag("overlay")
               end
               for _, tag in ipairs(info.tags or {}) do
                  obj.addTag(tag)
               end

               -- Change the name before the applying the "renamed" field
               -- As they might combine (eg. scenario 20)
               if info.as ~= nil then
                  obj.setName(info.as)
               end
               if info.renamed ~= nil then
                  if info.renamed == "by nr" then
                     local start_nr = info.start_nr or 1
                     obj.setName(obj.getName() .. " " .. (start_nr + count - i))
                  elseif info.renamed == "by letter" then
                     local letters = "abcdefghijklmnopqrstuvwxyz"
                     local start_nr = info.start_nr or 1
                     local letter = string.sub(letters, start_nr + count - i, start_nr + count - i)
                     obj.setName(obj.getName() .. " " .. letter)
                  end
               end

               if info.type ~= nil then
                  local type = info.type
                  local color = nil
                  local underlay = {
                     name = "underlay_" .. type,
                     position = { 0, 0, 0 },
                     scale = { .75, .75, .75 },
                     rotation = { 90, 0, 0 },
                  }
                  local overlay = {
                     name = "overlay_" .. type,
                     position = { 0, 0.025, -.25 },
                     scale = { 0.2, 0.2, 0.2 },
                     rotation = { 90, 0, 0 },
                  }
                  if type == "Obstacle" then
                     -- color = { 29, 126, 59 }
                     underlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219237165/2678AF8F59D023C77DF641FEC8910835D182257E/"
                     overlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219236688/D9F31375FC450BD9BE3984EB47FD1E3C5E758A17/"
                  elseif type == "Pressure Plate" then
                     -- color = { 173, 173, 173 }
                     underlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219237206/6A0777484779A8722080530B0C43D1C82473A0C5/"
                     overlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219236727/7D01B94C25BEA92CBE0957ECC6A422429EDD44CD/"
                  elseif type == "Trap" then
                     -- color = { 228, 19, 19 }
                     underlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219237268/7A7C3B0E0060C8FE23A359463F9A12C22FFA17DA/"
                     overlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219236774/BCB319F990BE7A9127849A4615486318C987AD7C/"
                  elseif type == "Wall" then
                     -- color = { 53, 52, 53 }
                     underlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219237311/0E7EBC101D0643E90645E0AFED2534DCD30CA7C9/"
                     overlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219236827/8B11DFC742D94410A3A220903F37894D384F5098/"
                  elseif type == "Corridor" then
                     -- color = { 172, 172, 172 }
                     underlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219236874/45C3A28338A6EFCB0A2FEE9332D3F6033CCB6F9B/"
                     overlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219236428/A0AF561889DB69EC01F03BBBE560396F343ADE69/"
                  elseif type == "Difficult Terrain" then
                     -- color = { 121, 58, 210 }
                     underlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219236926/31F6DFAA41FDB6649461472B1F8D3129E60CB4E4/"
                     overlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219236470/666B6A71A88CFFA389AAD94DB74060F77192063B/"
                  elseif type == "Door" then
                     -- color = { 34, 96, 209 }
                     underlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219236982/77263BF7C8933BF32D3F3C54BC5D13493B54D1CF/"
                     overlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219236511/1C789E9836AF1DC13FFFDABB239CBE3A19C0B3C5/"
                  elseif type == "Hazardous Terrain" then
                     -- color = { 244, 127, 32 }
                     underlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219237027/9EF685D0E353DB1ADE2826410AA3195F3095E8FB/"
                     overlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219236545/DD2676FE8B97B20F2C671803FED9BCC0C137B17D/"
                  elseif type == "Icy Terrain" then
                     -- color = { 83, 205, 20 }
                     underlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219237076/93DC787398B26C6263924F3AD2E1A03AA13A6162/"
                     overlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219236588/7A1556D352C180A003F8D5BC44BE6BB2FE1B486B/"
                  elseif type == "Objective" then
                     -- color = { 238, 189, 38 }
                     underlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219237113/AD6DDE3352CA5168C1FCCE247AF5BD9C3E544494/"
                     overlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219236640/33AF2DDD8AB13544A4954EBDD194CCD746BFE146/"
                  end

                  if color ~= nil then
                     color = { color[1] / 255, color[2] / 255, color[3] / 255 }
                     if settings["enable-highlight-tiles-by-type"] or false then
                        obj.highlightOn(color)
                     end
                     updateGMNotes(obj, { highlight = color })
                  end
                  local decals = {}
                  if underlay.url ~= nil then
                     table.insert(decals, underlay)
                     if (info.size or 1) > 1 then
                        underlay2 = {
                           name = underlay.name .. "_2",
                           url = underlay.url,
                           position = { -0.665, 0, 0 },
                           rotation = underlay.rotation,
                           scale = underlay.scale,
                        }
                        table.insert(decals, underlay2)
                        if info.size > 2 then
                           underlay3 = {
                              name = underlay.name .. "_3",
                              url = underlay.url,
                              position = { -0.3325, 0, -0.665 },
                              rotation = underlay.rotation,
                              scale = underlay.scale,
                           }
                           table.insert(decals, underlay3)
                        end
                     end
                  end
                  if overlay.url ~= nil then
                     table.insert(decals, overlay)
                  end
                  if Settings["enable-highlight-tiles-by-type"] or false then
                     obj.setDecals(decals)
                  end
               end


               if not addedToScenarioMat then
                  destination.putObject(obj)
               end
            else
               fhlog(ERROR, TAG, "Error finding overlay %s", name)
            end
         end
         bag.putObject(container)
      end
   end
   bag.setLock(true)
   return currentScenarioElementPosition
end

function updateGMNotes(obj, update)
   local current = getGMNotes(obj)
   for key, value in pairs(update) do
      current[key] = value
   end
   obj.setGMNotes(JSON.encode(current))
end

function getGMNotes(obj)
   local current = obj.getGMNotes()
   if current == nil or current == "" then
      current = {}
   else
      current = JSON.decode(current)
   end
   return current
end

function cleanupPrepareArea()
   local zone = getObjectFromGUID('1f0c29')
   for _, occupyingObject in ipairs(zone.getObjects(true)) do
      if occupyingObject.hasTag("deletable") then
         occupyingObject.destroyObject()
      end
   end
end

function cleanup(forceDelete, noMessage)
   forceDelete = forceDelete or false
   noMessage = noMessage or false
   local guids = {}
   local zones = { 'e1e978', '1f0c29' }
   local highlighted = false
   local deleted = false
   for _, zoneGuid in ipairs(zones) do
      local zone = getObjectFromGUID(zoneGuid)
      -- Iterate through object occupying the zone
      for _, occupyingObject in ipairs(zone.getObjects(true)) do
         if guids[occupyingObject.guid] == nil then
            guids[occupyingObject.guid] = 1
            if occupyingObject.hasTag("deletable") then
               if occupyingObject.hasTag("about to delete") or forceDelete then
                  occupyingObject.destroyObject()
                  deleted = true
               else
                  highlighted = true
                  occupyingObject.highlightOn('Red')
                  occupyingObject.addTag("about to delete")
               end
            end
         end
      end
   end

   if deleted then
      -- Notify all player mats to also cleanup their attack modifier decks
      for color, guid in pairs(PlayerMats) do
         getObjectFromGUID(guid).call("cleanup")
      end
      -- And clear the errata
      getScenarioMat().call('setErrata', nil)
   end

   if highlighted then
      if not noMessage then
         broadcastToAll("Delete highlighted objects? Press cleanup again.", { r = 1, g = 0, b = 0 })
      end
   end
   if not deleted then
      Wait.time(cleanupTimeout, 2)
   end

   return deleted
end

function cleanupTimeout()
   local zones = { 'e1e978', '1f0c29' }
   for _, zoneGuid in ipairs(zones) do
      local zone = getObjectFromGUID(zoneGuid)
      -- Iterate through object occupying the zone
      for _, occupyingObject in ipairs(zone.getObjects(true)) do
         if occupyingObject.hasTag("deletable") then
            occupyingObject.removeTag("about to delete")
            occupyingObject.highlightOff()
            local notes = getGMNotes(occupyingObject)
            if notes ~= nil and notes.highlight ~= nil then
               occupyingObject.highlightOn(notes.highlight)
            end
         end
      end
   end
end

function prepareSoloScenario(name)
   local scenario = scenarios["" .. name]
   if scenario ~= nil then
      local title = scenario["x-haven-title"]
      if title ~= nil then
         prepareScenario(name, "Solo", title)
      end
   end
end

function prepareFrosthavenScenario(name)
   local scenario = scenarios["" .. name]
   if scenario ~= nil then
      local title = "#" .. name .. " " .. (scenario.title or "")
      prepareScenario(name, "Frosthaven", title)
   end
end

function prepareScenario(name, campaign, title)
   name = tostring(name)
   Settings = JSON.decode(getSettings())
   -- This will simply highlight elements which would be destroyed if we were to prepare this scenario (if any)
   -- However, if the user retries the prepare this scenario, it will delete the current scenario mat and prepare the scenario
   local deleted = cleanup(false, true)
   local empty, hasItems = isLayoutAreaEmpty()
   if hasItems then
      -- Remove highlights right away
      cleanupTimeout()
      broadcastToAll("Scenario Mat has item cards on it. Can't prepare " .. title)
      return
   end
   if not deleted and not empty then
      broadcastToAll("Scenario Mat is not empty, try again to delete highlighted objects and prepare " .. title)
      return
   end
   broadcastToAll("Preparing " .. title)
   cleanupPrepareArea()
   CurrentScenario = {
      triggers = {
         byTriggerId = {},
         byObjectGuid = {},
         triggered = {},
         triggersById = {}
      },
      doors = {
      },
      tileGuids = {},
      objectsOnObjects = {},
      id = name,
      elements = scenarios[name],
      registeredForCollision = {}
   }
   self.setVar("triggerClicked_" .. name,
      function(obj, color, alt)
         onTriggerClicked(name, obj.guid, alt)
      end)

   local scenarioInfo = nil
   local layout = nil
   if ScenarioInfos ~= nil then
      scenarioInfo = deepCopy(ScenarioInfos[name])
      CurrentScenario.scenarioInfo = scenarioInfo
      if scenarioInfo ~= nil then
         layout = scenarioInfo.layout
      end
   end

   local scenarioBag = getObjectFromGUID('cd31b5')
   scenarioBag.reset()
   local elements = CurrentScenario.elements
   if elements ~= nil then
      local scenarioElementPositions = getScenarioMat().call("getScenarioElementPositions")
      local currentScenarioElementPosition = 0

      local choices = elements.choices

      if choices ~= nil then
         -- We first need to let players make a choice
         -- which we'll represent with tokens

         broadcastToAll("Please choose")

         -- We want to center the choices, and space them by two
         local firstPosition = (#scenarioElementPositions - #choices) / 2
         for _, choice in ipairs(choices) do
            local token = choice.token
            local value = choice.value
            if token ~= nil and value ~= nil then
               local title = choice.title or ("Choose " .. token)
               local obj = getToken({ name = token }, scenarioElementPositions[firstPosition])
               if obj ~= nil then
                  self.setVar("scenarioChoice_" .. token, function() prepareFrosthavenScenario(name .. value) end)
                  local params = {
                     click_function = "scenarioChoice_" .. token,
                     label = '',
                     position = { 0, 0.1, 0 },
                     rotation = { 0, 0, 0 },
                     width = 1000,
                     height = 1000,
                     color = { 1, 1, 1, 0 },
                     font_size = 50,
                     tooltip = title
                  }
                  obj.createButton(params)
               end
               firstPosition = firstPosition + 2
            end
         end
         if elements.page ~= nil then
            -- Tell the book mat to go to the right scenario page
            getObjectFromGUID('2a1fbe').call("setScenarioPage", { elements.page, tonumber(name), "Scenarios" })
         end
         return
      end


      local trackables = elements.trackables
      if trackables == nil then
         trackables = {}
      end

      for _, info in ipairs(elements.overlays) do
         local overlayName = info.name
         local count = info.count
         local size = 1
         if info.size ~= nil then
            size = info.size
            if size == 3 then
               -- 3 hex tiles only use 2 wide hexes
               size = 2
            elseif size == 2 then
               -- Now that we layout elements vertically, 2 wide elements only take 1 spot
               size = 1
            end
         end
         currentScenarioElementPosition = currentScenarioElementPosition + size
         -- print("Adding " ..
         --    count .. " " .. overlayName .. " to the scenario bag at pos " .. currentScenarioElementPosition)
         currentScenarioElementPosition = spawnNElementsIn(count, trackables, overlayName, info, scenarioBag,
            scenarioElementPositions, currentScenarioElementPosition)
      end



      -- print(JSON.encode(layout))

      for _, tileName in ipairs(elements.tiles) do
         -- print("Adding Map Tile " .. tileName .. " to the scenario bag")
         getMapTile(tileName, layout)
      end

      -- offset by 2 before the monsters
      currentScenarioElementPosition = currentScenarioElementPosition + 2
      if elements.monsters ~= nil then
         for index, monster in ipairs(elements.monsters) do
            -- print("Adding Monster " .. JSON.encode(monster))
            getMonster(monster, scenarioElementPositions, currentScenarioElementPosition)

            -- and they take a bit of space
            currentScenarioElementPosition = currentScenarioElementPosition + 1
         end
      end

      if elements.tokens ~= nil then
         for index, token in ipairs(elements.tokens) do
            -- print("Adding token " .. token.name)
            getToken(token, scenarioElementPositions[currentScenarioElementPosition])
            currentScenarioElementPosition = currentScenarioElementPosition + 1
         end
      end

      if elements.page ~= nil then
         -- Tell the book mat to go to the right scenario page
         local folder = "scenarios"
         if campaign == "Solo" then
            folder = "solo"
         end
         getObjectFromGUID('2a1fbe').call("setScenarioPage", { elements.page, name, folder })
      end

      getScenarioMat().call("setErrata", elements.errata)

      local settings = JSON.decode(getSettings())
      if settings["enable-automatic-scenario-layout"] or false then
         if name == "91" then
            prepareScenario91()
         end
         Wait.time(function() layoutScenarioElements(name) end, 0.5)
      end

      getScenarioMat().call("setScenario", { scenario = title, campaign = campaign })
   end
end

function isLayoutAreaEmpty()
   local zone = getObjectFromGUID(ScenarioMatZoneGuid)
   -- Iterate through object occupying the zone
   local hasDeletables = doesZoneContain(zone, "deletable")
   local hasItems = doesZoneContain(zone, "item")
   return not (hasDeletables or hasItems), hasItems
end

function doesZoneContain(zone, tag)
   for _, occupyingObject in ipairs(zone.getObjects(true)) do
      if occupyingObject.hasTag(tag) then
         return true
      end
   end
   return false
end

function layoutScenarioElements(id)
   if CurrentScenario.id == id then
      local scenarioInfo = CurrentScenario.scenarioInfo
      if scenarioInfo ~= nil then
         -- Locate the scenario entry map(s)
         CurrentScenarioObjects = getScenarioElementObjects()
         for _, map in ipairs(scenarioInfo['maps']) do
            if map.type == "scenario" then
               layoutMap(map)
            end
         end
      end
   end
end

function getScenarioElementObjects()
   local zone = getObjectFromGUID('1f0c29')
   return zone.getObjects(true)
end

function layoutMap(map)
   local elements = CurrentScenario.elements
   local scenarioInfo = CurrentScenario.scenarioInfo
   local objects = CurrentScenarioObjects
   -- Determine number of players
   local playerCount = getPlayerCount()
   if playerCount < 2 then
      playerCount = 2
   end

   local categories = { "monsters", "overlays", "tokens" }

   -- Calculate all name mappings
   local nameMappings = {}
   for _, category in ipairs(categories) do
      for _, entry in ipairs(elements[category] or {}) do
         local name = entry.name
         local to = entry.as or name
         local tos = nameMappings[name] or {}
         if entry.renamed ~= nil then
            local count = entry.count
            if entry.renamed == "by nr" then
               local start_nr = entry.start_nr or 1
               for i = 1, count do
                  table.insert(tos, to .. " " .. (start_nr + i - 1))
               end
            elseif entry.renamed == "by letter" then
               local letters = "abcdefghijklmnopqrstuvwxyz"
               local start_nr = entry.start_nr or 1
               for i = 1, count do
                  local letter = string.sub(letters, start_nr + i - 1, start_nr + i - 1)
                  table.insert(tos, to .. " " .. letter)
               end
            end
         else
            tos = table.insert(tos, to)
         end
         nameMappings[name] = tos
      end
   end

   for _, entry in ipairs(map.entries or {}) do
      local reference = entry.reference
      if reference == nil then
         return
      end
      local origin = getOrigin(scenarioInfo, reference.tile)
      if origin ~= nil then
         -- Overlays
         for _, overlay in ipairs(entry.overlays) do
            -- print("Looking for " .. overlay.name .. "(" .. overlay.orientation .. ")")
            for _, position in ipairs(overlay.positions) do
               local passesConditions = true
               if position.condition ~= nil then
                  if position.condition.players ~= nil then
                     passesConditions = false
                     for _, pass in ipairs(position.condition.players) do
                        if playerCount == pass then
                           passesConditions = true
                        end
                     end
                  end
               end

               if passesConditions then
                  -- print(" to put at location " .. JSON.encode(position))
                  local name = overlay.name
                  if position.renamed ~= nil then
                     name = position.renamed
                  end
                  local hx = position.x + origin.x
                  local hy = position.y + origin.y
                  local scenarioDoors = CurrentScenario.doors or {}
                  if position.type ~= "Door" or scenarioDoors[hx .. "," .. hy] == nil then
                     local obj = locateScenarioElementWithName(name, objects, true, nameMappings)
                     if position.rename ~= nil then
                        obj.setName(position.rename)
                     end
                     if obj ~= nil then
                        local x, z = getWorldPositionFromHexPosition(hx, hy)
                        if position.type == "Door" then
                           scenarioDoors[hx .. "," .. hy] = true
                        end
                        obj.setPosition({ x, 1.44, z })
                        local orientation = overlay.orientation or 0
                        if orientation > 180 then
                           orientation = orientation - 360
                        end
                        obj.setRotation({ 0, -orientation, 0 })

                        -- Handle potential triggers
                        if position.trigger ~= nil then
                           attachTriggerToElement(position.trigger, obj, scenarioInfo.id)
                        end
                     else
                        fhlog(WARNING, TAG, "Could not find object in prepare area : %s", overlay.name)
                     end
                  end
               end
            end
         end
         for _, token in ipairs(entry.tokens or {}) do
            local random = nil
            if token.random ~= nil then
               random = {}
               for i = 1, token.random.max do
                  table.insert(random, i)
               end

               -- Shuffle
               for i = #random, 2, -1 do
                  local j = math.random(i)
                  random[i], random[j] = random[j], random[i]
               end
            end

            for _, position in ipairs(token.positions) do
               local name = token.name
               if random ~= nil and #random > 0 then
                  name = "n" .. random[1]
                  table.remove(random, 1)
               end

               local obj = takeToken(name)
               if obj ~= nil then
                  local x, z = getWorldPositionFromHexPosition(position.x + origin.x, position.y + origin.y)
                  obj.setPosition({ x, 2.21, z })
                  local zRot = 0
                  if random ~= nil then
                     zRot = 180
                  end
                  obj.setRotation({ 0, 180, zRot })
                  if position.trigger ~= nil then
                     attachTriggerToElement(position.trigger, obj, scenarioInfo.id)
                  end
               end
            end
         end
         for _, monster in ipairs(entry.monsters or {}) do
            for _, position in ipairs(monster.positions) do
               local levels = position.levels
               if levels ~= nil then
                  local level = string.sub(levels, playerCount - 1, playerCount - 1)
                  if level == 'n' or level == 'e' or level == 'b' then
                     -- print("Adding a " .. level .. " " .. monster.name)
                     local monsterBag = locateScenarioElementWithName(monster.name, objects, false, nameMappings)
                     if monsterBag ~= nil then
                        local obj = monsterBag.takeObject({
                           callback_function = function(spawned) if level == 'e' then makeElite(spawned) end end,
                           smooth = false
                        })
                        local x, z = getWorldPositionFromHexPosition(position.x + origin.x, position.y + origin.y)
                        obj.setPosition({ x, 2.35, z })
                        -- Handle potential triggers
                        if position.trigger ~= nil then
                           attachTriggerToElement(position.trigger, obj, scenarioInfo.id)
                        end
                     end
                  end
               end
            end
         end
      end
   end

   local scenarioTriggers = CurrentScenario.triggers
   for _, trigger in ipairs(map.triggers or {}) do
      scenarioTriggers.triggersById[trigger.id] = trigger
      -- In addition, for manual triggers, we need to add a corresponding token
      if trigger.type == "manual" then
         local by = trigger.by
         local token = by.token
         local reference = by.at.reference
         local tokenOrigin = getOrigin(scenarioInfo, reference)
         if tokenOrigin ~= nil then
            local hx = by.at.x + tokenOrigin.x
            local hy = by.at.y + tokenOrigin.y
            local x, z = getWorldPositionFromHexPosition(hx, hy)
            local obj = getToken({ name = token }, { x = x, y = 2.35, z = z })
            Wait.time(function() obj.setLock(true) end, 2)
            attachTriggerToElement(trigger, obj, CurrentScenario.id, 2)
         end
      end
      -- Also handle custom triggers
      if trigger.type == "onload" then
         actualTriggered(CurrentScenario.id, trigger.id, nil, false, objects)
      end
   end
end

function popRandomItemFrom(list)
   local which = math.random(#list)
   local result = list[which]
   table.remove(list, which)
   return result
end

function deepCopy(obj)
   if type(obj) ~= 'table' then return obj end
   local res = {}
   for k, v in pairs(obj) do res[deepCopy(k)] = deepCopy(v) end
   return res
end

function prepareScenario91()
   local scenarioInfo = CurrentScenario.scenarioInfo
   if scenarioInfo == nil then return end

   local Scenario91Tokens = { "1", "2", "3", "4" }
   -- We need to pick 2 random numbers between 1 and 4
   local first = popRandomItemFrom(Scenario91Tokens)
   local second = popRandomItemFrom(Scenario91Tokens)
   local third = popRandomItemFrom(Scenario91Tokens)
   local fourth = popRandomItemFrom(Scenario91Tokens)

   -- broadcastToAll("Randomly picked " .. first .. ", " .. second .. ", " .. third .. ", " .. fourth)

   -- Fix the origin of 07-G
   for _, tile in ipairs(scenarioInfo.layout) do
      if tile.name == "07-G" then
         tile.origin = { x = -4, y = -1 }
      end
   end

   -- Setup each choice with the proper reference :
   -- first 07-G,
   -- second 07-D
   -- third 07-D
   -- fourth 07-B

   local newMaps = {}

   local maps = scenarioInfo.maps

   for _, map in ipairs(maps) do
      if map.type == "choice" then
         local tileName, mapName
         if map.name == first then
            tileName = "07-G"
            mapName = "first"
         elseif map.name == second then
            tileName = "07-D"
            mapName = "second"
         elseif map.name == third then
            tileName = "07-D"
            mapName = "third"
         elseif map.name == fourth then
            tileName = "07-B"
            mapName = "fourth"
         end
         --  Deep copy of this tile
         local newMap = deepCopy(map)
         for _, entry in ipairs(newMap.entries) do
            entry.reference.tile = tileName
         end
         newMap.name = mapName
         newMap.type = "tile"
         table.insert(newMaps, newMap)
      end
   end

   for _, map in ipairs(newMaps) do
      table.insert(maps, map)
   end
end

function getOrigin(scenarioInfo, reference)
   local origin = nil
   for _, layout in ipairs(scenarioInfo['layout'] or {}) do
      if layout.name == reference then
         origin = layout.origin
      end
   end
   return origin
end

function makeElite(obj)
   obj.setColorTint("Yellow")
   Global.call("getScenarioMat").call("toggled", obj)
end

function updateTriggers(trigger, obj)
   local scenarioTriggers = CurrentScenario.triggers
   local objs = scenarioTriggers.byTriggerId[trigger.id]
   if objs == nil then
      objs = {}
      scenarioTriggers.byTriggerId[trigger.id] = objs
   end
   local triggers = scenarioTriggers.byObjectGuid[obj.guid]
   if triggers == nil then
      triggers = {}
      scenarioTriggers.byObjectGuid[obj.guid] = triggers
   end
   scenarioTriggers.triggersById[trigger.id] = trigger
   table.insert(triggers, trigger.id)
   table.insert(objs, obj.guid)
end

function roundUpdate(payload)
   local currentRound = JSON.decode(payload)
   local scenarioTriggers = CurrentScenario.triggers
   -- Check potential triggers
   if scenarioTriggers ~= nil and scenarioTriggers.triggersById ~= nil then
      for id, trigger in pairs(scenarioTriggers.triggersById) do
         if trigger.type == "round" then
            if trigger.when.round == currentRound.round and trigger.when.state == currentRound.state then
               handleTriggerAction(trigger, CurrentScenario.id, nil, false)
            end
         end
      end
   end
end

function onEnemiesUpdate(payload)
   -- print("enemies update " .. payload)
   local characterStatus = nil
   -- Check potential triggers
   local scenarioTriggers = CurrentScenario.triggers
   if scenarioTriggers ~= nil and scenarioTriggers.triggersById ~= nil then
      for id, trigger in pairs(scenarioTriggers.triggersById) do
         if trigger.type == "alldead" then
            if characterStatus == nil then
               characterStatus = JSON.decode(payload)
            end
            -- Let's make sure that all monsters are dead
            local monsters = characterStatus.monsters or {}
            local allDead = true
            for name, info in pairs(monsters) do
               local excluded = false
               for _, excludedName in ipairs(trigger.exclude or {}) do
                  if string.find(name, excludedName) then
                     excluded = true
                  end
                  -- print(excludedName .. ", " .. name .. ", excluded : " .. tostring(excluded))
               end
               if not excluded and info.current > 0 then
                  allDead = false
               end
            end
            if allDead then
               handleTriggerAction(trigger, CurrentScenario.id, nil, false)
            end
         end
         if trigger.type == "health" then
            if characterStatus == nil then
               characterStatus = JSON.decode(payload)
            end
            local monsters = characterStatus.monsters or {}
            -- print(JSON.encode(monsters))
            for name, info in pairs(monsters) do
               if name == trigger.who then
                  local triggerLevel = math.ceil(info.max * trigger.level)
                  if info.current <= triggerLevel then
                     handleTriggerAction(trigger, CurrentScenario.id, nil, false)
                  end
               end
            end
         end
      end
   end
end

function onTriggerClicked(scenarioId, objGuid, undo)
   undo = undo or false
   if scenarioId == CurrentScenario.id then
      local objectTriggers = CurrentScenario.triggers.byObjectGuid[objGuid] or {}
      for _, triggerId in ipairs(objectTriggers) do
         actualTriggered(scenarioId, triggerId, objGuid, undo)
      end
   end
end

function triggeredById(triggerId)
   actualTriggered(CurrentScenario.id, triggerId, nil, false)
end

function triggerClicked(obj, color, alt)

end

function triggered(payload)
   local params = JSON.decode(payload)
   local scenarioId = params[1]
   local triggerId = params[2]
   local objGuid = params[3]
   actualTriggered(scenarioId, triggerId, objGuid, false)
end

function actualTriggered(scenarioId, triggerId, objGuid, undo)
   undo = undo or false
   local scenarioTriggers = CurrentScenario.triggers
   local trigger = scenarioTriggers.triggersById[triggerId]
   local type = trigger.type or ""

   if type == "countDown" then
      if trigger.current == 'playerCount' then
         trigger.current = getPlayerCount()
      end
      if undo then
         trigger.current = trigger.current + 1
      else
         trigger.current = trigger.current - 1
      end
      if trigger.current ~= 0 then
         -- Prevent triggering the countDown actions
         return
      end
   end

   if type == "door" or type == "on-death" then
      if trigger.locked or false then
         broadcastToAll("Locked")
         -- Prevent trigerring the door actions
         return
      end
      local doorGuidsToOpen
      local mode = trigger.mode or "first"
      if mode == "all" or mode == "removeall" then
         -- We need to open all doors for this trigger
         doorGuidsToOpen = scenarioTriggers.byTriggerId[trigger.id]
      else
         doorGuidsToOpen = { objGuid }
      end
      for _, guid in ipairs(doorGuidsToOpen) do
         local door = getObjectFromGUID(guid)
         if door ~= nil then
            if mode == "removeall" or type == "on-death" then
               destroyObject(door)
            else
               openDoor(door)
            end
         end
      end
   end

   if type == "pressure" and undo and (trigger.mode ~= "occupy") then
      -- We do not cancel non 'occupy' pressure plates
      return
   end

   handleTriggerAction(trigger, scenarioId, objGuid, undo)
end

function getTriggeredKey(trigger, objGuid)
   local dedupMode = trigger.dedupMode or "obj"

   local triggerKey = trigger.id
   if triggerKey == nil then
      fhlog(WARNING, TAG, "No trigger id in %s", trigger)
   end
   if dedupMode == "obj" then
      triggerKey = triggerKey .. "/" .. (objGuid or "scenario")
   elseif dedupMode == "first" then
      triggerKey = triggerKey .. "/first"
   else
      fhlog(WARNING, TAG, "Unknown dedupMode : %s in %s",dedupMode, trigger)
   end

   return triggerKey
end

function clearTriggered(trigger, guid)
   local scenarioTriggers = CurrentScenario.triggers
   local triggeredKey = getTriggeredKey(trigger, guid)
   -- Reset the triggered state
   -- print("Clearing " .. triggeredKey)
   scenarioTriggers.triggered[triggeredKey] = false

   -- Also reset poential `also` triggers
   if trigger.also ~= nil then
      for _, subTrigger in ipairs(trigger.also) do
         clearTriggered(subTrigger, guid)
      end
   end

   -- And other kind of sub triggers (timeout, trigger, ...)
   if trigger.trigger ~= nil and trigger.action ~= "attachTrigger" and trigger.action ~= "addTrigger" then
      clearTriggered(trigger.trigger, guid)
   end
end

-- Returns true if the targetted object was deleted, false, otherwise
function recursiveDeleteObjectsOn(guid, deleteSelf, exceptionsMap, onlysMap)
   exceptionsMap = exceptionsMap or {}
   deleteSelf = deleteSelf or false
   local objectsOnObjects = CurrentScenario.objectsOnObjects or {}
   local objectsOnObject = objectsOnObjects[guid] or {}
   -- Avoid possible endless recursion if an object is both on top and under an other one
   objectsOnObjects[guid] = {}
   for i = #objectsOnObject, 1, -1 do
      if recursiveDeleteObjectsOn(objectsOnObject[i], true, exceptionsMap, onlysMap) then
         table.remove(objectsOnObject, i)
      end
   end
   objectsOnObjects[guid] = objectsOnObject
   if deleteSelf then
      local object = getObjectFromGUID(guid)
      if object ~= nil then
         local name = object.getName()
         if object.hasTag("deletable") and exceptionsMap[name] == nil then
            if onlysMap == nil or onlysMap[name] ~= nil then
               -- Check if this is a door, in which case we need to update the scenarioDoors entries
               if string.find(name, "Door") then
                  local doorX, doorY = getHexPositionFromWorldPosition(object.getPosition())
                  local positionName = doorX .. "," .. doorY
                  local scenarioDoors = CurrentScenario.doors or {}
                  local found = scenarioDoors[positionName]
                  if found then
                     scenarioDoors[positionName] = nil
                  end
               end
               destroyObject(object)
               return true
            end
         end
      end
   end
   return false
end

function recursiveMoveObjectsOn(guid, dx, dy, smooth, selfOnly, hx, hy)
   if not selfOnly then
      local objectsOnObjects = CurrentScenario.objectsOnObjects or {}
      local objectsOnObject = objectsOnObjects[guid] or {}
      objectsOnObjects[guid] = {}
      for _, guid in ipairs(objectsOnObject) do
         recursiveMoveObjectsOn(guid, dx, dy, smooth, false, hx, hy)
      end
      objectsOnObjects[guid] = objectsOnObject
   end
   local object = getObjectFromGUID(guid)
   if object ~= nil then
      -- Check if this is a door, in which case we need to update the scenarioDoors entries
      if string.find(object.getName(), "Door") then
         local doorX, doorY = getHexPositionFromWorldPosition(object.getPosition())
         local positionName = doorX .. "," .. doorY
         local scenarioDoors = CurrentScenario.doors or {}
         local found = scenarioDoors[positionName]
         if found then
            scenarioDoors[positionName] = nil
            scenarioDoors[(doorX + hx) .. "," .. (doorY + hy)] = true
         end
      end
      local position = object.getPosition()
      local destination = { position.x + dx, position.y, position.z + dy }
      if smooth then
         object.setPositionSmooth(destination, false, false)
      else
         object.setPosition(destination)
      end
   end
end

function openDoor(obj)
   local guid = obj.guid
   local currentName = obj.getName()
   local newDoor = obj.setState(2)
   newDoor.setName(currentName)
   local newGuid = newDoor.guid
   local objectsOnObjects = CurrentScenario.objectsOnObjects or {}
   -- If the door was on some other object, then we should update it
   for _, objects in pairs(objectsOnObjects) do
      for i = 1, #objects do
         if objects[i] == guid then
            objects[i] = newGuid
         end
      end
   end
end

function handleTriggerAction(action, scenarioId, objGuid, undo)
   undo = undo or false
   -- print("Performing action on : " .. JSON.encode(action))
   local triggerKey = getTriggeredKey(action, objGuid)

   local scenarioTriggers = CurrentScenario.triggers
   local triggered = scenarioTriggers.triggered[triggerKey] or false
   if triggered == undo then
      -- print("Setting " .. triggerKey .. " to " .. tostring((not undo)))
      scenarioTriggers.triggered[triggerKey] = not undo
   else
      fhlog(DEBUG, TAG, "Not performing action, as trigger %s has already been triggered", triggerKey)
      -- We've already triggered this one, avoid triggering again
      return
   end

   if action.action == "timeout" then
      action.trigger.id = action.id .. "/timeout"
      Wait.time(function() handleTriggerAction(action.trigger, scenarioId, objGuid, undo) end, action.time)
   end

   if action.action == "reveal" then
      local what = action.what
      if what.type == "section" then
         broadcastToAll("Reading Section " .. what.name)
         getObjectFromGUID('2a1fbe').call('setSection', what.name)
         getScenarioMat().call("setSection", what.name)
      end
      if what.type == "section.solo" then
         playNarration({ "solo", what.name })
      end
      local key = what.type .. "/" .. what.name
      if not (scenarioTriggers.triggered[key] or false) then
         scenarioTriggers.triggered[key] = true
         local scenarioInfo = CurrentScenario.scenarioInfo
         if scenarioInfo ~= nil then
            for _, map in ipairs(scenarioInfo.maps) do
               if map.type == what.type and map.name == what.name then
                  layoutMap(map)
               end
            end
         end
      end
   end

   if action.action == "choice" then
      broadcastToAll("Please Choose")
      local scenarioInfo = CurrentScenario.scenarioInfos
      if scenarioInfo ~= nil then
         local choices = action.choices
         for i, choice in ipairs(choices) do
            if choice.tile ~= nil then
               local origin = nil
               for _, layout in ipairs(scenarioInfo['layout']) do
                  if layout.name == choice.tile then
                     origin = layout.origin
                  end
               end
               if origin ~= nil then
                  local obj = takeToken(choice.token)
                  if obj ~= nil then
                     local position = choice.position
                     local x, z = getWorldPositionFromHexPosition(position.x + origin.x, position.y + origin.y)
                     obj.setPosition({ x, 2.21, z })
                     obj.setRotation({ 0, 180, 0 })
                     local subTrigger = choice.data
                     subTrigger.id = action.id .. "/choice/" .. i
                     subTrigger.also = { { type = "removeMatching", what = (action.id .. "/choice") } }
                     scenarioTriggers.triggersById[subTrigger.id] = subTrigger
                     attachTriggerToElement(subTrigger, obj, scenarioId, 2)
                  end
               end
            end
         end
      end
   end

   if action.action == "trigger" then
      actualTriggered(scenarioId, action.what, objGuid, undo, objects)
   end

   if action.action == "open" then
      for _, otherTrigger in ipairs(scenarioTriggers.byTriggerId[action.what]) do
         local obj = getObjectFromGUID(otherTrigger)
         if obj ~= nil then
            openDoor(obj)
         end
      end
   end

   if action.action == "unlock" then
      local otherTrigger = scenarioTriggers.triggersById[action.what]
      otherTrigger.locked = undo
   end

   if action.action == "lock" then
      local otherTrigger = scenarioTriggers.triggersById[action.what]
      otherTrigger.locked = not undo
   end

   if action.action == "removeMatching" then
      local pattern = action.what
      for id, trigger in scenarioTriggers.triggersById do
         if string.sub(1, #pattern) == pattern then
            for _, guid in scenarioTriggers.byTriggerId[id] do
               local obj = getObjectFromGUID(guid)
               if obj ~= nil then
                  destroyObject(obj)
               end
            end
         end
      end
   end

   if action.action == "attachTrigger" then
      local what = action.what
      local currentTrigger = scenarioTriggers.triggersById[what]
      local newTrigger = action.trigger
      newTrigger.id = currentTrigger.id

      -- Reset the possible scenario triggered state
      clearTriggered(currentTrigger, nil)
      for _, objGuid in ipairs(scenarioTriggers.byTriggerId[what]) do
         if objGuid ~= nil then
            clearTriggered(currentTrigger, objGuid)
            local obj = getObjectFromGUID(objGuid)
            if obj ~= nil then
               attachTriggerToElement(newTrigger, obj, CurrentScenario.id, 1, true)
            end
         end
      end

      -- Attach the new trigger
      -- print("Replacing " .. action.what .. " into " .. JSON.encode(newTrigger))
      scenarioTriggers.triggersById[what] = newTrigger
   end

   if action.action == "addTrigger" then
      local what = action.what
      local newTrigger = action.trigger
      newTrigger.id = what

      scenarioTriggers.triggersById[what] = newTrigger
   end

   if action.action == "deleteOn" then
      local tileGuids = CurrentScenario.tileGuids or {}
      local tileGuid = tileGuids[action.what]
      if tileGuid ~= nil then
         local exceptions = {}
         for _, exception in ipairs(action.exceptions or {}) do
            exceptions[exception] = true
         end
         local onlys = nil
         if action.only ~= nil then
            onlys = {}
            for _, only in ipairs(action.only or {}) do
               onlys[only] = true
            end
         end
         recursiveDeleteObjectsOn(tileGuid, false, exceptions, onlys)
      end
   end

   if action.action == "move" then
      local what = action.what
      local by = action.by
      local mx, my = getWorldPositionFromHexPosition(by.x, by.y)
      local ox, oy = getWorldPositionFromHexPosition(0, 0)
      local dx = mx - ox
      local dy = my - oy
      local tileGuids = CurrentScenario.tileGuids or {}
      local tileGuid = tileGuids[what]
      if tileGuid ~= nil then
         local smooth = action.smooth
         local selfOnly = action.selfOnly or false
         if smooth == nil then smooth = true end
         recursiveMoveObjectsOn(tileGuid, dx, dy, smooth, selfOnly, by.x, by.y)
         -- We should also update the information in the scenario layout (in case a layout happens on that tile later)
         local scenarioInfo = CurrentScenario.scenarioInfo
         for _, tile in ipairs(scenarioInfo.layout) do
            if tile.name == what then
               tile.origin.x = tile.origin.x + by.x
               tile.origin.y = tile.origin.y + by.y
            end
         end
      end
   end

   if action.action == "flip" then
      local what = action.what
      local tileGuids = CurrentScenario.tileGuids or {}
      local tileGuid = tileGuids[what]
      if tileGuid ~= nil then
         local tileObject = getObjectFromGUID(tileGuid)
         if tileObject ~= nil then
            local rotation = tileObject.getRotation()
            if rotation.z > 160 then
               rotation.z = 0
            else
               rotation.z = 180
            end
            tileObject.setRotation(rotation)
         end
         local scenarioInfo = CurrentScenario.scenarioInfo
         for _, tile in ipairs(scenarioInfo.layout) do
            if tile.name == what then
               local nameMappings = {
                  A = "B",
                  B = "A",
                  C = "D",
                  D = "C",
                  E = "F",
                  F = "E",
                  G = "H",
                  H = "G",
                  I = "J",
                  J = "I"
               }
               local newName = string.sub(tile.name, 1, 3) .. nameMappings[string.sub(tile.name, 4, 4)]
               tile.name = newName
               CurrentScenario.tileGuids[newName] = tileGuid
            end
         end
      end
   end

   if action.action == "rotate" then
      local what = action.what
      local tileGuids = CurrentScenario.tileGuids or {}
      local tileGuid = tileGuids[what]
      if tileGuid ~= nil then
         local tileObject = getObjectFromGUID(tileGuid)
         if tileObject ~= nil then
            local rotation = tileObject.getRotation()
            rotation.y = rotation.y + (action.by or 0)
            tileObject.setRotation(rotation)
         end
         local scenarioInfo = CurrentScenario.scenarioInfo
         for _, tile in ipairs(scenarioInfo.layout) do
            if tile.name == what then
               local origin = tile.origin
               local center = tile.center
               local dx = origin.x - center.x
               local dy = origin.y - center.y
               local x, y = rotateHexCoordinates(dx, dy, action.by or 0)
               local originalOrigin = deepCopy(tile.origin)
               tile.origin.x = x + center.x
               tile.origin.y = y + center.y
               fhlog(DEBUG, TAG, "Remapped tile origin from %s to %s ", originalOrigin, tile.origin)
            end
         end
      end
   end

   if action.action == "layout" then
      local what = action.what
      layoutMap(what)
   end

   if action.also ~= nil then
      for i, subAction in ipairs(action.also) do
         subAction.id = subAction.id or action.id .. "/" .. i
         handleTriggerAction(subAction, scenarioId, objGuid, undo)
      end
   end
end

function attachTriggerToElement(trigger, obj, scenarioId, scale, skipUpdate)
   skipUpdate = skipUpdate or false
   if not skipUpdate then
      updateTriggers(trigger, obj)
   end
   local payload = JSON.encode({ scenarioId, trigger.id, obj.guid })
   if trigger.type ~= "pressure" then
      local fName = "trigger_" .. obj.guid .. "_" .. trigger.id
      self.setVar(fName, function() Global.call("triggered", payload) end)
      local label = trigger.display
      if label == nil then
         if trigger.type == "door" then
            label = "Open"
         elseif trigger.type == "on-death" then
            label = "Destroy"
         elseif trigger.type == "pressure" then
            if trigger.mode == "occupy" then
               label = "Occupy"
            else
               label = "Trigger"
            end
         elseif trigger.type == "manual" and trigger.action == "reveal" then
            label = "Reveal " .. trigger.what.type .. " " .. trigger.what.name
         end
      end
      -- Let's create a button
      local params = {
         click_function = "triggerClicked_" .. scenarioId,
         label = label,
         position = { 0, 0.01, 0 },
         rotation = { 0, 0, 0 },
         width = 250 * (scale or 1),
         height = 250 * (scale or 1),
         color = { 1, 1, 1, 0 },
         font_size = 50,
         tooltip = label
      }
      obj.createButton(params)
   end

   if trigger.type == "on-death" then
      -- We can also hook up a callback for when this item hit point reaches 0
      obj.setGMNotes(JSON.encode({ onDeath = payload }))
   end

   if trigger.type == "pressure" then
      -- Register the pressure plate
      registerPressurePlate(obj)
   end
end

function takeToken(name)
   local bagId = tokenBagsGuids[name]
   if bagId ~= nil then
      local bag = getObjectFromGUID(bagId)
      if bag ~= nil then
         return bag.takeObject()
      end
   end
end

function locateScenarioElementWithName(name, objects, remove, nameMappings)
   -- Look for the original name first, scenario 70 needs this as we have City Guards renamed and not at the same time
   for i, occupyingObject in ipairs(objects) do
      local candidateName = occupyingObject.getName()
      if name == candidateName then
         if remove then
            -- It's fine to remove while iterating, because we return right after,
            table.remove(objects, i)
         end
         return occupyingObject
      end
   end

   -- Then look for renamed items. Also, this works in scenario 70 because the renamed City Guard has been renamed in the layout data
   local alternateNames = nameMappings[name] or {}
   for _, alternateName in ipairs(alternateNames) do
      for i, occupyingObject in ipairs(objects) do
         local candidateName = occupyingObject.getName()
         if alternateName == candidateName then
            if remove then
               -- It's fine to remove while iterating, because we return right after,
               table.remove(objects, i)
            end
            return occupyingObject
         end
      end
   end
end

function onObjectLeaveContainer(container, leave_object)
   if container.hasTag("deletable") then
      leave_object.addTag("deletable")
   end
   if container.hasTag("spawner") then
      local params = {
         monster = leave_object,
         isBoss = container.hasTag("boss")
      }
      if container.hasTag("boss") then
         leave_object.addTag("boss")
         leave_object.setColorTint({ r = 1, g = 0, b = 0 })
      end
      if container.hasTag("loot as body") then
         leave_object.addTag("loot as body")
         leave_object.setGMNotes(JSON.encode({ container = container.getGUID() }))
      end
      if container.hasTag("no loot") then
         leave_object.addTag("no loot")
      end
      if container.hasTag("loot as rubble") then
         leave_object.addTag("loot as rubble")
      end
      --print(params)
      getScenarioMat().call("spawned", params)
   end
end

function playerDraw(player)
   playerMatId = PlayerMats[player.color]
   if playerMatId ~= nil then
      playerMat = getObjectFromGUID(playerMatId)
      playerMat.call("draw")
   end
end

cardMappings = {
   -- Back
   back = "http://cloud-3.steamusercontent.com/ugc/2015962364034087078/A85EDCBFFAC5277C9D58298A5487630525205BBC/",
   -- Player 1 Base Deck
   p1p0 = "http://cloud-3.steamusercontent.com/ugc/2015962364033586707/25C4C21E6EA700B44AF19264BE650A4666D8A25C/",
   p1p1 = "http://cloud-3.steamusercontent.com/ugc/2015962364033586750/726E0EFEF806D1B1DD47CCCB4384D3D8C14431A0/",
   p1m1 = "http://cloud-3.steamusercontent.com/ugc/2015962364033586598/CF62A2BB41B701B44D0C9051A11B24A9C0B6F64C/",
   p1p2 = "http://cloud-3.steamusercontent.com/ugc/2015962364033586787/11FAC77AB6833CF5FB7CFD9737AD0FACF2406D63/",
   p1m2 = "http://cloud-3.steamusercontent.com/ugc/2015962364033586657/45A36EAAE703A96269715F79CE141E613256A4ED/",
   p1t0 = "http://cloud-3.steamusercontent.com/ugc/2015962364033586818/BA2C72B962C235FEC0CAC034C4065483FDAE800A/",
   p1t2 = "http://cloud-3.steamusercontent.com/ugc/2015962364033586851/63DCB0F233ADDDED78487B20ECE78D7C068C13A3/",
   -- Player 2 Base Deck
   p2m1 = "http://cloud-3.steamusercontent.com/ugc/2015962364033936715/65CE2B05DA4A9CBF0842EA203624526346BC7853/",
   p2m2 = "http://cloud-3.steamusercontent.com/ugc/2015962364033936763/C33BDEBE1875288A310558644B93B03D95FE11F0/",
   p2p0 = "http://cloud-3.steamusercontent.com/ugc/2015962364033936816/92EB75AB6202617DA64130CA27F854F3A0939EA4/",
   p2p1 = "http://cloud-3.steamusercontent.com/ugc/2015962364033936851/D05D2DA9990714AED54C8C9E4CA03B0893292BA9/",
   p2p2 = "http://cloud-3.steamusercontent.com/ugc/2015962364033936892/483D5F28F1FF00767BA69577D833BFBBC008992F/",
   p2t0 = "http://cloud-3.steamusercontent.com/ugc/2015962364033936928/079E80C296E17CCC8F08E651137FE1C1378556BB/",
   p2t2 = "http://cloud-3.steamusercontent.com/ugc/2015962364033936960/A520F8A6FF5076C26C476847D07556B030E33AD1/",
   -- Player 3 Base Deck
   p3m1 = "http://cloud-3.steamusercontent.com/ugc/2015962364033937004/55B2DEE6FCEDAB7DA7FFA5D85E5B8A935759FE04/",
   p3m2 = "http://cloud-3.steamusercontent.com/ugc/2015962364033937041/2807B0F3D870496F90A5D5326CE4F5898AEE23CE/",
   p3p0 = "http://cloud-3.steamusercontent.com/ugc/2015962364033937096/30DF325C9A8F324F6DDAE0F818CE128B248DD7C5/",
   p3p1 = "http://cloud-3.steamusercontent.com/ugc/2015962364033937127/1FCE261C5B435741D5911A2A4087D080C1BA04CB/",
   p3p2 = "http://cloud-3.steamusercontent.com/ugc/2015962364033937160/85B7B72154342F220AF891FA8302007B9B096E47/",
   p3t0 = "http://cloud-3.steamusercontent.com/ugc/2015962364033937196/6B572A3ABCFA1EAAAF28C0881C1EF008ABF57C3C/",
   p3t2 = "http://cloud-3.steamusercontent.com/ugc/2015962364033937236/5D546B44F1ED21C2D46BF24C08A486080566F9C1/",
   -- Player 4 Base Deck
   p4m1 = "http://cloud-3.steamusercontent.com/ugc/2015962364033943348/6E80DA060712A1366F7E2E6382946C0E73806DCA/",
   p4m2 = "http://cloud-3.steamusercontent.com/ugc/2015962364033943182/87B1BEEF360E245CB62FB9CE6D49288017B3F86A/",
   p4p0 = "http://cloud-3.steamusercontent.com/ugc/2015962364033943221/9E38766E5EBF936748A72ADD944FB44C871D149B/",
   p4p1 = "http://cloud-3.steamusercontent.com/ugc/2015962364033943260/0630A4ABA63FACA323771B7C9C3176DA31E253E6/",
   p4p2 = "http://cloud-3.steamusercontent.com/ugc/2015962364033943383/E1A94165FC40C137EA6099E23FFCCFA121BECCB9/",
   p4t0 = "http://cloud-3.steamusercontent.com/ugc/2015962364033943305/8CCFC1850AC1227F6A7189875D79A8E667E1AC98/",
   p4t2 = "http://cloud-3.steamusercontent.com/ugc/2015962364033943426/B692A3A4BA1016B177506CE13F9533D49C3F502B/",
   -- Player Modifiers
   pmt0 = "http://cloud-3.steamusercontent.com/ugc/2015962364034012452/F3EFEE6B84F03E68E3A8867A610F66EDD551E3C1/",
   pmt2 = "http://cloud-3.steamusercontent.com/ugc/2015962364034012502/4B19CB0E63D5564EFD5BA127303EE77F4CBB0A7D/",
   pmm1 = "http://cloud-3.steamusercontent.com/ugc/2015962364034012405/EC6D9FEE108711106C8E4BFD977B4E1AC9BFECC3/",
   -- Blinkblade
   bbp1 = "http://cloud-3.steamusercontent.com/ugc/2015962364036077029/9AFC8342A83254879A2A25804C47DB38D8CB7E58/",
   bbwo = "http://cloud-3.steamusercontent.com/ugc/2015962364036077095/9F907307EEAFB62A7C0E67FEEF0DCE78331456EA/",
   bbim = "http://cloud-3.steamusercontent.com/ugc/2015962364036077157/56E5C9241D3181913DAF095BFEE56269FB4801CB/",
   bbna = "http://cloud-3.steamusercontent.com/ugc/2015962364036077218/1994C9DFCBDB917BE1159028BBB0E449C339176A/",
   bbp2 = "http://cloud-3.steamusercontent.com/ugc/2015962364036077270/814B4C42FEEF7B69FA1B5714A4A45F061B8FCE26/",
   bbgt = "http://cloud-3.steamusercontent.com/ugc/2015962364036077330/BBA95DFC1BBA51ABED3A0613BF2B8DB604510A44/",
   bbre = "http://cloud-3.steamusercontent.com/ugc/2015962364036077377/3418E436630107AE371F0D4AE33DA546451AE1E8/",
   -- Geminate
   gere = "http://cloud-3.steamusercontent.com/ugc/2015962364036106805/1CBB2610947A9F1AFF07A34DA41714C91EDDBBD0/",
   gebr = "http://cloud-3.steamusercontent.com/ugc/2015962364036106740/CD336F9B8C7154C44AFDB7F8423B335E21700E7A/",
   gepu = "http://cloud-3.steamusercontent.com/ugc/2015962364036106668/8263B9A464F92D43F104FFA9398AE4A8C70233E8/",
   gepi = "http://cloud-3.steamusercontent.com/ugc/2015962364036106601/01ABCCCE34C759AE850B8AA418989827BD764298/",
   gewo = "http://cloud-3.steamusercontent.com/ugc/2015962364036106522/4FF6E613E1E47EA7D883F9E5A029712DFF6CF278/",
   gepo = "http://cloud-3.steamusercontent.com/ugc/2015962364036106465/9DC40FAF11521F2DD365F7517109DDC35061B4DD/",
   gece = "http://cloud-3.steamusercontent.com/ugc/2015962364036106370/00E3E8DE0D507F40A0C953D6635CAC0FBCCC9DD1/",
   gep0 = "http://cloud-3.steamusercontent.com/ugc/2015962364036106294/B49188FE9E2A7E7CADB9143903AC0D7192FA722E/",
   -- Drifter
   drh1 = "http://cloud-3.steamusercontent.com/ugc/2015962364036880574/904692E2F7EBC6C18B56100B7CDA919619C21344/",
   drim = "http://cloud-3.steamusercontent.com/ugc/2015962364036880526/63A7EDC0755FBC9E325CFE301D8FBFBF606792DB/",
   drp3 = "http://cloud-3.steamusercontent.com/ugc/2015962364036880483/F3A1AC81B9ABC0566B27B72CB873D6F3FD8DB8D8/",
   drpu = "http://cloud-3.steamusercontent.com/ugc/2015962364036880419/B5C1CFC9F0068A99BFBC1582F5CD8BE25EC1A29F/",
   drpi = "http://cloud-3.steamusercontent.com/ugc/2015962364036880359/0220A1F8E475D284E89D1A7B624C4B8F0AC0FF41/",
   drmt = "http://cloud-3.steamusercontent.com/ugc/2015962364036880308/FC21221B7B4B6B69D77D8829E46866EA3DB21115/",
   drp0 = "http://cloud-3.steamusercontent.com/ugc/2015962364036880241/73E3627D32F97245B94EB107D0DE123367410208/",
   drp1 = "http://cloud-3.steamusercontent.com/ugc/2015962364036880098/6278AD04FCCC2F3A2C5B6870F10A16C57267A8BC/",
   -- Banner Spear
   bah1 = "http://cloud-3.steamusercontent.com/ugc/2015962364036932999/43E0E5B2BB774FA0785D15D3EB966597E4582F40/",
   bap1 = "http://cloud-3.steamusercontent.com/ugc/2015962364036932949/9B326AAC047BF95A5BF086C1E0BC0E649A6D53DB/",
   bapu = "http://cloud-3.steamusercontent.com/ugc/2015962364036932908/82AEB30DBF0E905331770CC72FFD4E81D0A87E1B/",
   badi = "http://cloud-3.steamusercontent.com/ugc/2015962364036932870/DE1FC7CEE6367134E04EDFC4740B9220402F3180/",
   baaa = "http://cloud-3.steamusercontent.com/ugc/2015962364036932825/1D58BBE763B2C3AC5DEA57EAE45028DE32A6AFCA/",
   bas1 = "http://cloud-3.steamusercontent.com/ugc/2015962364036932774/287535437A2FBC581A0312DAC2413162F9CA444F/",
   -- Deathwalker
   deh1 = "http://cloud-3.steamusercontent.com/ugc/2015962364036960925/DA2FBB0DE8B7E4017BDA25262CC474FA850C3D0F/",
   demu = "http://cloud-3.steamusercontent.com/ugc/2015962364036960864/5AB6E29D5DB7C3758557040A4F9F56AB0C036050/",
   dedi = "http://cloud-3.steamusercontent.com/ugc/2015962364036960788/6A7575160B982D72F8B2725BD472F9AF9B2C5280/",
   deda = "http://cloud-3.steamusercontent.com/ugc/2015962364036960744/7F1EF31507537625CD14D786F9ED972B9C30E767/",
   decu = "http://cloud-3.steamusercontent.com/ugc/2015962364036960690/E276347B9D8D8CF811572FB99C39DF5EDE070096/",
   dep1 = "http://cloud-3.steamusercontent.com/ugc/2015962364036960622/79E638DE30F2D35208EFAAAB2A9CDA21F8F8325A/",
   dep0 = "http://cloud-3.steamusercontent.com/ugc/2015962364036960557/C0422D56DDB07FD0C3D3E6C1DF0563EDC851361A/",
   -- Boneshaper
   bocu = "http://cloud-3.steamusercontent.com/ugc/2015962364033964134/543EF1ED932AD3F531BC5FEF799354C07C62068B/",
   bopo = "http://cloud-3.steamusercontent.com/ugc/2015962364033964178/7F749EA0051E438F580BAAFDD72D58A29B08E62A/",
   bop0 = "http://cloud-3.steamusercontent.com/ugc/2015962364033964214/543E3A66E193F9BA06B47A3A61F8A07AB6B6375C/",
   boki = "http://cloud-3.steamusercontent.com/ugc/2015962364033964254/F17B6006CCB47B2D8AD9CE4762A5486DBF1A6356/",
   boh1 = "http://cloud-3.steamusercontent.com/ugc/2015962364033964293/012BA21A2B0772BEA29D0D87DB47772A124666CB/",
   bop2 = "http://cloud-3.steamusercontent.com/ugc/2015962364033964336/A1E3B55849F018D57EEE0CCA2514FE1CA6D1AE68/",
   bop1 = "http://cloud-3.steamusercontent.com/ugc/2015962364033964387/A1F7E9221E5AD10D225CF34098DA71EA6C119CA7/",
   -- Crushing Tide
   ctpi = "http://cloud-3.steamusercontent.com/ugc/2015962364033970054/28C20A0819FA429719BAE51F00E134477060C640/",
   ctat = "http://cloud-3.steamusercontent.com/ugc/2015962364033970123/E6C1AA86566F949E999A66C0A1C7D0A678F543BD/",
   cts1 = "http://cloud-3.steamusercontent.com/ugc/2015962364033970197/B5A0C0F54EAE0A9243E7947370F354FC9F3DFBBD/",
   ctta = "http://cloud-3.steamusercontent.com/ugc/2015962364033970257/6B46962AD5302DBE16AFE3A0C39DED989B3759B3/",
   ctmu = "http://cloud-3.steamusercontent.com/ugc/2015962364033970299/102420EE27D1F1755344D928E9D29AFAEFD9BC42/",
   ctdi = "http://cloud-3.steamusercontent.com/ugc/2015962364033970347/923F59D605ECEF3FCB35535DE0C25155BF1EED9F/",
   cth1 = "http://cloud-3.steamusercontent.com/ugc/2015962364033970395/755EF077F21A23FCAA13B6D55F35D8C6858C2673/",
   --Pain Conduit
   pcp1 = "http://cloud-3.steamusercontent.com/ugc/2015962364036980258/8C133DE5C08F3C19B8EDD5E3D58C89A6C60FA67E/",
   pcnc = "http://cloud-3.steamusercontent.com/ugc/2015962364036980199/C1F329F34FA561D6453011A97B1D2B317DF78239/",
   pch1 = "http://cloud-3.steamusercontent.com/ugc/2015962364036980141/E4DDC1F2C383229529F3A0E175E493207CF71F36/",
   pccu = "http://cloud-3.steamusercontent.com/ugc/2015962364036980084/778DA1319ECBB7D8876433CB41D0C2769A9964B0/",
   pcp2 = "http://cloud-3.steamusercontent.com/ugc/2015962364036980029/722E12EDAABB7921FF0398034583526DB4A8BE8E/",
   pcfa = "http://cloud-3.steamusercontent.com/ugc/2015962364036979971/68DE2D314E151BD466FB8B027DBBCD159C44863D/",
   pcdi = "http://cloud-3.steamusercontent.com/ugc/2015962364036979925/AF87B97EC09DFD6366E475E74DA10F2CB754EE79/",
   pcdc = "http://cloud-3.steamusercontent.com/ugc/2015962364036979860/59E11617A0033C34EAD19F846C76136A12744A1E/",
   --Pyroclast
   pymu = "http://cloud-3.steamusercontent.com/ugc/2015962364036998763/BFAA36AA055511E0F83A89B73BABFF4803B5F805/",
   pyfe = "http://cloud-3.steamusercontent.com/ugc/2015962364036998708/E44D36EE52970C839CFE7D387C260E8505AE105A/",
   pyp2 = "http://cloud-3.steamusercontent.com/ugc/2015962364036998642/6DDBB726CAA03320969596C1ACDA5B54B27CB7C7/",
   pypu = "http://cloud-3.steamusercontent.com/ugc/2015962364036998591/473CEE63E422102A804FF0EE6327FF54C456FD21/",
   pyha = "http://cloud-3.steamusercontent.com/ugc/2015962364036998544/F11E0A04CAB24106540699803A1ED0EFB616C9B7/",
   pywo = "http://cloud-3.steamusercontent.com/ugc/2015962364036998497/37DD3A5C7BD4DB5D7C07404ECD08612739A4CEAD/",
   -- HIVE
   hiwo = "http://cloud-3.steamusercontent.com/ugc/2015962364037016159/C1690B5834B5F5FEC8F69ECF86048A4BCC5AA31C/",
   hipo = "http://cloud-3.steamusercontent.com/ugc/2015962364037016102/EA43647BC5FFF8851314EF327C28D272070AD643/",
   himu = "http://cloud-3.steamusercontent.com/ugc/2015962364037016048/5027AC17BFEA59C5925CEA9A9AECC3332C38958C/",
   hih1 = "http://cloud-3.steamusercontent.com/ugc/2015962364037015986/08DC361FE5454DD05587A6DDC12292CE1AD275E1/",
   himo = "http://cloud-3.steamusercontent.com/ugc/2015962364037015933/572226A888C90289DA80B95B2903E0757F28E9A9/",
   hism = "http://cloud-3.steamusercontent.com/ugc/2015962364037015868/9F3CCCFBE838BDB00C8688CD00117E935318D9B4/",
   -- Snowdancer
   sdhw = "http://cloud-3.steamusercontent.com/ugc/2015962364037036342/B8E59FAAFE790243F4A253A63FA71D93F303C847/",
   sdst = "http://cloud-3.steamusercontent.com/ugc/2015962364037036292/49BD0F1B156F1DE14983E154B4C03748428D1890/",
   sdda = "http://cloud-3.steamusercontent.com/ugc/2015962364037036241/1800A19869F6C10B690F40379AC44B0D60FE577A/",
   sdiw = "http://cloud-3.steamusercontent.com/ugc/2015962364037036190/24E074E707225848DAEB88CD66F82448DB9FDB47/",
   sdim = "http://cloud-3.steamusercontent.com/ugc/2015962364037036106/508B1CB5E8631B38B6E4B22347D69B004219A530/",
   sdh1 = "http://cloud-3.steamusercontent.com/ugc/2015962364037036056/2B4E6049FD6D81D72C77D73F81CB84417FBBF7E6/",
   -- Frozen Fist
   ffh1 = "http://cloud-3.steamusercontent.com/ugc/2015962364037054163/993049D9666A8F1792D3C49350DF28011E0BBDB2/",
   ffp3 = "http://cloud-3.steamusercontent.com/ugc/2015962364037054096/B5FFBF47F8682A2BA116367AE5CCB32864F17EEE/",
   ffit = "http://cloud-3.steamusercontent.com/ugc/2015962364037054038/1F63EE71AC7EF4506D10E828E087AAD8C4EC56DD/",
   ffie = "http://cloud-3.steamusercontent.com/ugc/2015962364037053982/20707593624C71B91F80C5D764427FCB9F981891/",
   ffs1 = "http://cloud-3.steamusercontent.com/ugc/2015962364037053933/7E6E6AA089A19664CEEA69A5FCC847979BE6CBA8/",
   ffp0 = "http://cloud-3.steamusercontent.com/ugc/2015962364037053874/01D010F30755BC93F3CD4EE1F1CDC396E557F369/",
   ffp1 = "http://cloud-3.steamusercontent.com/ugc/2015962364037053819/49A33728EA316315D0102DBC478E236B44C63960/",
   ffdi = "http://cloud-3.steamusercontent.com/ugc/2015962364037053760/C55191C35036B1D96FB353D3C27885037BFDEE13/",
   -- Metal Mosaic
   mmp1 = "http://cloud-3.steamusercontent.com/ugc/2015962364037077615/51E2F266F057C8C5C385751957097D6B8455A55D/",
   mmp3 = "http://cloud-3.steamusercontent.com/ugc/2015962364037077573/EF7E26592C75E84856F0C43F7D8C64218542C61E/",
   mmh2 = "http://cloud-3.steamusercontent.com/ugc/2015962364037077527/6E9F352CD119E62C5E9D7A3A7027A6DF2BFF58DC/",
   mmr2 = "http://cloud-3.steamusercontent.com/ugc/2015962364037077482/86585C64444A7B41588085B9D12443BD486845F1/",
   mmpi = "http://cloud-3.steamusercontent.com/ugc/2015962364037077437/C10641A769CCC8B51AF7F5E7BB52DEFB454DACC0/",
   mmda = "http://cloud-3.steamusercontent.com/ugc/2015962364037077391/872736D20F86FBA0337E8E38CA07B4981DE493A3/",
   mms1 = "http://cloud-3.steamusercontent.com/ugc/2015962364037077316/ACD54D5C34AA656CB46F6BB537C3663B6737232B/",
   mmpc = "http://cloud-3.steamusercontent.com/ugc/2015962364037077248/EE30B2B280263039902796D757C4B6D7D06CB7B2/",
   -- Infuser
   inai = "http://cloud-3.steamusercontent.com/ugc/2015962364037139066/B9CC14BBB8DDAF57F76D81945769F6480AC1DCAC/",
   inws = "http://cloud-3.steamusercontent.com/ugc/2015962364037138995/2ADF98285F59E60EEB010CB509DAE0FADA967FB4/",
   inp2 = "http://cloud-3.steamusercontent.com/ugc/2015962364037138953/4682F1AED5571A03964B2DF2CE7AD97550E103D9/",
   ined = "http://cloud-3.steamusercontent.com/ugc/2015962364037138896/93C3CE409E5FBB31F2C749CCF00F89EA4DDC65AB/",
   inwd = "http://cloud-3.steamusercontent.com/ugc/2015962364037138841/5224C9C7C381AE5DAC46D3F385DEBE9EB1C5241D/",
   inwe = "http://cloud-3.steamusercontent.com/ugc/2015962364037138785/CF654D83BDF722125E5EEF77DDFAE75D78C379F1/",
   in3e = "http://cloud-3.steamusercontent.com/ugc/2015962364037138713/45BE1666A7FA269085D8A0716578C78905CB4EE4/",
   inm1 = "http://cloud-3.steamusercontent.com/ugc/2015962364037138650/BEA9C8E8855AA0E19C4BF9CD67BF64D9336E8EE6/",
   -- Shattersong
   shgr = "http://cloud-3.steamusercontent.com/ugc/2015962364037163184/FAF69C24D6C35B0DA1B7909CF198CCE3EF7F7C12/",
   shh2 = "http://cloud-3.steamusercontent.com/ugc/2015962364037163148/72E04DD71BCC612D32C4092147421475F387EB36/",
   shwl = "http://cloud-3.steamusercontent.com/ugc/2015962364037163104/2BAAF5BBB0B2FE961FC48E88134DBE7D26898676/",
   shbr = "http://cloud-3.steamusercontent.com/ugc/2015962364037163050/15868C2E2DCB7DEC7B925763C3B92B242501830A/",
   shst = "http://cloud-3.steamusercontent.com/ugc/2015962364037162984/BD5CA6267C899891B824509027CD9EDE2A60EDB3/",
   shre = "http://cloud-3.steamusercontent.com/ugc/2015962364037162931/7D7376A1FAF9F50AD26A5CD868C3F406263CECA8/",
   -- Trapper
   trpp = "http://cloud-3.steamusercontent.com/ugc/2015962364037180380/3CB59E2540975D8BE2B2DB711BDB99064A057D6D/",
   trim = "http://cloud-3.steamusercontent.com/ugc/2015962364037180328/F71BE2D732B088F1B942E9C48B8914A0005997D4/",
   trat = "http://cloud-3.steamusercontent.com/ugc/2015962364037180267/DE9676108CFD8E25F193D0295CA80D766A67D2C7/",
   trst = "http://cloud-3.steamusercontent.com/ugc/2015962364037180223/8E0A78136E65C6E1F46A6FB0C44674B54C769BFB/",
   trht = "http://cloud-3.steamusercontent.com/ugc/2015962364037180172/945AC4871F294303516A8A626AE4EE2E9D7BFB66/",
   -- Deepwraith
   dwg1 = "http://cloud-3.steamusercontent.com/ugc/2015962364037195647/6B3D69343791DACAC06121EE607D3A9DE4B6533F/",
   dwcu = "http://cloud-3.steamusercontent.com/ugc/2015962364037195599/B2025CAEC7C23F2A64BA06E655ABF7D9BA1FE30C/",
   dwp2 = "http://cloud-3.steamusercontent.com/ugc/2015962364037195556/2057ED8CCAFF6E3AA67DB9921DC0CECCDEAA1B51/",
   dwpi = "http://cloud-3.steamusercontent.com/ugc/2015962364037195518/D12EA3FD5FECB77229B36BC9663617C25FFA8179/",
   dwin = "http://cloud-3.steamusercontent.com/ugc/2015962364037195474/5851C2C14323AF3098B40DFE8DF5C6E8443C9127/",
   dwst = "http://cloud-3.steamusercontent.com/ugc/2035104110939470310/79F9F03100BE2FF0955F5BDF80B385FEF3DF9E9A/",
   dwdi = "http://cloud-3.steamusercontent.com/ugc/2015962364037195432/D3E3629FA8DD3A45D772AA0518D519601FA267DE/",
}

function showDrawnCard(card)
   local desc = card.getDescription()
   if desc ~= nil then
      local image = cardMappings[desc]
      if image ~= nil then
         UI.setAttribute("drawnCard", "image", image)
         UI.show("drawnCard")
      end
   end
end

function resetDrawnCard()
   image = cardMappings["back"]
   UI.setAttribute("drawnCard", "image", image)
end

function playerShuffle(player)
   playerMatId = PlayerMats[player.color]
   if playerMatId ~= nil then
      playerMat = getObjectFromGUID(playerMatId)
      playerMat.call("shuffle")
   end
end

function playerOpenSectionBook(player, text)
   openSectionBookAtPage(tonumber(text))
end

function getPlayerCount()
   local count = 0
   for _, color in ipairs({ "Green", "Red", "White", "Blue" }) do
      if isPlayerPresent(color) then
         count = count + 1
      end
   end
   return count
end

function isPlayerPresent(color)
   local mat = getPlayerMatExt({ color })
   if mat ~= nil then
      return mat.call('getCharacterName') ~= nil
   end
   return false
end

function getPlayerMat(player)
   local playerMatId = PlayerMats[player.color]
   if playerMatId ~= nil then
      return getObjectFromGUID(playerMatId)
   end
   return nil
end

function getPlayerMatExt(params)
   local playerMatId = PlayerMats[params[1]]
   if playerMatId ~= nil then
      return getObjectFromGUID(playerMatId)
   end
   return nil
end

function getScenarioMat()
   return getObjectFromGUID('4aa570')
end

function onScriptingButtonDown(index, color)
   for _, player in ipairs(Player.getPlayers()) do
      if player.color == color then
         obj = player.getHoverObject()
         if obj ~= nil and obj.tag == "Card" then
            getScenarioMat().call("sendCard", { color, obj, index })
         end
      end
   end
end

function playCard(color, card)
   for _, player in ipairs(Player.getPlayers()) do
      if player.color == color then
         obj = player.getHoverObject()
         if obj ~= nil and obj.tag == "Card" then
            getScenarioMat().call("sendCard", { color, obj, card })
         end
      end
   end
end

function drawCard(color, card)
   for _, player in ipairs(Player.getPlayers()) do
      if player.color == color then
         obj = player.getHoverObject()
         if obj ~= nil and obj.tag == "Card" then
            obj.deal(1, color)
         end
      end
   end
end

function toggleControls()
   if UI.getAttribute("controls", "active") == "false" then
      UI.setAttribute("controls", "active", "true")
      UI.setAttribute("layout", "width", "165")
   else
      UI.setAttribute("controls", "active", "false")
      UI.setAttribute("layout", "width", "15")
   end
end

function toggleUI()
   if UI.getAttribute("ui", "active") == "false" then
      UI.setAttribute("ui", "active", "true")
      UI.setAttribute("uiLayout", "height", "825")
      UIEnabled = true
   else
      UI.setAttribute("ui", "active", "false")
      UI.setAttribute("uiLayout", "height", "25")
      UIEnabled = false
   end
end

function onObjectDestroy(object)
   if object.hasTag("tracked") then
      getScenarioMat().call('unregisterStandee', object)
   end
end

CollisionEnterCallbacks = {}
CollisionExitCallbacks = {}

function registerForCollision(obj)
   Wait.frames(function() obj.registerCollisions() end, 10)
   if obj.getVar("onObjectCollisionExit") ~= nil then
      CollisionExitCallbacks[obj.guid] = obj
   end
   if obj.getVar("onObjectCollisionEnter") ~= nil then
      CollisionEnterCallbacks[obj.guid] = obj
   end
end

function registerPressurePlate(pressurePlate)
   pressurePlate.addTag("pressurePlate")
   Wait.frames(function() pressurePlate.registerCollisions() end, 10)
end

function onObjectCollisionEnter(hit_object, collision_info)
   -- print("onObjectCollisionEnter")
   -- collision_info table:
   --   collision_object    Object
   --   contact_points      Table     {Vector, ...}
   --   relative_velocity   Vector
   local obj = collision_info.collision_object
   if obj.hasTag("condition") then
      getScenarioMat().call("applyCondition", { hit_object, obj.getName() })
      destroyObject(obj)
   end


   if hit_object.hasTag("pressurePlate") then
      -- "looter" should be good proxy for "character"
      if obj.hasTag("looter") then
         fhlog(DEBUG, TAG, "Pressing Pressure Plate")
         local scenarioTriggers = CurrentScenario.triggers
         local triggerIds = scenarioTriggers.byObjectGuid[hit_object.guid]
         for _, triggerId in ipairs(triggerIds) do
            Wait.frames(function()
                  actualTriggered(CurrentScenario.id, triggerId, hit_object.guid, false, getScenarioElementObjects())
               end,
               1)
         end
      end
   end


   for guid, obj in pairs(CollisionEnterCallbacks) do
      if guid == hit_object.guid then
         obj.call("onObjectCollisionEnter", { hit_object, collision_info })
      end
   end

   if hit_object.hasTag("overlay") or hit_object.hasTag("tile") or hit_object.hasTag("token") then
      if hit_object.getPosition().y < obj.getPosition().y then
         local objectsOnObjects = CurrentScenario.objectsOnObjects or {}
         local objectsOnObject = objectsOnObjects[hit_object.guid]
         if objectsOnObject == nil then
            objectsOnObject = {}
            objectsOnObjects[hit_object.guid] = objectsOnObject
         end
         table.insert(objectsOnObject, obj.guid)
         -- print(JSON.encode(objectsOnObject))
      end
   end
end

function onObjectCollisionExit(hit_object, collision_info)
   local obj = collision_info.collision_object
   -- print("onObjectCollisionExit")
   if hit_object.hasTag("pressurePlate") then
      -- "looter" should be good proxy for "character"
      if obj.hasTag("looter") then
         fhlog(DEBUG, TAG,"Releasing Pressure Plate")
         local scenarioTriggers = CurrentScenario.triggers
         local triggerIds = scenarioTriggers.byObjectGuid[hit_object.guid]
         for _, triggerId in ipairs(triggerIds) do
            actualTriggered(CurrentScenario.id, triggerId, obj.guid, true, getScenarioElementObjects())
         end
      end
   end

   for guid, obj in pairs(CollisionExitCallbacks) do
      if guid == hit_object.guid then
         obj.call("onObjectCollisionExit", { hit_object, collision_info })
      end
   end

   if hit_object.hasTag("overlay") or hit_object.hasTag("tile") or hit_object.hasTag("token") then
      local objectsOnObjects = CurrentScenario.objectsOnObjects or {}
      local objectsOnObject = objectsOnObjects[hit_object.guid]
      if objectsOnObject ~= nil then
         for i = #objectsOnObject, 1, -1 do
            if objectsOnObject[i] == obj.guid then
               table.remove(objectsOnObject, i)
            end
         end
      end
   end
end

function getSettings()
   local settingsMat = getObjectFromGUID('1a09ac')
   if settingsMat ~= nil then
      return settingsMat.call("getSettings") or "{}"
   end
   return "{}"
end

function getDevSettings()
   local developmentMat = getObjectFromGUID('b297f5')
   if developmentMat ~= nil then
      return developmentMat.call("getSettings") or "{}"
   end
   return "{}"
end

function sortHand(color)
   for _, player in ipairs(Player.getPlayers()) do
      if player.color == color then
         local cards = player.getHandObjects()
         local cardPositions = {}
         for _, card in ipairs(cards) do
            table.insert(cardPositions, card.getPosition())
         end
         table.sort(cards, function(c1, c2) return c1.getName() < c2.getName() end)
         for i, card in ipairs(cards) do
            card.setPosition(cardPositions[i])
         end
      end
   end
end

function onObjectPageChange(object)
   -- send to books mat
   getObjectFromGUID('2a1fbe').call("onPageChanged", object)
end

function playNarration(params)
   local settings = JSON.decode(getSettings())
   local address = settings["address"]
   local port = settings["port"] or 8080
   local folder = params[1]
   local file = params[2]
   if folder ~= nil and file ~= nil and address ~= nil then
      local url = "http://" .. address .. ":" .. port .. "/file/" .. folder .. "/" .. file .. ".mp3"
      -- print(url)
      MusicPlayer.setCurrentAudioclip({
         url = url,
         title = folder .. " : " .. file
      })
      MusicPlayer.play()
   end
end

Savables = {}

function registerSavable(savable)
   table.insert(Savables, savable)
end

function getSave()
   local save = {}
   for _, savable in ipairs(Savables) do
      local partialSave = savable.call("getSave")
      local copy = JSON.decode(partialSave)
      for key, value in pairs(copy) do
         save[key] = value
      end
   end
   return JSON.encode(save)
end

function loadSave(save)
   local data = JSON.decode(save)
   for i, savable in ipairs(Savables) do
      local name = savable.call("getName")
      local savableData = data[name]
      if savableData ~= nil then
         local encoded = JSON.encode(savableData)
         -- Spread the loading across multiple frames
         -- And also helps in debugging
         savable.call("loadSave", encoded)
      end
   end
end

function reset()
   for _, savable in ipairs(Savables) do
      savable.call("reset")
   end
end

function onObjectPickUp(color, obj)
   if obj.hasTag("character box") then
      if #obj.getObjects() == 0 then
         broadcastToColor("Drop on a player mat to pack that character", color)
      else
         broadcastToColor("Drop on a player mat to setup", color)
      end
   end
end

function onObjectDrop(color, obj)

end

function characterLevelChanged()
   -- We need to delay the update as we're getting the callback *before* the change is effective in the button
   Wait.frames(function() getScenarioMat().call("updateCharacters") end, 10)
end

DataUpdatables = {}
function registerDataUpdatable(object)
   table.insert(DataUpdatables, object)
end

function updateData()
   local baseUrl = getBaseUrl()
   for _, updatable in ipairs(DataUpdatables) do
      updatable.call("updateData", baseUrl)
   end
   refreshScenarioData(baseUrl)
end

function onPlayerPing(player, position, object)
   local devSettings = JSON.decode(getDevSettings())
   local printPingedCoordinates = devSettings['print-pinged-coordinates']
   if printPingedCoordinates ~= nil then
      if printPingedCoordinates == 'Global' then
         print(JSON.encode(position))
      else
         local target = getObjectFromGUID(printPingedCoordinates)
         if target ~= nil then
            print(JSON.encode(target.positionToLocal(position)))
         end
      end
   end
end

FhLoggers = {}

function registerFhLogger(obj)
   table.insert(FhLoggers, obj)
end

function fhLogSettingsUpdated()
   local devSettings = JSON.decode(getDevSettings())
   local level = devSettings['log-level']
   local tags = devSettings['log-tags']

   local payload = JSON.encode({level = level, tags = tags })
   for _, obj in ipairs(FhLoggers) do
      obj.call("onFhLogSettingsUpdated", payload)
   end
end
