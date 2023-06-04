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
    self.layoutParams = nil
    self.color = nil
    if container ~= nil then
        container:add(self)
    end
    return self
end

function Widget:getClassName()
    return "Widget"
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

function Widget:setColor(color)
    self.color = color
end

function Widget:getColor()
    return self.color
end

function Widget:setLayoutParams(layoutParams)
    self.layoutParams = layoutParams
end

function Widget:getLayoutParams()
    return self.layoutParams or {}
end

function Widget:measure()
    self.measuredWidth = self.width
    self.measuredHeight = self.height
    return self.measuredWidth, self.measuredHeight
end

function Widget:layout()
end

function Widget:getOutputAttributes(renderContext)
    local result = {
        offsetXY = (renderContext.x + self.measuredX) .. " " .. -(renderContext.y + self.measuredY),
        width = tostring(self.measuredWidth),
        height = tostring(self.measuredHeight),
    }
    if self:getId() ~= nil then
        result.id = renderContext:generateId(self:getId())
    end
    if self:getColor() ~= nil then
        result.color = self:getColor():output()
    end
    return result
end

function Widget:output(renderContext, widgets)
    local tag = self:getOutputTag()
    if tag ~= nil then
        local attributes = self:getOutputAttributes(renderContext)
        table.insert(widgets, { tag = tag, attributes = attributes })
    end
end

Container = {}
Container.__index = Container
setmetatable(Container, { __index = Widget })

function Container.new(container)
    local self = setmetatable(Widget.new(container), Container)
    self._children = {}
    self._layout = AbsoluteLayout.new()
    self.forceOutput = false
    return self
end

function Container:getClassName()
    return "Container"
end

function Container:setForceOutput(forceOutput)
    self.forceOutput = forceOutput
end

function Container:add(child)
    table.insert(self._children, child)
end

function Container:getChildren()
    return self._children
end

function Container:setLayout(layout)
    self._layout = layout
end

function Container:getLayout()
    return self._layout
end

function Container:measure()
    print("measure() : " .. self:getClassName())
    self.childrenWidth, self.childrenHeight = self:getLayout():measure(self:getChildren())
    self.measuredWidth = math.max(self.childrenWidth, self.width or 0)
    self.measuredHeight = math.max(self.childrenHeight, self.height or 0)
    return self.measuredWidth, self.measuredHeight
end

function Container:layout()
    print("layout() : " .. self:getClassName())
    local children = self:getChildren()
    for _, child in ipairs(children) do
        child:layout()
    end
    self:getLayout():layout(children, self)
end

function serializeAttributes(attributes)
    local output = ""
    for name, value in pairs(attributes) do
        output = output .. ' ' .. name .. '="' .. value .. '"'
    end
    return output
end

function Container:output(renderContext, children)
    if self:isVisible() then
        renderContext:push()

        if self:getId() ~= nil then
            renderContext:pushId(self:getId())
        end

        if self.forceOutput then
            local attributes = Widget.getOutputAttributes(self, renderContext)
            renderContext:reset()
            local childrenOutput = {}
            for _, child in ipairs(self:getChildren()) do
                child:output(renderContext, childrenOutput)
            end
            table.insert(children, { tag = "Panel", attributes = attributes, children = childrenOutput })
        else
            renderContext:translate(self.measuredX, self.measuredY)
            for _, child in ipairs(self:getChildren()) do
                child:output(renderContext, children)
            end
        end
        renderContext:pop()
    end
end

Font = {}
Font.__index = Font
function Font.new(url)
    local self = setmetatable({}, Font)
    self.url = url
    return self
end

Color = {}
Color.__index = Color
function Color.new(r, g, b, a)
    local self = setmetatable({}, Color)
    self.r = r
    self.g = g
    self.b = b
    self.a = a or 1
    return self
end

function Color:output()
    if self.outputCache == nil then
        local components = { 'r', 'g', 'b', 'a' }
        local output = "#"
        for _, component in ipairs(components) do
            local value = self[component]
            if value < 0 then
                value = 0
            elseif value > 1 then
                value = 1
            end
            output = output .. string.format("%02x", math.floor(value * 255))
        end
        self.outputCache = output
    end
    return self.outputCache
end

Colors = {
    White = Color.new(1, 1, 1),
    Black = Color.new(0, 0, 0),
    Grey = Color.new(0.5, 0.5, 0.5),
    LightGrey = Color.new(0.75, 0.75, 0.75),
    DarkGrey = Color.new(0.25, 0.25, 0.25),
}

Label = {}
Label.__index = Label
setmetatable(Label, { __index = Widget })

function Label.new(container)
    local self = setmetatable(Widget.new(container), Label)
    self.text = ""
    self.font = nil
    self.font_size = 20
    self.font_color = Colors.White
    self.text_align = nil
    return self
end

function Label:getClassName()
    return "Label"
end

function Label:setText(text)
    self.text = text
end

function Label:setFont(font)
    self.font = font
end

function Label:setFontSize(font_size)
    self.font_size = font_size
end

function Label:setFontColor(font_color)
    self.font_color = font_color
end

function Label:setTextAlign(textAlign)
    self.text_align = textAlign
end

function Label:getOutputAttributes(renderContext)
    local attributes = Widget.getOutputAttributes(self, renderContext)
    if self.font ~= nil then
        attributes.font = renderContext:getFontResource(self.font.url)
    end
    attributes.text = self.text
    attributes.fontSize = self.font_size
    if self.font_color ~= nil then
        attributes.color = self.font_color:output()
    end
    if self.text_align ~= nil then
        attributes.alignment = self.text_align
    end
    return attributes
end

function Label:getOutputTag()
    return "Text"
end

Image = {}
Image.__index = Image
setmetatable(Image, { __index = Widget })

function Image.new(container)
    local self = setmetatable(Widget.new(container), Image)
    self.image = ""
    return self
end

function Image:getClassName()
    return "Image"
end

function Image:setImage(image)
    self.image = image
end

function Image:getOutputAttributes(renderContext)
    local attributes = Widget.getOutputAttributes(self, renderContext)
    if self.image ~= nil then
        attributes.image = renderContext:getImageResource(self.image)
    end
    return attributes
end

function Image:getOutputTag()
    return "Image"
end

Panel = {}
Panel.__index = Panel
setmetatable(Panel, { __index = Container })

function Panel.new(container, id)
    local self = setmetatable(Container.new(container), Panel)
    self:setId(id)
    self:setForceOutput(true)
    return self
end

function Panel:getClassName()
    return "Panel"
end

UI = {}
UI.__index = UI
setmetatable(UI, { __index = Container })

function UI.new()
    local self = setmetatable(Container.new(), UI)
    self.measuredX = 0
    self.measuredY = 0
    return self
end

function UI:getClassName()
    return "UI"
end

function UI:output()
    self:measure()
    self:layout()
    local renderContext = RenderContext.new()
    local result = {
        {
            tag = "Defaults",
            children = {
                { tag = "Image", attributes = { preserveAspect = true, rectAlignment = "UpperLeft" } },
                { tag = "Text",  attributes = { rectAlignment = "UpperLeft", alignment = "UpperLeft" } },
                { tag = "Panel", attributes = { allowDragging = true, returnToOriginalPositionWhenReleased = false } },
            }
        } }
    Container.output(self, renderContext, result)
    local assets = renderContext:outputCustomAssets()
    Global.UI.setCustomAssets(assets)
    Global.UI.setXmlTable(result, assets)
end

RenderContext = {}
RenderContext.__index = RenderContext
function RenderContext.new()
    local self = setmetatable({}, RenderContext)
    self.x = 0
    self.y = 0
    self.ids = {}
    self.resources = {}
    self.nextResource = 1
    self.stack = {}
    return self
end

function RenderContext:getClassName()
    return "RenderContext"
end

function RenderContext:push()
    local idsCopy = {}
    for _, id in ipairs(self.ids) do
        table.insert(idsCopy, id)
    end
    table.insert(self.stack, { x = self.x, y = self.y, ids = idsCopy })
    return self
end

function RenderContext:pop()
    local save = table.remove(self.stack)
    self.x = save.x
    self.y = save.y
    self.ids = save.ids
    return self
end

function RenderContext:translate(x, y)
    self.x = self.x + x
    self.y = self.y + y
    return self
end

function RenderContext:reset()
    self.x = 0
    self.y = 0
end

function RenderContext:pushId(id)
    table.insert(self.ids, id)
    return self
end

function RenderContext:generateId(id)
    local result = ""
    for _, part in ipairs(self.ids) do
        result = result .. part .. "_"
    end
    return result .. id
end

function RenderContext:getResource(url, type)
    if self.resources[url] == nil then
        self.resources[url] = { type = type, id = tostring(self.nextResource) }
        self.nextResource = self.nextResource + 1
    end
    return self.resources[url].id
end

function RenderContext:outputCustomAssets()
    local result = {}
    for url, resource in pairs(self.resources) do
        -- if resource.type > 0 then
        table.insert(result, { name = resource.id, url = url, type = resource.type })
        -- else
        --     table.insert(result, { name = resource.id, url = url })
        -- end
    end
    return result
end

function RenderContext:getImageResource(url)
    return self:getResource(url, 0)
end

function RenderContext:getFontResource(url)
    return self:getResource(url, 1)
end

Layout = {}
Layout.__index = Layout
function Layout.new()
    local self = setmetatable({}, Layout)
    return self
end

function Layout:getClassName()
    return "Layout"
end

Orientations = {
    horizontal = 1,
    vertical = 2,
}

function Layout:measure(children)
    return 0, 0
end

function Layout:layout(children, container)
    for _, child in ipairs(children) do
        child.measuredX = child.x
        child.measuredY = child.y
    end
end

AbsoluteLayout = {}
AbsoluteLayout.__index = AbsoluteLayout
setmetatable(AbsoluteLayout, { __index = Layout })
function AbsoluteLayout.new()
    local self = setmetatable(Layout.new(), AbsoluteLayout)
    return self
end

function AbsoluteLayout:getClassName()
    return "AbsoluteLayout"
end

function AbsoluteLayout:measure(children)
    local width = 0
    local height = 0
    for _, child in ipairs(children) do
        local childWidth, childHeight = child:measure()
        width = math.max(width, child.x + childWidth)
        height = math.max(height, child.y + childHeight)
    end
    self.measuredWidth = width
    self.measuredHeight = height
    return width, height
end

LinearLayout = {}
LinearLayout.__index = LinearLayout
setmetatable(LinearLayout, { __index = Layout })
function LinearLayout.new(orientation)
    local self = setmetatable(Layout.new(), LinearLayout)
    self.orientation = orientation or Orientations.horizontal
    self.spacing = 0
    self.alongAxisAlignment = Alignment.left
    return self
end

function LinearLayout:getClassName()
    return "LinearLayout"
end

function LinearLayout:setOrientation(orientation)
    self.orientation = orientation
    return self
end

function LinearLayout:setSpacing(spacing)
    self.spacing = spacing
    return self
end

function LinearLayout:setAlongAxisAlignment(alignment)
    self.alongAxisAlignment = alignment
    return self
end

function LinearLayout:measure(children)
    local width = 0
    local height = 0
    if self.orientation == Orientations.horizontal then
        for i, child in ipairs(children) do
            local childWidth, childHeight = child:measure()
            width = width + childWidth + (i > 1 and self.spacing or 0)
            height = math.max(height, childHeight)
        end
        width = width + self.spacing * (#children - 1)
    else
        for i, child in ipairs(children) do
            local childWidth, childHeight = child:measure()
            width = math.max(width, childWidth)
            height = height + childHeight + (i > 1 and self.spacing or 0)
        end
        height = height + self.spacing * (#children - 1)
    end
    self.measuredWidth = width
    self.measuredHeight = height
    return width, height
end

function LinearLayout:layout(children, container)
    local x = 0
    local y = 0
    if self.orientation == Orientations.horizontal then
        x = x + (container.measuredWidth - container.childrenWidth) * self.alongAxisAlignment
    else
        y = y + (container.measuredHeight - container.childrenHeight) * self.alongAxisAlignment
    end
    for _, child in ipairs(children) do
        local childParams = child:getLayoutParams()
        local childCrossAxisAlignment = childParams.crossAxisAlignment or Alignment.top
        child.measuredX = x
        child.measuredY = y
        if self.orientation == Orientations.horizontal then
            child.measuredY = child.measuredY +
                (container.measuredHeight - child.measuredHeight) * childCrossAxisAlignment
            x = x + child.measuredWidth + self.spacing
        else
            child.measuredX = child.measuredX + (container.measuredWidth - child.measuredWidth) * childCrossAxisAlignment
            y = y + child.measuredHeight + self.spacing
        end
    end
end

LayoutParams = {}
LayoutParams.__index = LayoutParams

function LayoutParams.new()
    local self = setmetatable({}, LayoutParams)
    return self
end

function LayoutParams:getClassName()
    return "LayoutParams"
end

Alignment = {
    top = 0,
    left = 0,
    center = 0.5,
    middle = 0.5,
    bottom = 1,
    right = 1,
}

LinearLayoutParams = {}
LinearLayoutParams.__index = LinearLayoutParams
setmetatable(LinearLayoutParams, { __index = LayoutParams })
function LinearLayoutParams.new(alignment)
    local self = setmetatable(LayoutParams.new(), LinearLayoutParams)
    self.crossAxisAlignment = alignment or Alignment.top
    return self
end

function LinearLayoutParams:getClassName()
    return "LinearLayoutParams"
end

function LinearLayoutParams:setCrossAxisAlignment(crossAxisAlignment)
    self.crossAxisAlignment = crossAxisAlignment
    return self
end
