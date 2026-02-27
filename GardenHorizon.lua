-- Garden Horizon Script Hub
-- Uses Rayfield UI

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Rayfield

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
local RE_UnseatPlayer = Remotes:WaitForChild("UnseatPlayer")

local ItemInventory = require(ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("ItemInventory"))
local SeedShopData = require(ReplicatedStorage:WaitForChild("Shop"):WaitForChild("ShopData"):WaitForChild("SeedShopData")).ShopData
local GearShopData = require(ReplicatedStorage:WaitForChild("Shop"):WaitForChild("ShopData"):WaitForChild("GearShopData")).ShopData
local PlantData = require(ReplicatedStorage:WaitForChild("Plants"):WaitForChild("Definitions"):WaitForChild("PlantDataDefinitions"))
local FruitValueCalculator = require(ReplicatedStorage:WaitForChild("Economy"):WaitForChild("FruitValueCalculator"))

local function safeInvoke(remote, ...)
    local ok, result = pcall(function()
        return remote:InvokeServer(...)
    end)
    if ok then
        return result
    end
    return nil
end

local function safeFire(remote, ...)
    pcall(function()
        remote:FireServer(...)
    end)
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
table.sort(seedShopItems)

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

    autoHarvest = false,
    harvestInterval = 0.4,
    harvestBatch = 60,
    mutationFilter = "All",
    skipFavorited = true,
    inventoryLimit = 300,

    autoHarvestBell = false,
    harvestBellInterval = 1.5,
    harvestBellRadius = 25,
    harvestBellSkipFavorited = true,

    autoFavorite = false,
    favoriteMutations = true,
    favoriteGiants = true,
    favoriteInterval = 2,

    autoPlant = false,
    plantType = plantTypes[1] or "Carrot",
    plantInterval = 0.4,
    plantSpacing = 3,
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
    buyDelay = 0.2,
    buyInterval = 15,
    minShillingsToBuy = 0,

    autoMerge = false,
    mergeInterval = 10,

    antiAfk = true,
    autoClaimCash = false,
    claimInterval = 60,

    restockNotify = true,

    autoQuest = false,
    questDaily = true,
    questWeekly = true,
    questAllowSell = false,
    questAutoTeleport = true,
    questInterval = 5,
    questPlantInterval = 0.4,
    questHarvestInterval = 0.4,
    questBuyInterval = 5,
    questTargetType = nil,
    questTargetItem = nil,
    questTargetCategory = nil,
    questTargetSlot = nil,
    questNotifySell = true
}

local antiAfkConnection = nil
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

local function stopAll()
    state.running = false
    state.autoSell = false
    state.autoSellValue = false
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
    state.autoQuest = false
    setAntiAfk(false)
    setRestockNotify(false)
end

local function canBuy(required)
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

local plantPositions = {}
local plantIndex = 1

local function refreshPlantPositions()
    plantPositions = buildPlantPositions(state.plantSpacing)
    plantIndex = 1
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

local function getShopItemForPlantType(plantType)
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
                    if filterPlantType and plantType ~= filterPlantType then
                        goto continue
                    end
                    if shouldHarvestByMutation(model) then
                        table.insert(list, data)
                        if #list >= state.harvestBatch then
                            break
                        end
                    end
                end
            end
        end
        ::continue::
    end
    return list
end

local function buyAllSeedsOnce()
    for _, itemName in ipairs(seedShopItems) do
        local price = seedShopPrices[itemName]
        if canBuy(price) then
            safeInvoke(RF_PurchaseShopItem, "SeedShop", itemName)
            task.wait(state.buyDelay)
        end
    end
end

local function buyAllGearsOnce()
    for _, itemName in ipairs(gearShopItems) do
        local price = gearShopPrices[itemName]
        if canBuy(price) then
            safeInvoke(RF_PurchaseShopItem, "GearShop", itemName)
            task.wait(state.buyDelay)
        end
    end
end

local function buySelectedSeedOnce()
    if state.selectedSeedShopItem then
        local price = seedShopPrices[state.selectedSeedShopItem]
        if canBuy(price) then
            safeInvoke(RF_PurchaseShopItem, "SeedShop", state.selectedSeedShopItem)
        end
    end
end

local function buySelectedGearOnce()
    if state.selectedGearShopItem then
        local price = gearShopPrices[state.selectedGearShopItem]
        if canBuy(price) then
            safeInvoke(RF_PurchaseShopItem, "GearShop", state.selectedGearShopItem)
        end
    end
end

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

local function pickQuestTarget()
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
                if quest and not quest.Claimed then
                    if quest.Progress >= quest.Goal then
                        claimQuest(category, i)
                    else
                        return category, i, quest
                    end
                end
            end
        end
    end
    return nil, nil, nil
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

FarmingTab:CreateSection("Harvest")

FarmingTab:CreateToggle({
    Name = "Auto Harvest",
    CurrentValue = false,
    Callback = function(value)
        state.autoHarvest = value
    end
})

FarmingTab:CreateDropdown({
    Name = "Mutation Filter",
    Options = { "All", "Only Mutated", "Only Non-Mutated" },
    CurrentOption = "All",
    MultipleOptions = false,
    Callback = function(option)
        state.mutationFilter = option
    end
})

FarmingTab:CreateToggle({
    Name = "Skip Favorited",
    CurrentValue = true,
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
    CurrentValue = false,
    Callback = function(value)
        state.autoHarvestBell = value
    end
})

FarmingTab:CreateToggle({
    Name = "Skip Favorited (Bell)",
    CurrentValue = true,
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
    CurrentValue = false,
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
    CurrentValue = false,
    Callback = function(value)
        state.autoPlant = value
        if value then
            refreshPlantPositions()
        end
    end
})

FarmingTab:CreateToggle({
    Name = "Use Equipped Seed",
    CurrentValue = false,
    Callback = function(value)
        state.useEquippedSeed = value
    end
})

FarmingTab:CreateToggle({
    Name = "Auto Buy Needed Seed (Auto Plant)",
    CurrentValue = false,
    Callback = function(value)
        state.autoBuyPlantSeed = value
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
    CurrentValue = false,
    Callback = function(value)
        state.plantRotation = value
    end
})

FarmingTab:CreateDropdown({
    Name = "Rotation Types",
    Options = plantTypes,
    CurrentOption = {},
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
    CurrentValue = false,
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

FarmingTab:CreateSection("Selling")

FarmingTab:CreateToggle({
    Name = "Auto Sell",
    CurrentValue = false,
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
    CurrentValue = false,
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

FarmingTab:CreateToggle({
    Name = "Auto Sell By Value",
    CurrentValue = false,
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
        safeInvoke(RF_SellItems, "SellAll")
    end
})

ShopTab:CreateSection("Seeds")

ShopTab:CreateToggle({
    Name = "Auto Buy All Seeds",
    CurrentValue = false,
    Callback = function(value)
        state.autoBuyAllSeeds = value
    end
})

ShopTab:CreateToggle({
    Name = "Auto Buy Selected Seed",
    CurrentValue = false,
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
    CurrentValue = false,
    Callback = function(value)
        state.autoBuyAllGears = value
    end
})

ShopTab:CreateToggle({
    Name = "Auto Buy Selected Gear",
    CurrentValue = false,
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

ShopTab:CreateSlider({
    Name = "Buy Delay Between Items (sec)",
    Range = { 0.05, 2 },
    Increment = 0.05,
    Suffix = "s",
    CurrentValue = state.buyDelay,
    Callback = function(value)
        state.buyDelay = value
    end
})

ShopTab:CreateSlider({
    Name = "Auto Buy Loop Interval (sec)",
    Range = { 5, 300 },
    Increment = 5,
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
    CurrentValue = false,
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
    CurrentValue = false,
    Callback = function(value)
        state.autoQuest = value
        if value then
            requestQuests()
        end
    end
})

QuestTab:CreateToggle({
    Name = "Include Daily",
    CurrentValue = true,
    Callback = function(value)
        state.questDaily = value
    end
})

QuestTab:CreateToggle({
    Name = "Include Weekly",
    CurrentValue = true,
    Callback = function(value)
        state.questWeekly = value
    end
})

QuestTab:CreateToggle({
    Name = "Allow Auto Sell (Shillings Quest)",
    CurrentValue = false,
    Callback = function(value)
        state.questAllowSell = value
    end
})

QuestTab:CreateToggle({
    Name = "Auto Teleport For Quests",
    CurrentValue = true,
    Callback = function(value)
        state.questAutoTeleport = value
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
    CurrentValue = false,
    Callback = function(value)
        state.autoClaimCash = value
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
                if #plantPositions == 0 then
                    refreshPlantPositions()
                end
                local pos = nextPlantPosition()
                if pos then
                    safeInvoke(RF_PlantSeed, plantType, pos)
                end
            else
                local shopItem = getShopItemForPlantType(plantType)
                if shopItem and state.autoBuyPlantSeed then
                    local price = seedShopPrices[shopItem]
                    if canBuy(price) then
                        safeInvoke(RF_PurchaseShopItem, "SeedShop", shopItem)
                    end
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
                safeInvoke(RF_SellItems, state.sellMode)
            end
        end
        task.wait(state.sellInterval)
    end
end)

task.spawn(function()
    while state.running do
        if state.autoBuyAllSeeds then
            buyAllSeedsOnce()
        elseif state.autoBuySeed then
            buySelectedSeedOnce()
        end
        task.wait(state.buyInterval)
    end
end)

task.spawn(function()
    while state.running do
        if state.autoBuyAllGears then
            buyAllGearsOnce()
        elseif state.autoBuyGear then
            buySelectedGearOnce()
        end
        task.wait(state.buyInterval)
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
                safeInvoke(RF_SellItems, "SellSingle")
            end
        end
        task.wait(state.sellValueInterval)
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
                if #plantPositions == 0 then
                    refreshPlantPositions()
                end
                local pos = nextPlantPosition()
                if pos then
                    safeInvoke(RF_PlantSeed, plantType, pos)
                end
            else
                local shopItem = getShopItemForPlantType(plantType)
                if shopItem and (os.clock() - lastQuestBuy > state.questBuyInterval) then
                    lastQuestBuy = os.clock()
                    if state.questAutoTeleport then
                        teleportToSeeds()
                    end
                    local price = seedShopPrices[shopItem]
                    if canBuy(price) then
                        safeInvoke(RF_PurchaseShopItem, "SeedShop", shopItem)
                    end
                end
            end
        end
        task.wait(state.questPlantInterval)
    end
end)

task.spawn(function()
    while state.running do
        if state.autoQuest and state.questTargetType == "HarvestCrops" and state.questTargetItem then
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
                    teleportToSell()
                end
                local targets = collectHarvestTargets(nil)
                if #targets > 0 and getToolCount() < state.inventoryLimit then
                    safeFire(RE_HarvestFruit, targets)
                end
                safeInvoke(RF_SellItems, "SellAll")
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
