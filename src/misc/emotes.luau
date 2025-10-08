if getgenv().EmoteHub_Loaded then return end
getgenv().EmoteHub_Loaded = true

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local Library = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"))()

local Options = Library.Options

local function fetchPaginated(url)
    local results = {}
    local cursor = nil
    
	repeat
		local fullUrl = cursor and (url .. "&cursor=" .. cursor) or url
		local success, response = pcall(function()
			return HttpService:JSONDecode(game:HttpGetAsync(fullUrl))
		end)
        
		if not success or not response or not response.data then
            break
        end
        
		for _, item in response.data do
            table.insert(results, item)
        end
        
		cursor = response.nextPageCursor
	until not cursor
    
	return results
end

local function fetchAnimationBundles()
	local bundles = fetchPaginated("https://catalog.roblox.com/v1/search/items?category=12&subcategory=38&limit=100&IncludeNotForSale=true")
    
	local ids = {}
	for _, b in bundles do
        table.insert(ids, b.id)
    end
    
	return ids
end

local function fetchEmoteIds()
	local items = fetchPaginated("https://catalog.roblox.com/v1/search/items?category=12&subcategory=39&limit=100&IncludeNotForSale=true")
    
	local ids = {}
	for _, item in items do
        table.insert(ids, item.id)
    end
    
	return ids
end

local function fetchEmoteDetails(ids)
    local emotes = {}

    for _, id in ipairs(ids) do
        local url = `https://catalog.roblox.com/v1/catalog/items/{id}/details?itemType=Asset`
        local success, response = pcall(function()
            return HttpService:JSONDecode(game:HttpGetAsync(url))
        end)

        if success and response then
            table.insert(emotes, {
                id = response.id,
                name = response.name,
                creator = response.creatorName
            })
        else
            Library:Notify(`Failed to fetch emote ID {id}`)
        end
    end

    return emotes
end

local function fetchBundleDetails(bundleIds)
	local bundles = {}
    
	for _, id in bundleIds do
		local success, response = pcall(function()
			local url = `https://catalog.roblox.com/v1/bundles/{id}/details`
			return HttpService:JSONDecode(game:HttpGetAsync(url))
		end)
        
		if success and response and response.items then
			table.insert(bundles, { id = response.id, name = response.name, items = response.items })
		end
	end
    
	return bundles
end

local function extractAnimationsFromBundle(bundle)
	local animations = {}
    
	for _, item in bundle.items do
		if item.type == "Asset" then
			local success, objs = pcall(function()
				return game:GetObjects(("rbxassetid://%d"):format(item.id))
			end)
            
			if success and objs and objs[1] then
				for _, inst in objs[1]:GetDescendants() do
					if inst:IsA("Animation") then
						table.insert(animations, { name = inst.Name, id = inst.AnimationId, fromBundle = bundle.name })
					end
				end
			end
		end
	end
    
	return animations
end

local function populateDropdownWithEmotes(dropdown)
	local ids = fetchEmoteIds()
	if #ids == 0 then return end
    
	local emotes = fetchEmoteDetails(ids)
    
	local map = {}
    local values = {}
    
	for _, e in pairs(emotes) do
		table.insert(values, e.name)
		map[e.name] = e
	end
    
	dropdown:SetValues(values)
	dropdown._emoteMap = map
end

local function populateDropdownWithBundles(dropdown)
	local bundleIds = fetchAnimationBundles()
	if #bundleIds == 0 then return end
    
	local bundles = fetchBundleDetails(bundleIds)
    
	local map = {}
    local values = {}
    
	for _, b in bundles do
		table.insert(values, b.name)
		map[b.name] = b
	end
    
	dropdown:SetValues(values)
	dropdown._bundleMap = map
end

local function playEmote(emoteId)
	local char = Player.Character or Player.CharacterAdded:Wait()
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid:PlayEmoteAndGetAnimTrackById(emoteId) end
end

local function applyAnimationPack(bundle)
	local animations = extractAnimationsFromBundle(bundle)
	if not animations or #animations == 0 then return end

	local char = Player.Character or Player.CharacterAdded:Wait()
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local animate = char:FindFirstChild("Animate")
	if not humanoid or not animate then return end

	local animMap = {
		idle = { "Animation1", "Animation2" },
		walk = { "WalkAnim" },
		run = { "RunAnim" },
		jump = { "JumpAnim" },
		fall = { "FallAnim" },
		climb = { "ClimbAnim" },
		swim = { "Swim" },
		swimidle = { "SwimIdle" },
	}

	local idleIds = {}
	for _, anim in animations do
		local n = anim.name:lower()
		if not (n:find("walk") or n:find("run") or n:find("jump") or n:find("fall") or n:find("climb") or n:find("swim")) then
			table.insert(idleIds, anim.id)
		end
	end
    
	local idleSlot = animate:FindFirstChild("idle")
	if idleSlot then
		for i = 1, 2 do
			local obj = idleSlot:FindFirstChild(`Animation{i}`)
			if obj then
                obj.AnimationId = idleIds[i] or obj.AnimationId
            end
		end
	end

	for typeName, animNames in animMap do
		if typeName == "idle" then continue end
        
		local parent = animate:FindFirstChild(typeName)
		if not parent then continue end
        
		for _, animName in animNames do
			local obj = parent:FindFirstChild(animName)
			if obj and obj:IsA("Animation") then
				for _, anim in animations do
					local n = anim.name:lower()
					if typeName == "swim" or typeName == "swimidle" then
						if n == typeName then 
                            obj.AnimationId = anim.id
                            break
                        end
					elseif n:find(typeName) then
						obj.AnimationId = anim.id
                        break
					end
				end
			end
		end
	end

	Library:Notify("Animation pack applied!")
end

local Window = Library:CreateWindow({
	Title = "<b><font color='#FFD700' size='20'>✨ Emotes <font color='#FFFFFF'>Hub</font></font></b>",
	Footer = "<font color='#888888' size='12'><i>Made with ❤️ by <font color='#FFD700'>_zylx</font></i></font>",
})

local Tabs = {
	Animations = Window:AddTab("Animations", "smile"),
	UISettings = Window:AddTab("UI Settings", "settings")
}

local InfoGroup = Tabs.Animations:AddLeftGroupbox("Info", "info")
local AnimGroup = Tabs.Animations:AddRightGroupbox("Animations", "person-standing")
local MenuGroup = Tabs.UISettings:AddLeftGroupbox("Menu", "wrench")

local emoteDropdown = AnimGroup:AddDropdown("EmotesDropdown", {
    Text = "Emotes List",
    Searchable = true
})
local animDropdown = AnimGroup:AddDropdown("AnimDropdown", {
    Text = "Animation Pack List",
    Searchable = true 
})

local animImage = InfoGroup:AddImage("animImage", {
    Image = "rbxthumb://type=Asset&id=0&w=150&h=150",
    Height=200 
})
local infoLabel = InfoGroup:AddLabel("<b><font color='#FFD700'>???</font></b>")

AnimationsGroup:AddButton({
	Text = "<b><font color='#FFFFFF'>Play</font> <font color='#FFD700'>Selected Emote</font></b>",
	Func = function()
		local name = emoteDropdown.Value
		local data = emoteDropdown._emoteMap and emoteDropdown._emoteMap[name]
		if data then
            playEmote(data.id)
        else 
            Library:Notify("No emote selected")
        end
	end
})

AnimationsGroup:AddButton({
	Text = "<b><font color='#FFFFFF'>Apply</font> <font color='#FFD700'>Selected Animation Pack</font></b>",
	Func = function()
		local name = animDropdown.Value
		local bundle = animDropdown._bundleMap and animDropdown._bundleMap[name]
		if bundle then 
            applyAnimationPack(bundle)
        else 
            Library:Notify("No animation pack selected.")
        end
	end
})

emoteDropdown:OnChanged(function()
	local data = emoteDropdown._emoteMap and emoteDropdown._emoteMap[Options.EmotesDropdown.Value]
	if data then
		animImage:SetImage(`rbxthumb://type=Asset&id={data.id}&w=150&h=150`)
		infoLabel:SetText(`<b><font color='#FFD700'>{data.name}</font></b>`)
	end
end)

animDropdown:OnChanged(function()
	local bundle = animDropdown._bundleMap and animDropdown._bundleMap[Options.AnimDropdown.Value]
	if bundle then
		animImage:SetImage(`rbxthumb://type=BundleThumbnail&id={bundle.id}&w=150&h=150`)
		infoLabel:SetText(`<b><font color='#FFD700'>{bundle.name}</font></b>`)
	end
end)

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

Library.ToggleKeybind = Options.MenuKeybind

populateDropdownWithEmotes(emoteDropdown)
populateDropdownWithBundles(animDropdown)
