local repo = "https://github.com/Vexx3/zylx-hub/tree/main/src/scripts"

local supportedGames = {
	-- [17574618959] = true,
}

if supportedGames[game.GameId] then
	loadstring(game:HttpGet(`{repo}{game.GameId}.luau`))()
else
	loadstring(game:HttpGet(`{repo}universal.luau`))()
end
