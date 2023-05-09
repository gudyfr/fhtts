function onLoad()
    local params = {
        input_function = "noop",
        function_owner = self,
        position = { x = 0, y = 0.10, z = 0.85 },
        scale = { .5, .5, .5 },
        width = 4000,
        height = 220,
        font_size = 180,
        color = { 1, 1, 1, 0 },
        font_color = { .2, .24, 0.28, 100 },
        alignment = 3,
        value = "https://gudyfr.github.io/fhtts/docs/"
    }
    self.createInput(params)
end

function noop()
end
