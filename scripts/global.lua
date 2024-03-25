require('json')
require('constants')
require('coordinates')
require('fhlog')
require('attack_modifiers')
require('data/scenarios')
require('data/processedScenarios3')
require("data/random_dungeons")

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
   FhLoggers = {}
   fhLogInit()

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

   Wait.frames(onAfterLoad, 1)
end

function onAfterLoad()
   loadData()
   fhLogSettingsUpdated()
   local settings = JSON.decode(getSettings())
   updateHotkeys({ enabled = settings["enable-solo"] or false, fivePlayers = settings["enable-5p"] or false })
   UI.setAttribute("layout", "active", settings['enable-am-ui-overlay'])
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

function refreshScenarioData(baseUrl, first)
   if baseUrl ~= "https://gudyfr.github.io/fhtts/" or not first then
      broadcastToAll("Reloading Scenario Data")
      WebRequest.get(baseUrl .. "scenarios.json", processScenarioData)
      WebRequest.get(baseUrl .. "processedScenarios3.json", processAdditionalScenarioData)
   end
end

function processScenarioData(request)
   Scenarios = json.parse(request.text)
   fhlog(DEBUG, TAG, "Scenario Data loaded")
end

function processAdditionalScenarioData(request)
   ProcessedScenarios3 = jsonDecode(request.text)
   fhlog(DEBUG, TAG, "Scenario Layout Data loaded")
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

function GetMapTileEx(params)
   getMapTile(params.tile, params.layout)
end

function getMapTile(mapName, layout)
   local nameLen = string.len(mapName)
   local letter = string.sub(mapName, nameLen)
   local config = letterConfigs[letter]
   local mapTileName = string.sub(mapName, 1, nameLen - 1) .. config.tile
   local mapBag = getObjectFromGUID(mapTilesBagId)
   for _, tile in pairs(mapBag.getObjects()) do
      if tile.name == mapTileName then
         print("Getting tile ", mapTileName)
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
                  print("tile layout: ", JSON.encode(tileLayout)) --TODO: comment
                  local center = tileLayout.center

                  -- Hacky Fixes, we should fix the assets themselves instead
                  local tileNumber = string.sub(mapName, 1, 2)
                  local tileLetter = string.sub(mapName, 4, 4)
                  local mappedTileLetter = TileLetterMappings[tileLetter]
                  local orientation = 180 + (tonumber(tileLayout.orientation) or 0)
                  orientation = orientation + (AdditionalRotation[tileNumber] or 0)
                  orientation = orientation + (AdditionalRotation[tileNumber .. "-" .. mappedTileLetter] or 0)

                  if orientation > 180 then
                     orientation = orientation - 360
                  end

                  clone.setRotation({ 0, -orientation, targetZRot })
                  local hx, hz = getWorldPositionFromHexPosition(center.x, center.y)
                  clone.setPositionSmooth({ hx, 1.39, hz })
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
               clone.addTag("renaming")
               local obj = clone.takeObject()
               obj.setName(monster.as)
               clone.setName(monster.as)
               clone.reset()
               clone.putObject(obj)
               clone.removeTag("renaming")
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
               clone.setPositionSmooth(pos)
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
   start = '2a4be3',
   loot = '5e0624',
   section = '9ddb6d'
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
               obj = bag.takeObject({ position = pos, smooth = true })
            else
               obj = bag.takeObject()
            end
            obj.setRotation({ 0, 0, 0 })
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
               obj.addTag("no loot")
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

function spawnNElementsIn(count, name, info, destination, scenarioElementPositions,
                          currentScenarioElementPosition)
   destination = getObjectFromGUID('cd31b5')
   bag = getObjectFromGUID('5cd812')
   bag.setLock(false)
   bags = bag.getObjects()
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
                  obj = container.takeObject({ position = pos, smooth = true })
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
                  obj.addTag("no loot")
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
                  local underlay = {
                     name = "underlay_" .. type,
                     position = { 0, 0, 0 },
                     scale = { .75, .75, .75 },
                     rotation = { 90, 180, 0 },
                  }
                  local overlay = {
                     name = "overlay_" .. type,
                     position = { 0, 0.05, 0.25 },
                     scale = { 0.2, 0.2, 0.2 },
                     rotation = { 90, 180, 0 },
                  }
                  if type == "Obstacle" then
                     underlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219237165/2678AF8F59D023C77DF641FEC8910835D182257E/"
                     overlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219236688/D9F31375FC450BD9BE3984EB47FD1E3C5E758A17/"
                  elseif type == "Pressure Plate" then
                     underlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219237206/6A0777484779A8722080530B0C43D1C82473A0C5/"
                     overlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219236727/7D01B94C25BEA92CBE0957ECC6A422429EDD44CD/"
                  elseif type == "Trap" then
                     underlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219237268/7A7C3B0E0060C8FE23A359463F9A12C22FFA17DA/"
                     overlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219236774/BCB319F990BE7A9127849A4615486318C987AD7C/"
                  elseif type == "Wall" then
                     underlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219237311/0E7EBC101D0643E90645E0AFED2534DCD30CA7C9/"
                     overlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219236827/8B11DFC742D94410A3A220903F37894D384F5098/"
                  elseif type == "Corridor" then
                     underlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219236874/45C3A28338A6EFCB0A2FEE9332D3F6033CCB6F9B/"
                     overlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219236428/A0AF561889DB69EC01F03BBBE560396F343ADE69/"
                  elseif type == "Difficult Terrain" then
                     underlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219236926/31F6DFAA41FDB6649461472B1F8D3129E60CB4E4/"
                     overlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219236470/666B6A71A88CFFA389AAD94DB74060F77192063B/"
                  elseif type == "Door" then
                     underlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219236982/77263BF7C8933BF32D3F3C54BC5D13493B54D1CF/"
                     overlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219236511/1C789E9836AF1DC13FFFDABB239CBE3A19C0B3C5/"
                  elseif type == "Hazardous Terrain" then
                     underlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219237027/9EF685D0E353DB1ADE2826410AA3195F3095E8FB/"
                     overlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219236545/DD2676FE8B97B20F2C671803FED9BCC0C137B17D/"
                  elseif type == "Icy Terrain" then
                     underlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219237076/93DC787398B26C6263924F3AD2E1A03AA13A6162/"
                     overlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219236588/7A1556D352C180A003F8D5BC44BE6BB2FE1B486B/"
                  elseif type == "Objective" then
                     underlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219237113/AD6DDE3352CA5168C1FCCE247AF5BD9C3E544494/"
                     overlay.url =
                     "http://cloud-3.steamusercontent.com/ugc/2035105992219236640/33AF2DDD8AB13544A4954EBDD194CCD746BFE146/"
                  end

                  local decals = {}
                  if underlay.url ~= nil then
                     table.insert(decals, underlay)
                     if (info.size or 1) == 2 then
                        local underlay2 = {
                           name = underlay.name .. "_2",
                           url = underlay.url,
                           position = { 0.665, 0, 0 },
                           rotation = underlay.rotation,
                           scale = underlay.scale,
                        }
                        table.insert(decals, underlay2)
                     elseif (info.size or 1) == 3 then
                        local underlay2 = {
                           name = underlay.name .. "_2",
                           url = underlay.url,
                           position = { 0.665, 0, 0 },
                           rotation = underlay.rotation,
                           scale = underlay.scale,
                        }
                        table.insert(decals, underlay2)

                        local underlay3 = {
                           name = underlay.name .. "_3",
                           url = underlay.url,
                           position = { 0.3325, 0, -0.665 },
                           rotation = underlay.rotation,
                           scale = underlay.scale,
                        }
                        table.insert(decals, underlay3)
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
         local mat = getObjectFromGUID(guid)
         if mat ~= nil then
            mat.call("cleanup")
         end
      end
      -- Notify the BattleInterfaceMat to cleanup as well
      local battleInterfaceMat = getObjectFromGUID(BattleInterfaceMat)
      if battleInterfaceMat ~= nil then
         battleInterfaceMat.call("cleanup")
      end
      -- And clear the errata
      getScenarioMat().call('setErrata', nil)
      getScenarioMat().call('onCleanedUp')

      CurrentScenario = {}
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
   local scenario = Scenarios["" .. name]
   if scenario ~= nil then
      local title = scenario["x-haven-title"]
      if title ~= nil then
         prepareScenario(name, "Solo", title)
      end
   end
end

function prepareFrosthavenScenario(name)
   local scenario = Scenarios["" .. name]
   if scenario ~= nil then
      local title = "#" .. name .. " " .. (scenario.title or "")
      prepareScenario(name, "Frosthaven", title)
   end
end

function prepareScenarioEx(params)
   prepareScenario(params.name, params.campaign, params.scenario)
end

function waitms(ms)
   local start = os.time()
   while os.time() < start + ms / 1000 do
      coroutine.yield(0)
   end
end

function CreateRandomScenarioEx()
   local id = math.random(1000000) + 1000
   local title = "Random Scenario"
   if MaybeCleanupAndInitScenario(tostring(id), title) then
      CurrentScenario.scenarioInfo = { layout = {} }
   end
end

function AddRandomScenarioLayoutEx(params)
   local layout = { params.layout }
   table.insert(CurrentScenario.scenarioInfo.layout, layout)
   layoutMap(params.map)
end

function MaybeCleanupAndInitScenario(name, title)
   -- This will simply highlight elements which would be destroyed if we were to prepare this scenario (if any)
   -- However, if the user retries the prepare this scenario, it will delete the current scenario mat and prepare the scenario
   local deleted = cleanup(false, true)
   local empty, hasItems = isLayoutAreaEmpty()
   if hasItems then
      -- Remove highlights right away
      cleanupTimeout()
      broadcastToAll("Scenario Mat has item cards on it. Can't prepare " .. title)
      return false
   end
   if not deleted and not empty then
      broadcastToAll("Scenario Mat is not empty, try again to delete highlighted objects and prepare " .. title)
      return false
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
      elements = Scenarios[name],
      registeredForCollision = {}
   }
   return true
end

function prepareScenario(name, campaign, title)
   local prepareFunc = "prepareScenario_" .. campaign .. "_" .. name
   self.setVar(prepareFunc, function()
      continuePreparing(name, campaign, title)
      return 1
   end)
   startLuaCoroutine(Global, prepareFunc)
end

function continuePreparing(name, campaign, title, is_random)
   name = tostring(name)
   Settings = JSON.decode(getSettings())
   if not MaybeCleanupAndInitScenario(name, title) then
      return
   end
   self.setVar("triggerClicked_" .. name,
      function(obj, color, alt)
         onTriggerClicked(name, obj.guid, alt)
      end)

   local scenarioInfo = nil
   local layout = nil
   if campaign == "random" then
      if scenarioInfo ~= nil then
         layout = scenarioInfo.layout
      end
   else
      if ProcessedScenarios3 ~= nil then
         scenarioInfo = deepCopy(ProcessedScenarios3[name])
         CurrentScenario.scenarioInfo = scenarioInfo
         if scenarioInfo ~= nil then
            layout = scenarioInfo.layout
         end
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
         local xOffset = -2 * (#choices - 1) / 2
         for i, choice in ipairs(choices) do
            local token = choice.token
            local value = choice.value
            if token ~= nil and value ~= nil then
               local title = choice.title or ("Choose " .. token)
               local x, z = getWorldPositionFromHexPosition(xOffset + 2 * (i - 1), 0)
               local obj = getToken({ name = token }, { x = x, y = 1.5, z = z })
               obj.setScale({ 0.5, 0.5, 0.5 })
               if obj ~= nil then
                  self.setVar("scenarioChoice_" .. token,
                     function()
                        cleanup(true, true)
                        Wait.frames(function()
                           prepareFrosthavenScenario(name .. value)
                        end, 2)
                     end)
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
            end
         end
         if elements.page ~= nil then
            -- Tell the book mat to go to the right scenario page
            getObjectFromGUID('2a1fbe').call("setScenarioPage", { elements.page, tonumber(name), "Scenarios" })
         end
         return
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
         currentScenarioElementPosition = spawnNElementsIn(count, overlayName, info, scenarioBag,
            scenarioElementPositions, currentScenarioElementPosition)
         waitms(LAYOUT_WAIT_TIME_MS)
      end



      -- print(JSON.encode(layout))

      for _, tileName in ipairs(elements.tiles) do
         -- print("Adding Map Tile " .. tileName .. " to the scenario bag")
         getMapTile(tileName, layout)
         waitms(LAYOUT_WAIT_TIME_MS)
      end

      -- offset by 2 before the monsters
      currentScenarioElementPosition = currentScenarioElementPosition + 2
      if elements.monsters ~= nil then
         for index, monster in ipairs(elements.monsters) do
            -- print("Adding Monster " .. JSON.encode(monster))
            getMonster(monster, scenarioElementPositions, currentScenarioElementPosition)
            waitms(LAYOUT_WAIT_TIME_MS)
            -- and they take a bit of space
            currentScenarioElementPosition = currentScenarioElementPosition + 1
         end
      end

      if elements.tokens ~= nil then
         for index, token in ipairs(elements.tokens) do
            -- print("Adding token " .. token.name)
            getToken(token, scenarioElementPositions[currentScenarioElementPosition])
            waitms(LAYOUT_WAIT_TIME_MS)
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

      getScenarioMat().call("setScenario", { scenario = title, campaign = campaign, name = name })

      local settings = JSON.decode(getSettings())
      if settings["enable-automatic-scenario-layout"] or false then
         if name == "91" then
            prepareScenario91()
         end
         waitms(1000)
         layoutScenarioElements(name)
      end
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
               layoutMapAsync(map)
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
   local layoutMapFunc = "layoutMap_" .. map.name
   self.setVar(layoutMapFunc, function()
      layoutMapAsync(map)
      return 1
   end)
   startLuaCoroutine(Global, layoutMapFunc)
end

LAYOUT_WAIT_TIME_MS = 150

function layoutMapAsync(map)
   local elements = CurrentScenario.elements
   local scenarioInfo = CurrentScenario.scenarioInfo
   local objects = CurrentScenarioObjects
   -- Determine number of players
   local playerCount = getPlayerCount()
   local originalPlayerCount = playerCount
   if playerCount < 2 then
      playerCount = 2
   elseif playerCount > 4 then
      playerCount = 4
   end

   broadcastToAll(originalPlayerCount .. " players detected. Laying out map for " .. playerCount .. " players.")

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
         for _, overlay in ipairs(entry.overlays or {}) do
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
                           fhlog(INFO, TAG, "Adding door at %s,%s", hx, hy)
                           scenarioDoors[hx .. "," .. hy] = true
                        end
                        obj.setPositionSmooth({ x, 1.44, z })
                        local orientation = overlay.orientation or 0
                        if orientation > 180 then
                           orientation = orientation - 360
                        end
                        obj.setRotationSmooth({ 0, -orientation, 0 })

                        -- Handle potential triggers
                        if position.trigger ~= nil then
                           attachTriggerToElement(position.trigger, obj, scenarioInfo.id)
                        end
                        waitms(LAYOUT_WAIT_TIME_MS)
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
                  obj.setPositionSmooth({ x, 2.21, z })
                  local zRot = 0
                  if random ~= nil then
                     zRot = 180
                  end
                  local yRot = 0
                  obj.setRotation({ 0, yRot, zRot })
                  if position.trigger ~= nil then
                     attachTriggerToElement(position.trigger, obj, scenarioInfo.id)
                  end
                  waitms(LAYOUT_WAIT_TIME_MS)
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
                           callback_function = function(spawned)
                              if level == 'e' then makeElite(spawned) end
                              if position.standeeNr ~= nil then
                                 Global.call("setStandeeNr", {
                                    spawned, position.standeeNr })
                              end
                           end,
                           smooth = false
                        })
                        local x, z = getWorldPositionFromHexPosition(position.x + origin.x, position.y + origin.y)
                        obj.setPositionSmooth({ x, 2.35, z })
                        -- Handle potential triggers
                        if position.trigger ~= nil then
                           attachTriggerToElement(position.trigger, obj, scenarioInfo.id)
                        end
                        waitms(LAYOUT_WAIT_TIME_MS)
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
         actualTriggered(CurrentScenario.id, trigger.id, nil, false)
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
   getScenarioMat().call("toggled", obj)
end

function setStandeeNr(params)
   local standee = params[1]
   local nr = params[2]
   getScenarioMat().call("updateStandeeNr", { standee, nr })
end

function updateTriggers(trigger, obj)
   fhlog(DEBUG, TAG, "Updating trigger %s for %s", trigger, obj.guid)
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
      fhlog(DEBUG, TAG, "Countdown %s: %s", triggerId, trigger.current)
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
      fhlog(WARNING, TAG, "Unknown dedupMode : %s in %s", dedupMode, trigger)
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

function onScenarioCompleted()
   if CurrentScenario ~= nil and CurrentScenario.elements ~= nil then
      local completion = CurrentScenario.elements.completion
      if completion ~= nil then
         if completion.section ~= nil then
            broadcastToAll("Reading Section " .. completion.section)
            getObjectFromGUID('2a1fbe').call('setSection', completion.section)
         end
      end
   end
end

function handleTriggerAction(action, scenarioId, objGuid, undo)
   fhlog(DEBUG, TAG, "Handling trigger: %s", action)
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
      actualTriggered(scenarioId, action.what, objGuid, undo)
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

   -- handle random dungeons triggers
   -- obj = getobjfromguid
   -- obj.call("function_name", {})
   -- fct with one table as only parameter

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
      local tooltip = trigger.display
      if tooltip == nil then
         if trigger.type == "door" then
            tooltip = "Open"
         elseif trigger.type == "on-death" then
            tooltip = "Destroy"
         elseif trigger.type == "pressure" then
            if trigger.mode == "occupy" then
               tooltip = "Occupy"
            else
               tooltip = "Trigger"
            end
         elseif trigger.type == "manual" and trigger.action == "reveal" then
            tooltip = "Reveal " .. trigger.what.type .. " " .. trigger.what.name
         end
      end
      local label = ""
      if obj.getName() == "Section Link" and trigger.action == "reveal" then
         label = trigger.what.name
         -- Fake button as a label
         local params = {
            click_function = "noop",
            label = label,
            position = { 0, 0.01, -0.1 },
            rotation = { 0, 180, 0 },
            width = 0,
            height = 0,
            font_size = 50,
            font_color = { 0, 0, 0, 1 },
         }
         obj.createButton(params)
         scale = 0.75
      else
         -- Let's add the reveal sticker to the object
         local decal = {
            name = "section link",
            position = { 0, 0.05, 0 },
            url = "http://cloud-3.steamusercontent.com/ugc/2036234265704024562/6F6BE585CFC15298B022BEA3CE1F25D8AE7EE612/",
            scale = { 0.25, 0.25, 0.25 },
            rotation = { 90, 180 - obj.getRotation().y, 0 }
         }
         obj.addDecal(decal)
      end
      -- Let's create a button
      local params = {
         click_function = "triggerClicked_" .. scenarioId,
         label = "",
         position = { 0, 0.01, 0 },
         rotation = { 0, 0, 0 },
         width = 250 * (scale or 1),
         height = 250 * (scale or 1),
         color = { 1, 1, 1, 0 },
         font_size = 50,
         font_color = { 0, 0, 0, 0 },
         tooltip = tooltip
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

function noop()
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
   if container.hasTag("battle map token") then
      leave_object.addTag("battle map token")
      leave_object.addTag("scenarioElement")
      leave_object.registerCollisions()
      leave_object.sticky = false
   end
   if container.hasTag("deletable") then
      leave_object.addTag("deletable")
   end
   if container.hasTag("spawner") and not container.hasTag("renaming") then
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

function recoverAttackModifiers(color)
   if color == "monster" or color == "ally" then
      local battleInterfaceMat = getObjectFromGUID(BattleInterfaceMat)
      if battleInterfaceMat ~= nil then
         battleInterfaceMat.call("returnDrawnCards", true)
      end
   else
      local playerMatId = PlayerMats[color]
      if playerMatId ~= nil then
         local playerMat = getObjectFromGUID(playerMatId)
         if playerMat ~= nil then
            playerMat.call("returnDrawnCards")
         end
      end
   end
end

function playerDraw(player)
   if player.color == "ally" then
      local battleInterfaceMat = getObjectFromGUID(BattleInterfaceMat)
      if battleInterfaceMat ~= nil then
         battleInterfaceMat.call("onAllyDraw", true)
      end
   elseif player.color == "monster" then
      local battleInterfaceMat = getObjectFromGUID(BattleInterfaceMat)
      if battleInterfaceMat ~= nil then
         battleInterfaceMat.call("onMonsterDraw", true)
      end
   else
      local playerMatId = PlayerMats[player.color]
      if playerMatId ~= nil then
         local playerMat = getObjectFromGUID(playerMatId)
         if playerMat ~= nil then
            playerMat.call("drawAttackModifier", true)
         end
      end
   end
end

function showDrawnCard(params)
   local source = params.source
   local card = params.card
   local desc = card.getDescription()
   if desc ~= nil then
      local image = CardMappings[desc]
      if image ~= nil then
         UI.setAttribute("drawnCard", "image", image)
         UI.show("drawnCard")
      end
   end
   local description = CardDescriptions[desc] or " an unknown card"
   if source.type == "player" then
      broadcastToAll("Player " .. source.player .. " drew : " .. description)
   elseif source.type == "monster" then
      broadcastToAll("Monster drew : " .. description)
   elseif source.type == "ally" then
      broadcastToAll("Ally drew : " .. description)
   end
end

function resetDrawnCard()
   image = CardMappings["back"]
   UI.setAttribute("drawnCard", "image", image)
end

function playerShuffle(player)
   if player.color == "ally" then
      local battleInterfaceMat = getObjectFromGUID(BattleInterfaceMat)
      if battleInterfaceMat ~= nil then
         battleInterfaceMat.call("onAllyShuffle", true)
      end
   elseif player.color == "monster" then
      local battleInterfaceMat = getObjectFromGUID(BattleInterfaceMat)
      if battleInterfaceMat ~= nil then
         battleInterfaceMat.call("onMonsterShuffle", true)
      end
   else
      local playerMatId = PlayerMats[player.color]
      if playerMatId ~= nil then
         local playerMat = getObjectFromGUID(playerMatId)
         if playerMat ~= nil then
            playerMat.call("shuffleAttackModifiers")
         end
      end
   end
end

function getPlayerCount()
   local count = 0
   for _, color in ipairs({ "Green", "Red", "White", "Blue", "Yellow" }) do
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
   -- Explicitely ignore scripting buttons
end

function onScriptingButtonUp(index, color)
   -- Explicitely ignore scripting buttons
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

function drawCard(color)
   for _, player in ipairs(Player.getPlayers()) do
      if player.color == color then
         local obj = player.getHoverObject()
         if obj ~= nil then
            if obj.tag == "Card" or obj.tag == "Deck" then
               obj.deal(1, color)
            end
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
      getScenarioMat().call('unregisterStandee', { target = object })
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
   local obj = collision_info.collision_object
   if obj.hasTag("condition") then
      getScenarioMat().call("applyCondition", { hit_object, obj.getName() })
      destroyObject(obj)
   elseif obj.getName() == "damage" then
      getScenarioMat().call("changeStandeeHp", { standee = hit_object, amount = -1 })
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
         fhlog(DEBUG, TAG, "Releasing Pressure Plate")
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
      if settings["play-narration-in-assistant"] or false then
         getScenarioMat().call("playNarrationInAssistant", folder .. "/" .. file .. ".mp3")
      else
         local url = "http://" .. address .. ":" .. port .. "/file/" .. folder .. "/" .. file .. ".mp3"
         MusicPlayer.setCurrentAudioclip({
            url = url,
            title = folder .. " : " .. file
         })
         MusicPlayer.play()
      end
   end
end

Savables = {}

function registerSavable(info)
   table.insert(Savables, info)
end

function getSave()
   local save = {}
   for _, info in ipairs(Savables) do
      local partialSave = info.savable.call("getSave")
      local copy = JSON.decode(partialSave)
      for key, value in pairs(copy) do
         save[key] = value
      end
   end
   return JSON.encode(save)
end

function loadSave(save)
   self.setVar("_loadSave", function()
      loadSaveAsync(save)
      return 1
   end)
   startLuaCoroutine(Global, "_loadSave")
end

function loadSaveAsync(save)
   broadcastToAll("Loading in Progress...")
   table.sort(Savables, function(a, b) return a.priority < b.priority end)
   local data = JSON.decode(save)
   for i, info in ipairs(Savables) do
      local name = info.savable.call("getName")
      local savableData = data[name]
      if savableData ~= nil then
         info.savable.call("loadSave", { savableData })
         while info.savable.call("isStateUpdating") do
            waitms(100)
         end
         waitms(250)
      end
   end
   broadcastToAll("Loading Complete")
end

function reset()
   broadcastToAll("Reset in Progress...")
   startLuaCoroutine(Global, "resetAsync")
end

function resetAsync()
   MusicPlayer.setPlaylist({})
   for _, info in ipairs(Savables) do
      info.savable.call("reset")
      while info.savable.call("isStateUpdating") do
         waitms(100)
      end
      waitms(250)
   end
   broadcastToAll("Reset Complete")
   return 1
end

function characterLevelChanged()
   -- We need to delay the update as we're getting the callback *before* the change is effective in the button
   Wait.frames(function() getScenarioMat().call("updateCharacters") end, 10)
end

DataUpdatables = {}
function registerDataUpdatable(object)
   table.insert(DataUpdatables, object)
end

function loadData()
   updateData(true)
end

function updateData(first)
   first = first or false
   local baseUrl = getBaseUrl()
   for _, updatable in ipairs(DataUpdatables) do
      updatable.call("updateData", { baseUrl = baseUrl, first = first })
   end
   refreshScenarioData(baseUrl, first)
end

PingListeners = {}

function registerForPing(params)
   local obj = params[1]
   table.insert(PingListeners, obj)
end

function round(x, digits)
   local mult = 10 ^ (digits or 0)
   return math.floor(x * mult + 0.5) / mult
end

function roundTable(table, digits)
   for key, value in pairs(table) do
      if type(value) == "number" then
         table[key] = round(value, digits)
      end
   end
   return table
end

function onPlayerPing(player, position, object)
   local devSettings = JSON.decode(getDevSettings())
   local printPingedCoordinates = devSettings['print-pinged-coordinates']
   if printPingedCoordinates ~= nil then
      if printPingedCoordinates == 'Global' then
         print(JSON.encode(roundTable(position, 3)))
      else
         local target = getObjectFromGUID(printPingedCoordinates)
         if target ~= nil then
            print(JSON.encode(roundTable(target.positionToLocal(position), 3)))
         end
      end
   end

   for _, obj in ipairs(PingListeners) do
      local payload = JSON.encode(position)
      obj.call("onPing", payload)
   end
end

function registerFhLogger(obj)
   table.insert(FhLoggers, obj)
end

function fhLogSettingsUpdated()
   local devSettings = JSON.decode(getDevSettings())
   local level = devSettings['log-level']
   local tags = devSettings['log-tags']

   local payload = JSON.encode({ level = level, tags = tags })
   for _, obj in ipairs(FhLoggers) do
      obj.call("onFhLogSettingsUpdated", payload)
   end
end

DropListeners = {}

function registerForDrop(params)
   local obj = params[1]
   table.insert(DropListeners, obj)
end

function onObjectDrop(player_color, dropped_object)
   -- Let's do a cast to see if we're being dropped on top of one of the listeners
   local hitlist = Physics.cast({
      origin = dropped_object.getPositionSmooth(),
      direction = { 0, -1, 0 },
      debug = false,
   })
   if dropped_object.hasTag("battle map token") then
      onBattleMapTokenDrop(player_color, dropped_object, hitlist)
   end
   for _, hit in ipairs(hitlist) do
      local obj = hit.hit_object
      if obj ~= nil then
         for _, listener in ipairs(DropListeners) do
            if obj.guid == listener.guid then
               listener.call("onObjectDropCallback", { player_color = player_color, object = dropped_object })
            end
         end
      end
   end
end

function onBattleMapTokenDrop(player_color, dropped_object, hitlist)
   for _, hit in pairs(hitlist) do
      local obj = hit.hit_object
      if obj.hasTag("tracked") then
         local pos = obj.getPosition()
         if (dropped_object.getPosition().y > pos.y) then
            dropped_object.setPositionSmooth({ x = pos.x, y = 1.45, z = pos.z }, false, true)
            obj.setPositionSmooth({ x = pos.x, y = pos.y + 0.2, z = pos.z })
         end
      end
   end
end

function onObjectPickUp(player_color, picked_up_object)
   -- Let's do a cast to see if we're being dropped on top of one of the listeners
   local hitlist = Physics.cast({
      origin = picked_up_object.getPositionSmooth(),
      direction = { 0, -1, 0 },
      debug = false,
   })
   for _, hit in ipairs(hitlist) do
      local obj = hit.hit_object
      if obj ~= nil then
         for _, listener in ipairs(DropListeners) do
            if obj.guid == listener.guid then
               listener.call("onObjectPickUpCallback", { player_color = player_color, object = dropped_object })
            end
         end
      end
   end

   if picked_up_object.hasTag("character box") then
      Wait.frames(function()
         local objects = picked_up_object.getObjects ~= nil and picked_up_object.getObjects() or {}
         if #objects > 0 then
            broadcastToColor("Drop on a player mat to setup", player_color)
         end
      end, 1)
   end
end

function lootKeyPressed(color, hovered)
   if hovered and hovered.getName and hovered.getName() == "Loot" then
      destroyObject(hovered)
      getScenarioMat().call("doLoot", { player_color = color, count = 1 })
   end
end

function becomeColor(player_color, new_color)
   for _, player in ipairs(Player.getPlayers()) do
      if player.color == player_color then
         player.changeColor(new_color)
      end
   end
end

function fixHealthBars()
   getScenarioMat().call("fixStandees")
end

function updateHotkeys(params)
   clearHotkeys()
   local enabled = params.enabled or false
   local fivePlayers = params.fivePlayers or false
   addHotkey("Play Initiative Card",
      function(player_color, hovered_object, pointer, key_up) playCard(player_color, 1) end)
   addHotkey("Play Second Card", function(player_color, hovered_object, pointer, key_up) playCard(player_color, 2) end)
   addHotkey("Play Third Card", function(player_color, hovered_object, pointer, key_up) playCard(player_color, 3) end)
   addHotkey("Draw Card", function(player_color, hovered_object, point, key_up) drawCard(player_color) end)
   addHotkey("Sort Hand by initiative", function(player_color, hovered_object, point, key_up) sortHand(player_color) end)
   addHotkey("Loot a Token",
      function(player_color, hovered_object, point, key_up) lootKeyPressed(player_color, hovered_object) end)
   addHotkey("Fix Health Bars", function(player_color, hovered_object, point, key_up) fixHealthBars() end)

   if enabled then
      addHotkey("Loot a Token (Player 1)",
         function(player_color, hovered_object, point, key_up) lootKeyPressed("Green", hovered_object) end)
      addHotkey("Loot a Token (Player 2)",
         function(player_color, hovered_object, point, key_up) lootKeyPressed("Red", hovered_object) end)
      addHotkey("Loot a Token (Player 3)",
         function(player_color, hovered_object, point, key_up) lootKeyPressed("White", hovered_object) end)
      addHotkey("Loot a Token (Player 4)",
         function(player_color, hovered_object, point, key_up) lootKeyPressed("Blue", hovered_object) end)

      if fivePlayers then
         addHotkey("Loot a Token (Player 5)",
            function(player_color, hovered_object, point, key_up) lootKeyPressed("Yellow", hovered_object) end)
      end

      addHotkey("Change Seat to Player 1",
         function(player_color, hovered_object, point, key_up) becomeColor(player_color, "Green") end)
      addHotkey("Change Seat to Player 2",
         function(player_color, hovered_object, point, key_up) becomeColor(player_color, "Red") end)
      addHotkey("Change Seat to Player 3",
         function(player_color, hovered_object, point, key_up) becomeColor(player_color, "White") end)
      addHotkey("Change Seat to Player 4",
         function(player_color, hovered_object, point, key_up) becomeColor(player_color, "Blue") end)

      if fivePlayers then
         addHotkey("Change Seat to Player 5",
            function(player_color, hovered_object, point, key_up) becomeColor(player_color, "Yellow") end)
      end

      addHotkey("Play Initiative Card (Player 1)",
         function(player_color, hovered_object, pointer, key_up) playCard("Green", 1) end)
      addHotkey("Play Second Card (Player 1)",
         function(player_color, hovered_object, pointer, key_up) playCard("Green", 2) end)
      addHotkey("Play Third Card (Player 1)",
         function(player_color, hovered_object, pointer, key_up) playCard("Green", 3) end)

      addHotkey("Play Initiative Card (Player 2)",
         function(player_color, hovered_object, pointer, key_up) playCard("Red", 1) end)
      addHotkey("Play Second Card (Player 2)",
         function(player_color, hovered_object, pointer, key_up) playCard("Red", 2) end)
      addHotkey("Play Third Card (Player 2)",
         function(player_color, hovered_object, pointer, key_up) playCard("Red", 3) end)

      addHotkey("Play Initiative Card (Player 3)",
         function(player_color, hovered_object, pointer, key_up) playCard("White", 1) end)
      addHotkey("Play Second Card (Player 3)",
         function(player_color, hovered_object, pointer, key_up) playCard("White", 2) end)
      addHotkey("Play Third Card (Player 3)",
         function(player_color, hovered_object, pointer, key_up) playCard("White", 3) end)

      addHotkey("Play Initiative Card (Player 4)",
         function(player_color, hovered_object, pointer, key_up) playCard("Blue", 1) end)
      addHotkey("Play Second Card (Player 4)",
         function(player_color, hovered_object, pointer, key_up) playCard("Blue", 2) end)
      addHotkey("Play Third Card (Player 4)",
         function(player_color, hovered_object, pointer, key_up) playCard("Blue", 3) end)

      if fivePlayers then
         addHotkey("Play Initiative Card (Player 5)",
            function(player_color, hovered_object, pointer, key_up) playCard("Yellow", 1) end)
         addHotkey("Play Second Card (Player 5)",
            function(player_color, hovered_object, pointer, key_up) playCard("Yellow", 2) end)
         addHotkey("Play Third Card (Player 5)",
            function(player_color, hovered_object, pointer, key_up) playCard("Yellow", 3) end)
      end

      addHotkey("Sort Hand by initiative (Player 1)",
         function(player_color, hovered_object, point, key_up) sortHand("Green") end)
      addHotkey("Sort Hand by initiative (Player 2)",
         function(player_color, hovered_object, point, key_up) sortHand("Red") end)
      addHotkey("Sort Hand by initiative (Player 3)",
         function(player_color, hovered_object, point, key_up) sortHand("White") end)
      addHotkey("Sort Hand by initiative (Player 4)",
         function(player_color, hovered_object, point, key_up) sortHand("Blue") end)

      if fivePlayers then
         addHotkey("Sort Hand by initiative (Player 5)",
            function(player_color, hovered_object, point, key_up) sortHand("Yellow") end)
      end
   end
end
