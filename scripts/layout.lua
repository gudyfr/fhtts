Widget = {}
Widget.__index = Widget
function Widget.new(container)
    local self = setmetatable({}, Widget)
    self.id = nil
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    self.visible = true
    if container ~= nil then
        container:add(self)
    end
    return self
end

function Widget:setPosition(x, y)
    self.x = x
    self.y = y
end

function Widget:setSize(width, height)
    self.width = width
    self.height = height
end

function Widget:setVisible(visible)
    self.visible = visible
end

function Widget:isVisible()
    return self.visible
end

function Widget:setId(id)
    self.id = id
end

function Widget:getId()
    return self.id
end

Container = {}
Container.__index = Container
setmetatable(Container, { __index = Widget })

function Container.new(container)
    local self = setmetatable(Widget.new(container), Container)
    self.children = {}
    return self
end

function Container:add(child)
    table.insert(self.children, child)
end

Label = {}
Label.__index = Label
setmetatable(Label, { __index = Widget })

function Label.new(container)
    local self = setmetatable(Widget.new(container), Label)
    self.text = ""
    self.font_size = 0
    self.font_color = { 1, 1, 1, 1 }
    return self
end

function Label:setText(text)
    self.text = text
end

function Label:setFontSize(font_size)
    self.font_size = font_size
end

function Label:setFontColor(font_color)
    self.font_color = font_color
end

Image = {}
Image.__index = Image
setmetatable(Image, { __index = Widget })

function Image.new(container)
    local self = setmetatable(Widget.new(container), Image)
    self.image = ""
    return self
end

function Image:setImage(image)
    self.image = image
end

Panel = {}
Panel.__index = Panel
setmetatable(Panel, { __index = Container })

function Panel.new(container, id)
    local self = setmetatable(Container.new(container), Panel)
    self:setId(id)
    return self
end

UI = {}
UI.__index = UI
setmetatable(UI, { __index = Container })

function UI.new()
    local self = setmetatable(Container.new(), UI)
    return self
end

function UI:output()
    local renderContext = RenderContext.new()
    local result = {}
    Container.output(self, renderContext, result)
    return result
end

RenderContext = {}
RenderContext.__index = RenderContext
function RenderContext.new()
    local self = setmetatable({}, RenderContext)
    self.x = 0
    self.y = 0
    self.ids = {}
    return self
end

function RenderContext:copy()
    local result = RenderContext.new()
    result.x = self.x
    result.y = self.y
    result.ids = {}
    for _, id in ipairs(self.ids) do
        table.insert(result.ids, id)
    end
    return result
end

function RenderContext:translate(x, y)
    self.x = self.x + x
    self.y = self.y + y
end

function RenderContext:pushId(id)
    table.insert(self.ids, id)
end

function RenderContext:generateId(id)
    local result = ""
    for _, part in ipairs(self.ids) do
        result = result .. part .. "_"
    end
    return result .. id
end

function Container:output(renderContext, widgets)
    if self:isVisible() then
        local subContext = renderContext:copy()
        subContext:translate(self.x, self.y)
        if self:getId() ~= nil then
            subContext:pushId(self:getId())
        end
        for _, child in ipairs(self.children) do
            child:output(subContext, widgets)
        end
    end
end

function Widget:output(renderContext, widgets)
    local result = {
        x = renderContext.x + self.x,
        y = renderContext.y + self.y,
        width = self.width,
        height = self.height,
    }
    if self:getId() ~= nil then
        result.id = renderContext:generateId(self:getId())
    end
    return result
end

function Image:output(renderContext, widgets)
    local result = Widget.output(self, renderContext)
    result.type = "image"
    result.image = self.image
    table.insert(widgets, result)
end

function Label:output(renderContext, widgets)
    local result = Widget.output(self, renderContext)
    result.type = "text"
    result.text = self.text
    result.font_size = self.font_size
    result.font_color = self.font_color
    table.insert(widgets, result)
end

local UI = UI.new()

local mainPanel = Panel.new(UI, 'main')
local c1 = Container.new(mainPanel)
c1:setPosition(30, 30)
local l1 = Label.new(c1)
l1:setText("Hello World")
l1:setPosition(0, 0)
local l2 = Label.new(c1)
l2:setId("label2")
l2:setText("Hello World 2")
l2:setPosition(0, 50)
local l3 = Label.new(c1)
l3:setText("Hello World 3")
l3:setPosition(100, 0)

local output = UI:output()
print(JSON.encode(output))