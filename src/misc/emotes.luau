if getgenv().EmoteHub_Loaded then
    return
end

getgenv().EmoteHub_Loaded = true

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local Library = loadstring(
	game:HttpGetAsync("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua")
)()

local Options = Library.Options

local function fetchEmoteIds()
    local baseUrl = "https://catalog.roblox.com/v1/search/items?category=12&subcategory=39&limit=100"
    local cursor = nil
    local ids = {}

    while true do
        local url = baseUrl
        if cursor then
            url = url .. "&cursor=" .. cursor
        end

        local success, response = pcall(function()
            return HttpService:JSONDecode(game:HttpGetAsync(url))
        end)

        if not success or not response or not response.data then
            Library:Notify("Failed to fetch emotes")
            break
        end

        for _, item in response.data do
            table.insert(ids, item.id)
        end

        if response.nextPageCursor then
            cursor = response.nextPageCursor
        else
            break
        end
    end

    return ids
end

local function fetchEmoteDetails(ids)
    local url = "https://catalog.roblox.com/v1/catalog/items/details"
    local emotes = {}

    for i = 1, #ids, 50 do
        local batch = {}
        for j = i, math.min(i + 49, #ids) do
            table.insert(batch, { itemType = 1, id = ids[j] })
        end

        local success, response = pcall(function()
            return HttpService:JSONDecode(game:HttpPostAsync(url, HttpService:JSONEncode({ items = batch })))
        end)

        if success and response and response.data then
            for _, item in response.data do
                table.insert(emotes, { name = item.name, id = item.id, creator = item.creatorName })
            end
        else
            Library:Notify("Failed to fetch some emote details")
        end
    end

    return emotes
end

local function populateEmotes(dropdown)
    Library:Notify("Loading all emotes")
	local ids = fetchEmoteIds()
	if #ids == 0 then
		return
	end

	local emotes = fetchEmoteDetails(ids)
	if #emotes == 0 then
		return
	end

	local dropdownValues = {}
	local emoteMap = {}
	for _, emote in emotes do
		table.insert(dropdownValues, emote.name)
		emoteMap[emote.name] = emote
	end

	dropdown:SetValues(dropdownValues)
    Library:Notify("Loaded all emotes")
	dropdown._emoteMap = emoteMap
end

local function playEmote(emoteId)
    local character = Player.Character or Player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local success, animation = humanoid:PlayEmoteAndGetAnimTrackById(emoteId)
end

-- UI (im too lazy to make a ui for the emotes so pls forgive me)

local Window = Library:CreateWindow({
	Title = "<b><font color='#FFD700' size='20'>✨ Emotes <font color='#FFFFFF'>Hub</font></font></b>",
	Footer = "<font color='#888888' size='12'><i>Made with ❤️ by <font color='#FFD700'>_zylx</font></i></font>",
})

local Tabs = {
	Animations = Window:AddTab("Animations", "smile"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

local InfoGroup = Tabs.Animations:AddLeftGroupbox("Info", "info")
local AnimationsGroup = Tabs.Animations:AddRightGroupbox("Animations", "person-standing")
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")

local emoteDropdown = AnimationsGroup:AddDropdown("EmotesDropdown", {
	Text = "Emotes List",
	Searchable = true,
})

populateEmotes(emoteDropdown)

local emoteImage = InfoGroup:AddImage("EmoteImage", {
        Image = "rbxthumb://type=Asset&id=000000000&w=150&h=150",
        Height = 200,
})

local infoLabel = InfoGroup:AddLabel("<b><font color='#FFD700'>???</font></b>")

AnimationsGroup:AddButton({
	Text = "<b><font color='#FFFFFF'>Play</font> <font color='#FFD700'>Selected Emote</font></b>",
	Func = function()
		local selectedName = emoteDropdown.Value
		local data = emoteDropdown._emoteMap and emoteDropdown._emoteMap[selectedName]

		if data and data.id then
			playEmote(data.id)
		else
			Library:Notify("No emote selected")
		end
	end,
})

AnimationsGroup:AddDivider()

AnimationsGroup

emoteDropdown:OnChanged(function()
    local data = emoteDropdown._emoteMap and emoteDropdown._emoteMap[Options.EmotesDropdown.Value]
    if not data then return end

    local thumbUrl = string.format("rbxthumb://type=Asset&id=%d&w=150&h=150", data.id)
    emoteImage:SetImage(thumbUrl)

    infoLabel:SetText(string.format("<b><font color='#FFD700'>%s</font></b>", data.name))
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
