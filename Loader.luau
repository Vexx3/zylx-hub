local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = cloneref(game:GetService("VirtualUser"))

type Connections = {
    brightLoop: RBXScriptConnection?,
    noclipping: RBXScriptConnection?,
    antiAfkConnection: RBXScriptConnection?,
    autoRejoinConnection: RBXScriptConnection?,
    infJumpConnection: RBXScriptConnection?,
    promptButtonHoldBegan: RBXScriptConnection?,
    staffWatchJoin: RBXScriptConnection?,
}

type HumanoidConnectionTable = {
    WalkSpeed: { RBXScriptConnection },
    JumpPower: { RBXScriptConnection }
}

local HumanoidConnections: HumanoidConnectionTable = {
    WalkSpeed = {},
    JumpPower = {}
}

local connections: Connections = {
    brightLoop = nil,
    noclipping = nil,
    antiAfkConnection = nil,
    autoRejoinConnection = nil,
    infJumpConnection = nil,
    promptButtonHoldBegan = nil,
    staffWatchJoin = nil,
}

local disabledRobloxConnections: { RBXScriptConnection } = {}

local GROUP_ID = 1200769
local STAFF_RANK: {string} = {"Core", "Group Lead - Create", "Group Lead", "Town Hall Leads", "Town Hall Collaborators", "Intern"}

local Player = Players.LocalPlayer

local Terrain = workspace:FindFirstChildOfClass("Terrain")

local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")

local originalWalkSpeed = Humanoid.WalkSpeed
local originalJumpValue = if Humanoid.UseJumpPower then Humanoid.JumpPower else Humanoid.JumpHeight
local originalFOV = workspace.CurrentCamera.FieldOfView

local PlaceId = game.PlaceId
local JobId = game.JobId

local infJumpDebounce = false

local function removeConnection(connectionName: keyof<Connections>)
    local connection = connections[connectionName]
    if connection then
        connection:Disconnect()
        connections[connectionName] = nil
    end
end

local function rejoin()
    if #Players:GetPlayers() <= 1 then
        Player:Kick("\nRejoining...")
        task.wait()
        TeleportService:Teleport(PlaceId, Player)
    else
        TeleportService:TeleportToPlaceInstance(PlaceId, JobId, Player)
    end
end

local function getStaffRole(player: Player)
    local result: { Role: string?, Staff: boolean? } = {}
    if player:IsInGroup(GROUP_ID) then
        local role = player:GetRoleInGroup(GROUP_ID)
        for _, staffRole in STAFF_RANK do
            if role == staffRole then
                result.Role = staffRole
                result.Staff = true
            end
        end
    end

    return result
end

local function formatUsername(player: Player): string
    if player.DisplayName ~= player.Name then
        return `player.Name ({player.DisplayName})`
    end
    return player.Name
end

local function doStaffAction(action: "Kick" | "Shutdown" | "Notify", staffList: {string})
    if action == "Kick" then
        Player:Kick(table.concat(staffList, ",\n"))
    elseif action == "Shutdown" then
        game:Shutdown()
    elseif action == "Notify" then
        Library:Notify({
            Title = "Anti Mod",
            Description = table.concat(staffList, ",\n"),
            Time = 10
        })
    end
end

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(`{repo}Library.lua`))()
local ThemeManager = loadstring(game:HttpGet(`{repo}addons/ThemeManager.lua`))()
local SaveManager = loadstring(game:HttpGet(`{repo}addons/SaveManager.lua`))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.NotifyOnError = true

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
    General = Tabs.Player:AddLeftGroupbox("General", "user-round-plus"),
    Game = Tabs.Player:AddRightGroupbox("Game", "eye"),
    Server = Tabs.Player:AddLeftGroupbox("Server", "server"),
    Safety = Tabs.Player:AddRightGroupbox("Safety", "shield"),
    UISettingsGroup = Tabs.UISettings:AddLeftGroupbox("Menu", "wrench"),
}

local walkSpeed = Groupboxes.General:AddDependencyBox()
local jumpPower = Groupboxes.General:AddDependencyBox()
local fov = Groupboxes.General:AddDependencyBox()

local walkSpeedToggle = Groupboxes.General:AddToggle("walkSpeedToggle", {
    Text = "WalkSpeed",
    Tooltip = "Change your walkspeed"
})

local jumpPowerToggle = Groupboxes.General:AddToggle("jumpPowerToggle", {
    Text = "Jump Power",
    Tooltip = "Change your jump power"
})

local fovToggle = Groupboxes.General:AddToggle("fovToggle", {
    Text = "FOV",
    Tooltip = "Adjusts field of view"
})

walkSpeed:SetupDependencies({
    { Toggles.walkSpeedToggle, true }
})

jumpPower:SetupDependencies({
    { Toggles.jumpPowerToggle, true }
})

fov:SetupDependencies({
    { Toggles.fovToggle, true }
})

local walkSpeedSlider = walkSpeed:AddSlider("WalkSpeedSlider", {
    Text = "WalkSpeed",
    Default = Humanoid.WalkSpeed,
    Min = Humanoid.WalkSpeed,
    Max = 300
})

local jumpPowerSlider = jumpPower:AddSlider("JumpPowerSlider", {
    Text = "Jump Power",
    Default = Humanoid.UseJumpPower and Humanoid.JumpPower or Humanoid.JumpHeight,
    Min = Humanoid.UseJumpPower and Humanoid.JumpPower or Humanoid.JumpHeight,
    Max = 300
})

local fovSlider = fov:AddSlider("FOVSlider", {
    Text = "FOV",
    Default = workspace.CurrentCamera.FieldOfView,
    Max = 120
})

local noclip = Groupboxes.General:AddToggle("Noclip", {
    Text = "Noclip",
    Tooltip = "Allows you to go through objects"
})

local infJump = Groupboxes.General:AddToggle("InfJump", {
    Text = "Infinite Jump",
    Tooltip = "Allows you to jump multiple times before hitting the ground"
})

local instantPrompt = Groupboxes.General:AddToggle("Instant Prompt", {
    Text = "Instant Prompt",
    Tooltip = "Disable the cooldown for proximity prompts"
})

local fullBright = Groupboxes.Game:AddToggle("FullBright", {
    Text = "Full Bright",
    Tooltip = "Makes the map brighter / more visible"
})

local noRender = Groupboxes.Game:AddToggle("NoRender", {
    Text = "No Render",
    Tooltip = "Disable 3d rendering to decrease the amount of CPU the client uses"
})

local lowGraphics = Groupboxes.Game:AddButton("LowGraphics", {
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

local noFog = Groupboxes.Game:AddButton("NoFog", {
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

local antiAfk = Groupboxes.Server:AddToggle("AntiAfk", {
    Text = "Anti AFK",
    Default = true,
    Tooltip = "Prevents the game from kicking you for being idle/afk"
})

local autoRejoin = Groupboxes.Server:AddToggle("AutoRejoin", {
    Text = "Auto Rejoin",
    Default = true,
    Tooltip = "Auto rejoins the server if you get kicked/disconnected"
})

local rejoinButton = Groupboxes.Server:AddButton("Rejoin", {
    Text = "Rejoin",
    Tooltip = "Rejoins the game",
    Func = rejoin
})

local serverHop = Groupboxes.Server:AddButton("ServerHop", {
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

local antiMod = Groupboxes.Safety:AddToggle("AntiMod", {
    Text = "Anti Mod",
    Default = true,
    Tooltip = "Checks if a staff member of the game joins the server then do the action",
    DisabledTooltip = "Game is not owned by a group"
})

local actionMod = Groupboxes.Safety:AddDropdown("ActionMod", {
    Values = {"Shutdown", "Kick", "Notify"},
    Default = "Kick",
    Tooltip = "Action to do if the staff is in the game",
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

local function disconnectConnections(list: { RBXScriptConnection })
    for _, connection in list do
        connection:Disconnect()
    end
    table.clear(list)
end

local function updateWalkSpeed(speed: number)
    if Humanoid then
        Humanoid.WalkSpeed = speed
    end
end

local function updateJumpPower(power: number)
    if Humanoid then
        if Humanoid.UseJumpPower then
            Humanoid.JumpPower = power
        else
            Humanoid.JumpHeight = power
        end
    end
end

local function setupWalkSpeed(speed: number)        
    disconnectConnections(HumanoidConnections.WalkSpeed)
    updateWalkSpeed(speed)

    table.insert(HumanoidConnections.WalkSpeed, Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        updateWalkSpeed(speed)
    end))
end

local function setupJumpPower(power: number)    
    disconnectConnections(HumanoidConnections.JumpPower)
    updateJumpPower(power)

    local typeOfJump = if Humanoid.UseJumpPower then "JumpPower" else "JumpHeight" 

    table.insert(HumanoidConnections.JumpPower, Humanoid:GetPropertyChangedSignal(typeOfJump):Connect(function()
        updateJumpPower(power)
    end))
end

walkSpeedToggle:OnChanged(function(enabled)
    if enabled then
        setupWalkSpeed(Options.WalkSpeedSlider.Value)
    else
        disconnectConnections(HumanoidConnections.WalkSpeed)
        updateWalkSpeed(originalWalkSpeed)
    end
end)

jumpPowerToggle:OnChanged(function(enabled)
    if enabled then
        setupJumpPower(Options.JumpPowerSlider.Value)
    else
        disconnectConnections(HumanoidConnections.JumpPower)
        updateJumpPower(originalJumpValue)
    end
end)

fovToggle:OnChanged(function(enabled)
    if enabled then
        workspace.CurrentCamera.FieldOfView = Options.FOVSlider.Value
    else
        workspace.CurrentCamera.FieldOfView = originalFOV
    end
end)

walkSpeedSlider:OnChanged(function(value)
    setupWalkSpeed(value)
end)

jumpPowerSlider:OnChanged(function(value)
    setupJumpPower(value)
end)

fovSlider:OnChanged(function(value)
    workspace.CurrentCamera.FieldOfView = value
end)

noclip:OnChanged(function(enabled)
    removeConnection("noclipping")
    
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
    removeConnection("infJumpConnection")

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

instantPrompt:OnChanged(function(enabled)
    removeConnection("promptButtonHoldBegan")

    if not enabled then return end

    if fireproximityprompt then
        promptButtonHoldBegan = ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
            fireproximityprompt(prompt)
        end)
    else
        Library:Notify({
            Title = "Incompatible Exploit",
            Description = "Your exploit does not support this feature (missing fireproximityprompt)",
            Time = 10
        })
    end
end)

fullBright:OnChanged(function(enabled)
    removeConnection("brightLoop")

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

local function setupAntiAfk(enabled: boolean)
    removeConnection("antiAfkConnection")

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
end

local function setupAutoRejoin(enabled: boolean)
    removeConnection("autoRejoinConnection")

    if not enabled then return end
    
    autoRejoinConnection = GuiService.ErrorMessageChanged:Connect(function()
        rejoin()
    end)
end

local function setupAutoMod(enabled: boolean)
    removeConnection("staffWatchJoin")

    if not enabled then return end

    if game.CreatorType ~= Enum.CreatorType.Group then
        antiMod:SetValue(false)
        antiMod:Disabled(true)
        return
    end

    local found: {string} = {}

    staffWatchJoin = Players.PlayerAdded:Connect(function(player)
        local result = getStaffRole(player)
        if result.Staff then
            doStaffAction(Options.ActionMod.Value, found)
        end
    end)
        
    for _, player in Players:GetPlayers() do
        local result = getStaffRole(player)
        if result.Staff then
            table.insert(found, `{formatUsername} is a {result.Role}`)
            doStaffAction(Options.ActionMod.Value, found)
        end
    end

    if #found > 0 then
        doStaffAction(Options.ActionMod.Value, found)
    end
end

antiAfk:OnChanged(function(enabled)
    setupAntiAfk(enabled)
end)

autoRejoin:OnChanged(function(enabled)
    setupAutoRejoin(enabled)
end)

antiMod:OnChanged(function(enabled)
    setupAutoMod(enabled)
end)

Player.CharacterAdded:Connect(function(character)
    Character = character
    Humanoid = character:WaitForChild("Humanoid")

    local walkSpeedValue = if Toggles.walkSpeedToggle.Value then Options.WalkSpeedSlider.Value else originalWalkSpeed
    local jumpPowerValue = if Toggles.jumpPowerToggle.Value then Options.JumpPowerSlider.Value else originalJumpValue

    setupWalkSpeed(walkSpeedValue)
    setupJumpPower(jumpPowerValue)
end)

setupAntiAfk(Toggles.AntiAfk.Value)
setupAutoRejoin(Toggles.AutoRejoin.Value)
setupAutoMod(Toggles.AntiMod.Value)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:BuildConfigSection(Tabs.UISettings)

ThemeManager:ApplyToTab(Tabs.UISettings)
SaveManager:LoadAutoloadConfig()
