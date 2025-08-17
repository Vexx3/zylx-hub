local repo = "https://raw.githubusercontent.com/Vexx3/zylx-hub/refs/heads/main/scripts/"

local supportedGames = {
	-- [17574618959] = true,
}

if supportedGames[game.GameId] then
	assert(loadstring(`{repo}{game.GameId}.luau`))()
else
	assert(loadstring(`{repo}universal.luau`))()
end
