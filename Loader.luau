local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = cloneref(game:GetService("VirtualUser"))

local Player = Players.LocalPlayer

local Terrain = workspace:FindFirstChildOfClass("Terrain")

local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")

local PlaceId = game.PlaceId
local JobId = game.JobId

local HumanoidConnections = {
    WalkSpeed = {},
    JumpPower = {}
}

local noclipping = nil

local infJumpConnection
local infJumpDebounce = false

local brightLoop

local antiAfkConnection
local disabledRobloxConnections = {}

local function rejoin()
    if #Players:GetPlayers() <= 1 then
        Player:Kick("\nRejoining...")
        task.wait()
        TeleportService:Teleport(PlaceId, Player)
    else
        TeleportService:TeleportToPlaceInstance(PlaceId, JobId, Player)
    end
end

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
    Player = Window:AddTab("Player", "user", "Customization and settings for your player"),
    UISettings = Window:AddTab("UI Settings", "settings", "Customize the UI Settings"),
}

local Groupboxes = {
    Movement = Tabs.Player:AddLeftGroupbox("Movement", "user-round-plus"),
    Visual = Tabs.Player:AddRightGroupbox("Visual", "eye"),
    PlayerOthers = Tabs.Player:AddLeftGroupbox("Others", "box"),
    UISettingsGroup = Tabs.UISettings:AddLeftGroupbox("Menu", "wrench"),
}

local walkSpeed = Groupboxes.Movement:AddSlider("WalkSpeedSlider", {
    Text = "WalkSpeed",
    Default = Humanoid.WalkSpeed,
    Min = Humanoid.WalkSpeed,
    Max = 500,
    Rounding = 1,
    Tooltip = "Change your walkspeed"
})

local jumpPower = Groupboxes.Movement:AddSlider("JumpPowerSlider", {
    Text = "Jump Power",
    Default = Humanoid.UseJumpPower and Humanoid.JumpPower or Humanoid.JumpHeight,
    Min = Humanoid.UseJumpPower and Humanoid.JumpPower or Humanoid.JumpHeight,
    Max = 500,
    Rounding = 1,
    Tooltip = "Change your jump power"
})

local fov = Groupboxes.Movement:AddSlider("FOVSlider", {
    Text = "Field Of View",
    Default = workspace.CurrentCamera.FieldOfView,
    Max = 120,
    Rounding = 1,
    Tooltip = "Adjusts field of view"
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
		    elseif instance:IsA("ParticleEmitter") or instance:IsA("Trail") then
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

local noFog = Groupboxes.Visual:AddButton("NoFog", {
    Text = "No Fog",
    Tooltip = "Removes fog",
    Func = function()
        Lighting.FogEnd = 100000

        for _, lighting in Lighting:GetDescendants() do
            if lighting:IsA("Atmosphere") then
                lighting:Destroy()
            end
        end
    end
})

local fullBright = Groupboxes.Visual:AddToggle("FullBright", {
    Text = "Full Bright",
    Tooltip = "Makes the map brighter / more visible"
})

local noRender = Groupboxes.Visual:AddToggle("NoRender", {
    Text = "No Render",
    Tooltip = "Disable 3d rendering to decrease the amount of CPU the client uses"
})

local antiAfk = Groupboxes.PlayerOthers:AddToggle("AntiAfk", {
    Text = "Anti AFK",
    Default = true,
    Tooltip = "Prevents the game from kicking you for being idle/afk"
})

local autoRejoin = Groupboxes.PlayerOthers:AddToggle("AutoRejoin", {
    Text = "Auto Rejoin",
    Tooltip = "Auto rejoins the server if you get kicked/disconnected"
})

local rejoinButton = Groupboxes.PlayerOthers:AddButton("Rejoin", {
    Text = "Rejoin",
    Tooltip = "Rejoins the game",
    Func = rejoin
})

local serverHop = Groupboxes.PlayerOthers:AddButton("ServerHop", {
    Text = "Server Hop",
    Tooltip = "Teleports you to a different server",
    Func = function()
        -- credits for IY
        local servers = {}
        local request = game:HttpGet(`https://games.roblox.com/v1/games/{PlaceId}/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true`)
        local body = HttpService:JSONDecode(request)

        if body and body.data then
            for _, info in body.data do
                if type(info) == "table" and tonumber(info.playing) and tonumber(info.maxPlayers) and info.playing < info.maxPlayers and info.id ~= JobId then
                    table.insert(servers, 1, info.id)
                end
            end
        end

        if #servers > 0 then
            TeleportService:TeleportToPlaceInstance(PlaceId, servers[math.random(1, #servers)], Player)
        else
            Library:Notify({
                Title = "Server Hop",
                Description = "Couldn't find a server.",
                Time = 10
            })
        end
    end
})

Groupboxes.UISettingsGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "Open Keybind Menu",
	Callback = function(value)
		Library.KeybindFrame.Visible = value
	end,
})
Groupboxes.UISettingsGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = true,
	Callback = function(Value)
		Library.ShowCustomCursor = Value
	end,
})
Groupboxes.UISettingsGroup:AddDropdown("NotificationSide", {
	Values = { "Left", "Right" },
	Default = "Right",

	Text = "Notification Side",

	Callback = function(Value)
		Library:SetNotifySide(Value)
	end,
})
Groupboxes.UISettingsGroup:AddDropdown("DPIDropdown", {
	Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	Default = "100%",

	Text = "DPI Scale",

	Callback = function(Value)
		Value = Value:gsub("%%", "")
		local DPI = tonumber(Value)

		Library:SetDPIScale(DPI)
	end,
})
Groupboxes.UISettingsGroup:AddDivider()
Groupboxes.UISettingsGroup:AddLabel("Menu bind")
    :AddKeyPicker("MenuKeybind", { Text = "Menu keybind", Default = "RightShift", NoUI = true  })

Groupboxes.UISettingsGroup:AddButton("Unload", function()
	Library:Unload()
end)

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

fov:OnChanged(function(value)
    workspace.CurrentCamera.FieldOfView = value
end)

noclip:OnChanged(function(enabled)
    if noclipping then
        noclipping:Disconnect()
        noclipping = nil
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

fullBright:OnChanged(function(enabled)
    if brightLoop then
        brightLoop:Disconnect()
        brightLoop = nil
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

noRender:OnChanged(function(enabled)
    if enabled then
        RunService:Set3dRenderingEnabled(false)
    else
        RunService:Set3dRenderingEnabled(true)
    end
end)

antiAfk:OnChanged(function(enabled)
    if antiAfkConnection then
        antiAfkConnection:Disconnect()
        antiAfkConnection = nil
    end

    if #disabledRobloxConnections > 0 then
        for _, connection in disabledRobloxConnections do
            if connection.Enable then
                connection:Enable()
            end
        end
        table.clear(disabledRobloxConnections)
    end

    if not enabled then return end

    local getcon = getconnections
    if getcon then
        for _, connection in getcon(Player.Idled) do
            if connection.Disable then
                connection:Disable()
                table.insert(disabledRobloxConnections, connection)
            elseif connection.Disconnect then
                connection:Disconnect()
            end
        end
    else
        antiAfkConnection = Player.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton(Vector2.new())
        end)
    end
end)

autoRejoin:OnChanged(function(enabled)
    GuiService.ErrorMessageChanged:Connect(function()
        rejoin()
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
