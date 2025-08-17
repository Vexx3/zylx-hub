local repo = "https://raw.githubusercontent.com/Vexx3/zylx-hub/refs/heads/main/scripts/"

local supportedGames = {
	-- [17574618959] = true,
}

if supportedGames[game.GameId] then
	loadstring(`{repo}{game.GameId}.luau`)()
else
	loadstring(`{repo}universal.luau`)()
end
