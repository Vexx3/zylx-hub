local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")

local HumanoidConnections = {
    WalkSpeed = {},
    JumpPower = {}
}

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(`{repo}Library.lua`))()
local ThemeManager = loadstring(game:HttpGet(`{repo}addons/ThemeManager.lua`))()
local SaveManager = loadstring(game:HttpGet(`{repo}addons/SaveManager.lua`))()

local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({
    Title = "Zylx Hub",
    Footer = "v0.0.1",
    Icon = "zap",    
})

local Tabs = {
    Main = Window:AddTab("Main", "house", "Core features and primary functions"),
    Misc = Window:AddTab("Misc", "shuffle", "Extra tools and miscellaneous features"),
    Player = Window:AddTab("Player", "user", "Customization and settings for your player")
}

local Groupboxes = {
    Movement = Tabs.Player:AddLeftGroupbox("Movement"),
    Visual = Tabs.Player:AddLeftGroupbox("Visual")
}

local walkSpeed = Groupboxes.Movement:AddSlider("WalkSpeedSlider", {
    Text = "Character WalkSpeed",
    Default = Humanoid.WalkSpeed,
    Min = Humanoid.WalkSpeed,
    Rounding = 1,
    Tooltip = "Change your walkspeed"
})

local jumpPower = Groupboxes.Movement:AddSlider("JumpPowerSlider", {
    Text = "Character Jump Power",
    Default = Humanoid.UseJumpPower and Humanoid.JumpPower or Humanoid.JumpHeight,
    Min = Humanoid.UseJumpPower and Humanoid.JumpPower or Humanoid.JumpHeight,
    Rounding = 1,
    Tooltip = "Change your jump power"
})

local function disconnectConnections(list)
    for _, connection in list do
        connection:Disconnect()
    end
    table.clear(list)
end

local function updateWalkSpeed(speed)
    if Humanoid then
        Humanoid.WalkSpeed = speed
    end
end

local function updateJumpPower(power)
    if Humanoid then
        if Humanoid.UseJumpPower then
            Humanoid.JumpPower = power
        else
            Humanoid.JumpHeight = power
        end
    end
end

local function setupWalkSpeed(speed)
    disconnectConnections(HumanoidConnections.WalkSpeed)
    updateWalkSpeed(speed)

    table.insert(HumanoidConnections.WalkSpeed, Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        updateWalkSpeed(speed)
    end))
end

local function setupJumpPower(power)
    disconnectConnections(HumanoidConnections.JumpPower)
    updateJumpPower(power)

    table.insert(HumanoidConnections.JumpPower, Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        updateJumpPower(power)
    end))
end

walkSpeed:OnChanged(function(value)
    setupWalkSpeed(value)
end)

jumpPower:OnChanged(function(value)
    setupJumpPower(value)
end)

Player.CharacterAdded:Connect(function(character)
    Humanoid = character:WaitForChild("Humanoid")

    setupWalkSpeed(Options.WalkSpeedSlider.Value)
    setupJumpPower(Options.JumpPower.Value)
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
