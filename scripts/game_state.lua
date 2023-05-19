-- A collection of Lua objects to capture game state

-- Utility functions

function shuffle(table)
    for i = #table, 2, -1 do
        local j = math.random(i)
        table[i], table[j] = table[j], table[i]
    end
end

function map(list, func)
    local result = {}
    for _, entry in ipairs(list) do
        table.insert(result, func(entry))
    end
    return result
end

-- Card Class

Card = {}
Card.__index = Card
function Card.new(json)
    local self = setmetatable({}, Card)
    self.number = json[1]
    self.shuffle = json[2]
    self.initiative = json[3]
    return self
end

-- Pile class

Pile = {}
Pile.__index = Pile
function Pile.new()
    local self = setmetatable({}, Pile)
    self.cards = {}
    return self
end

function Pile:addCard(card)
    table.insert(self.cards, card)
end

function Pile:drawCard()
    local cards = self.cards
    if #cards > 0 then
        local card = cards[#cards]
        table.remove(cards, #cards)
        return card
    else
        return nil
    end
end

function Pile:shuffle()
    shuffle(self.cards)
end

function Pile:shouldShuffle()
    for _, card in ipairs(self.cards) do
        if card.shuffle then
            return true
        end
    end
    return false
end

function Pile:moveCardsTo(otherPile)
    for _, card in ipairs(self.cards) do
        otherPile:addCard(card)
    end
    self.cards = {}
end

-- Deck

Deck = {}
Deck.__index = Deck

function Deck.new(json)
    local self = setmetatable({}, Deck)
    self.drawPile = Pile.new()
    self.discardPile = Pile.new()

    if json ~= nil then
        for _, cardJson in ipairs(json) do
            self:addCard(Card.new(cardJson))
        end
    end
    self.drawPile:shuffle()
    return self
end

function Deck:addCard(card)
    self.drawPile:addCard(card)
end

function Deck:draw()
    local card = self.drawPile:drawCard()
    if card ~= nil then
        self.discardPile:addCard(card)
    end
    return card
end

function Deck:shouldShuffle()
    return self.discardPile:shouldShuffle()
end

function Deck:shuffle()
    self.discardPile:moveCardsTo(self.drawPile)
    self.drawPile:shuffle()
end

function Deck:shuffleIfNeeded()
    if self:shouldShuffle() then
        self:shuffle()
    end
end

-- MonsterInstance class

MonsterInstance = {}
MonsterInstance.__index = MonsterInstance

function MonsterInstance.new(monster, nr, monsterLevel, type)
    local self = setmetatable({}, MonsterInstance)
    local maxHp = monsterLevel[type].hp
    self.monster = monster
    self.type = type or "normal"
    self.nr = nr
    self.hp = maxHp
    self.maxHp = maxHp
    self.conditions = {}
    self.level = monsterLevel
    return self
end

function MonsterInstance:switchType()
    if self.type == "normal" then
        self.type = "elite"
    elseif self.type == "elite" then
        self.type = "normal"
    end
    if self.hp == self.maxHp then
        local newMaxHp = level[self.type].hp
        self.maxHp = newMaxHp
        self.hp = newMaxHp
    end
end

function MonsterInstance:changeHp(amount)
    self.hp = self.hp + amount
    if self.hp <= 0 then
        -- death, free up this instance
        self.monster:removeInstance(self)
    elseif self.hp > self.maxHp then
        self.hp = self.maxHp
    end
end

function MonsterInstance:toggleCondition(condition)
    local current = self.conditions[condition] or false
    self.conditions[condition] = not condition
end

function MonsterInstance:toState()
    print("toto")
    return {
        type = self.type,
        nr = self.nr,
        hp = self.hp,
        conditions = self.conditions,
        level = self.level[self.type],
    }
end

MonsterLevelType = {}
MonsterLevelType.__index = MonsterLevelType
function MonsterLevelType.new(json)
    local self = setmetatable({}, MonsterLevelType)
    self.hp = json.hp
    self.shield = json.shield or 0
    self.retaliate = json.retaliate or 0
    self.immunities = json.immunities or {}
    self.conditions = json.conditions or {}


    return self
end

MonsterLevel = {}
MonsterLevel.__index = MonsterLevel

function MonsterLevel.new(json)
    local self = setmetatable({}, MonsterLevel)
    if json.normal then
        self.normal = MonsterLevelType.new(json.normal)
    else
        self.normal = {}
    end
    if json.elite then
        self.elite = MonsterLevelType.new(json.elite)
    else
        self.elite = {}
    end
    if json.boss then
        self.boss = MonsterLevelType.new(json.boss)
    else
        self.boss = {}
    end
    return self
end

Monster = {}
Monster.__index = Monster

-- json :
-- {
--     "name" : "Monster Name",
--     "maxInstances" : 8,
--     "deck" : [{"234", true}, {"235", false}, ...],
--     "isBoss" : false,
--     "levels" : [
--         {
--             "normal" : {"hp" : 10},
--             "elite" : {"hp" : 14}
--         },
--         {
--             ...
--         }
--     ]
-- }
function Monster.new(json, level)
    local remainingStandees = {}
    for i = 1, json.maxInstances do
        table.insert(remainingStandees, i)
    end
    shuffle(remainingStandees)
    local levels = {}
    for _, lvl in ipairs(json.levels) do
        table.insert(levels, MonsterLevel.new(lvl))
    end
    local self = setmetatable({}, Monster)
    self.name = json.name
    self.deck = Deck.new(json.deck)
    self.instances = {}
    self.remainingStandees = remainingStandees
    self.isBoss = json.isBoss
    self.level = level
    self.levels = levels

    return self
end

function Monster:newInstance(type)
    type = type or "normal"
    local standees = self.remainingStandees
    if #standees > 0 then
        local nr = standees[#standees]
        table.remove(standees, #standees)
        local instance = MonsterInstance.new(self, nr, self.levels[self.level + 1], type)
        table.insert(self.instances, instance)
        return instance
    else
        return nil
    end
end

function Monster:removeInstance(instance)
    for i = #self.instances, 1, -1 do
        if self.instances[i] == instance then
            local nr = instance.nr
            table.insert(self.remainingStandees, nr)
            shuffle(self.remainingStandees)
            table.remove(self.instances, i)
        end
    end
end

function Monster:findInstance(nr)
    for _, instance in ipairs(self.instances) do
        if instance.nr == nr then
            return instance
        end
    end
    return nil
end

function Monster:startRound()
    self.currentCard = deck:drawCard()
end

function Monster:endRound()
    self.currentCard = nil
    deck:shuffleIfNeeded()
end

function Monster:toState()
    local result = {
        name = self.name,
        instances = map(self.instances, MonsterInstance.toState)
    }
    if self.currentCard ~= nil then
        result.currentCard = self.currentCard.nr
        result.initiative = self.currentCard.initiative
    else
        result.currentCard = 0
        result.initiative = 100
    end
    return result
end

GameState = {}
GameState.__index = GameState

function GameState.new(gameData)
    local self = setmetatable({}, GameState)
    self.gameData = gameData
    self.characters = {}
    self.monsters = {}
    self.round = 1
    self.roundState = 0
    self.level = 0
    return self
end

function GameState:addMonster(name)
    local monsterData = self.gameData.monsters[name]
    table.insert(self.monsters, Monster.new(monsterData, self.level))
end

function GameState:setLevel(level)
    self.level = level
end

function GameState:newMonsterInstance(name, type)
    local monster = self:findMonster(name)
    if monster ~= nil then
        return monster:newInstance(type)
    end
end

function GameState:changeHealth(name, nr, amount)
    local target = self:findTarget(name, nr)
    if target ~= nil then
        target:changeHp(amount)
    end
end

function GameState:toState()
    return {
        level = self.level,
        round = self.round,
        roundState = self.roundState,
        monsters = map(self.monsters, Monster.toState),
    }
end

function GameState:findMonster(name)
    for _, monster in ipairs(self.monsters) do
        if monster.name == name then
            return monster
        end
    end
end

function GameState:findTarget(name, nr)
    local monster = self:findMonster(name)
    if monster ~= nil then
        return monster:findInstance(nr)
    end
end

function test()
    local gameData = {
        monsters = {
            Test = {
                name = "Test",
                maxInstances = 8,
                isBoss = false,
                levels = {
                    { normal = { hp = 8 },  elite = { hp = 10 } },
                    { normal = { hp = 18 }, elite = { hp = 20 } },
                    { normal = { hp = 28 }, elite = { hp = 30 } },
                    { normal = { hp = 38 }, elite = { hp = 40 } },
                    { normal = { hp = 48 }, elite = { hp = 50 } },
                    { normal = { hp = 58 }, elite = { hp = 60 } },
                    { normal = { hp = 68 }, elite = { hp = 70 } },
                    { normal = { hp = 78 }, elite = { hp = 80 } },
                    { normal = { hp = 88 }, elite = { hp = 90 } },
                },
                deck = {
                    { 231, false, 10 },
                    { 232, true,  20 },
                    { 233, false, 30 },
                    { 234, false, 40 },
                    { 235, false, 50 },
                    { 236, false, 60 },
                    { 237, true,  70 },
                    { 238, false, 80 },
                }
            }
        }
    }
    local gameState = GameState.new(gameData)
    gameState:addMonster("Test")
    local nr1 = gameState:newMonsterInstance("Test", "normal").nr
    gameState:newMonsterInstance("Test", "elite")
    print(JSON.encode(gameState:toState()))

    gameState:changeHealth("Test", nr1, -50)
    print(JSON.encode(gameState:toState()))
end
