local repo = "https://raw.githubusercontent.com/Vexx3/zylx-hub/refs/heads/main/src/scripts/"

local supportedGames = {
	[102992620118098] = true,
}

if supportedGames[game.GameId] then
	loadstring(game:HttpGet(`{repo}{game.GameId}.luau`))()
else
	loadstring(game:HttpGet(`{repo}universal.luau`))()
end
