local code

local CodeGenerator = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vexx3/zylx-hub/refs/heads/main/ServerCodeGenerator.luau"))()

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"))()

local Options = Library.Options

local Window = Library:CreateWindow({
    Title = "Private Server Creator",
    Footer = "made by _zylx",
})

local Tabs = {
    Main = Window:AddTab("Main", "house"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

local Groupboxes = {
    PSInfo = Tabs.Main:AddLeftGroupbox("Private Server Info", "info"),
    PSGroupbox = Tabs.Main:AddRightGroupbox("Private Server", "server"),
}

Groupboxes.PSInfo:AddLabel(`Access Code: none`)

Groupboxes.PSGroupbox:AddButton("Create Private Server", function()
    code = CodeGenerator:GenerateReservedServerCode(game.PlaceId)
    Groupboxes.PSInfo:SetText(`Access Code: {code}`)
end)

Groupboxes.PSGroupbox:AddButton("Join Private Server", function()
    if code ~= nil then
        game.RobloxReplicatedStorage.ContactListIrisInviteTeleport:FireServer(game.PlaceId, "", code)
    end
end)

Groupboxes.PSGroupbox:AddButton("Copy Server Code", function()
    if setclipboard and code ~= nil then
        setclipboard(tostring(code))
    end
end)

Groupboxes.PSGroupbox:AddInput("ServerCodeInput", {
    Text = "Server Code",
    Placeholder = "Server Code to join",
})

Groupboxes.PSGroupbox:AddButton("Join Server Code", function()
    if Options.ServerCodeInput.Value ~= nil then
        game.RobloxReplicatedStorage.ContactListIrisInviteTeleport:FireServer(game.PlaceId, "", code)
    end
end)
