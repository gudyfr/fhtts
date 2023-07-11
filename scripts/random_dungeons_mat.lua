require("fhlog")
require("data/random_dungeons")

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

function locateElementsFromTags()
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
      click_function = "StartRandomDungeon",
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

  --   Global.call("registerForCollision", self)
  --   self.addContextMenuItem("Pack Character", packCharacter)
  -- end

  -- updateDecals()
  -- registerSavable(self.getName())

  -- Global.call("registerForDrop", { self })
end

function StartRandomDungeon(external)
  if external ~= true then
    external = false
  end
  shuffle(RandomRoomCardPositions.deck, RandomRoomCardPositions.actives)
  draw({ type = "player", player = getPlayerNumber() }, RandomRoomCardPositions.deck, RandomRoomCardPositions.actives,
    not external)
  shuffle(RandomMonstersCardPositions.deck, RandomMonstersCardPositions.actives)
  draw({ type = "player", player = getPlayerNumber() }, RandomMonstersCardPositions.deck,
    RandomMonstersCardPositions.actives,
    not external)
end

function function_name(params)
  -- Global.call()
end
