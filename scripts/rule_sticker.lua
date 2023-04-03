function setInfo(sticker, page, width, height)
    Sticker = sticker
    Page = page
    createButton(width, height)
end

function createButton(width, height)
    local params = {
        function_owner = self,
        click_function = "addToRuleBook",
        label          = "",
        position       = { 0, 0.05, 0 },
        width          = width,
        height         = height,
        font_size      = 200,
        color          = { 1, 1, 1, 0 },
        scale          = { 1, 1, 1 },
        font_color     = { 0, 0, 0, 100 },
        tooltip        = "Click to add sticker " .. Sticker .. " to rulebook on page " .. Page
    }
    self.createButton(params)
end

function addToRuleBook(obj, player_color, alt_click)
    -- Tell the books mat to add this sticker
    local booksMat = getObjectFromGUID('2a1fbe')

    local clickingPlayer
    for _, player in ipairs(Player.getPlayers()) do
        if player.color == player_color then
            clickingPlayer = player
        end
    end
    self.setPositionSmooth(booksMat.getPosition(), false, true)
    booksMat.call("addRulebookSticker", {Page, Sticker})

    -- Destroy this sticker
    Wait.time(function() addedToRuleBook(clickingPlayer, booksMat) end, 0.5)
end

function addedToRuleBook(player, booksMat)
    destroyObject(self)
end
