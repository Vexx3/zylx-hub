local repo = "https://raw.githubusercontent.com/Vexx3/zylx-hub/refs/heads/main/scripts/"

local supportedGames = {
	-- [17574618959] = true,
}

if supportedGames[game.GameId] then
	print("supported game loading")
	loadstring(`{repo}{game.GameId}.luau`)()
else
	print("loading universal")
	loadstring(`{repo}universal.luau`)()
end
