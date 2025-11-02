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

------------------------------------- UI Setup

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

local stockfishDepth = autoPlayGroupbox:AddInput("StockfishDepth", {
        Text = "Stockfish Depth",
        Default = 9,
        AllowEmpty = false,
        EmptyReset = 9,
})

local moveDelaySlider = autoPlayGroupbox:AddSlider("MoveDelay", {
        Text = "Move Delay",
        Default = 1,
        Min = 0.5,
        Max = 3,
        Rounding = 1,
        Suffix = "s",
})

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

local function getBestMove(FEN: string)
    local engine = Options.Engine.Value

    local move
    if engine == "GarboChess" then
        move = GarboChess:GetBestMoveFromFEN(FEN, 1)
    elseif engine == "Sunfish" then
        move = Sunfish:GetBestMove(FEN, 500)
    elseif engine == "Stockfish" then
        move = getStockfishMove(FEN)
        if not move then
            move = Sunfish:GetBestMove(FEN, 500)
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

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:BuildConfigSection(Tabs.UISettings)
ThemeManager:ApplyToTab(Tabs.UISettings)
SaveManager:LoadAutoloadConfig()
