require("savable")

function getState()
    local data_to_save = createEmptyState()
	for i, v in pairs(buttons) do
		if i ~= "count" then
			if v.label == "\u{2717}" then
				data_to_save.buttons[i] = "u{2717}"
			else
				data_to_save.buttons[i] = v.label
			end
		end
	end
	local inputs = self.getInputs()
	for _, v in pairs(inputs) do
		name = v.label
		data_to_save.inputs[name] = v.value
	end
    return data_to_save
end

function onStateUpdate(state)
    self.clearButtons()
    self.clearInputs()
    refreshUI(state)
    forceSave()
end

function createEmptyState()
    return {buttons = {}, inputs = {}}
end

toggleSymbol = "\u{2717}"
hideButtonBack = true

thick = 0.05

function initCustomButtons()
	thick = 0.05

	dx = -0.65; dz = -1.29
	createTextField('Name', 'txt', dx, dz)

	dx = -1.3; dz = -0.4
	setupButton('inspiration', 'counter', dx, dz)
	dx = -0.7; dz = -0.4
	setupButton('total_defense', 'counter', dx, dz)

    dx = -1.3; dz = -1.05
    setupButton('lumber', 'smallCounter', dx, dz)
    dx = -0.7
    setupButton('metal', 'smallCounter', dx, dz)
    dx = -0.2
    setupButton('hide', 'smallCounter', dx, dz)

    dx = -1.3; dz = -0.9
    setupButton('arrowvine', 'smallCounter', dx, dz)
    dx = -0.7
    setupButton('axenut', 'smallCounter', dx, dz)
    dx = -0.2
    setupButton('corpsecap', 'smallCounter', dx, dz)

    dx = -1.3; dz = -0.77
    setupButton('flamefruit', 'smallCounter', dx, dz)
    dx = -0.7
    setupButton('rockroot', 'smallCounter', dx, dz)
    dx = -0.2
    setupButton('snowthistle', 'smallCounter', dx, dz)


	-- retirement
	player = 1
	dz0 = 0.99
	dx0 = -1.35
	dx = dx0; dz = dz0; px = 0.02; pz = 0.098
	local fields = {
		player = 0.335,
		character = 0.285,
		class = 0.2,
		levels = 0.13,
		perks = 0.16,
		masteries = 0.2}
	for c=1,2 do
		for r=1,11 do
			dx = dx0 + (c-1) * 1.55
			for type,w in pairs(fields) do
				createTextField(type .. "_" .. player, type, dx, dz)
				dx = dx + w + px
			end
			player = player + 1
			dz = dz + pz			
		end
		dz = dz0
	end

	-- Calendar
	week = 1
	dx0 = -1.46
	dz = -1.81; px = 0.153; pz = 0.12
	for r=1, 4 do
		dx = dx0
		for w=1,20 do
			createTextField('w' .. week, "week", dx, dz)
			setupButton('t' .. week, 'toggleA', dx, dz)
			dx = dx + px
			week = week + 1
		end
		dz = dz + pz
	end

	dx = 0; dz = -1.76
	setupButton('weekCount', 'hiddenCounter', dx, dz)

    -- Prosperity
	dx = -1.18; dz = 0.59; px = 0.0333 spx = 0.054; ddz = 0.115
	prosperities = {{6,9,12,15,18}, {21,24,27}}
	pr = 1
	for l,properity in ipairs(prosperities) do
		for i,p in ipairs(properity) do
			for j=1, p do
				setupButton('prosperity' .. pr, "toggleC", dx, dz)
				dx = dx + px
				pr = pr + 1
			end
			dx = dx + spx
		end
		dz = dz + ddz
		dx = -1.0
	end

	-- Town Guard Perks
	tgp = 1
	dx = 0.86; dz = -1.23; px = 0.049 ; spx = 0.095; pz=0.06
	for r=1,5 do
		for g=1,3 do
			for i=1,3 do
				setupButton('tgp' .. tgp, "toggleC", dx, dz)
				tgp = tgp + 1
				dx  = dx + px
			end
			dx = dx + spx
		end
		dz = dz + pz
		dx = 0.86
	end

	-- Acquired Town Guard Perks

	dx = 0.82; dz = -.88; pz = 0.05
	local perks = {
		2,
		0.1, 2,
		0.1, 2,
		0.05, 2,
		0.05, 2,
		0.1, 2,
		0.05, 1,
		0.075, 1,
		0.075, 1}
	for i,val in ipairs(perks) do
		if i % 2 == 1 then
			for b=1, val do
				setupButton('p' .. tgp, "toggleD", dx, dz)
				tgp = tgp + 1
				dz = dz + pz
			end
		else
			dz = dz + val
		end
	end
	

	-- Morale
	dx = 0.28; dz = -0.26; pz = -0.0495
	for m=0,20 do
		setupButton('morale_' .. m, "toggleC", dx, dz)
		dz = dz +  pz
	end

	-- Soldiers
	dx = -0.25; dz = -0.58; px = 0.078; pz = 0.1
	soldiers = {4,2,2,2}
	sol = 1
	for i,soldier in ipairs(soldiers) do
		for n=1,soldier do
			setupButton('soldier_' .. sol, "toggleB", dx, dz)
			dx = dx + px
			sol = sol + 1
		end
		dz = dz + pz
		dx = -0.172
	end
end

function initButtonsTable()
	buttons = {}
	inputs = {}
	buttons.count = 0

	buttons.counter = {
		width = 0, height = 0, font = 800,
		ox = 0.16, oz = -0.16, ow = 300, oh = 300
	}
    buttons.smallCounter = {
        width = 0, height = 0, font = 200,
		ox = 0.06, oz = -0.04, ow = 150, oh = 150
    }
	buttons.hiddenCounter = {
		width = 0, height = 0, font = 600,
		ox = 0.16, oz = -0.16, ow = 300, oh = 300
	}
	buttons.toggleA = {
		width = 300, height = 300, font = 400
	}
	buttons.toggleB = {
		width = 120, height = 120, font = 120
	}
	buttons.toggleC = {
		width = 90, height = 90, font = 100
	}
	buttons.toggleD = {
		width = 300, height = 300, font = 400, scale = {0.2,0.2,0.05}
	}
	buttons.txt = {
		width = 3200, height = 300, font = 250, alignment = 3
	}
	buttons.player = {
		width = 800, height = 180, font = 100, alignment = 2, empty=1
	}
	buttons.character = {
		width = 780, height = 180, font = 100, alignment = 2, empty=1
	}
	buttons.class = {
		width = 600, height = 180, font = 100, alignment = 2, empty=1
	}
	buttons.levels = {
		width = 320, height = 180, font = 100, alignment = 2, empty=1
	}
	buttons.perks = {
		width = 320, height = 180, font = 100, alignment = 2, empty=1
	}
	buttons.masteries = {
		width = 450, height = 180, font = 100, alignment = 2, empty=1
	}
	buttons.week = {
		width = 340, height = 271, font = 83, alignment = 2, empty=1
	}
	buttons.editBox = {
		width = 320, height = 1050, font = 250, alignment = 2
	}

end

function forceSave()
	local data_to_save = getState()
	local saved_data = JSON.encode_pretty(data_to_save)
	self.script_state = saved_data
	return saved_data
end

function onload(saved_data)
    local loaded_data = JSON.decode(saved_data)
    refreshUI(loaded_data)
    registerSavable("Campaign Sheet")
end

function refreshUI(loaded_data)
    initButtonsTable()
	if loaded_data ~= nil then
		for i,v in pairs(loaded_data.buttons) do
			buttons[i] = {label = v}
		end
		for i,v in pairs(loaded_data.inputs) do
			inputs[i] = v
		end
	end
	initCustomButtons()
end


function dud()
end

function clickedToggle(index)
  if buttons[index].label == "" then
    buttons[index].label = "\u{2717}"		
		if index:find("morale") then
			local mLevel = tonumber(index:sub(8))
			for m=0, 20 do
				if m ~= mLevel then
					buttons["morale_"..m].label = ""
					self.editButton(buttons["morale_" .. m])
				end
			end
		end
  else
    buttons[index].label = ""
  end
  self.editButton(buttons[index])
	forceSave()
end

function createTextField(name, type, x, z)
	local input_parameters = {}
	input_parameters.height = buttons[type].height
	input_parameters.width = buttons[type].width
	input_parameters.font_size = buttons[type].font
	input_parameters.alignment = buttons[type].alignment

	input_parameters.input_function = "editTextField"
	input_parameters.function_owner = self	
	input_parameters.label = name
	input_parameters.scale = {0.2, 0.2, 0.2}
	input_parameters.position = {x, thick, z}
	if hideButtonBack then
		input_parameters.color = {1, 1, 1, 0}
		input_parameters.font_color = {0, 0, 0, 100}
	end

	if inputs[name] ~= nil then
		input_parameters.value = inputs[name]
		-- if input_parameters.value == '' then
		-- 	if  buttons[type].empty == nil or  buttons[type].empty != 1 then
		-- 		input_parameters.value = " "
		-- 	end
		-- end
	end
	self.createInput(input_parameters)
end

function editTextField(object, color, text, editing)
	if not editing then
		forceSave()
	end
end

function setupButton(name, type, x, z)
  local button_parameters = {}
  button_parameters.index = buttons.count
	button_parameters.height = buttons[type].height
	button_parameters.width = buttons[type].width
	button_parameters.font_size = buttons[type].font
	if type == "counter" or type == "smallCounter" or type == "hiddenCounter" then
		button_parameters.click_function = "dud"
		button_parameters.label = "0"
		createpm(name, type, x, z)
		button_parameters.index = buttons.count
	elseif type == "toggleA" or type == "toggleB" or type == "toggleC" or type == "toggleD" then
		self.setVar("toggleClick_" .. name, function () clickedToggle(name) end)
		button_parameters.click_function = "toggleClick_" .. name
		button_parameters.label = ""
	else
		button_parameters.click_function = "dud"
		button_parameters.label = "0"
	end

	if hideButtonBack then
		button_parameters.color = {1, 1, 1, 0}
		button_parameters.font_color = {0, 0, 0, 100}
	end
	if type == "hiddenCounter" then
		button_parameters.font_color = {1,1,1,0}
	end
	button_parameters.scale = buttons[type].scale or {0.2, 0.2, 0.2}
  	button_parameters.position = {x, thick, z}
	button_parameters.function_owner = self

	if buttons[name] ~= nil then
		if buttons[name].label == "u{2717}" then
			button_parameters.label = "\u{2717}"
		else
			button_parameters.label = buttons[name].label
		end

	end

  self.createButton(button_parameters)
  buttons[name] = button_parameters
  buttons.count = buttons.count + 1
end

function createpm(name, type, x, z)
  local button_parameters = {}
  button_parameters.index = buttons.count
	button_parameters.height = buttons[type].oh
	button_parameters.width = buttons[type].ow
	button_parameters.font_size = buttons[type].font * 0.7
  self.setVar("add_" .. name, function (obj, color, alt_click) add(name, 1, alt_click) end)
  button_parameters.click_function = "add_" .. name
  button_parameters.label = "+"
  button_parameters.function_owner = self
  button_parameters.scale = {0.2, 0.2, 0.2}
	if hideButtonBack then
		button_parameters.color = {1, 1, 1, 0}
		button_parameters.font_color = {0, 0, 0, 100}
	end
  button_parameters.position = {x + buttons[type].ox, thick, z + buttons[type].oz}
  self.createButton(button_parameters)
  buttons["p_" .. name] = button_parameters
  buttons.count = buttons.count + 1

  button_parameters.index = buttons.count
  self.setVar("sub_" .. name, function (obj, color, alt_click) add(name, - 1, alt_click) end)
  button_parameters.click_function = "sub_" .. name
  button_parameters.label = "-"
  button_parameters.position = {x - buttons[type].ox, thick, z + buttons[type].oz}
  self.createButton(button_parameters)
  buttons["m_" .. name] = button_parameters
  buttons.count = buttons.count + 1
end

function addEx(params) add(params.name, params.amount) end

function add(name, amount, alt_click)
	if alt_click then amount = amount * 10 end
	local new_value = tonumber(buttons[name].label) + amount
	if name == "weekCount" then
		if new_value < 0 then
			new_value = 0
		elseif new_value > 80 then
			new_value = 80
		end
	end
  	buttons[name].label = tostring(new_value)
 	self.editButton(buttons[name])
	if name == "weekCount" then
		print("Week changed : " .. new_value)
		for w=1, new_value do
			buttons["t"..w].label = "\u{2717}"
			self.editButton(buttons["t"..w])
		end
		for w=new_value+1, 80 do
			buttons["t"..w].label = ""
			self.editButton(buttons["t"..w])
		end
	end
	level = 0
	forceSave()
end