local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Terrain = game:GetService("Terrain")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")

local HumanoidConnections = {
    WalkSpeed = {},
    JumpPower = {}
}

local noclipping = nil

local infJumpConnection
local infJumpDebounce = false

local brightLoop

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
    PlayerOthers = Tabs.Player:AddLeftGroupbox("Others", "box")
}

local walkSpeed = Groupboxes.Movement:AddSlider("WalkSpeedSlider", {
    Text = "WalkSpeed",
    Default = Humanoid.WalkSpeed,
    Min = Humanoid.WalkSpeed,
    Rounding = 1,
    Tooltip = "Change your walkspeed"
})

local jumpPower = Groupboxes.Movement:AddSlider("JumpPowerSlider", {
    Text = "Jump Power",
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

local lowGraphics = Groupboxes.Visual:AddButton("LowGraphics", {
    Text = "Low Graphics",
    Tooltip = "Lowers game quality to boost FPS",
    Func = function()
        Terrain.WaterWaveSize = 0
    	Terrain.WaterWaveSpeed = 0
    	Terrain.WaterReflectance = 0
    	Terrain.WaterTransparency = 1
    	Lighting.GlobalShadows = false
    	Lighting.FogEnd = 9e9
    	Lighting.FogStart = 9e9
        
        settings().Rendering.QualityLevel = 1
        
        for _, instance in game:GetDescendants() do
            if instance:IsA("BasePart") then
                instance.Material = "Plastic"
    			instance.Reflectance = 0
    			instance.BackSurface = "SmoothNoOutlines"
    			instance.BottomSurface = "SmoothNoOutlines"
    			instance.FrontSurface = "SmoothNoOutlines"
    			instance.LeftSurface = "SmoothNoOutlines"
    			instance.RightSurface = "SmoothNoOutlines"
    			instance.TopSurface = "SmoothNoOutlines"
            elseif instance:IsA("Decal") then
			    instance.Transparency = 1
		    elseif instance:IsA("ParticleEmitter") or v:IsA("Trail") then
    			instance.Lifetime = NumberRange.new(0)
            end
        end

        for _, lighting in Lighting:GetDescendants() do
            if lighting:IsA("PostEffect") then
                lighting.Enabled = false
            end
        end

        workspace.DescendantAdded:Connect(function(descendant)
            task.spawn(function()
                if descendant:IsA("ForceField") or descendant:IsA("Sparkles") or descendant:IsA("Smoke") or descendant:IsA("Fire") or descendant:IsA("Beam") then
                    RunService.Heartbeat:Wait()
                    descendant:Destroy()
                end
            end)
        end)
    end
})

local fullBright = Groupboxes.Visual:AddToggle("FullBright", {
    Text = "Full Bright",
    Tooltip = "Makes the map brighter / more visible
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
    end

    if not enabled then return end
    if not Character then return end

    noclipping = RunService.Stepped:Connect(function()
        for _, child in Character:GetDescendants() do
            if child:IsA("BasePart") and child.CanCollide == true then
                child.CanCollide = false
            end
        end
    end)
end)

infJump:OnChanged(function(enabled)
    if infJumpConnection then
        infJumpConnection:Disconnect()
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

fullBright:OnChanged(function(enabled)
    if brightLoop then
        brightLoop:Disconnect()
    end

    if not enabled then return end

    brightLoop = RunService.RenderStepped:Connect(function()
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
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
