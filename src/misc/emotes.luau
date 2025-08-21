local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local Library = loadstring(
	game:HttpGetAsync("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua")
)()

local currentAnimation

local function fetchEmoteIds()
	local url = "https://catalog.roblox.com/v1/search/items?category=12&subcategory=39&limit=100"
	local success, response = pcall(function()
		return HttpService:JSONDecode(game:HttpGetAsync(url))
	end)

	if not success then
		Library:Notify("Failed to fetch emotes", 5)
		return {}
	end

	local ids = {}

	for _, item in response.data do
		table.insert(ids, item.id)
	end

	return ids
end

local function fetchEmoteDetails(ids)
	local url = "https://catalog.roblox.com/v1/catalog/items/details"
	local requestData = {
		items = {},
	}

	for _, id in ids do
		table.insert(requestData.items, { itemType = 1, id = id })
	end

	local success, response = pcall(function()
		return HttpService:JSONDecode(game:HttpPostAsync(url, HttpService:JSONEncode(requestData)))
	end)

	if not success then
		Library:Notify("Failed to fetch emote details", 5)
		return {}
	end

	local emotes = {}

	for _, item in response.data do
		table.insert(emotes, { name = item.name, id = item.id })
	end

	return emotes
end

local function populateEmotes(dropdown)
	local ids = fetchEmoteIds()
	if #ids == 0 then
		return
	end

	local emotes = fetchEmoteDetails(ids)
	if #emotes == 0 then
		return
	end

	local dropdownValues = {}
	local emoteMap = {} -- id for callback
	for _, emote in emotes do
		table.insert(dropdownValues, emote.name)
		emoteMap[emote.name] = emote.id
	end

	dropdown:SetValues(dropdownValues)
	dropdown._emoteMap = emoteMap -- realll
end

local function playEmote(emoteId)
    local character = Player.Character or Player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end

    if currentAnimation then
        currentAnimation:Stop()
        currentAnimation = nil
    end

    local animation = Instance.new("Animation")
    animation.AnimationId = `rbxassetid://{emoteId}`

    local track = animator:LoadAnimation(animation)
    track:Play()
    currentAnimation = track
end

local function stopEmote()
    if currentAnimation then
        currentAnimation:Stop()
        currentAnimation = nil
    else
        Library:Notify("No emote playing", 5)
    end
end

-- UI (im too lazy to make a ui for the emotes so pls forgive me)

local Window = Library:CreateWindow({
	Title = "Zylx Hub | Emotes",
	Footer = "v0.0.1",
})

local Tabs = {
	Emotes = Window:AddTab("Emotes", "smile"),
}

local Groupboxes = {
	EmotesGroupbox = Tabs.Emotes:AddRightGroupbox("Play Emotes", "smile"),
}

local emoteDropdown = Groupboxes.EmotesGroupbox:AddDropdown("EmotesDropdown", {
	Text = "Emotes List",
	Searchable = true,
})

populateEmotes(emoteDropdown)

Groupboxes.EmotesGroupbox:AddButton({
	Text = "Play Emote",
	Func = function()
		local selectedName = emoteDropdown.Value
		local id = emoteDropdown._emoteMap and emoteDropdown._emoteMap[selectedName]

		if id then
			playEmote(id)
		else
			Library:Notify("No emote selected", 5)
		end
	end,
	Tooltip = "Plays the selected emote",
})

Groupboxes.EmotesGroupbox:AddButton({
	Text = "Stop Emote",
	Func = function()
		Library:Notify("Stopping emote", 5)
	end,
	Tooltip = "Stops the selected emote",
})
