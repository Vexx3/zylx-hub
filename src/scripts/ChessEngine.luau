local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local PlayerScripts = LocalPlayer.PlayerScripts

local AI = PlayerScripts.AI

local GarboChess = require(AI.GarboChess)
local Sunfish = require(AI.Sunfish)

local GetActiveTableset = ReplicatedStorage.InternalClientEvents.GetActiveTableset
local SubmitMove = ReplicatedStorage.Chess.SubmitMove

local lastFEN

------------------------------------- UI Setup ----------------------------------------------------

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({
        Title = "Chess Engine",
        Footer = "Made by _zylx",
})

local Tabs = {
    Main = Window:AddTab("Main", "user"),
    UISettings = Window:AddTab("UI Settings", "settings"),
}

local autoPlayGroupbox = Tabs.Main:AddLeftGroupbox("Autoplay", "play")

local autoPlayToggle = autoPlayGroupbox:AddToggle("AutoMove", {
        Text = "Auto Move",
})

local engineDropdown = autoPlayGroupbox:AddDropdown("Engine", {
        Text = "Chess Engine",
        Values = { "GarboChess", "Sunfish", "Stockfish" },
        Default = 3,
})

autoPlayGroupbox:AddLabel("GarboChess/Sunfish: Built-in, balanced performance. Stockfish: External, stronger but slower at higher depths.")

local stockfishDepthSlider = autoPlayGroupbox:AddSlider("StockfishDepth", {
        Text = "Stockfish Depth",
        Default = 12,
        Min = 1,
        Max = 18,
})

autoPlayGroupbox:AddLabel("Depth: Higher = stronger moves but slower response, may require a good internet. Lower = faster but weaker moves (more natural mistakes). Recommended: 9-12 for balance")

local stockfishMaxThinkingSlider = autoPlayGroupbox:AddSlider("MaxThinkingTime", {
        Text = "Stockfish Max Thinking Time",
        Default = 50,
        Min = 1,
        Max = 100,
        Suffix = "ms",
})

local moveDelaySlider = autoPlayGroupbox:AddSlider("MoveDelay", {
        Text = "Move Delay",
        Default = 1,
        Min = 0.5,
        Max = 3,
        Rounding = 1,
        Suffix = "s",
})

autoPlayGroupbox:AddLabel("Delay: Adds a pause between moves so you don't play instantly. Short = faster but may look bot-like. Longer = slower but more human-like. Recommended: 0.8-1.5s")

----------------------------------------------------------------------------------------------------

local function getChessTableset()
    local ChessTableset = GetActiveTableset:Invoke()
    if not ChessTableset then
        return nil
    end

    local FEN = ChessTableset.FEN.Value
    local IsGameActive = ChessTableset.IsGameActive.Value
    
    return FEN, IsGameActive
end

--[[
local function getStockfishMove(FEN: string)
    local depth = Options.StockfishDepth.Value
    local endpoint = "https://stockfish.online/api/s/v2.php?fen="..HttpService:UrlEncode(FEN).."&depth="..depth
    
    local success, response = pcall(function()
        return game:HttpGet(endpoint)
    end)

    if success and response then
        local data = HttpService:JSONDecode(response)
        if data and data.bestmove then
            local move = data.bestmove:match("bestmove%s+(%w+)")
            return move
        end
    else
        return nil
    end
end
]]

local function getInfoChessAPI(FEN: string) -- retrieves info from chess-api.com
    local url = "https://chess-api.com/v1"

    local requestBody = {
        fen = FEN,
        depth = Options.StockfishDepth.Value,
        maxThinkingTime = Options.MaxThinkingTime.Value
    }
    
    local success, response = pcall(function()
        return game:HttpPost(
            url,
            HttpService:JSONEncode(requestBody),
            false,
            "application/json"
        )
    end)

    if success and response then
        local data = HttpService:JSONDecode(response)
        print(HttpService:JSONEncode(data))
        return data
    end

    return nil
end

local function getBestMove(FEN: string)
    local engine = Options.Engine.Value

    local move
    if engine == "GarboChess" then
        move = GarboChess:GetBestMoveFromFEN(FEN, 1)
    elseif engine == "Sunfish" then
        move = Sunfish:GetBestMove(FEN, 500)
    elseif engine == "Stockfish" then
        --[[
        move = getStockfishMove(FEN)
        if not move then
            move = Sunfish:GetBestMove(FEN, 500)
        end
        ]]
        local data = getInfoChessAPI(FEN)
        if data and data.move then
            move = data.move
        else
            Library:Notify("Stockfish failed to analyze the best move. Using sunfish as fallback...")
            move = Sunfish:GetBestMove(FEN, 2000)
        end
    end

    return move
end

local function submitMove(move: string)
    if not move then return end
    SubmitMove:InvokeServer(move)
end

local elapsed = 0
local checkInterval = 0.3
local function onHeartbeat(deltaTime)
    elapsed += deltaTime
    if elapsed >= checkInterval then
        elapsed = 0
        
        if not Toggles.AutoMove.Value then return end
    
        local FEN, IsGameActive = getChessTableset()
        if not IsGameActive then return end
    
        if FEN ~= lastFEN then
            lastFEN = FEN
    
            local move = getBestMove(FEN)
            if move then
                local baseDelay = Options.MoveDelay.Value
                task.spawn(function()
                    task.wait(baseDelay + math.random() * 0.3)
                    submitMove(move)
                end)
            end
        end
    end
end

RunService.Heartbeat:Connect(onHeartbeat)

local MenuGroup = Tabs.UISettings:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "Open Keybind Menu",
	Callback = function(value)
		Library.KeybindFrame.Visible = value
	end,
})
MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = true,
	Callback = function(Value)
		Library.ShowCustomCursor = Value
	end,
})
MenuGroup:AddDropdown("NotificationSide", {
	Values = { "Left", "Right" },
	Default = "Right",

	Text = "Notification Side",

	Callback = function(Value)
		Library:SetNotifySide(Value)
	end,
})
MenuGroup:AddDropdown("DPIDropdown", {
	Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	Default = "100%",

	Text = "DPI Scale",

	Callback = function(Value)
		Value = Value:gsub("%%", "")
		local DPI = tonumber(Value)

		Library:SetDPIScale(DPI)
	end,
})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind")
	:AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

MenuGroup:AddButton("Unload", function()
	Library:Unload()
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:BuildConfigSection(Tabs.UISettings)
ThemeManager:ApplyToTab(Tabs.UISettings)
SaveManager:LoadAutoloadConfig()
