repeat task.wait(1) until game:IsLoaded()

local GSP = "https://github.com/kelliark/test/blob/main/scripts/README.md"
local KEYSYS_URL = "https://raw.githubusercontent.com/almond0507/scripts/refs/heads/main/loader/keysys.lua"

local Games = {
    [99248392277037] = {
        name   = "Almond Hub | Untitled Melee RNG",
        script = "https://raw.githubusercontent.com/almond0507/scripts/refs/heads/main/UntitledMeleeRNG/UMR.lua",
    },
    [114640202062357] = {
        name   = "Almond Hub | Swing For Brainrot",
        script = "https://raw.githubusercontent.com/almond0507/scripts/refs/heads/main/UntitledMeleeRNG/SFB.lua",
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
        "Game Not Supported!\n\nVisit " .. GSP .. " to see what games are supported."
    )
    return
end

_G.AlmondHub = config
loadstring(game:HttpGet(KEYSYS_URL))()
