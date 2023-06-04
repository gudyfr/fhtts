require("layout")
require("standees")
require("data/monsterStats")
require("data/monsterAbilities")

Pirata = Font.new(
    'http://cloud-3.steamusercontent.com/ugc/2028354869650206853/B4E2841BFD94B1A273A829C9D5458D643FA73216/')

function createInstance(parent, data)
    local container = Container.new(parent)
    container:setLayoutParams(LinearLayoutParams.new(Alignment.middle))
    container:setSize(100, 36)
    local mainLayout = LinearLayout.new(Orientations.horizontal)
    mainLayout:setSpacing(2)
    container:setLayout(mainLayout)
    local image = Image.new(container)
    image:setSize(35, 35)
    image:setLayoutParams(LinearLayoutParams.new(Alignment.bottom))
    if data.type == 1 then
        image:setImage(StandeeNumbers[data.standeeNr])
    elseif data.type == 2 then
        image:setImage(EliteStandeeNumbers[data.standeeNr])
    end
    local verticalContainer = Container.new(container)
    verticalContainer:setLayoutParams(LinearLayoutParams.new(Alignment.bottom))
    verticalContainer:setLayout(LinearLayout.new(Orientations.vertical):setAlongAxisAlignment(Alignment.bottom))
    verticalContainer:setSize(65, 30)

    local conditionsContainer = Container.new(verticalContainer)
    conditionsContainer:setLayout(LinearLayout.new(Orientations.horizontal):setSpacing(2))
    conditionsContainer:setSize(65, 15)
    for _, condition in ipairs(data.conditions) do
        local conditionImage = Image.new(conditionsContainer)
        conditionImage:setImage(conditionStickerUrls[conditionsOrder[condition + 1]])
        conditionImage:setSize(15, 15)
    end
    local healthContainer = Container.new(verticalContainer)
    healthContainer:setLayout(LinearLayout.new(Orientations.horizontal):setSpacing(2))
    healthContainer:setSize(65, 15)
    local healthImage = Image.new(healthContainer)
    healthImage:setImage(
        'http://cloud-3.steamusercontent.com/ugc/2028354869650263195/F327B0CCBA108760456F132CDAE5EB987F34C7BB/')
    healthImage:setSize(15, 21)
    healthImage:setLayoutParams(LinearLayoutParams.new(Alignment.bottom))

    local healthText = Label.new(healthContainer)
    healthText:setText(data.health .. " / " .. data.maxHealth)
    healthText:setFont(Pirata)
    healthText:setSize(40, 21)
    healthText:setFontSize(16)
    healthText:setTextAlign("LowerLeft")
end

function createDivider(parent)
    local divider = Image.new(parent)
    divider:setImage(
        'http://cloud-3.steamusercontent.com/ugc/2028354869650285695/31F0866A92D61724D8553F6B9FC966A9CF7EFC2F/')
    divider:setSize(490, 10)
    divider:setLayoutParams(LinearLayoutParams.new(Alignment.middle))
end

function createMonster(parent, data)
    local height = 150
    if #data.monsterInstances > 0 then
        height = height + 40
        if #data.monsterInstances > 5 then
            height = height + 40
        end
    end
    local container = Container.new(parent)
    container:setSize(500, height)
    local mainLayout = LinearLayout.new(Orientations.vertical)
    mainLayout:setSpacing(5)
    container:setLayout(mainLayout)
    local infoContainer = Container.new(container)
    infoContainer:setLayout(LinearLayout.new(Orientations.horizontal))
    infoContainer:setSize(500, 150)
    local image = Image.new(infoContainer)
    image:setSize(90, 90)
    image:setImage(MonsterStats[data.id])
    image:setLayoutParams(LinearLayoutParams.new(Alignment.middle))

    local abilityImage = Image.new(infoContainer)
    abilityImage:setSize(200, 140)
    abilityImage:setLayoutParams(LinearLayoutParams.new(Alignment.middle))

    if data.currentCard ~= nil and data.currentCard > 0 then
        abilityImage:setImage(MonsterAbilities[data.id .. "_" .. data.level .. "_" .. data.currentCard])
    else
        abilityImage:setImage("http://cloud-3.steamusercontent.com/ugc/2036234357198483076/21FC5F0477C27012058B3AC2BFD381ED5C07C04C/")
    end

    local statsImage = Image.new(infoContainer)
    statsImage:setSize(250, 150)
    statsImage:setImage(MonsterStats[data.id .."_" .. data.level])
    
    

    if #data.monsterInstances > 0 then
        local monsterInstancesContainer = Container.new(container)
        monsterInstancesContainer:setSize(500, 40)
        local monsterInstancesLayout = LinearLayout.new(Orientations.horizontal)
        -- monsterInstancesLayout:setSpacing(5)
        monsterInstancesContainer:setLayout(monsterInstancesLayout)
        for i = 1, math.min(#data.monsterInstances, 5) do
            createInstance(monsterInstancesContainer, data.monsterInstances[i])
        end
        if #data.monsterInstances > 5 then
            monsterInstancesContainer = Container.new(container)
            monsterInstancesContainer:setSize(500, 40)
            monsterInstancesLayout = LinearLayout.new(Orientations.horizontal)
            monsterInstancesContainer:setLayout(monsterInstancesLayout)
            for j = 6, #data.monsterInstances do
                createInstance(monsterInstancesContainer, data.monsterInstances[j])
            end
        end
    end
end

print(JSON.encode(Global.UI.getCustomAssets()))

local UI = UI.new()

local mainPanel = Panel.new(UI, 'main')
mainPanel:setColor(Colors.DarkGrey)
mainPanel:setLayout(LinearLayout.new(Orientations.vertical):setSpacing(5):setAlongAxisAlignment(Alignment.center))

createMonster(mainPanel,
    { id = "Abael Herder", level=1,
        monsterInstances = { { conditions = { 1, 3 }, health = 1, maxHealth = 1, standeeNr = 3, type = 2 },
            { conditions = { 2 }, health = 1, maxHealth = 1, standeeNr = 7, type = 2 },
            { conditions = {  }, health = 1, maxHealth = 1, standeeNr = 1, type = 1 },
            { conditions = {  }, health = 1, maxHealth = 1, standeeNr = 2, type = 1 },
            { conditions = { 11,5,6 }, health = 1, maxHealth = 1, standeeNr = 5, type = 1 },
            { conditions = { 2}, health = 1, maxHealth = 1, standeeNr = 6, type = 1 },
            { conditions = { 3 }, health = 1, maxHealth = 1, standeeNr = 8, type = 1 },
            { conditions = { 10 }, health = 1, maxHealth = 1, standeeNr = 9, type = 1 } } })
createDivider(mainPanel)
createMonster(mainPanel,
    { id = "Algox Stormcaller", level=1,
        monsterInstances = { { conditions = { 1 }, health = 1, maxHealth = 1, standeeNr = 1, type = 1 } } })
createDivider(mainPanel)


-- local c1 = Container.new(mainPanel)
-- local layout = LinearLayout.new(Orientations.vertical)
-- layout:setAlongAxisAlignment(Alignment.center)
-- local layoutParams = LinearLayoutParams.new()
-- layoutParams:setCrossAxisAlignment(Alignment.left)

-- c1:setLayout(layout)
-- c1:setPosition(30, 30)
-- c1:setSize(300, 500)
-- local l1 = Label.new(c1)
-- l1:setFont(Pirata)
-- l1:setText("Hello World")
-- l1:setSize(100, 50)
-- l1:setLayoutParams(layoutParams)

-- local l2 = Label.new(c1)
-- l2:setFont(Pirata)
-- l2:setId("label2")
-- l2:setText("Hello World 2")
-- l2:setSize(120, 50)
-- l2:setLayoutParams(layoutParams)

-- local l3 = Label.new(c1)
-- l3:setFont(Pirata)
-- l3:setText("Hello World 3")
-- l3:setSize(150, 50)
-- l3:setLayoutParams(layoutParams)

-- local image1 = Image.new(c1)
-- image1:setImage("http://cloud-3.steamusercontent.com/ugc/2028354869650263195/F327B0CCBA108760456F132CDAE5EB987F34C7BB/")
-- image1:setSize(50,50)

-- layout:setSpacing(10)

UI:output()
