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
local Library = loadstring(game:HttpGetAsync(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGetAsync(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGetAsync(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({
        Title = "Chess Engine",
        Footer = "Made by _zylx",
})

-- Structure
local Tabs = {
    Main = Window:AddTab("Main", "user"),
    UISettings = Window:AddTab("UI Settings", "settings"),
}

local autoPlayGroupbox = Tabs.Main:AddLeftGroupbox("Autoplay", "play")
local infoGroupbox = Tabs.Main:AddRightGroupbox("Game Info", "info")

-- Elements
-- Main
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
        Default = 9,
        Min = 1,
        Max = 15,
})

autoPlayGroupbox:AddLabel("Depth: Higher = stronger moves but slower response, may require a good internet. Lower = faster but weaker moves (more natural mistakes). Recommended: 9-12 for balance")

local moveDelaySlider = autoPlayGroupbox:AddSlider("MoveDelay", {
        Text = "Move Delay",
        Default = 1.5,
        Min = 0.5,
        Max = 3,
        Rounding = 1,
        Suffix = "s",
})

autoPlayGroupbox:AddLabel("Delay: Adds a pause between moves so you don't play instantly. Short = faster but may look bot-like. Longer = slower but more human-like. Recommended: 0.8-1.5s")

-- Info

local gameInfo = infoGroupbox:AddLabel()

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

local function getStockfishInfo(FEN: string)
    local depth = Options.StockfishDepth.Value
    local endpoint = "https://stockfish.online/api/s/v2.php?fen="..HttpService:UrlEncode(FEN).."&depth="..depth
    
    local success, response = pcall(function()
        return game:HttpGetAsync(endpoint)
    end)

    if success and response then
        local data = HttpService:JSONDecode(response)
        if data then
            local move
            if data.bestmove then
                move = data.bestmove:match("bestmove%s+(%w+)")
            end

            local info = {}
            
            if data.evaluation then
                local eval = data.evaluation
                local evalDesc, winChance

                local whiteChance = 1 / (1 + 10^(-eval / 4))
                whiteChance = math.floor(whiteChance * 100 + 0.5)
                
                if eval > 2 then
                    evalDesc = "White is clearly winning"
                elseif eval > 1 then
                    evalDesc = "White is slightly winning"
                elseif eval > 0.3 then
                    evalDesc = "White has a small advantage"
                elseif eval < -2 then
                    evalDesc = "Black is clearly winning"
                elseif eval < -1 then
                    evalDesc = "Black is slightly winning"
                elseif eval < -0.3 then
                    evalDesc = "Black has a small advantage"
                else
                    evalDesc = "The position is equal"
                end

                local percentText
                if eval >= 0 then
                    percentText = string.format("~%d%% White", whiteChance)
                else
                    percentText = string.format("~%d%% Black", 100 - whiteChance)
                end
                
                info.Evaluation = string.format("%.2f (%s, %s win chance)", eval, evalDesc, percentText)
            end

            if data.mate ~= nil then
                info.Mate = data.mate and ("Mate in " .. data.mate) or nil
            end
            
            if data.bestmove then info.BestMove = data.bestmove end
            if data.continuation then info.Continuation = data.continuation end

            return move, info
        end
    end

    return nil, nil
end

local function getBestMove(FEN: string)
    local engine = Options.Engine.Value

    local move
    local info = {}
    
    if engine == "GarboChess" then
        move = GarboChess:GetBestMoveFromFEN(FEN, 15)
    elseif engine == "Sunfish" then
        move = Sunfish:GetBestMove(FEN, 5000)
    elseif engine == "Stockfish" then
        move, info = getStockfishInfo(FEN)
        if not move then
            move = Sunfish:GetBestMove(FEN, 2000)
            Library:Notify("Stockfish failed to analyze the best move. using sunfish as fallback...")
        end
    end

    return move, info
end

local function submitMove(move: string)
    if not move then return end
    SubmitMove:InvokeServer(move)
end

local function updateGameInfoLabel(info)
    if Options.Engine.Value ~= "Stockfish" then
        gameInfo:SetText()
        return
    end

    local parts = {}
    if info.Evaluation then table.insert(parts, `Evaluation: {info.Evaluation}`) end
    if info.Mate then table.insert(parts, `Mate in: {info.Mate}`) end
    if info.BestMove then table.insert(parts, `Best Move: {info.BestMove}`) end
    if info.Continuation then table.insert(parts, `Continuation: {info.Continuation}`) end

    if #parts == 0 then
        gameInfo:SetText()
    else
        gameInfo:SetText(table.concat(parts, "\n"))
    end
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
    
            local move, info = getBestMove(FEN)
            updateGameInfoLabel(info)
            
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
