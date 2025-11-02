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

-- UI Setup

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
        Values = { "GarboChess", "Sunfish" },
        Default = 2,
})

--[[
local moveDelaySlider = autoPlayGroupbox:AddSlider("MoveDelay", {
        Text = "Move Delay",
        Default = 2500,
        Min = 500,
        Max = 8000,
        Rounding = 1,
        Suffix = "ms",
})
]]

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

local function getBestMove(FEN)
    local engine = Options.Engine.Value
    --local moveDelay = Options.MoveDelay.Value

    local move

    if engine == "GarboChess" then
        --move = GarboChess:GetBestMoveFromFEN(FEN, moveDelay / 1000)
        move = GarboChess:GetBestMoveFromFEN(FEN, 0.15)
    elseif engine == "Sunfish" then
        move = Sunfish:GetBestMove(FEN, 1)
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
                submitMove(move)
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
