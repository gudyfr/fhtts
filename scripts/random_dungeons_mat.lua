require("fhlog")
require('coordinates')
require("data/random_dungeons")
local deck_helper = require("deck_helper")

TokenBagsGuids = {
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


RandomRoomCardPositions = {
  deck = {},
  actives = {}
}
RandomMonstersCardPositions = {
  deck = {},
  actives = {}
}
ButtonPositions = {
  start = {},
  rooms = {}
}

local function locateElementsFromTags()
  for _, point in ipairs(self.getSnapPoints()) do
    local tagsMap = {}
    local position = point.position
    for _, tag in ipairs(point.tags) do
      tagsMap[tag] = true
    end

    if tagsMap["random room"] ~= nil then
      if tagsMap["deck"] ~= nil then
        RandomRoomCardPositions.deck = position
      else
        RandomRoomCardPositions.actives = position
      end
    elseif tagsMap["random monsters"] ~= nil then
      if tagsMap["deck"] ~= nil then
        RandomMonstersCardPositions.deck = position
      else
        RandomMonstersCardPositions.actives = position
      end
    elseif tagsMap["button"] ~= nil then
      if tagsMap["start"] ~= nil then
        ButtonPositions.start = position
      else
        table.insert(ButtonPositions.rooms, position)
      end
    end
  end
  table.sort(ButtonPositions.rooms, function(a, b) return a.z < b.z end)
end

function onLoad()
  TAG = self.getDescription()
  fhLogInit()
  locateElementsFromTags()

  if ButtonPositions.start ~= nil then
    local pos = ButtonPositions.start
    local button_parameters = {
      function_owner = self,
      click_function = "TestDraw",
      label          = "Draw",
      position       = { -pos.x, pos.y, pos.z },
      width          = 600,
      height         = 200,
      font_size      = 50,
      color          = { 1, 1, 1, 0 },
      scale          = { 1, 1, 1 },
      font_color     = { 1, 1, 1, 0 },
      tooltip        = "Start a Random Dungeon",
    }
    self.createButton(button_parameters)
  end

  if ButtonPositions.rooms ~= nil then
    local room_number = 1
    for _, room_position in ipairs(ButtonPositions.rooms) do
      local room_tooltip
      if room_number == 1 then
        room_tooltip = "Show the layout of the first room"
      elseif room_number == 2 then
        room_tooltip = "Show the layout of the second room"
      else
        room_tooltip = "Show the layout of the final room"
      end
      local button_parameters = {
        function_owner = self,
        click_function = "ShowRoom" .. room_number,
        label          = "Draw",
        position       = { -room_position.x, room_position.y, room_position.z },
        width          = 400,
        height         = 100,
        font_size      = 50,
        color          = { 1, 1, 1, 0 },
        scale          = { 1, 1, 0.7 },
        font_color     = { 1, 1, 1, 0 },
        tooltip        = room_tooltip,
      }

      self.createButton(button_parameters)
      room_number = room_number + 1
    end
  end

  Global.call('registerForDrop', { self })

  --   Global.call("registerForCollision", self)

  -- registerSavable(self.getName())
end

-- Function to create a coroutine that waits for a specified amount of time
local function wait(seconds)
  local co = coroutine.create(function()
      local startTime = os.time()
      local endTime = startTime + seconds

      while os.time() < endTime do
          coroutine.yield()
      end
  end)

  return function()
      local success, errorMessage = coroutine.resume(co)
      if not success then
          print("Error in wait function: " .. errorMessage)
      end
  end
end


--- Function to draw room cards until one is drawn with the correct entrance
---@param roomNumber integer the number of room which must be drawn (if 1, no check is done)
---@param exit_type string the exit type of the previous room (that the entrance type of the drawn room must match)
---@param RandomRoomCardPositions table the table of random room cards positions 
---@return any room_card the correct room card object drawn 
local function drawUntilCorrectRoom(roomNumber, exit_type, RandomRoomCardPositions)
  if roomNumber == 1 then
    local room_card = deck_helper.draw(RandomRoomCardPositions.deck, RandomRoomCardPositions.actives)
    return room_card
  else
    while true do
      print("Drawing card")
      local room_card = deck_helper.draw(RandomRoomCardPositions.deck, RandomRoomCardPositions.actives)
      print(room_card)
      for entrance_type, _ in pairs(Random_dungeons.rooms[room_card.getName()].entrances) do
        print("entrance_type: ", entrance_type)
        if entrance_type == exit_type then
          return room_card
        end
      end
      print("Drew incorrect room, redrawing")
      local waitFunction = wait(3)
      waitFunction()
    end
  end
end

--- Function to draw a room card and a monster card for a new room
local function drawRoom(roomNumber, exit_type)
  deck_helper.shuffle(RandomRoomCardPositions.deck, RandomRoomCardPositions.actives)
  deck_helper.shuffle(RandomMonstersCardPositions.deck,RandomMonstersCardPositions.actives)
  local room_card = drawUntilCorrectRoom(roomNumber, exit_type, RandomRoomCardPositions)
  local monster_card = deck_helper.draw(RandomMonstersCardPositions.deck,RandomMonstersCardPositions.actives)
  return room_card, monster_card
end

function TestDraw()
  local room_card1, _ = drawRoom(2, "B")
  print(JSON.encode(Random_dungeons.rooms[room_card1.getName()]))
  local exit_type_1 = Random_dungeons.rooms[room_card1.getName()].exit.type
  -- local exit_type_2 =Random_dungeons.rooms[roomCard2.getName()].exit.type
  -- local roomCard3, _ = drawRoom(3, exit_type_2)
  -- print(JSON.encode(roomCard3))
  return exit_type_1
end

function GetDeckOrCardAtPosition(position)
  if position ~= nil then
      local hitlist = Physics.cast({
          origin       = position,
          direction    = { 0, 1, 0 },
          type         = 2,
          size         = { 1, 1, 1 },
          max_distance = 0,
          debug        = false
      })
      for _, h in ipairs(hitlist) do
          if h.hit_object.tag == "Deck" then
              return h.hit_object
          end
          if h.hit_object.tag == "Card" then
              return h.hit_object
          end
      end
  end
  return nil
end

local function init_current_rooms()
  local current_rooms = { rooms = {} }
  return current_rooms
end


Current_rooms = init_current_rooms()


function GetOppositeCoordinates(pos)
  return { x = -pos.x, y = -pos.y }
end

function AddCoordinates(pos1, pos2)
  return { x = pos1.x + pos2.x, y = pos1.y + pos2.y }
end

function RotateCoordinates(pos, orientation)
  local x, y = RotateHexHelper(pos.x, pos.y, tonumber(orientation))
  return { x = x, y = y }
end

function RotateHexHelper(x, y, orientation)
  if x == 0 and y == 0 then
    return x, y
  end
  if orientation < 0 then
    orientation = orientation + 360
  end
  if orientation == 0 then
    return x, y
  elseif orientation == 60 then
    return -y, x + y
  elseif orientation == 120 then
    return -x - y, x
  elseif orientation == 180 then
    return -x, -y
  elseif orientation == 240 then
    return y, -x - y
  elseif orientation == 300 then
    return x + y, -x
  end
end

function DefineOffset(room_data)
  if room_data.exit.type == "A" then
    if room_data.exit.direction >= 180 and room_data.exit.direction < 359 then
      return { x = -3, y = 6, direction = 270 }
    else
      return { x = 3, y = -6, direction = 90 }
    end
  else
    if room_data.exit.direction >= 90 and room_data.exit.direction < 269 then
      return { x = 6, y = 0, direction = 180 }
    else
      return { x = -6, y = 0, direction = 0 }
    end
  end
end

function AddLayout(room_data, start, target)
  -- 1st tile: start = offset, target = exit
  -- others: start = exit-1, target = entrance
  -- angle = start.direction - target.direction
  -- origin = start - rot(target, angle)
  -- center = origin + rot(center, angle)
  -- exit = origin + rot(exit, angle)
  -- exit.direction = exit.direction + angle
  local orientation = start.direction - target.direction
  local origin = AddCoordinates(start, GetOppositeCoordinates(RotateCoordinates(target, orientation)))
  local center = AddCoordinates(origin, RotateCoordinates(room_data.center, orientation))
  local exit = AddCoordinates(origin, RotateCoordinates(room_data.exit, orientation))
  exit.direction = room_data.exit.direction + orientation
  exit.type = room_data.exit.type
  local layout = {
    name = room_data.tile,
    orientation = tostring(orientation),
    center = center,
    origin = origin
  }
  if room_data.otherTiles ~= nil then
    layout.other_layouts = {}
    for _, other_tile in ipairs(room_data.otherTiles) do
      local other_center = AddCoordinates(origin, RotateCoordinates(other_tile.center, orientation))
      local other_layout = {
        name = other_tile.tile,
        orientation = tostring(orientation),
        center = other_center,
        origin = origin
      }
      table.insert(layout.other_layouts, other_layout)
    end
  end
  return layout, exit
end

local function create_layout(room_data, Current_rooms)
  Current_rooms.offset = DefineOffset(room_data)
  local layout, exit = AddLayout(room_data, Current_rooms.offset, room_data.exit)
  print("layout: ", JSON.encode(layout))
  return layout, exit
end

function ContinueLayout(room_data, Current_rooms)
  local layout, exit = AddLayout(room_data, Current_rooms.last_exit, room_data.entrances[Current_rooms.last_exit.type])
  return layout, exit
end

function AddRandomScenarioLayout(room_data, Current_rooms) -- TODO
  local layout = {}
  if Current_rooms == nil then
    Current_rooms = {}
    layout = create_layout(room_data)
    table.insert(Current_rooms, { room = room_data, layout = layout })
  else
    layout = ContinueLayout(room_data, Current_rooms)
    table.insert(Current_rooms, { room = room_data, layout = layout })
  end
  local params = { layout = layout }
  Global.call("AddRandomScenarioLayoutEx", params)
end

function PlaceNumberedTokens(room_data, room_layout)
  for i, rel_pos in ipairs(room_data.locations) do
    local token_name = "n" .. i
    local bagId = tokenBagsGuids[token_name]
    local token_pos = AddCoordinates(room_layout.origin, RotateCoordinates(rel_pos, room_layout.orientation))
    local x, z = getWorldPositionFromHexPosition(token_pos.x, token_pos.y)
    local obj = getToken({ name = token_name }, { x = x, y = 2.35, z = z })
  end
end

function TestRoomLayout(card_name, Current_rooms)
  print("Current_rooms:", JSON.encode(Current_rooms))
  local room_data = Random_dungeons.rooms[card_name]
  if room_data ~= nil then
    local layout
    local exit
    if #Current_rooms.rooms == 0 then
      Global.call("CreateRandomScenarioEx")
      print("Preparing first room")
      layout, exit = create_layout(room_data, Current_rooms)
    elseif #Current_rooms.rooms < 3 then
      print("Preparing new room")
      layout, exit = ContinueLayout(room_data, Current_rooms)
    else
      print("End of scenario") --TODO
    end
    local params = {
      tile = room_data.tile,
      layout = { layout }
    }
    table.insert(Current_rooms.rooms,
      {
        room = room_data,
        layout = layout
      })
    --Maybe not needed to store all this information
    Current_rooms.last_exit = exit
    Global.call("GetMapTileEx", params)
    if layout.other_layouts ~= nil then
      for _, other_layout in ipairs(layout.other_layouts) do
        local other_params = {
          tile = other_layout.name,
          layout = { other_layout }
        }
        Global.call("GetMapTileEx", other_params)
      end
    end
  end
end

function GetDungeonLoot()
  local loot = {
    Arrowvine = 1,
    Axenut = 1,
    Coins = 12,
    Corpsecap = 1,
    Flamefruit = 1,
    Hide = 2,
    Item = 0,
    Lumber = 2,
    Metal = 2,
    Rockroot = 1,
    Snowthistle = 1
  }
  return loot
end

function UpdateDungeonOverlays(room_data, Dungeon_elements)
  -- Treat loot and overlays defined on the room card only
  local used_dungeon_overlays = {}
  if Dungeon_elements.loot == nil then
    Dungeon_elements.loot = GetDungeonLoot()
    Dungeon_elements.overlays = {}
  else
    for _, used_overlay in ipairs(Dungeon_elements.overlays) do
      used_dungeon_overlays[used_overlay.name] = true
    end
  end
  for room_overlay in room_data.overlays do
    if used_dungeon_overlays[room_overlay.name] then
      for dungeon_overlay in Dungeon_elements.overlays do
        if room_overlay.name == dungeon_overlay.name then
          dungeon_overlay.count = dungeon_overlay + 1
        end
      end
    else
      table.insert(Dungeon_elements.overlays,
        { name = room_overlay.name, count = #room_overlay.positions, type = room_overlay.type })
      -- TODO: Add type to room_data overlays
    end
  end
end

function UpdateDungeonMonsters(monsters_data, Dungeon_elements)
  --Treat monsters and overlays from monsters random cards
  local used_dungeons_monsters = {}
  local used_dungeon_overlays = {}
  if Dungeon_elements.monsters == nil then
    Dungeon_elements.monsters = {}
  else
    for _, used_monster_element in ipairs(Dungeon_elements.monsters) do
      if used_monster_element.category == "monster" then
        used_dungeons_monsters[used_monster_element.name] = true
      elseif used_monster_element.category == "overlay" then
        used_dungeon_overlays[used_monster_element.name] = true
      end
    end
  end
  for room_monster_element in monsters_data.positions do
    if room_monster_element.category == "monster" then
      if used_dungeons_monsters[room_monster_element.name] == nil then
        table.insert(Dungeon_elements.monsters, { name = room_monster_element.name })
      end
    elseif room_monster_element.category == "overlay" then
      if not used_dungeon_overlays[room_monster_element.name] then
        table.insert(Dungeon_elements.overlays,
          { name = room_monster_element.name, count = 1, type = room_monster_element.type })
        used_dungeon_overlays[room_monster_element.name] = true
      else
        for _, dungeon_overlay in ipairs(Dungeon_elements.overlays) do
          if dungeon_overlay.name == room_monster_element.name then
            dungeon_overlay.count = dungeon_overlay.count + 1
          end
        end
      end
    end
  end
end

function SpawnDungeonElements(room_data, monsters_data, Dungeon_elements, CurrentScenarioElementPosition)
  UpdateDungeonOverlays(room_data, Dungeon_elements)
  UpdateDungeonMonsters(monsters_data, Dungeon_elements)
  local scenarioBag = getObjectFromGUID('cd31b5')
  for _, info in ipairs(Dungeon_elements.overlays) do
    local overlayName = info.name
    local count = info.count
    local size = 1
    CurrentScenarioElementPosition = CurrentScenarioElementPosition + size
    print("Spawning elements")
    CurrentScenarioElementPosition = spawnNElementsIn(count, overlayName, info, scenarioBag, --move in utils
      scenarioElementPositions, CurrentScenarioElementPosition)
    WaitMS(LAYOUT_WAIT_TIME_MS)
  end
end

local function fillRoomContent(card_number)
end

function onObjectDropCallback(params)
  local card = params.object
  if card ~= nil and card.tag == "Card" then
    local card_name = card.getName()
    local card_number = tonumber(card_name)
    if card_number > 866 and card_number < 891 then
      print("Doing Layout for card ", card_number)
      TestRoomLayout(card_name, Current_rooms)
    else
      fillRoomContent(card_name)
    end
  end
end


function StartRandomDungeon(external)
  if external ~= true then
    external = false
  end
  Global.call("CreateRandomScenarioEx")
  --output:
  -- CurrentScenario = {
  --     triggers = {
  --        byTriggerId = {},
  --        byObjectGuid = {},
  --        triggered = {},
  --        triggersById = {}
  --     },
  --     doors = {
  --     },
  --     tileGuids = {},
  --     objectsOnObjects = {},
  --     id = name, name is a random string between 1,000 and 1,000,000
  --     elements = Scenarios[name], TODO: modify this
  --     registeredForCollision = {}
  --  }
  local current_rooms = init_current_rooms()
  local roomCard, monsterCard = drawRoom(1)
  local layout, exit = create_layout(Random_dungeons.rooms[roomCard.getName()], Current_rooms)
  -- entries = BuildEntries(room,)
  print("RoomCard: ", JSON.encode(Random_dungeons.rooms[roomCard.getName()]))
  Global.call("AddRandomScenarioLayoutEx", params)
  -- shuffle(RandomRoomCardPositions.deck, RandomRoomCardPositions.actives)
  -- draw({ type = "player", player = getPlayerNumber() }, RandomRoomCardPositions.deck, RandomRoomCardPositions.actives,
  --   true)
  -- shuffle(RandomMonstersCardPositions.deck, RandomMonstersCardPositions.actives)
  -- draw({ type = "player", player = getPlayerNumber() }, RandomMonstersCardPositions.deck,
  --   RandomMonstersCardPositions.actives,
  --   not external)
end