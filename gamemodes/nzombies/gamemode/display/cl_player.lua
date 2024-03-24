--if (game.SinglePlayer()) then -- InitPostEntity seems to fail for Singleplayer? Weird..
playerColors = {
	Color(239,154,154),
	Color(244,143,177),
	Color(159,168,218),
	Color(129,212,250),
	Color(128,203,196),
	Color(165,214,167),
	Color(230,238,156),
	Color(255,241,118),
	Color(255,224,130),
	Color(255,171,145),
	Color(161,136,127),
	Color(224,224,224),
	Color(144,164,174),
}

local blooddecalsFallback = {
	Material("bloodline_score1.png", "unlitgeneric smooth"),
	Material("bloodline_score2.png", "unlitgeneric smooth"),
	Material("bloodline_score3.png", "unlitgeneric smooth"),
	Material("bloodline_score4.png", "unlitgeneric smooth"),
	nil
}

function player.GetColorByIndex(index)
	local color = playerColors[((index) % #playerColors)]
	if color == nil then color = Color(math.random(0, 255), math.random(0, 255), math.random(0, 255), 255) end
	return color
end

function player.GetBloodByIndex(index)
	return NZCustomPointsHUD != nil and NZCustomPointsHUD[((index) % #NZCustomPointsHUD) + 1] or blooddecalsFallback[((index) % #blooddecalsFallback) + 1]
end
--return end

-- hook.Add("InitPostEntity", "ColorAndBloodFunc", function()
	
-- end)


net.Receive("NZPlayerColors", function() -- Synchronise player colors from the server so that everyone sees the same colors
	local newTbl = net.ReadTable()
	if !newTbl || table.IsEmpty(newTbl) then return end
	playerColors = newTbl
end)

