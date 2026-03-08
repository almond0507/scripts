repeat task.wait(1) until game:IsLoaded()

local DISCORD = "https://discord.gg/36Pf7W5hgd"
local KEYSYS_URL = "https://raw.githubusercontent.com/almond0507/scripts/refs/heads/main/loader/keysys.lua"

local Games = {
    [99248392277037] = {
        name   = "Almond Hub | Untitled Melee RNG",
        script = "https://raw.githubusercontent.com/almond0507/scripts/refs/heads/main/UntitledMeleeRNG/UMR.lua",
    },
}

local placeId = game.PlaceId
local config = nil

for id, cfg in pairs(Games) do
    if placeId == id then
        config = cfg
        break
    end
end

if not config then
    game:GetService("Players").LocalPlayer:Kick(
        "Game Not Supported!\n\nVisit " .. DISCORD .. " to see what games are supported."
    )
    return
end

_G.AlmondHub = config
loadstring(game:HttpGet(KEYSYS_URL))()
