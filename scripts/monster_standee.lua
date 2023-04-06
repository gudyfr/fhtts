function onLoad(save_state)
	local state = JSON.decode(save_state)
	if state == nil then
		state = {}
	end
	local params = {
		function_owner = self,
		input_function = "editTextField",
		width = 300,
		height = 250,
		font_size = 200,
		alignment = 3,
		value = state['nr'] or '1',
		scale = { .4,.4,.4 },
		position = { 0, -0.72, -0.14 },
		rotation = {0,180,0},
		color = { 1, 1, 1, 0 },
		font_color = { 0, 0, 0, 100 }
	}
	self.createInput(params)

	params = {
		function_owner = self,
		click_function = "toggleType",
		height = 60,
		width = 300,
		font_size = 90,
		alignment = 3,
		scale = { 1, 1, .5 },
		position = { 0, -0.63, 0.0 },
		color = { 1, 1, 1, 0 },
		font_color = { 0, 0, 0, 100 },
	}
	self.createButton(params)
end

function onSave()
	state = {}
	state.nr = self.getInputs()[1]["value"]
	return JSON.encode(state)
end

function editTextField()
end

function toggleType()
	print(self.getColorTint())
	if self.getColorTint().r == 1.0 then
		self.setColorTint("Yellow")
	else
		self.setColorTint("White")
	end
	Global.call("getScenarioMat").call("toggled", self)
end