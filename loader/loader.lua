repeat task.wait(1) until game:IsLoaded()

local GSP = "https://pastebin.com/u/kelliark"
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
    [74277864669743] = {
        name   = "Almond Hub | Fly For Brainrots",
        script = "https://raw.githubusercontent.com/almond0507/scripts/refs/heads/main/UntitledMeleeRNG/FFB.lua",
    },
    [82031770257269] = {
        name   = "Almond Hub | Jump to steal lucky blocks",
        script = "https://raw.githubusercontent.com/almond0507/scripts/refs/heads/main/UntitledMeleeRNG/JTSLB.lua",
    },
    [124473577469410] = {
        name   = "Almond Hub | Be a lucky block",
        script = "https://raw.githubusercontent.com/almond0507/scripts/refs/heads/main/UntitledMeleeRNG/BALB.lua",
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
