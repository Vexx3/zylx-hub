local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")

local HumanoidConnections = {
    WalkSpeed = {},
    JumpPower = {}
}

local noclipping = nil
local clip = true

local infJumpConnection
local infJumpDebounce = false

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
    Movement = Tabs.Player:AddLeftGroupbox("Movement", "user-round-plus"),
    Visual = Tabs.Player:AddRightGroupbox("Visual", "eye")
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

local noclip = Groupboxes.Movement:AddToggle("Noclip", {
    Text = "Noclip",
    Tooltip = "Allows you to go through objects"
})

local infJump = Groupboxes.Movement:AddToggle("InfJump", {
    Text = "Infinite Jump",
    Tooltip = "Allows you to jump multiple times before hitting the ground"
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

    local typeOfJump = Humanoid.UseJumpPower and "JumpPower" or "JumpHeight" 

    table.insert(HumanoidConnections.JumpPower, Humanoid:GetPropertyChangedSignal(typeOfJump):Connect(function()
        updateJumpPower(power)
    end))
end

walkSpeed:OnChanged(function(value)
    setupWalkSpeed(value)
end)

jumpPower:OnChanged(function(value)
    setupJumpPower(value)
end)

noclip:OnChanged(function(enabled)
    if noclipping then
        noclipping:Disconnect()
        noclipping = nil
    end

    if not enabled then return end

    --[[
    local function noclipLoop()
        if clip == false and Character ~= nil then
            for _, child in Character:GetDescendants() do
                if child:IsA("BasePart") and child.CanCollide == true then
                    child.CanCollide = false
                end
            end
        end
    end
    ]]

    noclipping = RunService.Stepped:Connect(function()
        if not Character then return end
        for _, child in Character:GetDescendants() do
            if child:IsA("BasePart") then
                child.CanCollide = false
            end
        end
    end)
end)

infJump:OnChanged(function(enabled)
    if infJumpConnection then
        infJumpConnection:Disconnect()
        infJumpConnection = nil
    end

    if not enabled then return end

    infJumpDebounce = false

    infJumpConnection = UserInputService.JumpRequest:Connect(function()
        if infJumpDebounce then return end
        infJumpDebounce = true
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        task.wait()
        infJumpDebounce = false
    end)
end)

Player.CharacterAdded:Connect(function(character)
    Character = character
    Humanoid = character:WaitForChild("Humanoid")

    setupWalkSpeed(Options.WalkSpeedSlider.Value)
    setupJumpPower(Options.JumpPowerSlider.Value)
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
