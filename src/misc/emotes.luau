local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local Library = loadstring(
	game:HttpGetAsync("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua")
)()

local function fetchEmoteIds()
    local baseUrl = "https://catalog.roproxy.com/v1/search/items?category=12&subcategory=39&limit=100"
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
            Library:Notify("Failed to fetch emotes", 5)
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

        task.wait(0.2)
    end

    return ids
end

local function fetchEmoteDetails(ids)
    local url = "https://catalog.roproxy.com/v1/catalog/items/details"
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
                table.insert(emotes, { name = item.name, id = item.id })
            end
        else
            Library:Notify("Failed to fetch some emote details", 5)
        end

        task.wait(0.2)
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
	local emoteMap = {}
	for _, emote in emotes do
		table.insert(dropdownValues, emote.name)
		emoteMap[emote.name] = emote.id
	end

	dropdown:SetValues(dropdownValues)
	dropdown._emoteMap = emoteMap
end

local function playEmote(emoteId)
    local character = Player.Character or Player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local animation = humanoid:PlayEmoteAndGetAnimTrackById(emoteId)
    currentAnimation = animation
end

-- UI (im too lazy to make a ui for the emotes so pls forgive me)

local Window = Library:CreateWindow({
	Title = "Zylx Hub | Emotes Menu",
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
