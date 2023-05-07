-- Box assets
BoxMesh = "http://cloud-3.steamusercontent.com/ugc/2036232998933400478/2973421F4D8FCE14B6B71BD76EA81AB8C32BB94E/"
BoxImage = "http://cloud-3.steamusercontent.com/ugc/2036232998933389672/06BD5782ABE774C7FBDD726D68B79895E5258E32/"


function onLoad()
    local snapPoints = {}
    for _, snapPoint in ipairs(self.getSnapPoints()) do
        table.insert(snapPoints, snapPoint.position)
    end

    table.sort(snapPoints, function(a, b) return a.z < b.z end)

    SavePosition = snapPoints[1]
    addButton("save", SavePosition)
    LoadPosition = snapPoints[2]
    Global.call("registerForCollision", self)
end

function addButton(name, position)
    local params = {
        function_owner = self,
        click_function = "on_" .. name,
        height = 100,
        width = 600,
        font_size = 90,
        alignment = 3,
        scale = { 1, 1, 1 },
        position = { -position.x, position.y, position.z },
        color = { 1, 1, 1, 0 },
        font_color = { 0, 0, 0, 100 },
        tooltip = name
    }
    self.createButton(params)
end

function on_save()
    createSaveBundle()
end

function onObjectCollisionEnter(obj)
    -- print("onObjectCollisionEnter")
    local hitlist = Physics.cast({
        origin       = self.positionToWorld(LoadPosition),
        direction    = { 0, 1, 0 },
        type         = 2,
        size         = { 1, 1, 1 },
        max_distance = 0,
        debug        = true
    })

    for _, hit in ipairs(hitlist) do
        if hit.hit_object.hasTag("Save Bundle") then
            loadSaveFromBundle(hit.hit_object)
        end
    end
end

function loadSaveFromBundle(saveBundle)
    local save = saveBundle.getGMNotes()
    Global.call("loadSave", save)
    broadcastToAll("Game Loaded")
end

function shiftUp(position)
    return { x = position.x, y = position.y + 0.1, z = position.z }
end

function createSaveBundle()
    -- Gather the data
    local save = Global.call("getSave")

    -- create the save box
    local obj = spawnObject({
        type = "Custom_Model",
        position = self.positionToWorld(shiftUp(SavePosition)),
        scale = { 1, 1, 1 },
        sound = false
    })
    obj.setCustomObject({
        mesh = BoxMesh,
        type = 6,
        material = 3,
        diffuse = BoxImage,
    })
    obj.addTag("Save Bundle")
    obj.setName("Frosthaven Save")
    obj.setGMNotes(save)
    broadcastToAll("Game Saved")
end
