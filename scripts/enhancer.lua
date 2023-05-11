require('fhlog')
require('number_decals')
TAG = "Enhancer"

Y_DECAL = 0.364

TYPES = {
    s = {
        field = "type",
        off = "http://cloud-3.steamusercontent.com/ugc/2036234357174450762/81464C345F6B32BEA9CD5CE149417948883F0DED/",
        on = "http://cloud-3.steamusercontent.com/ugc/2036234357174450835/313816ED50612B81F5268D3E3EE74E122336949F/"
    },
    c = {
        field = "type",
        off = "http://cloud-3.steamusercontent.com/ugc/2036234357174449146/A9B21A354183BC39DA3E347B747EF0BDFB0FD8B2/",
        on = "http://cloud-3.steamusercontent.com/ugc/2036234357174449182/62B2508396C599C3BB503124C22D32EB45E3E06B/"
    },
    dm = {
        field = "type",
        off = "http://cloud-3.steamusercontent.com/ugc/2036234357174449277/2BD12B5202C2E75FB314BF68BDEE654C89D115CC/",
        on = "http://cloud-3.steamusercontent.com/ugc/2036234357174449334/76A6C88C62732800F07093CD5420C6265D793DFE/"
    },
    dp = {
        field = "type",
        off = "http://cloud-3.steamusercontent.com/ugc/2036234357174449376/0D31FD217C00ADBFA86320D68B2A114D85DEF101/",
        on = "http://cloud-3.steamusercontent.com/ugc/2036234357174449415/A9AD11B75FCA2921915638B77F3290B9923FFA56/"
    },
    h = {
        field = "type",
        off = "http://cloud-3.steamusercontent.com/ugc/2036234357174448786/05DD958F69E900E6E90F918120BF687E0DDE4769/",
        on = "http://cloud-3.steamusercontent.com/ugc/2036234357174448845/F32C1D1C0676430028072FFE0B3A91D1317FFCC1/"
    },
    multi = {
        field = "multi",
        off = "http://cloud-3.steamusercontent.com/ugc/2036234357174450031/07CEFFC5F84EA21EB2DE8D7B01CD7003751DC60D/",
        on = "http://cloud-3.steamusercontent.com/ugc/2036234357174450081/AF0E402EE4CBAE9D2CA1B64836E8CE6CA4E1D3FA/"
    },
    summon = {
        field = "summon",
        off = "http://cloud-3.steamusercontent.com/ugc/2036234357174450910/B15963637A6D9B88E807BE58A394FB7B076F1E77/",
        on = "http://cloud-3.steamusercontent.com/ugc/2036234357174450946/0535A5B2AF1AB838D68617F461F58CD0D0678AA6/"
    },
    persist = {
        field = "persist",
        off = "http://cloud-3.steamusercontent.com/ugc/2036234357174775644/6E67DBF3BA127067A1942F3D8D01F4B77A34B1C2/",
        on = "http://cloud-3.steamusercontent.com/ugc/2036234357174775691/880701661E25FCBF54200A56C1258CC771BF0052/"
    },
    lost = {
        field = "lost",
        off = "http://cloud-3.steamusercontent.com/ugc/2036234357174775536/8FB9AF8BAAC04295F45006F6C053AD34A49FDB2E/",
        on = "http://cloud-3.steamusercontent.com/ugc/2036234357174775594/DCCD4208493984751721AE52FEAAED44B3E8F685/"
    },
    target = {
        field = "ability",
        off = "http://cloud-3.steamusercontent.com/ugc/2036234357174450994/06434FDC924CAA56160B48CFDD1C22D51404365D/",
        on = "http://cloud-3.steamusercontent.com/ugc/2036234357174451033/4434B261AC3D9E00A596C7DEFD3D33A28AF93D90/"
    },
    pull = {
        field = "ability",
        off = "http://cloud-3.steamusercontent.com/ugc/2036234357174450294/981B60D893D947E85A31830E64DEE8D4499F1F01/",
        on = "http://cloud-3.steamusercontent.com/ugc/2036234357174450330/6BB49AA5311BFEFB702F2A3437C7AC6328CC5FE3/"
    },
    push = {
        field = "ability",
        off = "http://cloud-3.steamusercontent.com/ugc/2036234357174450372/DA8F49A7B4D0CE273BB7874481CBF31B9EC9CE61/",
        on = "http://cloud-3.steamusercontent.com/ugc/2036234357174450416/333EBE6FB0333005F46008BD27CEC1BACF699588/"
    },
    range = {
        field = "ability",
        off = "http://cloud-3.steamusercontent.com/ugc/2036234357174450464/611A5C7ED19F9C9C1FF09C60DF770D870FAA94BE/",
        on = "http://cloud-3.steamusercontent.com/ugc/2036234357174450509/88F1A37F5371E599CD2E56A630D0F0E7E55635E5/"
    },
    pierce = {
        field = "ability",
        off = "http://cloud-3.steamusercontent.com/ugc/2036234357174450141/BB4B28EC13B85C211910A02E62FFEAC3EA9FF98A/",
        on = "http://cloud-3.steamusercontent.com/ugc/2036234357174450194/9C72F6E0232DBD05ECC629BCE7FE1105A7C03AAA/",
    },
    attack = {
        field = "ability",
        off = "http://cloud-3.steamusercontent.com/ugc/2036234357174448939/8F1948E8D216A0F31C722C0FC460E4D14563C043/",
        on = "http://cloud-3.steamusercontent.com/ugc/2036234357174448984/E4C1F8C02F6B97A158DD980E3C9799560DA34779/"
    },
    move = {
        field = "ability",
        off = "http://cloud-3.steamusercontent.com/ugc/2036234357174449922/8B6F857164729F98E1DA0BA9456701BA34CE7F09/",
        on = "http://cloud-3.steamusercontent.com/ugc/2036234357174449966/D90F6A4235BB2B398EA726A4092F1C56E60804AC/"
    },
    teleport = {
        field = "ability",
        off = "http://cloud-3.steamusercontent.com/ugc/2036234357174451068/A5F6B3FBBDCD698C72C3B592C06933C25B88CF10/",
        on = "http://cloud-3.steamusercontent.com/ugc/2036234357174451105/4E7B7BB9C670748FDB48B5C3019AC5967D59C7C9/"
    },
    shield = {
        field = "ability",
        off = "http://cloud-3.steamusercontent.com/ugc/2036234357174450675/E2C07E451BD8E0C99834F5FBEB92D558C833EC47/",
        on = "http://cloud-3.steamusercontent.com/ugc/2036234357174450716/F4285BF030E1A50CCC19A9FB09FA3F124E26228D/"
    },
    retaliate = {
        field = "ability",
        off = "http://cloud-3.steamusercontent.com/ugc/2036234357174450587/26EC03F694530ABA53248F7BDCD2C382C2074790/",
        on = "http://cloud-3.steamusercontent.com/ugc/2036234357174450632/5E006CB5BE4502443DD7ADC3AC6CCC91C6D08772/"
    },
    heal = {
        field = "ability",
        off = "http://cloud-3.steamusercontent.com/ugc/2036234357174449572/AA74E92DB2BC87AB5EAD6C86D49C625D8FE57F4F/",
        on = "http://cloud-3.steamusercontent.com/ugc/2036234357174449614/D5FEF2FAE64E1D295BBCD9276507067D2284B45E/"
    }
}

Enhancements = {
    s = {
        p1 = {
            url = "http://cloud-3.steamusercontent.com/ugc/2036234357173349226/13443CCFE7AAC91B5A878D3ECA8AA2E315F0A917/",
            costByAbility = {
                move = 30,
                attack = 50,
                range = 50,
                target = 75,
                shield = 80,
                retaliate = 60,
                pierce = 30,
                heal = 30,
                push = 30,
                pull = 20,
                teleport = 50,
                summonheal = 40,
                summonmove = 60,
                summonattack = 100,
                summonrange = 50,
            }
        },
        jump = {
            url = "http://cloud-3.steamusercontent.com/ugc/2036234357173350365/2BAF501676982C2A37505F840C874A40FF4F2ECE/",
            cost = 60,
            action = "move",
            summon = "",
        }
    },
    c = {
        fire = {
            url = "http://cloud-3.steamusercontent.com/ugc/2036234357173350086/E347FE3FD0BBF7FC01D253A501CD18CE69A7B50B/",
            cost = 100
        },
        ice = {
            url = "http://cloud-3.steamusercontent.com/ugc/2036234357173350278/9126BCE0F71FF7BE872ACEA8A96C704F1CD3DF42/",
            cost = 100
        },
        wind = {
            url = "http://cloud-3.steamusercontent.com/ugc/2036234357173350912/82E761E40DAE3CFC61DFFD3B123B6A991E1CBDE5/",
            cost = 100
        },
        earth = {
            url = "http://cloud-3.steamusercontent.com/ugc/2036234357173350040/40005EB46E670E3CF8563D5264A1BEFDD535FDB5/",
            cost = 100
        },
        light = {
            url = "http://cloud-3.steamusercontent.com/ugc/2036234357173350410/387DEB66C88D81303291F8FBE56DADA91DD20B6C/",
            cost = 100
        },
        dark = {
            url = "http://cloud-3.steamusercontent.com/ugc/2036234357173349596/30907C3E62A3BF8A2BBA17C045BFD425B0810787/",
            cost = 100
        },
        wild = {
            url = "http://cloud-3.steamusercontent.com/ugc/2036234357173350878/1B99CD5666133F8742DAF14EDC6792D9C5EB9DD5/",
            cost = 150
        }
    },
    dm = {
        wound = {
            url = "http://cloud-3.steamusercontent.com/ugc/2036234357173350954/16EA9997952D8EDC857A13CDACBAFB243ECE808C/",
            cost = 75
        },
        poison = {
            url = "http://cloud-3.steamusercontent.com/ugc/2036234357173350580/12C65315B2AFCFF6A4D37240CDBD4DD38F1CA4BA/",
            cost = 50
        },
        immobilize = {
            url = "http://cloud-3.steamusercontent.com/ugc/2036234357173350319/2F92B6C425D07918CF5A71902BBCD13BF2E12FDE/",
            cost = 150
        },
        curse = {
            url = "http://cloud-3.steamusercontent.com/ugc/2036234357173349518/CA97B483607681EFB621BAE2908DB5A4F44F75AB/",
            cost = 150
        },
    },
    dp = {
        bless = {
            url = "http://cloud-3.steamusercontent.com/ugc/2036234357173349310/A50C9B14891B8041A3BCB27E6C937E4F697BE72B/",
            cost = 75
        },
        regenerate = {
            url = "http://cloud-3.steamusercontent.com/ugc/2036234357173350630/1EF9805B977DBF42FCB8CE6F590F1CEF2B34026F/",
            cost = 40
        },
        strenghten = {
            url = "http://cloud-3.steamusercontent.com/ugc/2036234357173350795/B8DF48B76C333565E5676FECDE792B9874B8B946/",
            cost = 100
        },
        ward = {
            url = "http://cloud-3.steamusercontent.com/ugc/2036234357173350835/3BDB3F290D0A70F2680DDAD6B4BE86FCAB4B32C5/",
            cost = 75
        }
    },
    hex = {
        hex = {
            url = "http://cloud-3.steamusercontent.com/ugc/2036234357173350130/F1F822497F171BF0FE822B9F08470AB8B7CCB946/",
            cost = 200
        }
    },
}

local TypesPerType = {
    s = { 's' },
    c = { 's', 'c' },
    dm = { 's', 'c', 'dm' },
    dp = { 's', 'c', 'dp' },
    h = { 'hex' }
}

function onLoad(save)
    fhLogInit()
    DevMode = true
    Global.call('registerForCollision', self)
    Global.call('registerForPing', self)
    if save ~= nil then
        State = JSON.decode(save)
    end

    if State == nil then
        State = {}
    end
end

CurrentCard = nil
CurrentSpot = nil
function onObjectCollisionEnter(payload)
    local _, collision_info = table.unpack(payload)
    CurrentCard = collision_info.collision_object
    local name = CurrentCard.getName()
    if State[name] == nil then
        State[name] = { level = 1, spots = {} }
    end
    fhlog(DEBUG, TAG, "Current card : %s, state : %s", name, State[name])
    -- fhlog(DEBUG, TAG, "Current decals : %s", CurrentCard.getDecals() or {})
    refreshDecals()
end

function onSave()
    return JSON.encode(State)
end

function isDevMode()
    return self.getDescription() == "dev"
end

function onObjectCollisionExit()
    if CurrentCard ~= nil then
        CurrentCard.setDecals({})
        CurrentCard.clearButtons()
        CurrentCard = nil
    end
    CurrentSpot = nil
    refreshDecals()
end

function round(number)
    return tonumber(string.format("%.3f", number))
end

function onPing(payload)
    if not isDevMode() then
        return
    end
    local position = JSON.decode(payload)
    if CurrentCard ~= nil then
        local name = CurrentCard.getName()
        local cardPosition = CurrentCard.positionToLocal(position)
        fhlog(DEBUG, TAG, "Pinged position %s", cardPosition)
        local spots = State[name].spots
        local removed = false
        for i = #spots, 1, -1 do
            if distance(spots[i].position, cardPosition) < 0.1 then
                fhlog(DEBUG, TAG, "Removing position")
                table.remove(spots, i)
                removed = true
            end
        end
        if not removed then
            fhlog(DEBUG, TAG, "Adding position")
            table.insert(spots,
                {type = "", position = { x = round(cardPosition.x), z = round(cardPosition.z) } })
        end
        fhlog(DEBUG, TAG, "Current card : %s, state : %s", name, State[name])
        refreshDecals()
    end
end

function distance(pos1, pos2)
    local dx = pos1.x - pos2.x
    local dz = pos1.z - pos2.z
    return math.sqrt(dx * dx + dz * dz)
end

function refreshDecals()
    self.clearButtons()
    local boardDecals = {}
    if CurrentCard ~= nil then
        -- Buttons
        CurrentCard.clearButtons()

        -- Show highlights on the various spots
        local cardDecals = {}
        local spots = State[CurrentCard.getName()].spots or {}
        for i, spot in ipairs(spots) do
            local highlight = {
                rotation = { 90, 0, 0 },
                scale = { 0.2, 0.2, 0.2 },
                position = { spot.position.x, Y_DECAL, spot.position.z },
                name = "highlight " .. i,
                url =
                "http://cloud-3.steamusercontent.com/ugc/2036234357173350181/63029F7ADA4B615AD8B7462ACFBE5692CEFB3229/"
            }
            if spot.type == '' then
                -- Error, type is not set
                highlight.url =
                "http://cloud-3.steamusercontent.com/ugc/2036234357173472307/796C4B05A774DF34D17AB4DA6D2F58E9B4D6728C/"
            end
            if spot == CurrentSpot then
                highlight.url =
                "http://cloud-3.steamusercontent.com/ugc/2036234357173350229/1DCD8E19A4D68F2CA5586EB61D2044A0A1A2889C/"
            end
            table.insert(cardDecals, highlight)

            local fName = "selectSpot_" .. i
            self.setVar(fName, function(p, c, alt) onSpotClicked(i, alt) end)
            local params = {
                function_owner = self,
                click_function = fName,
                position       = { -spot.position.x, 0.05, spot.position.z },
                width          = 100,
                height         = 100,
                font_size      = 50,
                color          = { 1, 1, 1, 0 },
                scale          = { 1, 1, 1 },
                font_color     = { 1, 1, 1, 0 },
            }
            CurrentCard.createButton(params)
        end
        CurrentCard.setDecals(cardDecals)

        if isDevMode() then
            -- Add controls for the card level
            addLevelDecals(boardDecals)
        end

        if CurrentSpot ~= nil then
            if isDevMode() then
                -- Show all the type stickers
                local currentZ = -0.8
                local currentX = -0.3
                for name, value in pairs(TYPES) do
                    local onOff = "off"
                    if CurrentSpot[value['field']] == name then
                        onOff = "on"
                    end
                    local position = { x = currentX, y = Y_DECAL, z = currentZ }
                    local params = {
                        rotation = { 90, 180, 0 },
                        scale = { .22, 0.2, 0.2 },
                        position = position,
                        name = "type " .. name .. onOff,
                        url = value[onOff]
                    }
                    table.insert(boardDecals, params)
                    currentZ = currentZ + 0.3
                    if currentZ >= 1.6 then
                        currentZ = -0.8
                        currentX = currentX - 0.5
                    end

                    local fName = "toggleType_" .. name
                    self.setVar(fName, function() onTypeClicked(name) end)
                    local params = {
                        function_owner = self,
                        click_function = fName,
                        position       = { -position.x, position.y, position.z },
                        width          = 150,
                        height         = 150,
                        font_size      = 50,
                        color          = { 1, 1, 1, 0 },
                        scale          = { 1, 1, 1 },
                        font_color     = { 1, 1, 1, 0 },
                    }
                    self.createButton(params)
                    if name == "h" and onOff == "on" then
                        -- Create arrows to change the base number of hexes
                        createHexControls(boardDecals, position)
                    end
                end                
            else
                -- Determine which enhancements to show
                local enhancements = {}
                local type = CurrentSpot.type
                local action = CurrentSpot.ability or ""
                local summon = CurrentSpot.summon or ""
                local multi = CurrentSpot.multi or ""
                local lost = CurrentSpot.lost or ""
                local persist = CurrentSpot.persist or ""
                local level = State[CurrentCard.getName()].level or 1
                local currentZ = -0.7
                local currentX = -0.3
                for _, t in ipairs(TypesPerType[type]) do
                    for name, info in pairs(Enhancements[t]) do
                        if (info.action == nil or info.action == action) and (info.summon == nil or info.summon == summon) then
                            local position = { x = currentX, y = 0.06, z = currentZ }
                            local params = {
                                rotation = { 90, 180, 0 },
                                scale = { .7, 0.2, 0.2 },
                                position = position,
                                name = "enhancement " .. name,
                                url = info.url
                            }
                            table.insert(boardDecals, params)
                            currentZ = currentZ + 0.3
                            if currentZ >= 1.6 then
                                currentZ = -0.7
                                currentX = currentX - 0.8
                            end
                            local ability = summon .. action
                            local cost = info.cost or info.costByAbility[ability] or 0
                            if type == 'h' then
                                cost = math.ceil(cost/(CurrentSpot.baseHexes or 1))
                            end
                            if multi == "multi" then
                                cost = cost * 2
                            end
                            if lost == "lost" then
                                cost = cost / 2
                            end
                            if persist == "persist" then
                                cost = cost * 3
                            end
                            
                            -- the 25 cost changes based on enhancer level ...
                            cost = cost + (level - 1) * 25

                            -- Purchase button with cost shown
                            local fName = "buy_" .. name
                            self.setVar(fName, function(player) onEnhancementBuy(player, name, cost) end)
                            local params = {
                                label          = cost .. " gold",
                                function_owner = self,
                                click_function = fName,
                                position       = { -position.x + 0.07, position.y, position.z },
                                width          = 600,
                                height         = 220,
                                font_size      = 100,
                                color          = { 1, 1, 1, 0 },
                                scale          = { .5, .5, .5 },
                                font_color     = { 0, 0, 0, 100 },
                                tooltip        = "Purchase enhancement"
                            }
                            self.createButton(params)
                        end
                    end
                end
            end
        else
            if #spots > 0 then
                -- Select a spot
                local params = {
                    rotation = { 90, 180, 0 },
                    scale = { 1.3, 0.3, 0.3 },
                    position = { -0.9, 0.06, 0.2 },
                    name = "info_spot",
                    url =
                    "http://cloud-3.steamusercontent.com/ugc/2036234357174649715/E7A88FDFD332CDB6384731E951F42F6A5C25FA52/"
                }
                table.insert(boardDecals, params)
            else
                --No available spot
                local params = {
                    rotation = { 90, 180, 0 },
                    scale = { 1.3, 0.6, 0.6 },
                    position = { -0.9, 0.06, 0.2 },
                    name = "info_no-enhacement",
                    url =
                    "http://cloud-3.steamusercontent.com/ugc/2036234357174649817/933FB3B2FF41AD944B6394F4550745164D85D6D4/"
                }
                table.insert(boardDecals, params)
            end
        end
    else
        -- Drop a card
        local params = {
            rotation = { 90, 180, 0 },
            scale = { 1.3, 0.3, 0.3 },
            position = { -0.9, 0.06, 0.2 },
            name = "info_card",
            url = "http://cloud-3.steamusercontent.com/ugc/2036234357174649771/D8410C048AA7A7ABE9F6A85BD6A4C9AB6E6A442E/"
        }
        table.insert(boardDecals, params)
    end
    self.setDecals(boardDecals)
end

function createHexControls(stickers, position)
    local baseHexes = CurrentSpot.baseHexes or 1
    if baseHexes > 1 then
        -- left arrow sticker and button
        local sticker = {
            position = {   position.x + 0.2, position.y, position.z },
            scale = { .07, .05, .05 },
            rotation = { 90, 180, 0 },
            url = "http://cloud-3.steamusercontent.com/ugc/2035105157823185573/8BABEE86FE1085D5C001E6DD4EE1F1E040BF6D1D/",
            name = "hexes down",
        }
        table.insert(stickers, sticker)
        local params = {
            function_owner = self,
            click_function = "hexesDown",
            label          = "",
            position       = {   -position.x - 0.2, position.y, position.z },
            width          = 200,
            height         = 220,
            font_size      = 100,
            color          = { 1, 1, 1, 0 },
            scale          = { 0.5, 1, .25 },
            font_color     = { 0, 0, 0, 100 },
        }
        self.createButton(params)
    end

    -- A button with no size to show the info
    local params = {
        label = tostring(baseHexes),
        function_owner = self,
        click_function = "hexesUp",
        position       = {   -position.x , position.y+0.01, position.z },
        width          = 0,
        height         = 0,
        font_size      = 100,
        color          = { 1, 1, 1, 1 },
        scale          = { 0.5, 0.5, 0.5 },
        font_color     = { 0, 0, 0, 1 },
    }
    self.createButton(params)

    if baseHexes < 20 then
        -- right arrow sticker and button
        local sticker = {
            position = {   position.x - 0.2, position.y, position.z },
            scale = { .07, .05, .05 },
            rotation = { 90, 180, 0 },
            url = "http://cloud-3.steamusercontent.com/ugc/2035105157823185619/529E35C0294D03A666C9EA9C924105F40F07697F/",
            name = "hexes up",
        }
        table.insert(stickers, sticker)
        local params = {
            function_owner = self,
            click_function = "hexesUp",
            label          = "",
            position       = {   -position.x + 0.2, position.y, position.z },
            width          = 200,
            height         = 220,
            font_size      = 100,
            color          = { 1, 1, 1, 0 },
            scale          = { 0.5, 1, .25 },
            font_color     = { 0, 0, 0, 100 },
        }
        self.createButton(params)
    end
end

function addLevelDecals(stickers)
    -- stickers
    local yPosition = 1.685
    local name = CurrentCard.getName()
    local level = State[name].level or 1
    local sticker = {
        position = { 0.95, 0.06, yPosition },
        scale = { .5, .5, .25 },
        rotation = { 90, 180, 0 },
        url = NumberDecals[level + 1],
        name = "level_" .. level,
    }
    table.insert(stickers, sticker)

    if level > 1 then
        -- left arrow sticker and button
        sticker = {
            position = {   1.25, 0.06, yPosition },
            scale = { .15, .05, .05 },
            rotation = { 90, 180, 0 },
            url = "http://cloud-3.steamusercontent.com/ugc/2035105157823185573/8BABEE86FE1085D5C001E6DD4EE1F1E040BF6D1D/",
            name = "level down",
        }
        table.insert(stickers, sticker)
        local params = {
            function_owner = self,
            click_function = "levelDown",
            label          = "",
            position       = {-1.25, 0.06, yPosition },
            width          = 200,
            height         = 220,
            font_size      = 100,
            color          = { 1, 1, 1, 0 },
            scale          = { 0.5, 1, .25 },
            font_color     = { 0, 0, 0, 100 },
        }
        self.createButton(params)
    end

    if level < 9 then
        -- right arrow sticker and button
        sticker = {
            position = { .65, 0.06, yPosition },
            scale = { .15, .05, .05 },
            rotation = { 90, 180, 0 },
            url = "http://cloud-3.steamusercontent.com/ugc/2035105157823185619/529E35C0294D03A666C9EA9C924105F40F07697F/",
            name = "level up",
        }
        table.insert(stickers, sticker)
        local params = {
            function_owner = self,
            click_function = "levelUp",
            label          = "",
            position       = { -0.65, 0.06, yPosition },
            width          = 200,
            height         = 220,
            font_size      = 100,
            color          = { 1, 1, 1, 0 },
            scale          = { 0.5, 1, .25 },
            font_color     = { 0, 0, 0, 100 },
        }
        self.createButton(params)
    end
end

function levelDown()
    if CurrentCard ~= nil then
        local name = CurrentCard.getName()
        State[name].level = State[name].level - 1
        refreshDecals()
    end
end

function levelUp()
    if CurrentCard ~= nil then
        local name = CurrentCard.getName()
        State[name].level = State[name].level + 1
        refreshDecals()
    end
end

function hexesDown()
    if CurrentSpot ~= nil then
        local baseHexes = CurrentSpot.baseHexes or 1
        CurrentSpot.baseHexes = baseHexes - 1
        refreshDecals()
    end
end

function hexesUp()
    if CurrentSpot ~= nil then
        local baseHexes = CurrentSpot.baseHexes or 1
        CurrentSpot.baseHexes = baseHexes + 1
        refreshDecals()
    end
end

function onSpotClicked(n, alt)
    if alt then
        table.remove(State[CurrentCard.getName()].spots, n)
    end
    if CurrentCard ~= nil then
        local newSpot = State[CurrentCard.getName()].spots[n]
        if CurrentSpot == newSpot then
            CurrentSpot = nil
        else
            CurrentSpot = newSpot
        end
    end
    refreshDecals()
end

function onTypeClicked(name)
    if CurrentCard ~= nil then
        local type = TYPES[name]
        local field = type['field']
        local currentValue = CurrentSpot[field]
        if currentValue == name then
            CurrentSpot[field] = ''
        else
            CurrentSpot[field] = name
        end
        refreshDecals()
    end
end

function onEnhancementBuy(player, name, price)

end
