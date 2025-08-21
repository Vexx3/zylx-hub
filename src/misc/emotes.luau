local HttpService = game:GetService("HttpService")

local WindUI = loadstring(game:HttpGetAsync("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local function fetchEmoteIds()
    local url = "https://catalog.roblox.com/v1/search/items?category=12&subcategory=39&limit=100"
    local success, response = pcall(function()
        return HttpService:JSONDecode(game:HttpGetAsync(url))
    end)

    if not success then
        WindUI:Notify({
            Title = "Emotes",
            Content = "Failed to fetch emotes"
        })
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
        items = {}
    }

    for _, id in ids do
        table.insert(requestData.items, { itemType = 1, id = id })
    end

    local success, response = pcall(function()
        return HttpService:JSONDecode(game:HttpPostAsync(url, HttpService:JSONEncode(requestData)))
    end)

    if not success then
        WindUI:Notify({ Title = "Emotes", Content = "Failed to fetch emote details" })
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
    if #ids == 0 then return end

    local emotes = fetchEmoteDetails(ids)
    if #emotes == 0 then return end

    local dropdownValues = {}
    local emoteMap = {} -- id for callback
    for _, emote in emotes do
        table.insert(dropdownValues, emote.name)
        emoteMap[emote.name] = emote.id
    end

    dropdown:SetValues(dropdownValues)
    dropdown._emoteMap = emoteMap
end

-- UI pls i hate my life (im too lazy to make a ui for this)

local Window = WindUI:CreateWindow({
    Title = "Zylx Hub | Emotes",
    Icon = "zap",
    Author = "by zylx",
    Folder = "EmoteHub",
    Transparent = true,

    --[[
    KeySystem = {
        Note = "Zylx Hub requires a key.",
        API = {
            {
                Type = "platoboost",
                ServiceId = 5748,
                Secret = "4b34ab81-c4c9-4427-9f0f-547a01be1c19"
            }
        }
    }
    ]]
})

Window:Tag({
    Title = "v0.0.1",
    Color = Color3.fromHex("#eb6734")
})

Window:Tag({
    Title = "Pre-release",
    Color = Color3.fromHex("#d61c32")
})

local Tabs = {
    Emotes = Window:Tab({ Title = "Emotes", Icon = "smile" })
}

local emoteDropdown -- me when type error
emoteDropdown = Tabs.Emotes:Dropdown({
    Title = "Emotes Menu",
    Values = {},
    Value = "",
    Callback = function(option)
        local id = emoteDropdown._emoteMap and emoteDropdown._emoteMap[option] or nil
        if id then
            print(`Selected: {option} (ID: {id})`)
        else
            print(`Selected: {option} (ID not found)`)
        end
    end
})

populateEmotes(emoteDropdown)

Tabs.Emotes:Button({
    Title = "Play Emote",
    Desc = "Plays the selected emote",
    Callback = function()
        local selectedName = emoteDropdown.Value
        local id = emoteDropdown._emoteMap and emoteDropdown._emoteMap[selectedName]
        if id then
            print(`Playing emote {selectedName} with ID {id}`)
        else
            WindUI:Notify({ Title = "Emotes", Content = "No emote selected" })
        end
    end
})

Tabs.Emotes:Button({
    Title = "Stop Emote",
    Desc = "Stops the currently playing emote",
    Callback = function()
        print("Stopping emote")
    end
})
