scenarioPickerPage = 0
minScenarioPickerPage = 0
maxScenarioPickerPage = math.floor(154 / 10)

scenarioBagId = 'cd31b5'
ruleBookId = '0ea82e'
monsterStandeesBagId = '454465'
characterStandeesBagId = '09c686'
bossStandeesBagId = '69b1fc'
scenarioBookId = '5cd351'
mapTilesBagId = '9cbcab'

playerMats = {
   Blue  = 'b6aae9',
   White = '1b07a2',
   Red   = '24c70e',
   Green = 'afdfff'
}

--[[ The onLoad event is called after the game save finishes loading. --]]
function onLoad()
   -- load scenario data
   refreshScenarioData()

   setupScenarioPicker()
   scenarioBag = getObjectFromGUID(scenarioBagId)
   -- scenarioBag.reset()

   -- getObjectFromGUID(ruleBookId).Book.setPage(83)

   addHotkey("Play Initiative Card",
      function(player_color, hovered_object, pointer, key_up) playCard(player_color, 1) end)
   addHotkey("Play Second Card", function(player_color, hovered_object, pointer, key_up) playCard(player_color, 2) end)
   addHotkey("Play Third Card", function(player_color, hovered_object, pointer, key_up) playCard(player_color, 3) end)
   addHotkey("Draw Card", function(player_color, hovered_object, point, key_up) drawCard(player_color) end)
   addHotkey("Sort Hand by initiative", function(player_color, hovered_object, point, key_up) sortHand(player_color) end)
end

function refreshScenarioData()
   print("Loading Scenario Data")
   WebRequest.get("https://gudyfr.github.io/fhtts/scenarios.json", processScenarioData)
end

function processScenarioData(request)
   -- print("Parsing Scenario Data")
   scenarios = json.parse(request.text)
   refreshPickerList()
   print("Scenario Data loaded")
end

--[[ The onUpdate event is called once per frame. --]]
function onUpdate()
   --[[ print('onUpdate loop!') --]]
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

function getMapTile(mapName)
   nameLen = string.len(mapName)
   letter = string.sub(mapName, nameLen)
   config = letterConfigs[letter]
   mapTileName = string.sub(mapName, 1, nameLen - 1) .. config.tile
   mapBag = getObjectFromGUID(mapTilesBagId)
   for id, tile in pairs(mapBag.getObjects())
   do
      if tile.name == mapTileName
      then
         mapTile = mapBag.takeObject({ guid = tile.guid })
         clone = mapTile.clone()
         mapBag.putObject(mapTile)
         if config.flip then
            if clone.getRotation().z > 90 then
               clone.setRotation({ 0, 0, 0 })
            else
               clone.setRotation({ 0, 0, 180 })
            end
         end
         clone.addTag("deletable")
         getObjectFromGUID(scenarioBagId).putObject(clone)
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
            clone = monsterStandees.clone()
            monsterBag.putObject(monsterStandees)
            clone.addTag("deletable")
            clone.addTag("spawner")
            if bagId == bossStandeesBagId or (monster.boss or false) then
               clone.addTag("boss")
            end

            if monster.as ~= nil then
               -- We need to get a monster out of the bad, reset the bag and put the monster back in the bag.
               -- And rename both
               local obj = clone.takeObject()
               obj.setName(monster.as)
               clone.setName(monster.as .. "s")
               clone.reset()
               clone.putObject(obj)
            end

            if position ~= nil then
               local pos = { position.x, position.y + 1.4, position.z }
               --clone.setLock(true)
               clone.setPosition(pos)
               clone.setRotation({ 0, 180, 0 })
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
}

function getToken(token, scenarioElementPositions, currentScenarioElementPosition)
   local bagId = tokenBagsGuids[token.name]
   if bagId == nil then
      bagId = tokenBagsGuids["n" .. token.name]
   end
   if bagId ~= nil then
      local bag = getObjectFromGUID(bagId)
      if bag ~= nil then
         local position = scenarioElementPositions[currentScenarioElementPosition]
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
               obj.addTag("deletable")
               if (info.trackable or false) then
                  obj.addTag("trackable")
                  -- For sizing of the overlays
                  obj.addTag("overlay")
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
                  if type == "Obstacle" then
                     color = { 29, 126, 59 }
                  elseif type == "Pressure Plate" then
                     color = { 173, 173, 173 }
                  elseif type == "Trap" then
                     color = { 228, 19, 19 }
                  elseif type == "Wall" then
                     color = { 53, 52, 53 }
                  elseif type == "Corridor" then
                     color = { 172, 172, 172 }
                  elseif type == "Difficult Terrain" then
                     color = { 121, 58, 210 }
                  elseif type == "Door" then
                     color = { 34, 96, 209 }
                  elseif type == "Hazardous Terrain" then
                     color = { 244, 127, 32 }
                  elseif type == "Icy Terrain" then
                     color = { 83, 205, 20 }
                  elseif type == "Objective" then
                     color = { 238, 189, 38 }
                  end

                  if color ~= nil then
                     color = { color[1] / 255, color[2] / 255, color[3] / 255 }
                     if settings["enable-highlight-tiles-by-type"] or false then
                        obj.highlightOn(color)
                     end
                     updateGMNotes(obj, {highlight=color})
                  end
               end
     

               if not addedToScenarioMat then
                  destination.putObject(obj)
               end
            else
               print("Error finding overlay " .. name)
            end
         end
         bag.putObject(container)
      end
   end
   bag.setLock(true)
   return currentScenarioElementPosition
end

function updateGMNotes(obj,update)
  local current = getGMNotes(obj)
   for key,value in pairs(update) do
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

function cleanup()
   local zones = { 'e1e978', '1f0c29' }
   local highlighted = false
   local deleted = false
   for _, zoneGuid in ipairs(zones) do
      local zone = getObjectFromGUID(zoneGuid)
      -- Iterate through object occupying the zone
      for _, occupyingObject in ipairs(zone.getObjects(true)) do
         if occupyingObject.hasTag("deletable") then
            if occupyingObject.hasTag("about to delete") then
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

   if deleted then
      -- Notify all player mats to also cleanup their attack modifier decks
      for color, guid in pairs(playerMats) do
         getObjectFromGUID(guid).call("cleanup")
      end
   end

   if highlighted then
      broadcastToAll("Delete highlighted objects? Press cleanup again.", { r = 1, g = 0, b = 0 })
   end

   Wait.time(cleanupTimeout, 2)
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
   print("Requesting scenario '" .. name .. "'")
   cleanupPrepareArea()
   scenarioBag = getObjectFromGUID('cd31b5')
   scenarioBag.reset()
   settings = JSON.decode(getSettings())
   local elements = scenarios["" .. name]
   if elements ~= nil then
      local scenarioElementPositions = getScenarioMat().call("getScenarioElementPositions")
      local currentScenarioElementPosition = 0

      local choices = elements.choices

      if choices ~= nil then
         -- We first need to let players make a choice
         -- which we'll represent with tokens

         -- We want to center the choices, and space them by two
         local firstPosition = (#scenarioElementPositions - #choices) / 2
         for _, choice in ipairs(choices) do
            local token = choice.token
            local value = choice.value
            if token ~= nil and value ~= nil then
               local title = choice.title or ("Choose " .. token)
               local obj = getToken({ name = token }, scenarioElementPositions, firstPosition)
               print(obj)
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
            getObjectFromGUID('2a1fbe').call("setScenarioPage", elements.page)
         end
         return
      end


      local trackables = elements.trackables
      if trackables == nil then
         trackables = {}
      end


      for _, info in ipairs(elements.overlays) do
         local name = info.name
         local count = info.count
         local size = 1
         if info.size ~= nil then
            size = info.size
            if size == 3 then
               -- 3 hex tiles only use 2 wide hexes
               size = 2
            end
         end
         currentScenarioElementPosition = currentScenarioElementPosition + size
         print("Adding " .. count .. " " .. name .. " to the scenario bag at pos " .. currentScenarioElementPosition)
         currentScenarioElementPosition = spawnNElementsIn(count, trackables, name, info, scenarioBag,
            scenarioElementPositions, currentScenarioElementPosition)
      end

      for index, name in ipairs(elements.tiles) do
         print("Adding Map Tile " .. name .. " to the scenario bag")
         getMapTile(name)
      end

      -- offset by 2 for the monsters
      currentScenarioElementPosition = currentScenarioElementPosition + 2
      if elements.monsters ~= nil then
         for index, monster in ipairs(elements.monsters) do
            print("Adding Monster " .. JSON.encode(monster))
            getMonster(monster, scenarioElementPositions, currentScenarioElementPosition)

            -- and they take a bit of space
            currentScenarioElementPosition = currentScenarioElementPosition + 2
         end
      end

      if elements.tokens ~= nil then
         for index, token in ipairs(elements.tokens) do
            print("Adding token " .. token.name)
            getToken(token, scenarioElementPositions, currentScenarioElementPosition)
            currentScenarioElementPosition = currentScenarioElementPosition + 1
         end
      end

      if elements.grid == "Horizontal" or elements.grid == "horizontal" then
         Grid.type = 2
      else
         Grid.type = 3
      end

      if elements.page ~= nil then
         -- Tell the book mat to go to the right scenario page
         getObjectFromGUID('2a1fbe').call("setScenarioPage", elements.page)
      end

      if elements.errata ~= nil then
         getObjectFromGUID('a46bc7').setDescription(elements.errata)
      else
         getObjectFromGUID('a46bc7').setDescription("")
      end

      getScenarioMat().call("setScenario", { scenario = title, campaign = campaign })
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
      --print(params)
      getScenarioMat().call("spawned", params)
   end
end

function setupScenarioPicker()
   picker = getObjectFromGUID('98c349')
   prevParameters = {
      click_function = 'prevPickerPage',
      label = '<',
      position = { 0.4, 5.0, 0.4 },
      rotation = { 0, 180, 0 },
      width = 50,
      height = 50,
      font_size = 50,
   }
   picker.createButton(prevParameters)

   nextParameters = {
      click_function = 'nextPickerPage',
      label = '>',
      position = { -0.4, 5.0, 0.4 },
      rotation = { 0, 180, 0 },
      width = 50,
      height = 50,
      font_size = 50,
   }
   picker.createButton(nextParameters)


   for i = 1, 10 do
      self.setVar('chooseScenario' .. i, function() chooseScenario(i) end)
      buttonParam = {
         click_function = 'chooseScenario' .. i,
         label = '.',
         position = { 0.45, 4.0, 0.37 - 0.082 * i },
         rotation = { 0, 180, 0 },
         width = 25,
         height = 25,
         font_size = 50,
      }
      picker.createButton(buttonParam)
   end

   --refreshPickerList()
end

function prevPickerPage()
   scenarioPickerPage = scenarioPickerPage - 1
   if scenarioPickerPage < 0 then
      scenarioPickerPage = 0
   end
   refreshPickerList()
end

function nextPickerPage()
   scenarioPickerPage = scenarioPickerPage + 1
   if scenarioPickerPage > maxScenarioPickerPage then
      scenarioPickerPage = maxScenarioPickerPage
   end
   refreshPickerList()
end

function refreshPickerList()
   description = ""
   for i = scenarioPickerPage * 10 + 1, scenarioPickerPage * 10 + 10 do
      scenario = scenarios[i]
      if scenario ~= nil then
         description = description .. "     " .. i .. ". " .. scenario.title .. "\n"
      else
         description = description .. "     " .. i .. ".\n"
      end
   end
   picker = getObjectFromGUID('98c349')
   picker.setDescription(description)
   title = "Scenario Picker (" .. scenarioPickerPage .. " of " .. maxScenarioPickerPage .. ")"
   picker.setName(title)
end

function chooseScenario(i)
   n = scenarioPickerPage * 10 + i
   print("Chosen Scenario : " .. n)
   prepareFrosthavenScenario(n)
end

function playerDraw(player)
   playerMatId = playerMats[player.color]
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
   playerMatId = playerMats[player.color]
   if playerMatId ~= nil then
      playerMat = getObjectFromGUID(playerMatId)
      playerMat.call("shuffle")
   end
end

function playerOpenSectionBook(player, text)
   openSectionBookAtPage(tonumber(text))
end

function getPlayerMat(player)
   playerMatId = playerMats[player.color]
   if playerMatId ~= nil then
      return getObjectFromGUID(playerMatId)
   end
   return nil
end

function getPlayerMatExt(params)
   playerMatId = playerMats[params[1]]
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

function onObjectDestroy(object)
   if object.hasTag("tracked") then
      getScenarioMat().call('unregisterStandee', object)
   end
end

collisionCallbacks = {}

function registerForCollision(obj)
   Wait.frames(function() obj.registerCollisions() end, 10)
   collisionCallbacks[obj.guid] = obj
end

function onObjectCollisionEnter(hit_object, collision_info)
   -- print("onObjectCollisionEnter " .. JSON.encode(hit_object))
   -- collision_info table:
   --   collision_object    Object
   --   contact_points      Table     {Vector, ...}
   --   relative_velocity   Vector
   local obj = collision_info.collision_object
   if obj.hasTag("condition") then
      getScenarioMat().call("applyCondition", { hit_object, obj.getName() })
      destroyObject(obj)
   end

   for guid, obj in pairs(collisionCallbacks) do
      if guid == hit_object.guid then
         obj.call("onObjectCollisionEnter", { hit_object, collision_info })
      end
   end
end

function getSettings()
   return getObjectFromGUID('1a09ac').call("getSettings") or "{}"
end

function sortHand(color)
   for _, player in ipairs(Player.getPlayers()) do
      if player.color == color then
         local cards = player.getHandObjects()
         local cardPositions = {}   
         for _, card in ipairs(cards) do
            table.insert(cardPositions, card.getPosition())
         end
         table.sort(cards, function(c1,c2) return c1.getName() < c2.getName() end)
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