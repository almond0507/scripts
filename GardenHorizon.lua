-- Garden Horizon Script Hub
-- Uses Rayfield UI

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Rayfield
local CONFIG_DIR = "GardenHorizon"
local CONFIG_FILE = CONFIG_DIR .. "/hub_state_v1.json"
local unpackArgs = table.unpack or unpack

local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local RF_SellItems = Remotes:WaitForChild("SellItems")
local RF_ClaimSoftlockCash = Remotes:WaitForChild("ClaimSoftlockCash")
local RF_PlantSeed = Remotes:WaitForChild("PlantSeed")
local RE_HarvestFruit = Remotes:WaitForChild("HarvestFruit")
local RF_PurchaseShopItem = Remotes:WaitForChild("PurchaseShopItem")
local RE_UseGear = Remotes:WaitForChild("UseGear")
local RE_RequestQuests = Remotes:WaitForChild("RequestQuests")
local RE_UpdateQuests = Remotes:WaitForChild("UpdateQuests")
local RE_ClaimQuest = Remotes:WaitForChild("ClaimQuest")
local RE_PurchaseQuestRefresh = Remotes:WaitForChild("PurchaseSingleRefresh")
local RE_UnseatPlayer = Remotes:WaitForChild("UnseatPlayer")

local ItemInventory = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("ItemInventory"))
local SeedShopData = require(ReplicatedStorage:WaitForChild("Shop"):WaitForChild("ShopData"):WaitForChild("SeedShopData")).ShopData
local GearShopData = require(ReplicatedStorage:WaitForChild("Shop"):WaitForChild("ShopData"):WaitForChild("GearShopData")).ShopData
local PlantData = require(ReplicatedStorage:WaitForChild("Plants"):WaitForChild("Definitions"):WaitForChild("PlantDataDefinitions"))
local FruitValueCalculator = require(ReplicatedStorage:WaitForChild("Economy"):WaitForChild("FruitValueCalculator"))

local function safeInvoke(remote, ...)
    local args = table.pack(...)
    local ok, result = pcall(function()
        return remote:InvokeServer(unpackArgs(args, 1, args.n))
    end)
    if ok then
        return result
    end
    return nil
end

local function safeFire(remote, ...)
    local args = table.pack(...)
    pcall(function()
        remote:FireServer(unpackArgs(args, 1, args.n))
    end)
end

local function canUseFileApi()
    return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end

local function safeNotify(title, content, duration)
    if Rayfield and Rayfield.Notify then
        Rayfield:Notify({
            Title = title,
            Content = content,
            Duration = duration or 4
        })
    end
end

local function findToolByName(name)
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChild(name)
        if tool and tool:IsA("Tool") then
            return tool, true
        end
    end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        local tool = backpack:FindFirstChild(name)
        if tool and tool:IsA("Tool") then
            return tool, false
        end
    end
    return nil, false
end

local function equipTool(tool)
    if not tool then
        return
    end
    local char = LocalPlayer.Character
    if not char then
        return
    end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:EquipTool(tool)
    end
end

local function getRoot()
    local char = LocalPlayer.Character
    if not char then
        return nil
    end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = LocalPlayer.Character
    if not char then
        return nil
    end
    return char:FindFirstChildOfClass("Humanoid")
end

local function teleportToPart(part, yOffset)
    if not part then
        return
    end
    local char = LocalPlayer.Character
    local humanoid = getHumanoid()
    local root = getRoot()
    if not (char and humanoid and root) then
        return
    end
    if humanoid:GetAttribute("IsRagdolled") == true then
        return
    end
    pcall(function()
        RE_UnseatPlayer:FireServer()
    end)
    root.Anchored = true
    root.CFrame = part.CFrame * CFrame.new(0, yOffset or 3, 0)
    root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    task.wait(0.05)
    root.Anchored = false
end

local function getOwnPlot()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then
        return nil
    end
    for _, plot in ipairs(plots:GetChildren()) do
        if plot:IsA("Model") and plot:GetAttribute("Owner") == LocalPlayer.UserId then
            return plot
        end
    end
    return nil
end

local function teleportToGarden()
    local plot = getOwnPlot()
    if not plot then
        return
    end
    local spawn = plot:FindFirstChild("Spawn")
    if spawn then
        spawn = spawn:FindFirstChild("Spawn") or spawn
    end
    if spawn and spawn:IsA("BasePart") then
        teleportToPart(spawn, 3.5)
    end
end

local function teleportToSeeds()
    local map = workspace:FindFirstChild("MapPhysical")
    local teleports = map and map:FindFirstChild("Teleports")
    local part = teleports and teleports:FindFirstChild("SeedsTeleport")
    if part then
        teleportToPart(part, 3)
    end
end

local function teleportToGears()
    local map = workspace:FindFirstChild("MapPhysical")
    local teleports = map and map:FindFirstChild("Teleports")
    local part = teleports and (teleports:FindFirstChild("GearTeleport") or teleports:FindFirstChild("GearsTeleport") or teleports:FindFirstChild("SeedsTeleport"))
    if part then
        teleportToPart(part, 3)
    end
end

local function teleportToSell()
    local map = workspace:FindFirstChild("MapPhysical")
    local teleports = map and map:FindFirstChild("Teleports")
    local part = teleports and teleports:FindFirstChild("SellTeleport")
    if part then
        teleportToPart(part, 3)
    end
end

local function teleportToQuestBoard()
    local map = workspace:FindFirstChild("MapPhysical")
    local board = map and map:FindFirstChild("QuestBoard")
    if board then
        if board:IsA("BasePart") then
            teleportToPart(board, 3)
            return
        end
        if board:IsA("Model") then
            local part = board:FindFirstChildWhichIsA("BasePart", true)
            if part then
                teleportToPart(part, 3)
            end
        end
    end
end

local function getShillings()
    local stats = LocalPlayer:FindFirstChild("leaderstats")
    local shillings = stats and stats:FindFirstChild("Shillings")
    if shillings then
        return shillings.Value
    end
    return 0
end

local function getToolCount()
    local count = 0
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                count = count + 1
            end
        end
    end
    local char = LocalPlayer.Character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") then
                count = count + 1
            end
        end
    end
    return count
end

local function findSeedTool(plantType)
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and item:GetAttribute("PlantType") == plantType and not item:GetAttribute("IsHarvested") then
                return item
            end
        end
    end
    local char = LocalPlayer.Character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") and item:GetAttribute("PlantType") == plantType and not item:GetAttribute("IsHarvested") then
                return item
            end
        end
    end
    return nil
end

local function getEquippedPlantType()
    local char = LocalPlayer.Character
    if not char then
        return nil
    end
    local tool = char:FindFirstChildWhichIsA("Tool")
    if tool then
        return tool:GetAttribute("PlantType")
    end
    return nil
end

local function getPlantableParts()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then
        return {}
    end
    for _, plot in ipairs(plots:GetChildren()) do
        if plot:IsA("Model") and plot:GetAttribute("Owner") == LocalPlayer.UserId then
            local plantable = plot:FindFirstChild("PlantableArea")
            if not plantable then
                return {}
            end
            local parts = {}
            for _, part in ipairs(plantable:GetChildren()) do
                if part:IsA("BasePart") then
                    table.insert(parts, part)
                end
            end
            return parts
        end
    end
    return {}
end

local function buildPlantPositions(spacing)
    local positions = {}
    local parts = getPlantableParts()
    for _, part in ipairs(parts) do
        local size = part.Size
        local cf = part.CFrame
        local step = math.max(1, spacing)
        for x = -size.X / 2 + step / 2, size.X / 2 - step / 2, step do
            for z = -size.Z / 2 + step / 2, size.Z / 2 - step / 2, step do
                local pos = (cf * CFrame.new(x, 0, z)).Position
                pos = pos + cf.UpVector * (size.Y / 2)
                table.insert(positions, pos)
            end
        end
    end
    for i = #positions, 2, -1 do
        local j = math.random(i)
        positions[i], positions[j] = positions[j], positions[i]
    end
    return positions
end

local function getPlayerPlantPosition()
    local root = getRoot()
    if not root then
        return nil
    end

    local plantableParts = getPlantableParts()
    if #plantableParts == 0 then
        return nil
    end

    local rootPos = root.Position

    for _, part in ipairs(plantableParts) do
        local localPos = part.CFrame:PointToObjectSpace(rootPos)
        local halfX = part.Size.X * 0.5
        local halfZ = part.Size.Z * 0.5
        if math.abs(localPos.X) <= halfX and math.abs(localPos.Z) <= halfZ then
            local surfaceLocal = Vector3.new(
                math.clamp(localPos.X, -halfX, halfX),
                part.Size.Y * 0.5,
                math.clamp(localPos.Z, -halfZ, halfZ)
            )
            return part.CFrame:PointToWorldSpace(surfaceLocal)
        end
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = { LocalPlayer.Character }
    local hit = workspace:Raycast(rootPos + Vector3.new(0, 2, 0), Vector3.new(0, -20, 0), rayParams)
    if hit then
        for _, part in ipairs(plantableParts) do
            if hit.Instance == part then
                return hit.Position
            end
        end
    end

    return nil
end

local function getHarvestData(prompt)
    if not (prompt and prompt.Parent) then
        return nil, nil
    end
    local model = prompt.Parent
    if model:IsA("BasePart") then
        model = model.Parent
    end
    if not (model and model:IsA("Model")) then
        return nil, nil
    end
    if model:GetAttribute("HarvestablePlant") == true then
        local uuid = model:GetAttribute("Uuid")
        if uuid then
            return { Uuid = uuid }, model
        end
    end
    local parent = model.Parent
    if not (parent and parent:IsA("Model")) then
        return nil, model
    end
    local uuid = parent:GetAttribute("Uuid")
    if uuid then
        return { Uuid = uuid, GrowthAnchorIndex = model:GetAttribute("GrowthAnchorIndex") }, model
    end
    return nil, model
end

local function isOwned(model)
    if not model then
        return false
    end
    local owner = model:GetAttribute("OwnerUserId")
    if not owner and model.Parent and model.Parent:IsA("Model") then
        owner = model.Parent:GetAttribute("OwnerUserId")
    end
    return owner == LocalPlayer.UserId
end

local function isFavorited(model)
    if not model then
        return false
    end
    if model:GetAttribute("Favorited") then
        return true
    end
    if model.Parent and model.Parent:IsA("Model") and model.Parent:GetAttribute("Favorited") then
        return true
    end
    return false
end

local function getMutation(model)
    if not model then
        return nil
    end
    local mutation = model:GetAttribute("Mutation")
    if mutation and mutation ~= "" then
        return mutation
    end
    if model.Parent and model.Parent:IsA("Model") then
        local mutationParent = model.Parent:GetAttribute("Mutation")
        if mutationParent and mutationParent ~= "" then
            return mutationParent
        end
    end
    return nil
end

local function getMutationAny(model)
    local mutation = getMutation(model)
    if mutation then
        return mutation
    end
    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("Model") then
            local childMutation = getMutation(child)
            if childMutation then
                return childMutation
            end
        end
    end
    return nil
end

local function isHarvestItem(tool)
    if tool:GetAttribute("IsHarvested") then
        return true
    end
    if tool:GetAttribute("HarvestedFrom") then
        return true
    end
    if tool:GetAttribute("FruitValue") then
        return true
    end
    return false
end

local function getToolBaseName(tool)
    local harvested = tool:GetAttribute("HarvestedFrom")
    if harvested then
        return harvested
    end
    local base = tool:GetAttribute("BaseName") or tool.Name
    base = tostring(base)
    base = base:gsub("^x%d+%s+", "")
    return base
end

local function buildToolCounts()
    local counts = {}
    local function addTool(tool)
        if tool:IsA("Tool") and isHarvestItem(tool) then
            local base = getToolBaseName(tool)
            if base and base ~= "" then
                counts[base] = (counts[base] or 0) + (tool:GetAttribute("ItemCount") or 1)
            end
        end
    end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            addTool(tool)
        end
    end
    local char = LocalPlayer.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            addTool(tool)
        end
    end
    return counts
end

local function collectTools()
    local list = {}
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(list, tool)
            end
        end
    end
    local char = LocalPlayer.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(list, tool)
            end
        end
    end
    return list
end

local function getKeepLimit(base)
    if state.keepList and #state.keepList > 0 then
        for _, name in ipairs(state.keepList) do
            if name == base then
                return state.keepAmountSelected or 0
            end
        end
    end
    return state.keepAmountOthers or 0
end

local function countSpecialPlants()
    local mutationCount = 0
    local giantCount = 0
    for _, plant in ipairs(CollectionService:GetTagged("Plant")) do
        if plant:IsA("Model") and plant:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
            if plant:GetAttribute("FullyGrown") then
                if getMutationAny(plant) then
                    mutationCount = mutationCount + 1
                end
                if plant:GetAttribute("IsGiant") then
                    giantCount = giantCount + 1
                end
            end
        end
    end
    return mutationCount, giantCount
end

local function getFavoriteTarget(model)
    if not model then
        return nil, nil
    end
    if model:GetAttribute("HarvestablePlant") then
        local uuid = model:GetAttribute("Uuid")
        return uuid, nil
    end
    local uuid = model:GetAttribute("Uuid")
    if uuid then
        return uuid, nil
    end
    local parent = model.Parent
    if parent and parent:IsA("Model") then
        local parentUuid = parent:GetAttribute("Uuid")
        if parentUuid then
            return parentUuid, model:GetAttribute("GrowthAnchorIndex")
        end
    end
    return nil, nil
end

local plantTypes = {}
for plantType in pairs(PlantData) do
    table.insert(plantTypes, plantType)
end
table.sort(plantTypes)

local seedShopItems = {}
local plantTypeToShopName = {}
local seedShopPrices = {}
for plantType, data in pairs(SeedShopData) do
    local name = data.Name or plantType
    table.insert(seedShopItems, name)
    plantTypeToShopName[plantType] = name
    seedShopPrices[name] = data.Price or 0
end
table.sort(seedShopItems, function(a, b)
    if a == "Carrot" then
        return true
    end
    if b == "Carrot" then
        return false
    end
    return a < b
end)

local gearShopItems = {}
local gearShopPrices = {}
for _, data in pairs(GearShopData) do
    local name = data.Name or ""
    if name ~= "" then
        table.insert(gearShopItems, name)
        gearShopPrices[name] = data.Price or 0
    end
end
table.sort(gearShopItems)

local state = {
    running = true,

    autoSell = false,
    sellMode = "SellAll",
    sellInterval = 2.5,
    sellOnFull = false,
    sellThreshold = 280,
    autoSellValue = false,
    sellValueMin = 0,
    sellValueInterval = 1,
    autoSellKeep = false,
    keepList = {},
    keepAmountSelected = 0,
    keepAmountOthers = 0,
    keepInterval = 1.5,

    autoHarvest = false,
    harvestInterval = 0.4,
    harvestBatch = 60,
    mutationFilter = "All",
    skipFavorited = true,
    inventoryLimit = 300,
    harvestOnlyListEnabled = false,
    harvestOnlyList = {},

    autoHarvestBell = false,
    harvestBellInterval = 1.5,
    harvestBellRadius = 25,
    harvestBellSkipFavorited = true,

    autoFavorite = false,
    favoriteMutations = true,
    favoriteGiants = true,
    favoriteInterval = 2,
    alertSpecial = false,
    alertNotify = false,
    alertInterval = 5,
    lastMutationCount = 0,
    lastGiantCount = 0,

    autoPlant = false,
    plantType = plantTypes[1] or "Carrot",
    plantInterval = 0.4,
    plantSpacing = 3,
    plantAtPlayerPosition = true,
    autoTeleportGardenForPlant = true,
    useEquippedSeed = false,
    autoBuyPlantSeed = false,
    autoRefreshGrid = false,
    gridRefreshInterval = 30,
    plantRotation = false,
    rotationList = {},
    rotationInterval = 60,
    rotationIndex = 1,

    autoBuyAllSeeds = false,
    autoBuySeed = false,
    selectedSeedShopItem = seedShopItems[1],
    autoBuyAllGears = false,
    autoBuyGear = false,
    selectedGearShopItem = gearShopItems[1],
    buyDelay = 0.25,
    buyInterval = 0.25,
    minShillingsToBuy = 0,
    buyFromAnywhere = true,
    autoTeleportSeedShop = false,
    autoTeleportGearShop = false,
    autoTeleportSellShop = true,
    teleportCooldown = 1.5,

    autoMerge = false,
    mergeInterval = 10,

    antiAfk = true,
    autoClaimCash = false,
    claimInterval = 60,

    restockNotify = true,
    autoSprinkler = false,
    sprinklerType = "Basic Sprinkler",
    sprinklerInterval = 5,
    sprinklerSpacing = 12,
    sprinklerMax = 6,
    sprinklerAutoTeleport = true,

    autoQuest = false,
    questDaily = true,
    questWeekly = true,
    questPriority = "DailyFirst",
    questLastCategory = "Weekly",
    questAllowSell = false,
    questAutoTeleport = true,
    questInterval = 5,
    questPlantInterval = 0.4,
    questHarvestInterval = 0.4,
    questBuyInterval = 5,
    questClaimInterval = 1.5,
    questTargetType = nil,
    questTargetItem = nil,
    questTargetCategory = nil,
    questTargetSlot = nil,
    questNotifySell = true,
    questRestockPin = true,
    questRefresh = false,
    questRefreshMaxPrice = 50000,
    questRefreshMinShillings = 0,

    autoSaveConfig = false,
    autoSaveInterval = 15
}

local antiAfkConnection = nil
local canBuy
local getShopItemForPlantType
local ensureTeleported
local purchaseSeedShopItem
local purchaseGearShopItem
local performSell

local function setAntiAfk(enabled)
    state.antiAfk = enabled
    if enabled then
        if not antiAfkConnection then
            antiAfkConnection = LocalPlayer.Idled:Connect(function()
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new(0, 0))
                end)
            end)
        end
    elseif antiAfkConnection then
        antiAfkConnection:Disconnect()
        antiAfkConnection = nil
    end
end

local restockConnections = {}
local function setRestockNotify(enabled)
    state.restockNotify = enabled
    for _, conn in ipairs(restockConnections) do
        conn:Disconnect()
    end
    restockConnections = {}
    if not enabled then
        return
    end
    local function notify(title, content)
        if Rayfield and Rayfield.Notify then
            Rayfield:Notify({
                Title = title,
                Content = content,
                Duration = 4
            })
        end
    end
    table.insert(restockConnections, workspace:GetAttributeChangedSignal("SeedShop"):Connect(function()
        notify("Seed Shop", "Seed shop restocked.")
    end))
    table.insert(restockConnections, workspace:GetAttributeChangedSignal("GearShop"):Connect(function()
        notify("Gear Shop", "Gear shop restocked.")
    end))
end

local questRestockConnection = nil
local function setQuestRestockPin(enabled)
    state.questRestockPin = enabled
    if questRestockConnection then
        questRestockConnection:Disconnect()
        questRestockConnection = nil
    end
    if not enabled then
        return
    end
    questRestockConnection = workspace:GetAttributeChangedSignal("SeedShop"):Connect(function()
        if state.autoQuest and state.questTargetType == "PlantSeeds" and state.questTargetItem then
            if type(getShopItemForPlantType) ~= "function" or type(purchaseSeedShopItem) ~= "function" then
                return
            end
            local shopItem = getShopItemForPlantType(state.questTargetItem)
            if shopItem then
                if state.questAutoTeleport and type(ensureTeleported) == "function" then
                    ensureTeleported("seed")
                end
                purchaseSeedShopItem(shopItem)
            end
        end
    end)
end

local nonPersistentState = {
    running = true,
    questTargetType = true,
    questTargetItem = true,
    questTargetCategory = true,
    questTargetSlot = true,
    lastMutationCount = true,
    lastGiantCount = true
}

local function saveConfig()
    if not canUseFileApi() then
        return false, "File API unavailable in this executor."
    end

    local payload = {}
    for key, value in pairs(state) do
        if not nonPersistentState[key] then
            local valueType = type(value)
            if valueType == "boolean" or valueType == "number" or valueType == "string" then
                payload[key] = value
            elseif valueType == "table" then
                local arr = {}
                local serializable = true
                for _, item in ipairs(value) do
                    local itemType = type(item)
                    if itemType == "boolean" or itemType == "number" or itemType == "string" then
                        table.insert(arr, item)
                    else
                        serializable = false
                        break
                    end
                end
                if serializable then
                    payload[key] = arr
                end
            end
        end
    end

    if type(isfolder) == "function" and type(makefolder) == "function" then
        if not isfolder(CONFIG_DIR) then
            pcall(makefolder, CONFIG_DIR)
        end
    end

    local ok, err = pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(payload))
    end)
    if not ok then
        return false, tostring(err)
    end
    return true
end

local function applyConfig(data)
    if type(data) ~= "table" then
        return
    end

    for key, saved in pairs(data) do
        local current = state[key]
        if current ~= nil then
            if type(current) == type(saved) and type(saved) ~= "table" then
                state[key] = saved
            elseif type(current) == "table" and type(saved) == "table" then
                local arr = {}
                for _, item in ipairs(saved) do
                    table.insert(arr, item)
                end
                state[key] = arr
            end
        end
    end

    setAntiAfk(state.antiAfk)
    setRestockNotify(state.restockNotify)
    setQuestRestockPin(state.questRestockPin)

    if state.buyFromAnywhere then
        state.autoTeleportSeedShop = false
        state.autoTeleportGearShop = false
    end
end

local function loadConfig()
    if not canUseFileApi() then
        return false, "File API unavailable in this executor."
    end
    if not isfile(CONFIG_FILE) then
        return false, "Config file not found."
    end

    local raw
    local okRead, readErr = pcall(function()
        raw = readfile(CONFIG_FILE)
    end)
    if not okRead then
        return false, tostring(readErr)
    end

    local okDecode, decoded = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    if not okDecode then
        return false, "Failed to decode config JSON."
    end

    applyConfig(decoded)
    return true
end

local function stopAll()
    state.running = false
    state.autoSell = false
    state.autoSellValue = false
    state.autoSellKeep = false
    state.autoHarvest = false
    state.autoHarvestBell = false
    state.autoFavorite = false
    state.autoPlant = false
    state.autoBuyAllSeeds = false
    state.autoBuySeed = false
    state.autoBuyAllGears = false
    state.autoBuyGear = false
    state.autoMerge = false
    state.autoBuyPlantSeed = false
    state.autoRefreshGrid = false
    state.autoClaimCash = false
    state.autoSprinkler = false
    state.alertSpecial = false
    state.autoQuest = false
    state.questRefresh = false
    state.autoSaveConfig = false
    setAntiAfk(false)
    setRestockNotify(false)
    setQuestRestockPin(false)
end

canBuy = function(required)
    local minKeep = state.minShillingsToBuy or 0
    local cash = getShillings()
    if cash < minKeep then
        return false
    end
    if required and cash < required then
        return false
    end
    return true
end

local lastTeleportAt = {
    seed = 0,
    gear = 0,
    sell = 0,
    garden = 0
}

ensureTeleported = function(kind)
    local now = os.clock()
    local cooldown = math.max(0.1, state.teleportCooldown or 1.5)
    local last = lastTeleportAt[kind] or 0
    if now - last < cooldown then
        return
    end

    if kind == "seed" and state.autoTeleportSeedShop then
        teleportToSeeds()
        lastTeleportAt[kind] = now
    elseif kind == "gear" and state.autoTeleportGearShop then
        teleportToGears()
        lastTeleportAt[kind] = now
    elseif kind == "sell" and state.autoTeleportSellShop then
        teleportToSell()
        lastTeleportAt[kind] = now
    elseif kind == "garden" then
        teleportToGarden()
        lastTeleportAt[kind] = now
    end
end

purchaseSeedShopItem = function(itemName)
    if not itemName then
        return nil
    end
    local price = seedShopPrices[itemName]
    if not canBuy(price) then
        return nil
    end

    if state.buyFromAnywhere then
        return safeInvoke(RF_PurchaseShopItem, "SeedShop", itemName)
    end

    ensureTeleported("seed")
    return safeInvoke(RF_PurchaseShopItem, "SeedShop", itemName)
end

purchaseGearShopItem = function(itemName)
    if not itemName then
        return nil
    end
    local price = gearShopPrices[itemName]
    if not canBuy(price) then
        return nil
    end

    if state.buyFromAnywhere then
        return safeInvoke(RF_PurchaseShopItem, "GearShop", itemName)
    end

    ensureTeleported("gear")
    return safeInvoke(RF_PurchaseShopItem, "GearShop", itemName)
end

performSell = function(mode)
    ensureTeleported("sell")
    return safeInvoke(RF_SellItems, mode or "SellAll")
end

local plantPositions = {}
local plantIndex = 1
local sprinklerPositions = {}
local sprinklerIndex = 1

local function refreshPlantPositions()
    plantPositions = buildPlantPositions(state.plantSpacing)
    plantIndex = 1
end

local function refreshSprinklerPositions()
    sprinklerPositions = buildPlantPositions(state.sprinklerSpacing)
    sprinklerIndex = 1
end

local function nextPlantPosition()
    if #plantPositions == 0 then
        return nil
    end
    if plantIndex > #plantPositions then
        plantIndex = 1
    end
    local pos = plantPositions[plantIndex]
    plantIndex = plantIndex + 1
    return pos
end

local function getNextAutoPlantPosition(allowGardenTeleport)
    local shouldTeleportGarden = allowGardenTeleport == true

    if state.plantAtPlayerPosition then
        local playerPos = getPlayerPlantPosition()
        if playerPos then
            return playerPos
        end

        if shouldTeleportGarden then
            ensureTeleported("garden")
            task.wait(0.05)
            playerPos = getPlayerPlantPosition()
            if playerPos then
                return playerPos
            end
        end
    end

    if shouldTeleportGarden then
        ensureTeleported("garden")
    end

    if #plantPositions == 0 then
        refreshPlantPositions()
    end
    return nextPlantPosition()
end

local function nextSprinklerPosition()
    if #sprinklerPositions == 0 then
        return nil
    end
    if sprinklerIndex > #sprinklerPositions then
        sprinklerIndex = 1
    end
    local pos = sprinklerPositions[sprinklerIndex]
    sprinklerIndex = sprinklerIndex + 1
    return pos
end

local function getActivePlantType()
    if state.useEquippedSeed then
        local equipped = getEquippedPlantType()
        if equipped then
            return equipped
        end
    end
    if state.plantRotation and state.rotationList and #state.rotationList > 0 then
        if state.rotationIndex > #state.rotationList then
            state.rotationIndex = 1
        end
        return state.rotationList[state.rotationIndex]
    end
    return state.plantType
end

local function hasSeedForPlantType(plantType)
    if not plantType then
        return false
    end
    local tool = findSeedTool(plantType)
    if not tool then
        return false
    end
    return ItemInventory.getItemCount(tool) > 0
end

getShopItemForPlantType = function(plantType)
    return plantTypeToShopName[plantType]
end

local function shouldHarvestByMutation(model)
    local mutation = getMutation(model)
    if state.mutationFilter == "All" then
        return true
    end
    if state.mutationFilter == "Only Mutated" then
        return mutation ~= nil
    end
    if state.mutationFilter == "Only Non-Mutated" then
        return mutation == nil
    end
    return true
end

local function getPlantTypeForModel(model)
    if not model then
        return nil
    end
    local plantType = model:GetAttribute("PlantType")
    if plantType then
        return plantType
    end
    local parent = model.Parent
    if parent and parent:IsA("Model") then
        return parent:GetAttribute("PlantType")
    end
    return nil
end

local function collectHarvestTargets(filterPlantType)
    local list = {}
    for _, prompt in ipairs(CollectionService:GetTagged("HarvestPrompt")) do
        if prompt:IsA("ProximityPrompt") then
            local data, model = getHarvestData(prompt)
            if data and model then
                if isOwned(model) and (not state.skipFavorited or not isFavorited(model)) then
                    local plantType = getPlantTypeForModel(model)
                    local allowed = true

                    if filterPlantType and plantType ~= filterPlantType then
                        allowed = false
                    end

                    if allowed and (not filterPlantType) then
                        if state.harvestOnlyListEnabled and state.harvestOnlyList and #state.harvestOnlyList > 0 then
                            local inList = false
                            for _, name in ipairs(state.harvestOnlyList) do
                                if name == plantType then
                                    inList = true
                                    break
                                end
                            end
                            allowed = inList
                        end
                    end

                    if allowed and shouldHarvestByMutation(model) then
                        table.insert(list, data)
                        if #list >= state.harvestBatch then
                            break
                        end
                    end
                end
            end
        end
    end
    return list
end

local seedBuyIndex = 1
local gearBuyIndex = 1

local function buyNextSeedInOrder()
    if #seedShopItems == 0 then
        return
    end
    if seedBuyIndex > #seedShopItems then
        seedBuyIndex = 1
    end
    purchaseSeedShopItem(seedShopItems[seedBuyIndex])
    seedBuyIndex = seedBuyIndex + 1
end

local function buyNextGearInOrder()
    if #gearShopItems == 0 then
        return
    end
    if gearBuyIndex > #gearShopItems then
        gearBuyIndex = 1
    end
    purchaseGearShopItem(gearShopItems[gearBuyIndex])
    gearBuyIndex = gearBuyIndex + 1
end

local function buySelectedSeedOnce()
    if state.selectedSeedShopItem then
        purchaseSeedShopItem(state.selectedSeedShopItem)
    end
end

local function buySelectedGearOnce()
    if state.selectedGearShopItem then
        purchaseGearShopItem(state.selectedGearShopItem)
    end
end

loadConfig()
refreshPlantPositions()
refreshSprinklerPositions()
setAntiAfk(state.antiAfk)

local function findHarvestBellTarget()
    local root = getRoot()
    if not root then
        return nil
    end
    local bestUuid = nil
    local bestDist = nil
    for _, plant in ipairs(CollectionService:GetTagged("Plant")) do
        if plant:IsA("Model") and plant:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
            if plant:GetAttribute("FullyGrown") then
                if not (state.harvestBellSkipFavorited and plant:GetAttribute("Favorited")) then
                    local uuid = plant:GetAttribute("Uuid")
                    if uuid then
                        local ok, pivot = pcall(function()
                            return plant:GetPivot()
                        end)
                        if ok then
                            local dist = (pivot.Position - root.Position).Magnitude
                            if dist <= state.harvestBellRadius and (not bestDist or dist < bestDist) then
                                bestUuid = uuid
                                bestDist = dist
                            end
                        end
                    end
                end
            end
        end
    end
    return bestUuid
end

local function countSprinklers()
    local count = 0
    for _, spr in ipairs(CollectionService:GetTagged("Sprinkler")) do
        if spr:IsA("Model") and spr:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
            count = count + 1
        end
    end
    return count
end

local function findFavoriteTarget()
    for _, plant in ipairs(CollectionService:GetTagged("Plant")) do
        if plant:IsA("Model") and plant:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
            if plant:GetAttribute("FullyGrown") and not plant:GetAttribute("Favorited") then
                local isMutation = state.favoriteMutations and getMutationAny(plant) ~= nil
                local isGiant = state.favoriteGiants and plant:GetAttribute("IsGiant")
                if isMutation or isGiant then
                    local uuid, growthIndex = getFavoriteTarget(plant)
                    if uuid then
                        return uuid, growthIndex
                    end
                end
            end
        end
    end
    return nil, nil
end

local function findValuableTool()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local value = FruitValueCalculator.GetValue(tool)
                if value and value >= state.sellValueMin then
                    return tool
                end
            end
        end
    end
    local char = LocalPlayer.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                local value = FruitValueCalculator.GetValue(tool)
                if value and value >= state.sellValueMin then
                    return tool
                end
            end
        end
    end
    return nil
end

local questData = nil
local lastQuestRequest = 0
local lastQuestBuy = 0
local lastQuestNotify = 0

local function requestQuests()
    lastQuestRequest = os.clock()
    pcall(function()
        RE_RequestQuests:FireServer()
    end)
end

RE_UpdateQuests.OnClientEvent:Connect(function(data)
    questData = data
end)

local function claimQuest(category, slot)
    if category and slot then
        safeFire(RE_ClaimQuest, category, tostring(slot))
        task.delay(0.5, requestQuests)
    end
end

local function getQuestEntries(category)
    if not questData or not questData[category] then
        return nil
    end
    local info = questData[category]
    if not info.Active then
        return nil
    end
    return info.Active
end

local function buildQuestCategoryOrder()
    local categories = {}
    local daily = state.questDaily
    local weekly = state.questWeekly
    if not daily and not weekly then
        return categories
    end
    if state.questPriority == "WeeklyFirst" then
        if weekly then
            table.insert(categories, "Weekly")
        end
        if daily then
            table.insert(categories, "Daily")
        end
    elseif state.questPriority == "RoundRobin" then
        if daily and weekly then
            local first = state.questLastCategory == "Daily" and "Weekly" or "Daily"
            table.insert(categories, first)
            table.insert(categories, first == "Daily" and "Weekly" or "Daily")
        elseif daily then
            table.insert(categories, "Daily")
        elseif weekly then
            table.insert(categories, "Weekly")
        end
    else
        if daily then
            table.insert(categories, "Daily")
        end
        if weekly then
            table.insert(categories, "Weekly")
        end
    end
    return categories
end

local function questSupported(quest)
    if not quest or not quest.Type then
        return false
    end
    if quest.Type == "PlantSeeds" or quest.Type == "HarvestCrops" or quest.Type == "GainShillings" then
        return true
    end
    return false
end

local function questSeedInShop(item)
    return item and SeedShopData[item] ~= nil
end

local function pickQuestTarget()
    local categories = buildQuestCategoryOrder()
    for _, category in ipairs(categories) do
        local active = getQuestEntries(category)
        if active then
            for i = 1, 5 do
                local quest = active[tostring(i)]
                if quest and not quest.Claimed then
                    if quest.Progress >= quest.Goal then
                        claimQuest(category, i)
                    else
                        state.questLastCategory = category
                        return category, i, quest
                    end
                end
            end
        end
    end
    return nil, nil, nil
end

local function getQuestRefreshPrice(category, resetCount)
    local base = category == "Weekly" and 350000 or 50000
    return base * ((resetCount or 0) + 1)
end

local function claimCompletedQuests()
    if not questData then
        return
    end

    local categories = {}
    if state.questDaily then
        table.insert(categories, "Daily")
    end
    if state.questWeekly then
        table.insert(categories, "Weekly")
    end

    for _, category in ipairs(categories) do
        local active = getQuestEntries(category)
        if active then
            for i = 1, 5 do
                local quest = active[tostring(i)]
                if quest and not quest.Claimed and quest.Progress and quest.Goal and quest.Progress >= quest.Goal then
                    claimQuest(category, i)
                end
            end
        end
    end
end


Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Almond Hub",
    LoadingTitle = "Garden Horizon | v1.0",
    LoadingSubtitle = "Autofarm",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "GardenHorizon",
        FileName = "GardenHorizonHub"
    }
})

local FarmingTab = Window:CreateTab("Farming")
local ShopTab = Window:CreateTab("Shop")
local InventoryTab = Window:CreateTab("Inventory")
local QuestTab = Window:CreateTab("Quests")
local TeleportTab = Window:CreateTab("Teleport")
local SettingsTab = Window:CreateTab("Settings")

setRestockNotify(state.restockNotify)
setQuestRestockPin(state.questRestockPin)

FarmingTab:CreateSection("Harvest")

FarmingTab:CreateToggle({
    Name = "Auto Harvest",
    CurrentValue = state.autoHarvest,
    Callback = function(value)
        state.autoHarvest = value
    end
})

FarmingTab:CreateDropdown({
    Name = "Mutation Filter",
    Options = { "All", "Only Mutated", "Only Non-Mutated" },
    CurrentOption = state.mutationFilter,
    MultipleOptions = false,
    Callback = function(option)
        state.mutationFilter = option
    end
})

FarmingTab:CreateToggle({
    Name = "Harvest Only Selected Crops",
    CurrentValue = state.harvestOnlyListEnabled,
    Callback = function(value)
        state.harvestOnlyListEnabled = value
    end
})

FarmingTab:CreateDropdown({
    Name = "Harvest Crop List",
    Options = plantTypes,
    CurrentOption = state.harvestOnlyList,
    MultipleOptions = true,
    Callback = function(options)
        state.harvestOnlyList = options
    end
})

FarmingTab:CreateToggle({
    Name = "Skip Favorited",
    CurrentValue = state.skipFavorited,
    Callback = function(value)
        state.skipFavorited = value
    end
})

FarmingTab:CreateSlider({
    Name = "Harvest Interval (sec)",
    Range = { 0.15, 2 },
    Increment = 0.05,
    Suffix = "s",
    CurrentValue = state.harvestInterval,
    Callback = function(value)
        state.harvestInterval = value
    end
})

FarmingTab:CreateSlider({
    Name = "Harvest Batch Size",
    Range = { 10, 200 },
    Increment = 5,
    Suffix = "",
    CurrentValue = state.harvestBatch,
    Callback = function(value)
        state.harvestBatch = value
    end
})

FarmingTab:CreateSlider({
    Name = "Inventory Limit",
    Range = { 50, 300 },
    Increment = 10,
    Suffix = "",
    CurrentValue = state.inventoryLimit,
    Callback = function(value)
        state.inventoryLimit = value
    end
})

FarmingTab:CreateSection("Harvest Bell")

FarmingTab:CreateToggle({
    Name = "Auto Harvest Bell",
    CurrentValue = state.autoHarvestBell,
    Callback = function(value)
        state.autoHarvestBell = value
    end
})

FarmingTab:CreateToggle({
    Name = "Skip Favorited (Bell)",
    CurrentValue = state.harvestBellSkipFavorited,
    Callback = function(value)
        state.harvestBellSkipFavorited = value
    end
})

FarmingTab:CreateSlider({
    Name = "Bell Radius",
    Range = { 5, 60 },
    Increment = 1,
    Suffix = "",
    CurrentValue = state.harvestBellRadius,
    Callback = function(value)
        state.harvestBellRadius = value
    end
})

FarmingTab:CreateSlider({
    Name = "Bell Interval (sec)",
    Range = { 0.5, 5 },
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = state.harvestBellInterval,
    Callback = function(value)
        state.harvestBellInterval = value
    end
})

FarmingTab:CreateSection("Auto Favorite")

FarmingTab:CreateToggle({
    Name = "Auto Favorite",
    CurrentValue = state.autoFavorite,
    Callback = function(value)
        state.autoFavorite = value
    end
})

FarmingTab:CreateToggle({
    Name = "Favorite Mutations",
    CurrentValue = state.favoriteMutations,
    Callback = function(value)
        state.favoriteMutations = value
    end
})

FarmingTab:CreateToggle({
    Name = "Favorite Giants",
    CurrentValue = state.favoriteGiants,
    Callback = function(value)
        state.favoriteGiants = value
    end
})

FarmingTab:CreateSlider({
    Name = "Favorite Interval (sec)",
    Range = { 0.5, 10 },
    Increment = 0.5,
    Suffix = "s",
    CurrentValue = state.favoriteInterval,
    Callback = function(value)
        state.favoriteInterval = value
    end
})

FarmingTab:CreateSection("Planting")

FarmingTab:CreateToggle({
    Name = "Auto Plant",
    CurrentValue = state.autoPlant,
    Callback = function(value)
        state.autoPlant = value
        if value then
            refreshPlantPositions()
        end
    end
})

FarmingTab:CreateToggle({
    Name = "Plant At Player Position",
    CurrentValue = state.plantAtPlayerPosition,
    Callback = function(value)
        state.plantAtPlayerPosition = value
    end
})

FarmingTab:CreateToggle({
    Name = "Use Equipped Seed",
    CurrentValue = state.useEquippedSeed,
    Callback = function(value)
        state.useEquippedSeed = value
    end
})

FarmingTab:CreateToggle({
    Name = "Auto Buy Needed Seed (Auto Plant)",
    CurrentValue = state.autoBuyPlantSeed,
    Callback = function(value)
        state.autoBuyPlantSeed = value
    end
})

FarmingTab:CreateToggle({
    Name = "Auto Teleport Back To Garden (Plant)",
    CurrentValue = state.autoTeleportGardenForPlant,
    Callback = function(value)
        state.autoTeleportGardenForPlant = value
    end
})

FarmingTab:CreateDropdown({
    Name = "Plant Type",
    Options = plantTypes,
    CurrentOption = state.plantType,
    MultipleOptions = false,
    Callback = function(option)
        state.plantType = option
    end
})

FarmingTab:CreateToggle({
    Name = "Plant Rotation",
    CurrentValue = state.plantRotation,
    Callback = function(value)
        state.plantRotation = value
    end
})

FarmingTab:CreateDropdown({
    Name = "Rotation Types",
    Options = plantTypes,
    CurrentOption = state.rotationList,
    MultipleOptions = true,
    Callback = function(options)
        state.rotationList = options
        state.rotationIndex = 1
    end
})

FarmingTab:CreateSlider({
    Name = "Rotation Interval (sec)",
    Range = { 5, 300 },
    Increment = 5,
    Suffix = "s",
    CurrentValue = state.rotationInterval,
    Callback = function(value)
        state.rotationInterval = value
    end
})

FarmingTab:CreateSlider({
    Name = "Plant Interval (sec)",
    Range = { 0.15, 2 },
    Increment = 0.05,
    Suffix = "s",
    CurrentValue = state.plantInterval,
    Callback = function(value)
        state.plantInterval = value
    end
})

FarmingTab:CreateSlider({
    Name = "Plant Spacing",
    Range = { 2, 8 },
    Increment = 1,
    Suffix = "",
    CurrentValue = state.plantSpacing,
    Callback = function(value)
        state.plantSpacing = value
        refreshPlantPositions()
    end
})

FarmingTab:CreateToggle({
    Name = "Auto Refresh Plant Grid",
    CurrentValue = state.autoRefreshGrid,
    Callback = function(value)
        state.autoRefreshGrid = value
    end
})

FarmingTab:CreateSlider({
    Name = "Grid Refresh Interval (sec)",
    Range = { 5, 120 },
    Increment = 5,
    Suffix = "s",
    CurrentValue = state.gridRefreshInterval,
    Callback = function(value)
        state.gridRefreshInterval = value
    end
})

FarmingTab:CreateButton({
    Name = "Refresh Plant Grid",
    Callback = function()
        refreshPlantPositions()
    end
})

FarmingTab:CreateSection("Sprinklers")

FarmingTab:CreateToggle({
    Name = "Auto Place Sprinklers",
    CurrentValue = state.autoSprinkler,
    Callback = function(value)
        state.autoSprinkler = value
        if value then
            refreshSprinklerPositions()
        end
    end
})

FarmingTab:CreateDropdown({
    Name = "Sprinkler Type",
    Options = { "Basic Sprinkler", "Turbo Sprinkler", "Super Sprinkler" },
    CurrentOption = state.sprinklerType,
    MultipleOptions = false,
    Callback = function(option)
        state.sprinklerType = option
    end
})

FarmingTab:CreateToggle({
    Name = "Auto Teleport For Sprinklers",
    CurrentValue = state.sprinklerAutoTeleport,
    Callback = function(value)
        state.sprinklerAutoTeleport = value
    end
})

FarmingTab:CreateSlider({
    Name = "Sprinkler Spacing",
    Range = { 6, 20 },
    Increment = 1,
    Suffix = "",
    CurrentValue = state.sprinklerSpacing,
    Callback = function(value)
        state.sprinklerSpacing = value
        refreshSprinklerPositions()
    end
})

FarmingTab:CreateSlider({
    Name = "Sprinkler Max Count",
    Range = { 1, 20 },
    Increment = 1,
    Suffix = "",
    CurrentValue = state.sprinklerMax,
    Callback = function(value)
        state.sprinklerMax = value
    end
})

FarmingTab:CreateSlider({
    Name = "Sprinkler Interval (sec)",
    Range = { 1, 20 },
    Increment = 1,
    Suffix = "s",
    CurrentValue = state.sprinklerInterval,
    Callback = function(value)
        state.sprinklerInterval = value
    end
})

FarmingTab:CreateSection("Selling")

FarmingTab:CreateToggle({
    Name = "Auto Sell",
    CurrentValue = state.autoSell,
    Callback = function(value)
        state.autoSell = value
    end
})

FarmingTab:CreateDropdown({
    Name = "Sell Mode",
    Options = { "SellAll", "SellSingle" },
    CurrentOption = state.sellMode,
    MultipleOptions = false,
    Callback = function(option)
        state.sellMode = option
    end
})

FarmingTab:CreateToggle({
    Name = "Only Sell When Full",
    CurrentValue = state.sellOnFull,
    Callback = function(value)
        state.sellOnFull = value
    end
})

FarmingTab:CreateSlider({
    Name = "Sell Threshold",
    Range = { 50, 300 },
    Increment = 10,
    Suffix = "",
    CurrentValue = state.sellThreshold,
    Callback = function(value)
        state.sellThreshold = value
    end
})

FarmingTab:CreateSlider({
    Name = "Sell Interval (sec)",
    Range = { 0.5, 10 },
    Increment = 0.5,
    Suffix = "s",
    CurrentValue = state.sellInterval,
    Callback = function(value)
        state.sellInterval = value
    end
})

FarmingTab:CreateSection("Sell Keep Rules")

FarmingTab:CreateToggle({
    Name = "Auto Sell Keep Rules",
    CurrentValue = state.autoSellKeep,
    Callback = function(value)
        state.autoSellKeep = value
    end
})

FarmingTab:CreateDropdown({
    Name = "Keep List",
    Options = plantTypes,
    CurrentOption = state.keepList,
    MultipleOptions = true,
    Callback = function(options)
        state.keepList = options
    end
})

FarmingTab:CreateSlider({
    Name = "Keep Amount (Selected)",
    Range = { 0, 200 },
    Increment = 1,
    Suffix = "",
    CurrentValue = state.keepAmountSelected,
    Callback = function(value)
        state.keepAmountSelected = value
    end
})

FarmingTab:CreateSlider({
    Name = "Keep Amount (Others)",
    Range = { 0, 200 },
    Increment = 1,
    Suffix = "",
    CurrentValue = state.keepAmountOthers,
    Callback = function(value)
        state.keepAmountOthers = value
    end
})

FarmingTab:CreateSlider({
    Name = "Keep Sell Interval (sec)",
    Range = { 0.5, 10 },
    Increment = 0.5,
    Suffix = "s",
    CurrentValue = state.keepInterval,
    Callback = function(value)
        state.keepInterval = value
    end
})

FarmingTab:CreateToggle({
    Name = "Auto Sell By Value",
    CurrentValue = state.autoSellValue,
    Callback = function(value)
        state.autoSellValue = value
    end
})

FarmingTab:CreateSlider({
    Name = "Sell Min Value",
    Range = { 0, 500000 },
    Increment = 1000,
    Suffix = "",
    CurrentValue = state.sellValueMin,
    Callback = function(value)
        state.sellValueMin = value
    end
})

FarmingTab:CreateSlider({
    Name = "Sell Value Interval (sec)",
    Range = { 0.2, 5 },
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = state.sellValueInterval,
    Callback = function(value)
        state.sellValueInterval = value
    end
})

FarmingTab:CreateButton({
    Name = "Sell All Now",
    Callback = function()
        performSell("SellAll")
    end
})

ShopTab:CreateSection("Seeds")

ShopTab:CreateToggle({
    Name = "Auto Buy All Seeds",
    CurrentValue = state.autoBuyAllSeeds,
    Callback = function(value)
        state.autoBuyAllSeeds = value
        if value then
            seedBuyIndex = 1
        end
    end
})

ShopTab:CreateToggle({
    Name = "Auto Buy Selected Seed",
    CurrentValue = state.autoBuySeed,
    Callback = function(value)
        state.autoBuySeed = value
    end
})

ShopTab:CreateDropdown({
    Name = "Selected Seed",
    Options = seedShopItems,
    CurrentOption = state.selectedSeedShopItem,
    MultipleOptions = false,
    Callback = function(option)
        state.selectedSeedShopItem = option
    end
})

ShopTab:CreateButton({
    Name = "Buy Selected Seed Once",
    Callback = function()
        buySelectedSeedOnce()
    end
})

ShopTab:CreateSection("Gears")

ShopTab:CreateToggle({
    Name = "Auto Buy All Gears",
    CurrentValue = state.autoBuyAllGears,
    Callback = function(value)
        state.autoBuyAllGears = value
        if value then
            gearBuyIndex = 1
        end
    end
})

ShopTab:CreateToggle({
    Name = "Auto Buy Selected Gear",
    CurrentValue = state.autoBuyGear,
    Callback = function(value)
        state.autoBuyGear = value
    end
})

ShopTab:CreateDropdown({
    Name = "Selected Gear",
    Options = gearShopItems,
    CurrentOption = state.selectedGearShopItem,
    MultipleOptions = false,
    Callback = function(option)
        state.selectedGearShopItem = option
    end
})

ShopTab:CreateButton({
    Name = "Buy Selected Gear Once",
    Callback = function()
        buySelectedGearOnce()
    end
})

ShopTab:CreateSection("Shop Timing")

ShopTab:CreateToggle({
    Name = "Buy From Anywhere (No Teleport)",
    CurrentValue = state.buyFromAnywhere,
    Callback = function(value)
        state.buyFromAnywhere = value
        if value then
            state.autoTeleportSeedShop = false
            state.autoTeleportGearShop = false
        end
    end
})

ShopTab:CreateSlider({
    Name = "Buy Delay Between Items (sec)",
    Range = { 0.1, 2 },
    Increment = 0.05,
    Suffix = "s",
    CurrentValue = state.buyDelay,
    Callback = function(value)
        state.buyDelay = value
    end
})

ShopTab:CreateSlider({
    Name = "Selected Buy Interval (sec)",
    Range = { 0.1, 5 },
    Increment = 0.05,
    Suffix = "s",
    CurrentValue = state.buyInterval,
    Callback = function(value)
        state.buyInterval = value
    end
})

ShopTab:CreateSlider({
    Name = "Min Shillings To Buy",
    Range = { 0, 500000 },
    Increment = 1000,
    Suffix = "",
    CurrentValue = state.minShillingsToBuy,
    Callback = function(value)
        state.minShillingsToBuy = value
    end
})

InventoryTab:CreateSection("Inventory")

InventoryTab:CreateButton({
    Name = "Merge Backpack",
    Callback = function()
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            ItemInventory.mergeItemsInBackpack(backpack)
        end
    end
})

InventoryTab:CreateToggle({
    Name = "Auto Merge Backpack",
    CurrentValue = state.autoMerge,
    Callback = function(value)
        state.autoMerge = value
    end
})

InventoryTab:CreateSlider({
    Name = "Merge Interval (sec)",
    Range = { 3, 60 },
    Increment = 1,
    Suffix = "s",
    CurrentValue = state.mergeInterval,
    Callback = function(value)
        state.mergeInterval = value
    end
})

local inventoryLabel = InventoryTab:CreateLabel("Tools: 0")

QuestTab:CreateSection("Quest Automation")

QuestTab:CreateToggle({
    Name = "Auto Quest (Daily + Weekly)",
    CurrentValue = state.autoQuest,
    Callback = function(value)
        state.autoQuest = value
        if value then
            requestQuests()
        end
    end
})

QuestTab:CreateToggle({
    Name = "Include Daily",
    CurrentValue = state.questDaily,
    Callback = function(value)
        state.questDaily = value
    end
})

QuestTab:CreateToggle({
    Name = "Include Weekly",
    CurrentValue = state.questWeekly,
    Callback = function(value)
        state.questWeekly = value
    end
})

QuestTab:CreateDropdown({
    Name = "Quest Priority",
    Options = { "DailyFirst", "WeeklyFirst", "RoundRobin" },
    CurrentOption = state.questPriority,
    MultipleOptions = false,
    Callback = function(option)
        state.questPriority = option
    end
})

QuestTab:CreateToggle({
    Name = "Allow Auto Sell (Shillings Quest)",
    CurrentValue = state.questAllowSell,
    Callback = function(value)
        state.questAllowSell = value
    end
})

QuestTab:CreateToggle({
    Name = "Auto Teleport For Quests",
    CurrentValue = state.questAutoTeleport,
    Callback = function(value)
        state.questAutoTeleport = value
    end
})

QuestTab:CreateToggle({
    Name = "Quest Restock Pin",
    CurrentValue = state.questRestockPin,
    Callback = function(value)
        setQuestRestockPin(value)
    end
})

QuestTab:CreateToggle({
    Name = "Auto Refresh Unsupported",
    CurrentValue = state.questRefresh,
    Callback = function(value)
        state.questRefresh = value
    end
})

QuestTab:CreateSlider({
    Name = "Refresh Max Price",
    Range = { 0, 500000 },
    Increment = 5000,
    Suffix = "",
    CurrentValue = state.questRefreshMaxPrice,
    Callback = function(value)
        state.questRefreshMaxPrice = value
    end
})

QuestTab:CreateSlider({
    Name = "Refresh Min Shillings",
    Range = { 0, 1000000 },
    Increment = 5000,
    Suffix = "",
    CurrentValue = state.questRefreshMinShillings,
    Callback = function(value)
        state.questRefreshMinShillings = value
    end
})

QuestTab:CreateSlider({
    Name = "Quest Scan Interval (sec)",
    Range = { 2, 30 },
    Increment = 1,
    Suffix = "s",
    CurrentValue = state.questInterval,
    Callback = function(value)
        state.questInterval = value
    end
})

QuestTab:CreateSlider({
    Name = "Quest Claim Interval (sec)",
    Range = { 0.5, 10 },
    Increment = 0.5,
    Suffix = "s",
    CurrentValue = state.questClaimInterval,
    Callback = function(value)
        state.questClaimInterval = value
    end
})

QuestTab:CreateParagraph({
    Title = "Quest Status",
    Content = "No quest targeted yet."
})

local questStatus = QuestTab:CreateLabel("Target: none")

TeleportTab:CreateSection("Quick Teleport")

TeleportTab:CreateButton({
    Name = "Teleport To Seeds Shop",
    Callback = function()
        teleportToSeeds()
    end
})

TeleportTab:CreateButton({
    Name = "Teleport To Sell Shop",
    Callback = function()
        teleportToSell()
    end
})

TeleportTab:CreateButton({
    Name = "Teleport To Your Garden",
    Callback = function()
        teleportToGarden()
    end
})

TeleportTab:CreateButton({
    Name = "Teleport To Quest Board",
    Callback = function()
        teleportToQuestBoard()
    end
})

SettingsTab:CreateSection("Settings")

SettingsTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = state.antiAfk,
    Callback = function(value)
        setAntiAfk(value)
    end
})

SettingsTab:CreateToggle({
    Name = "Restock Notifier",
    CurrentValue = state.restockNotify,
    Callback = function(value)
        setRestockNotify(value)
    end
})

SettingsTab:CreateToggle({
    Name = "Auto Claim Softlock Cash",
    CurrentValue = state.autoClaimCash,
    Callback = function(value)
        state.autoClaimCash = value
    end
})

SettingsTab:CreateSection("Auto Teleport")

SettingsTab:CreateToggle({
    Name = "Teleport For Seed Shop",
    CurrentValue = state.autoTeleportSeedShop,
    Callback = function(value)
        state.autoTeleportSeedShop = value
    end
})

SettingsTab:CreateToggle({
    Name = "Teleport For Gear Shop",
    CurrentValue = state.autoTeleportGearShop,
    Callback = function(value)
        state.autoTeleportGearShop = value
    end
})

SettingsTab:CreateToggle({
    Name = "Teleport For Sell Shop",
    CurrentValue = state.autoTeleportSellShop,
    Callback = function(value)
        state.autoTeleportSellShop = value
    end
})

SettingsTab:CreateSlider({
    Name = "Teleport Cooldown (sec)",
    Range = { 0.2, 6 },
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = state.teleportCooldown,
    Callback = function(value)
        state.teleportCooldown = value
    end
})

SettingsTab:CreateSlider({
    Name = "Claim Interval (sec)",
    Range = { 10, 600 },
    Increment = 10,
    Suffix = "s",
    CurrentValue = state.claimInterval,
    Callback = function(value)
        state.claimInterval = value
    end
})

SettingsTab:CreateButton({
    Name = "Destroy UI",
    Callback = function()
        stopAll()
        if Rayfield and Rayfield.Destroy then
            Rayfield:Destroy()
        end
        local coreGui = game:GetService("CoreGui")
        local rayfieldGui = coreGui:FindFirstChild("Rayfield")
        if rayfieldGui then
            rayfieldGui:Destroy()
        end
    end
})

SettingsTab:CreateSection("Utilities")

SettingsTab:CreateButton({
    Name = "Claim Softlock Cash",
    Callback = function()
        safeInvoke(RF_ClaimSoftlockCash)
    end
})

SettingsTab:CreateParagraph({
    Title = "Notes",
    Content = "Auto Plant uses your plot PlantableArea. If planting fails, increase spacing or wait for plot updates."
})

SettingsTab:CreateSection("Alerts")

SettingsTab:CreateToggle({
    Name = "Track Mutations/Giants",
    CurrentValue = state.alertSpecial,
    Callback = function(value)
        state.alertSpecial = value
    end
})

SettingsTab:CreateToggle({
    Name = "Notify On New",
    CurrentValue = state.alertNotify,
    Callback = function(value)
        state.alertNotify = value
    end
})

SettingsTab:CreateSlider({
    Name = "Alert Interval (sec)",
    Range = { 2, 30 },
    Increment = 1,
    Suffix = "s",
    CurrentValue = state.alertInterval,
    Callback = function(value)
        state.alertInterval = value
    end
})

local alertLabel = SettingsTab:CreateLabel("Mutations: 0 | Giants: 0")

SettingsTab:CreateSection("Config")

SettingsTab:CreateToggle({
    Name = "Auto Save Config",
    CurrentValue = state.autoSaveConfig,
    Callback = function(value)
        state.autoSaveConfig = value
    end
})

SettingsTab:CreateSlider({
    Name = "Auto Save Interval (sec)",
    Range = { 5, 120 },
    Increment = 1,
    Suffix = "s",
    CurrentValue = state.autoSaveInterval,
    Callback = function(value)
        state.autoSaveInterval = value
    end
})

SettingsTab:CreateButton({
    Name = "Save Config Now",
    Callback = function()
        local ok, err = saveConfig()
        if ok then
            safeNotify("Config", "Saved successfully.")
        else
            safeNotify("Config", "Save failed: " .. tostring(err), 6)
        end
    end
})

SettingsTab:CreateButton({
    Name = "Load Config Now",
    Callback = function()
        local ok, err = loadConfig()
        if ok then
            refreshPlantPositions()
            refreshSprinklerPositions()
            if state.autoQuest then
                requestQuests()
            end
            safeNotify("Config", "Loaded.")
        else
            safeNotify("Config", "Load failed: " .. tostring(err), 6)
        end
    end
})

-- Loops

task.spawn(function()
    while state.running do
        if state.autoHarvest then
            if getToolCount() < state.inventoryLimit then
                local targets = collectHarvestTargets(nil)
                if #targets > 0 then
                    safeFire(RE_HarvestFruit, targets)
                end
            end
        end
        task.wait(state.harvestInterval)
    end
end)

task.spawn(function()
    while state.running do
        if state.autoPlant then
            local plantType = getActivePlantType()
            if plantType and hasSeedForPlantType(plantType) then
                local pos = getNextAutoPlantPosition(state.autoTeleportGardenForPlant)
                if pos then
                    safeInvoke(RF_PlantSeed, plantType, pos)
                end
            else
                local shopItem = getShopItemForPlantType(plantType)
                if shopItem and state.autoBuyPlantSeed then
                    purchaseSeedShopItem(shopItem)
                end
            end
        end
        task.wait(state.plantInterval)
    end
end)

task.spawn(function()
    while state.running do
        if state.autoSell then
            if not state.sellOnFull or getToolCount() >= state.sellThreshold then
                performSell(state.sellMode)
            end
        end
        task.wait(state.sellInterval)
    end
end)

task.spawn(function()
    while state.running do
        if state.autoBuyAllSeeds then
            buyNextSeedInOrder()
            task.wait(math.max(0.1, state.buyDelay))
        elseif state.autoBuySeed then
            buySelectedSeedOnce()
            task.wait(math.max(0.1, state.buyInterval))
        else
            task.wait(0.1)
        end
    end
end)

task.spawn(function()
    while state.running do
        if state.autoBuyAllGears then
            buyNextGearInOrder()
            task.wait(math.max(0.1, state.buyDelay))
        elseif state.autoBuyGear then
            buySelectedGearOnce()
            task.wait(math.max(0.1, state.buyInterval))
        else
            task.wait(0.1)
        end
    end
end)

task.spawn(function()
    while state.running do
        if state.autoRefreshGrid then
            refreshPlantPositions()
        end
        task.wait(state.gridRefreshInterval)
    end
end)

task.spawn(function()
    while state.running do
        if state.plantRotation and state.rotationList and #state.rotationList > 0 then
            state.rotationIndex = state.rotationIndex + 1
            if state.rotationIndex > #state.rotationList then
                state.rotationIndex = 1
            end
        end
        task.wait(state.rotationInterval)
    end
end)

task.spawn(function()
    while state.running do
        if state.autoHarvestBell then
            local tool, equipped = findToolByName("Harvest Bell")
            if tool then
                if not equipped then
                    equipTool(tool)
                end
                local targetUuid = findHarvestBellTarget()
                if targetUuid then
                    safeFire(RE_UseGear, tool, { targetUuid = targetUuid })
                end
            end
        end
        task.wait(state.harvestBellInterval)
    end
end)

task.spawn(function()
    while state.running do
        if state.autoFavorite then
            local tool, equipped = findToolByName("Favorite Tool")
            if tool then
                if not equipped then
                    equipTool(tool)
                end
                local uuid, growthIndex = findFavoriteTarget()
                if uuid then
                    safeFire(RE_UseGear, tool, {
                        PlantUuid = uuid,
                        GrowthAnchorIndex = growthIndex
                    })
                end
            end
        end
        task.wait(state.favoriteInterval)
    end
end)

task.spawn(function()
    while state.running do
        if state.autoSellValue then
            local tool = findValuableTool()
            if tool then
                equipTool(tool)
                task.wait(0.05)
                performSell("SellSingle")
            end
        end
        task.wait(state.sellValueInterval)
    end
end)

task.spawn(function()
    while state.running do
        if state.autoSellKeep then
            local counts = buildToolCounts()
            for _, tool in ipairs(collectTools()) do
                if tool:IsA("Tool") and isHarvestItem(tool) then
                    local base = getToolBaseName(tool)
                    local keepLimit = getKeepLimit(base)
                    local count = counts[base] or 0
                    if count > keepLimit then
                        equipTool(tool)
                        task.wait(0.05)
                        performSell("SellSingle")
                        counts[base] = count - 1
                        break
                    end
                end
            end
        end
        task.wait(state.keepInterval)
    end
end)

task.spawn(function()
    while state.running do
        if state.autoSprinkler then
            if countSprinklers() < state.sprinklerMax then
                if state.sprinklerAutoTeleport then
                    teleportToGarden()
                end
                local tool, equipped = findToolByName(state.sprinklerType)
                if tool then
                    if not equipped then
                        equipTool(tool)
                    end
                    if #sprinklerPositions == 0 then
                        refreshSprinklerPositions()
                    end
                    local pos = nextSprinklerPosition()
                    if pos then
                        safeFire(RE_UseGear, tool, { position = pos })
                    end
                end
            end
        end
        task.wait(state.sprinklerInterval)
    end
end)

task.spawn(function()
    while state.running do
        if state.autoClaimCash then
            safeInvoke(RF_ClaimSoftlockCash)
        end
        task.wait(state.claimInterval)
    end
end)

task.spawn(function()
    while state.running do
        if state.autoMerge then
            local backpack = LocalPlayer:FindFirstChild("Backpack")
            if backpack then
                ItemInventory.mergeItemsInBackpack(backpack)
            end
        end
        task.wait(state.mergeInterval)
    end
end)

task.spawn(function()
    while state.running do
        inventoryLabel:Set("Tools: " .. tostring(getToolCount()))
        task.wait(1)
    end
end)

task.spawn(function()
    while state.running do
        if state.autoSaveConfig then
            saveConfig()
        end
        task.wait(math.max(5, state.autoSaveInterval))
    end
end)

task.spawn(function()
    while state.running do
        if state.alertSpecial then
            local mutations, giants = countSpecialPlants()
            if alertLabel then
                alertLabel:Set(string.format("Mutations: %d | Giants: %d", mutations, giants))
            end
            if state.alertNotify then
                if mutations > state.lastMutationCount then
                    if Rayfield and Rayfield.Notify then
                        Rayfield:Notify({
                            Title = "Mutation Found",
                            Content = "Mutations: " .. tostring(mutations),
                            Duration = 4
                        })
                    end
                end
                if giants > state.lastGiantCount then
                    if Rayfield and Rayfield.Notify then
                        Rayfield:Notify({
                            Title = "Giant Found",
                            Content = "Giants: " .. tostring(giants),
                            Duration = 4
                        })
                    end
                end
            end
            state.lastMutationCount = mutations
            state.lastGiantCount = giants
        end
        task.wait(state.alertInterval)
    end
end)

task.spawn(function()
    while state.running do
        if state.autoQuest then
            claimCompletedQuests()
        end
        task.wait(state.questClaimInterval)
    end
end)

task.spawn(function()
    while state.running do
        if state.autoQuest then
            if not questData or (os.clock() - lastQuestRequest > 30) then
                requestQuests()
            end
            local category, slot, quest = pickQuestTarget()
            if quest then
                state.questTargetType = quest.Type
                state.questTargetItem = quest.Item
                state.questTargetCategory = category
                state.questTargetSlot = slot
                questStatus:Set(string.format("Target: %s %s (%s) %d/%d", category, tostring(slot), tostring(quest.Type), quest.Progress or 0, quest.Goal or 0))
                if state.questRefresh then
                    local unsupported = not questSupported(quest)
                    if quest.Type == "PlantSeeds" and not questSeedInShop(quest.Item) then
                        unsupported = true
                    end
                    if unsupported then
                        local resets = 0
                        if questData and questData[category] and questData[category].ResetCounts then
                            resets = questData[category].ResetCounts[tostring(slot)] or 0
                        end
                        local price = getQuestRefreshPrice(category, resets)
                        local shillings = getShillings()
                        if price <= state.questRefreshMaxPrice and shillings >= price and shillings >= state.questRefreshMinShillings then
                            safeFire(RE_PurchaseQuestRefresh, category, tostring(slot))
                            task.delay(0.5, requestQuests)
                        end
                    end
                end
            else
                state.questTargetType = nil
                state.questTargetItem = nil
                state.questTargetCategory = nil
                state.questTargetSlot = nil
                questStatus:Set("Target: none")
            end
        else
            state.questTargetType = nil
            state.questTargetItem = nil
            state.questTargetCategory = nil
            state.questTargetSlot = nil
            questStatus:Set("Target: none")
        end
        task.wait(state.questInterval)
    end
end)

task.spawn(function()
    while state.running do
        if state.autoQuest and state.questTargetType == "PlantSeeds" and state.questTargetItem then
            local plantType = state.questTargetItem
            if hasSeedForPlantType(plantType) then
                if state.questAutoTeleport then
                    ensureTeleported("garden")
                end
                local pos = getNextAutoPlantPosition(state.questAutoTeleport)
                if pos then
                    safeInvoke(RF_PlantSeed, plantType, pos)
                end
            else
                local shopItem = getShopItemForPlantType(plantType)
                if shopItem and (os.clock() - lastQuestBuy > state.questBuyInterval) then
                    lastQuestBuy = os.clock()
                    purchaseSeedShopItem(shopItem)
                end
            end
        end
        task.wait(state.questPlantInterval)
    end
end)

task.spawn(function()
    while state.running do
        if state.autoQuest and state.questTargetType == "HarvestCrops" and state.questTargetItem then
            if state.questAutoTeleport then
                ensureTeleported("garden")
            end
            local targets = collectHarvestTargets(state.questTargetItem)
            if #targets > 0 and getToolCount() < state.inventoryLimit then
                safeFire(RE_HarvestFruit, targets)
            end
        end
        task.wait(state.questHarvestInterval)
    end
end)

task.spawn(function()
    while state.running do
        if state.autoQuest and state.questTargetType == "GainShillings" then
            if not state.questAllowSell then
                if state.questNotifySell and os.clock() - lastQuestNotify > 10 then
                    lastQuestNotify = os.clock()
                    if Rayfield and Rayfield.Notify then
                        Rayfield:Notify({
                            Title = "Quest Requires Selling",
                            Content = "Enable 'Allow Auto Sell (Shillings Quest)' to complete this quest.",
                            Duration = 5
                        })
                    end
                end
            else
                if state.questAutoTeleport then
                    ensureTeleported("garden")
                end
                local targets = collectHarvestTargets(nil)
                if #targets > 0 and getToolCount() < state.inventoryLimit then
                    safeFire(RE_HarvestFruit, targets)
                end
                performSell("SellAll")
            end
        end
        task.wait(math.max(1, state.questHarvestInterval))
    end
end)

Rayfield:Notify({
    Title = "Garden Horizon",
    Content = "Loaded. Configure features in the tabs.",
    Duration = 4
})
