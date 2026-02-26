local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local playerDataContainer = player:WaitForChild("Data")
local playerData = playerDataContainer:WaitForChild("PlayerData")
local playerUpgrades = playerDataContainer:WaitForChild("Upgrades")

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local clickRemote = remotesFolder:WaitForChild("Clicker")
local buyUpgRemote = remotesFolder:WaitForChild("BuyUpg")

local upgradesModuleScript = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Upgrades")

local SCAN_SUMMARY = {
	files = 479,
	remoteCount = 32,
	playerDataFields = 73,
	referencedUpgradeIds = 327,
}

local DEFAULT_CLICK_INTERVAL = 0.1
local DEFAULT_BUY_INTERVAL = 0.15
local DEFAULT_AUTO_UPGRADE_STEP_DELAY = 0.06
local DEFAULT_AUTO_UPGRADE_SWEEP_DELAY = 0.35
local DEFAULT_PROGRESSION_INTERVAL = 0.8
local DEFAULT_DAILY_CLAIM_INTERVAL = 30
local DEFAULT_BLOCK_COLLECT_INTERVAL = 0.2
local DEFAULT_BLOCK_WALK_INTERVAL = 0.9
local DEFAULT_WORLD_SWITCH_COOLDOWN = 8
local DEFAULT_TOGGLE_KEY = Enum.KeyCode.RightShift

local PROFILE_FAST_REBIRTH = "Fast Rebirth"
local PROFILE_BALANCED = "Balanced"
local PROFILE_LATE_GAME = "Late Game"

local env = (getgenv and getgenv()) or _G
if type(env.__CLICKER_HUB_CLEANUP) == "function" then
	pcall(env.__CLICKER_HUB_CLEANUP)
end

local alive = true
local connections = {}

local autoClickEnabled = false
local autoUpgradeAllEnabled = false
local autoProgressionEnabled = false
local autoBlockCollectEnabled = false
local autoBlockWalkFallbackEnabled = true
local autoCompleteGameEnabled = false
local antiAfkEnabled = true
local autoProfileByWorldEnabled = false
local autoWorldRotateEnabled = true
local preferUpgradeWorldTargetEnabled = true
local preferHighestWorldFallbackEnabled = true

local clickInterval = DEFAULT_CLICK_INTERVAL
local buyInterval = DEFAULT_BUY_INTERVAL
local autoUpgradeStepDelay = DEFAULT_AUTO_UPGRADE_STEP_DELAY
local autoUpgradeSweepDelay = DEFAULT_AUTO_UPGRADE_SWEEP_DELAY
local progressionInterval = DEFAULT_PROGRESSION_INTERVAL
local dailyClaimInterval = DEFAULT_DAILY_CLAIM_INTERVAL
local blockCollectInterval = DEFAULT_BLOCK_COLLECT_INTERVAL
local blockWalkInterval = DEFAULT_BLOCK_WALK_INTERVAL
local worldSwitchCooldown = DEFAULT_WORLD_SWITCH_COOLDOWN
local uiToggleKey = DEFAULT_TOGGLE_KEY
local priorityProfile = PROFILE_BALANCED

local upgradeOptions = {}
local upgradeInfoById = {}
local sortedUpgradeIds = {}
local progressionAttempts = 0
local progressionFired = 0
local lastDailyAttemptAt = 0
local lastBuyAt = 0
local lastWorldSwitchAt = 0
local lastBlockWalkAt = 0
local worldRotationIndex = 0
local progressionActions

local WORLD_ROTATION_ORDER = {
	"Spawn",
	"Genesis",
	"Galaxy",
	"AntiWorld",
	"Supernova",
	"Tower",
	"God",
	"Obby",
	"Bigbang",
	"Void",
	"newWorld",
	"Cycle",
	"Hecker",
}

local WORLD_PRIORITY_DESC = {
	"Cycle",
	"newWorld",
	"Void",
	"Bigbang",
	"Obby",
	"God",
	"Tower",
	"Supernova",
	"AntiWorld",
	"Galaxy",
	"Genesis",
	"Spawn",
}

local CURRENCY_WORLD_HINTS = {
	Points = {"Spawn", "Genesis", "Galaxy"},
	Clicks = {"Spawn", "Genesis", "Galaxy"},
	PrestigePoints = {"Spawn", "Galaxy"},
	EvilPoints = {"Spawn", "Galaxy"},
	DarkEnergie = {"Galaxy", "Spawn"},
	DarkPrestigeEnergie = {"Galaxy", "Spawn"},
	Token = {"Galaxy", "Spawn"},
	DarkEvilEnergie = {"Galaxy", "Spawn"},
	AntiPoint = {"AntiWorld"},
	AntiPrestigePoint = {"AntiWorld"},
	AntiEvilPoint = {"AntiWorld"},
	SupernovaPoint = {"Supernova"},
	TowerPoints = {"Tower"},
	TowerPrestigePoints = {"Tower"},
	Beta = {"Bigbang"},
	Memories = {"Bigbang"},
	WorldCurrency = {"Void", "newWorld"},
	Shards = {"Void", "newWorld"},
	AscendPoints = {"Void", "newWorld"},
	VoidCurrency = {"Void", "newWorld"},
}

local remoteCache = {}
local function getRemote(name)
	local cached = remoteCache[name]
	if cached and cached.Parent then
		return cached
	end

	local found = remotesFolder:FindFirstChild(name)
	if found then
		remoteCache[name] = found
	end
	return found
end

local function fireRemote(name, ...)
	local remote = getRemote(name)
	if not remote then
		return false
	end

	local ok = pcall(function(...)
		remote:FireServer(...)
	end, ...)
	return ok
end

local Rayfield
local Window

local function connect(signal, callback)
	local conn = signal:Connect(callback)
	table.insert(connections, conn)
	return conn
end

local function notify(title, content, duration)
	if Rayfield and Rayfield.Notify then
		Rayfield:Notify({
			Title = title,
			Content = content,
			Duration = duration or 4
		})
	end
end

local function parseKeyCode(raw)
	if type(raw) ~= "string" then
		return nil
	end

	local normalized = string.lower(raw:gsub("%s+", ""))
	if normalized == "" then
		return nil
	end

	for _, keyCode in ipairs(Enum.KeyCode:GetEnumItems()) do
		if keyCode ~= Enum.KeyCode.Unknown then
			local keyName = string.lower(keyCode.Name:gsub("%s+", ""))
			if keyName == normalized then
				return keyCode
			end
		end
	end

	return nil
end

local function safeNumber(value)
	local numberValue = tonumber(value)
	if numberValue then
		return numberValue
	end
	return nil
end

local function buildUpgradeCatalog()
	local temp = {}

	local function ensure(id)
		if not temp[id] then
			temp[id] = {
				id = id,
				label = tostring(id),
				currency = "?",
				costDisplay = "?",
				maxDisplay = "?",
				unlockDisplay = "?",
				hasUnlockDisplay = "?",
				costRaw = nil,
				maxRaw = nil,
				unlockRaw = nil,
				hasUnlockRaw = nil,
			}
		end
		return temp[id]
	end

	for _, child in ipairs(playerUpgrades:GetChildren()) do
		local id = safeNumber(child.Name)
		if id and id >= 1 and id % 1 == 0 then
			ensure(id)
		end
	end

	local ok, moduleData = pcall(require, upgradesModuleScript)
	if ok and type(moduleData) == "table" then
		for key, entry in pairs(moduleData) do
			if type(entry) == "table" then
				local id = safeNumber(entry.Name) or safeNumber(key)
				if id and id >= 1 and id % 1 == 0 then
					local row = ensure(id)
					row.currency = tostring(entry.CurrencyCost or row.currency)
					row.costRaw = entry.Cost
					row.maxRaw = entry.Max
					row.unlockRaw = entry.Unlock
					row.hasUnlockRaw = entry.HasUnlock
					row.costDisplay = tostring(entry.Cost or row.costDisplay)
					row.maxDisplay = tostring(entry.Max or row.maxDisplay)
					row.unlockDisplay = tostring(entry.Unlock or row.unlockDisplay)
					row.hasUnlockDisplay = tostring(entry.HasUnlock or row.hasUnlockDisplay)
				end
			end
		end
	end

	local ids = {}
	for id, _ in pairs(temp) do
		table.insert(ids, id)
	end
	table.sort(ids)

	local options = {}
	local byId = {}
	for _, id in ipairs(ids) do
		local row = temp[id]
		local label = string.format(
			"%d | %s | Cost:%s | Max:%s | Unl:%s | Req:%s",
			id,
			row.currency,
			row.costDisplay,
			row.maxDisplay,
			row.unlockDisplay,
			row.hasUnlockDisplay
		)
		row.label = label
		byId[id] = row
		table.insert(options, label)
	end

	return options, byId, ids
end

local function doClick()
	if alive then
		clickRemote:FireServer()
	end
end

local function doBuy(id)
	if not alive then
		return false
	end
	if not id then
		return false
	end
	local now = os.clock()
	if now - lastBuyAt < buyInterval then
		return false
	end
	lastBuyAt = now
	buyUpgRemote:FireServer(id)
	return true
end

local function getUpgradeValueById(id)
	local obj = playerUpgrades:FindFirstChild(tostring(id))
	if not obj then
		return nil
	end
	if obj:IsA("IntValue") or obj:IsA("NumberValue") then
		return obj.Value
	end
	return nil
end

local function getPlayerDataValueByName(name)
	local obj = playerData:FindFirstChild(name)
	if not obj then
		return nil
	end
	local ok, result = pcall(function()
		return obj.Value
	end)
	if ok then
		return result
	end
	return nil
end

local function asNumber(value)
	if type(value) == "number" then
		return value
	end
	if type(value) == "string" then
		return tonumber(value)
	end
	return nil
end

local PROFILE_DESCRIPTIONS = {
	[PROFILE_FAST_REBIRTH] = "Prioritizes fast reset loops and unlock chains.",
	[PROFILE_BALANCED] = "General-purpose ordering for mixed progression.",
	[PROFILE_LATE_GAME] = "Prioritizes late-world and endgame currencies.",
}

local UPGRADE_PROFILE_WEIGHTS = {
	[PROFILE_FAST_REBIRTH] = {
		Points = 10, Clicks = 12, PrestigePoints = 20, EvilPoints = 30,
		DarkEnergie = 40, DarkPrestigeEnergie = 45, Token = 50, DarkEvilEnergie = 55,
		AntiPoint = 60, AntiPrestigePoint = 65, AntiEvilPoint = 70, SupernovaPoint = 75,
		TowerPoints = 80, TowerPrestigePoints = 85, Beta = 95, AscendPoints = 110,
		WorldCurrency = 120, Shards = 130, Memories = 140
	},
	[PROFILE_BALANCED] = {
		Points = 30, Clicks = 32, PrestigePoints = 36, EvilPoints = 40,
		DarkEnergie = 48, DarkPrestigeEnergie = 52, Token = 56, DarkEvilEnergie = 60,
		AntiPoint = 68, AntiPrestigePoint = 72, AntiEvilPoint = 76, SupernovaPoint = 80,
		TowerPoints = 84, TowerPrestigePoints = 88, Beta = 92, AscendPoints = 96,
		WorldCurrency = 102, Shards = 106, Memories = 110
	},
	[PROFILE_LATE_GAME] = {
		AscendPoints = 10, WorldCurrency = 12, Shards = 14, Memories = 16,
		Beta = 20, Currency3 = 24, Currency4 = 26, Currency5 = 28, VoidCurrency = 30,
		Hecker = 34, TowerPrestigePoints = 38, TowerPoints = 40, SupernovaPoint = 45,
		AntiEvilPoint = 55, AntiPrestigePoint = 58, AntiPoint = 60,
		DarkEvilEnergie = 65, Token = 68, DarkPrestigeEnergie = 72, DarkEnergie = 75,
		EvilPoints = 80, PrestigePoints = 84, Clicks = 90, Points = 95
	},
}

local WORLD_CURRENCY_BONUS = {
	Spawn = { Points = -10, Clicks = -8 },
	Genesis = { Points = -10, Clicks = -8 },
	Tower = { TowerPoints = -18, TowerPrestigePoints = -16, Points = -3 },
	BlackHole = { DarkEnergie = -20, DarkPrestigeEnergie = -18, Token = -15, DarkEvilEnergie = -12 },
	AntiWorld = { AntiPoint = -18, AntiPrestigePoint = -16, AntiEvilPoint = -14 },
	Supernova = { SupernovaPoint = -20, Shards = -12 },
	Bigbang = { Beta = -15, Memories = -12, Currency4 = -10, Currency5 = -10 },
	Void = { WorldCurrency = -18, Shards = -15, AscendPoints = -12, VoidCurrency = -10 },
	newWorld = { WorldCurrency = -18, Shards = -15, AscendPoints = -12, VoidCurrency = -10 },
}

local PROGRESSION_PROFILE_WEIGHTS = {
	[PROFILE_FAST_REBIRTH] = {
		Prestige = 1, Evil = 2, DarkPrestige = 3, Token = 4, DarkEvil = 5,
		AntiPrestige = 6, AntiEvil = 7, Supernova = 8, TowerPrestige = 9,
		Beta = 10, Bigbang = 11, Ascend = 12, Loop = 13, Cycle = 14, UnlockedUnderwater = 15, Daily = 99
	},
	[PROFILE_BALANCED] = {
		Prestige = 3, Evil = 4, DarkPrestige = 5, Token = 6, DarkEvil = 7,
		AntiPrestige = 8, AntiEvil = 9, Supernova = 10, TowerPrestige = 11,
		Beta = 12, Bigbang = 13, Ascend = 14, Loop = 15, Cycle = 16, UnlockedUnderwater = 17, Daily = 90
	},
	[PROFILE_LATE_GAME] = {
		Ascend = 1, Cycle = 2, Loop = 3, Supernova = 4, Bigbang = 5, Beta = 6,
		AntiEvil = 7, AntiPrestige = 8, DarkEvil = 9, Token = 10, DarkPrestige = 11,
		Evil = 12, TowerPrestige = 13, Prestige = 14, UnlockedUnderwater = 15, Daily = 30
	},
}

local PROGRESSION_WORLD_BONUS = {
	Tower = { TowerPrestige = -200 },
	Supernova = { Supernova = -200 },
	AntiWorld = { AntiPrestige = -140, AntiEvil = -120 },
	Galaxy = { DarkPrestige = -120, Token = -110, DarkEvil = -100 },
	Spawn = { Prestige = -100, Evil = -90 },
	Bigbang = { Bigbang = -180, Beta = -120 },
	Void = { Ascend = -180, Cycle = -120 },
	newWorld = { Ascend = -180, Cycle = -120 },
	Cycle = { Cycle = -200 },
}

local function getUpgradeWeightForProfile(currency)
	local tableForProfile = UPGRADE_PROFILE_WEIGHTS[priorityProfile] or UPGRADE_PROFILE_WEIGHTS[PROFILE_BALANCED]
	return tableForProfile[currency] or 500
end

local function getWorldCurrencyAdjustment(worldIn, currency)
	local worldTable = WORLD_CURRENCY_BONUS[worldIn]
	if not worldTable then
		return 0
	end
	return worldTable[currency] or 0
end

local function getUpgradePriorityScore(id, row, worldIn)
	local currency = row and row.currency or "?"
	local score = getUpgradeWeightForProfile(currency) + getWorldCurrencyAdjustment(worldIn, currency)

	local unlockNumber = nil
	if row and row.unlockRaw ~= nil then
		unlockNumber = asNumber(row.unlockRaw)
	end
	if unlockNumber and unlockNumber > 0 then
		score = score + math.min(unlockNumber * 0.02, 20)
	end

	local maxNumber = row and asNumber(row.maxRaw) or nil
	if maxNumber and maxNumber == 1 then
		score = score - 1
	end

	return score + (id * 0.001)
end

local function getOrderedUpgradeIdsForProfile()
	local worldIn = tostring(getPlayerDataValueByName("WorldIn") or "")
	local ids = {}
	for _, id in ipairs(sortedUpgradeIds) do
		table.insert(ids, id)
	end

	table.sort(ids, function(a, b)
		local rowA = upgradeInfoById[a]
		local rowB = upgradeInfoById[b]
		local scoreA = getUpgradePriorityScore(a, rowA, worldIn)
		local scoreB = getUpgradePriorityScore(b, rowB, worldIn)
		return scoreA < scoreB
	end)

	return ids
end

local function getOrderedProgressionActions()
	local weights = PROGRESSION_PROFILE_WEIGHTS[priorityProfile] or PROGRESSION_PROFILE_WEIGHTS[PROFILE_BALANCED]
	local worldIn = tostring(getPlayerDataValueByName("WorldIn") or "")
	local worldBonus = PROGRESSION_WORLD_BONUS[worldIn]
	local ordered = {}
	for _, action in ipairs(progressionActions) do
		table.insert(ordered, action)
	end

	local function effectiveWeight(action)
		local weight = weights[action.key] or 999
		if worldBonus and worldBonus[action.key] then
			weight = weight + worldBonus[action.key]
		end
		return weight
	end

	table.sort(ordered, function(a, b)
		local aWeight = effectiveWeight(a)
		local bWeight = effectiveWeight(b)
		if aWeight == bWeight then
			return a.key < b.key
		end
		return aWeight < bWeight
	end)

	return ordered
end

local function getRecommendedProfileByWorld(worldIn)
	if worldIn == "Spawn" or worldIn == "Genesis" then
		return PROFILE_FAST_REBIRTH
	end
	if worldIn == "Void" or worldIn == "newWorld" or worldIn == "Bigbang" then
		return PROFILE_LATE_GAME
	end
	return PROFILE_BALANCED
end

local function applyRecommendedProfile()
	local worldIn = tostring(getPlayerDataValueByName("WorldIn") or "")
	local recommended = getRecommendedProfileByWorld(worldIn)
	priorityProfile = recommended
	notify("Recommended Profile", "World: " .. worldIn .. " -> " .. recommended, 5)
end

local function isTruePlayerFlag(flagName)
	return getPlayerDataValueByName(flagName) == true
end

local function isUpgradeAtLeast(id, needed)
	local current = getUpgradeValueById(id)
	if current == nil then
		return false
	end
	return current >= (needed or 1)
end

local function isUnlockedOrUpgrade(flagName, upgradeId)
	if isTruePlayerFlag(flagName) then
		return true
	end
	if upgradeId then
		return isUpgradeAtLeast(upgradeId, 1)
	end
	return false
end

local progressionActionState = {
	Prestige = true,
	Evil = true,
	DarkPrestige = true,
	Token = true,
	DarkEvil = true,
	AntiPrestige = true,
	AntiEvil = true,
	Supernova = true,
	TowerPrestige = true,
	Beta = true,
	Bigbang = true,
	Ascend = true,
	Loop = true,
	Cycle = true,
	UnlockedUnderwater = true,
	Daily = true,
}

progressionActions = {
	{
		key = "Prestige",
		name = "Prestige",
		ready = function()
			return isUnlockedOrUpgrade("UnlockedPrestiges", 14)
		end,
	},
	{
		key = "Evil",
		name = "Evil",
		ready = function()
			return isUnlockedOrUpgrade("UnlockedEvil", 46)
		end,
	},
	{
		key = "DarkPrestige",
		name = "DarkPrestige",
		ready = function()
			return isUnlockedOrUpgrade("UnlockedDarkPrestiges", 118)
		end,
	},
	{
		key = "Token",
		name = "Token",
		ready = function()
			return isUnlockedOrUpgrade("UnlockedToken", 133)
		end,
	},
	{
		key = "DarkEvil",
		name = "DarkEvil",
		ready = function()
			return isUnlockedOrUpgrade("UnlockedDarkEvil", 142)
		end,
	},
	{
		key = "AntiPrestige",
		name = "AntiPrestige",
		ready = function()
			return isUnlockedOrUpgrade("UnlockedAntiPrestige", 167)
		end,
	},
	{
		key = "AntiEvil",
		name = "AntiEvil",
		ready = function()
			return isUnlockedOrUpgrade("UnlockedAntiEvil", 181)
		end,
	},
	{
		key = "Supernova",
		name = "Supernova",
		ready = function()
			local loopValue = asNumber(getPlayerDataValueByName("Loop")) or 0
			return isTruePlayerFlag("UnlockedSupernova") or loopValue >= 11
		end,
	},
	{
		key = "TowerPrestige",
		name = "TowerPrestige",
		ready = function()
			return isUnlockedOrUpgrade("UnlockedTowerPrestige", 281)
		end,
	},
	{
		key = "Beta",
		name = "Beta",
		ready = function()
			return isUnlockedOrUpgrade("UnlockedBeta", 295)
		end,
	},
	{
		key = "Bigbang",
		name = "Bigbang",
		ready = function()
			return isUnlockedOrUpgrade("UnlockedBigbang", 311)
		end,
	},
	{
		key = "Ascend",
		name = "Ascend",
		ready = function()
			return isUnlockedOrUpgrade("UnlockedAscend", 380)
		end,
	},
	{
		key = "Loop",
		name = "Loop",
		ready = function()
			local loopValue = getPlayerDataValueByName("Loop")
			return isUpgradeAtLeast(96, 1) or loopValue ~= nil
		end,
	},
	{
		key = "Cycle",
		name = "Cycle",
		ready = function()
			local cycleValue = getPlayerDataValueByName("Cycle")
			return isUpgradeAtLeast(405, 1) or cycleValue ~= nil
		end,
	},
	{
		key = "UnlockedUnderwater",
		name = "UnlockedUnderwater",
		ready = function()
			return isUpgradeAtLeast(31, 1) and not isTruePlayerFlag("UnlockedUnderwater")
		end,
	},
	{
		key = "Daily",
		name = "Daily",
		ready = function()
			if not isUpgradeAtLeast(30, 1) then
				return false
			end
			local now = os.clock()
			if now - lastDailyAttemptAt < dailyClaimInterval then
				return false
			end
			return true
		end,
	},
}

local function runProgressionTick()
	local attempted = 0
	local fired = 0

	local orderedActions = getOrderedProgressionActions()
	for _, action in ipairs(orderedActions) do
		if not alive then
			break
		end
		if not autoProgressionEnabled then
			break
		end

		if progressionActionState[action.key] then
			local ready = false
			local ok, result = pcall(action.ready)
			if ok and result then
				ready = true
			end

			if ready then
				attempted = attempted + 1
				local sent = fireRemote(action.name)
				if sent then
					fired = fired + 1
					if action.key == "Daily" then
						lastDailyAttemptAt = os.clock()
					end
				end
				task.wait(0.03)
			end
		end
	end

	progressionAttempts = progressionAttempts + attempted
	progressionFired = progressionFired + fired

	return attempted, fired
end

local function tryCollectBlockRemote()
	return fireRemote("BlockCollected")
end

local function findClosestCollectableBlock(position, maxDistance)
	local bestPart = nil
	local bestDistance = maxDistance

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") then
			local nameLower = string.lower(obj.Name)
			local parentNameLower = obj.Parent and string.lower(obj.Parent.Name) or ""
			local looksLikeBlock = string.find(nameLower, "block", 1, true) or string.find(parentNameLower, "block", 1, true)
			if looksLikeBlock and obj.Transparency < 1 then
				local maxAxis = math.max(obj.Size.X, obj.Size.Y, obj.Size.Z)
				if maxAxis <= 12 then
					local distance = (obj.Position - position).Magnitude
					if distance < bestDistance then
						bestDistance = distance
						bestPart = obj
					end
				end
			end
		end
	end

	return bestPart
end

local function walkToNearestBlock()
	local character = player.Character
	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then
		return false
	end

	local target = findClosestCollectableBlock(rootPart.Position, 250)
	if not target then
		return false
	end

	humanoid:MoveTo(target.Position + Vector3.new(0, 2, 0))
	return true
end

local function resolveUpgradeReference(value)
	local numberValue = asNumber(value)
	if numberValue and numberValue % 1 == 0 then
		return numberValue
	end
	return nil
end

local function isUnlockLikelyMet(row)
	if not row then
		return true
	end

	local unlock = row.unlockRaw
	local hasUnlock = row.hasUnlockRaw

	local unlockId = resolveUpgradeReference(unlock)
	if unlockId then
		if unlockId ~= 0 then
			local unlockValue = getUpgradeValueById(unlockId)
			if not unlockValue or unlockValue <= 0 then
				return false
			end
		end

		local hasUnlockId = resolveUpgradeReference(hasUnlock)
		if hasUnlockId and hasUnlockId ~= 0 then
			local hasUnlockValue = getUpgradeValueById(hasUnlockId)
			if not hasUnlockValue or hasUnlockValue <= 0 then
				return false
			end
		end
		return true
	end

	if unlock == "Loop" then
		local needed = asNumber(hasUnlock) or 0
		local current = asNumber(getPlayerDataValueByName("Loop")) or 0
		return current >= needed
	end
	if unlock == "Stage" then
		local needed = asNumber(hasUnlock) or 0
		local current = asNumber(getPlayerDataValueByName("Stage")) or 0
		return current >= needed
	end
	if unlock == "UnlockedSupernova" then
		return getPlayerDataValueByName("UnlockedSupernova") == true
	end
	if unlock == "SupernovaMilestone" then
		local needed = asNumber(hasUnlock) or 0
		local current = asNumber(getPlayerDataValueByName("SupernovaMilestone")) or 0
		return current >= needed
	end

	return true
end

local function getResolvedMax(row)
	if not row then
		return nil
	end

	local maxValue = row.maxRaw
	if type(maxValue) == "function" then
		local ok, result = pcall(maxValue, player, true)
		if ok then
			return asNumber(result)
		end
		return nil
	end

	return asNumber(maxValue)
end

local function getResolvedCost(id, row)
	if not row then
		return nil
	end

	local costValue = row.costRaw
	if type(costValue) == "function" then
		local currentLevel = getUpgradeValueById(id) or 0
		local ok, result = pcall(costValue, player, currentLevel, true)
		if ok then
			return asNumber(result)
		end
		local ok2, result2 = pcall(costValue, player)
		if ok2 then
			return asNumber(result2)
		end
		return nil
	end

	return asNumber(costValue)
end

local function isLikelyMaxed(id, row)
	local current = getUpgradeValueById(id)
	if current == nil then
		return false
	end

	local resolvedMax = getResolvedMax(row)
	if resolvedMax then
		return current >= resolvedMax
	end

	return false
end

local function canAffordUpgrade(id, row)
	if not row then
		return true
	end

	local currencyName = row.currency
	local wallet = asNumber(getPlayerDataValueByName(currencyName))
	local cost = getResolvedCost(id, row)
	if wallet and cost then
		return wallet >= cost
	end
	return true
end

local function canAttemptUpgrade(id, row)
	if isLikelyMaxed(id, row) then
		return false
	end
	if not isUnlockLikelyMet(row) then
		return false
	end
	if not canAffordUpgrade(id, row) then
		return false
	end
	return true
end

local function getBestUpgradeWorldTarget()
	local scoreByWorld = {}

	for _, id in ipairs(sortedUpgradeIds) do
		local row = upgradeInfoById[id]
		if canAttemptUpgrade(id, row) then
			local currency = row and row.currency or nil
			if currency then
				local hints = CURRENCY_WORLD_HINTS[currency]
				if hints then
					for rank, worldName in ipairs(hints) do
						local add = math.max(1, 8 - rank)
						scoreByWorld[worldName] = (scoreByWorld[worldName] or 0) + add
					end
				end
				for worldName, worldMap in pairs(WORLD_CURRENCY_BONUS) do
					if worldMap[currency] ~= nil then
						scoreByWorld[worldName] = (scoreByWorld[worldName] or 0) + 4
					end
				end
			end
		end
	end

	local bestWorld = nil
	local bestScore = 0
	for worldName, score in pairs(scoreByWorld) do
		if score > bestScore then
			bestScore = score
			bestWorld = worldName
		end
	end

	return bestWorld
end

local function getHighestWorldTarget(currentWorld)
	for _, worldName in ipairs(WORLD_PRIORITY_DESC) do
		if worldName ~= currentWorld then
			return worldName
		end
	end
	return nil
end

local function getRotationFallbackWorld(currentWorld)
	for _ = 1, #WORLD_ROTATION_ORDER do
		worldRotationIndex = (worldRotationIndex % #WORLD_ROTATION_ORDER) + 1
		local worldName = WORLD_ROTATION_ORDER[worldRotationIndex]
		if worldName ~= currentWorld then
			return worldName
		end
	end
	return nil
end

local function trySmartWorldRotation()
	if not alive or not autoWorldRotateEnabled then
		return false
	end

	local now = os.clock()
	if now - lastWorldSwitchAt < worldSwitchCooldown then
		return false
	end

	local currentWorld = tostring(getPlayerDataValueByName("WorldIn") or "")
	local targetWorld = nil
	local reason = nil

	if preferUpgradeWorldTargetEnabled then
		local bestUpgradeWorld = getBestUpgradeWorldTarget()
		if bestUpgradeWorld and bestUpgradeWorld ~= currentWorld then
			targetWorld = bestUpgradeWorld
			reason = "upgrade availability"
		end
	end

	if not targetWorld and preferHighestWorldFallbackEnabled then
		local highestWorld = getHighestWorldTarget(currentWorld)
		if highestWorld then
			targetWorld = highestWorld
			reason = "highest world fallback"
		end
	end

	if not targetWorld then
		local fallbackWorld = getRotationFallbackWorld(currentWorld)
		if fallbackWorld then
			targetWorld = fallbackWorld
			reason = "rotation fallback"
		end
	end

	if not targetWorld then
		return false
	end

	local sent = fireRemote("ChangeWorld", targetWorld)
	if not sent then
		return false
	end

	lastWorldSwitchAt = now
	notify("Smart World", "Switching to " .. targetWorld .. " (" .. tostring(reason) .. ").", 3)
	return true
end

local function runAutoUpgradeSweep()
	local attempted = 0
	local skipped = 0

	local orderedIds = getOrderedUpgradeIdsForProfile()
	for _, id in ipairs(orderedIds) do
		if not alive then
			break
		end
		if not autoUpgradeAllEnabled then
			break
		end

		local row = upgradeInfoById[id]
		if canAttemptUpgrade(id, row) then
			local bought = doBuy(id)
			if bought then
				attempted = attempted + 1
				task.wait(math.max(autoUpgradeStepDelay, buyInterval))
			else
				skipped = skipped + 1
			end
		else
			skipped = skipped + 1
		end
	end

	return attempted, skipped
end

local function setProgressionToggles(value)
	for key, _ in pairs(progressionActionState) do
		progressionActionState[key] = value
	end
end

local function setAutoCompleteGameState(enabled)
	autoCompleteGameEnabled = enabled

	if enabled then
		autoClickEnabled = true
		autoUpgradeAllEnabled = true
		autoProgressionEnabled = true
		autoBlockCollectEnabled = true
		autoBlockWalkFallbackEnabled = true
		autoProfileByWorldEnabled = true
		autoWorldRotateEnabled = true
		preferUpgradeWorldTargetEnabled = true
		preferHighestWorldFallbackEnabled = true
		antiAfkEnabled = true

		clickInterval = 0.08
		buyInterval = 0.08
		autoUpgradeStepDelay = 0.05
		autoUpgradeSweepDelay = 0.25
		progressionInterval = 0.45
		blockCollectInterval = 0.12
		blockWalkInterval = 0.9
		worldSwitchCooldown = 6
		dailyClaimInterval = DEFAULT_DAILY_CLAIM_INTERVAL

		setProgressionToggles(true)
		applyRecommendedProfile()

		task.spawn(function()
			if not alive then
				return
			end
			runProgressionTick()
			runAutoUpgradeSweep()
			trySmartWorldRotation()
		end)

		notify("Auto Complete", "Master mode enabled. Full automation started.", 5)
	else
		autoClickEnabled = false
		autoUpgradeAllEnabled = false
		autoProgressionEnabled = false
		autoBlockCollectEnabled = false
		autoProfileByWorldEnabled = false
		autoWorldRotateEnabled = false
		notify("Auto Complete", "Master mode disabled.", 4)
	end
end

local function cleanup()
	if not alive then
		return
	end

	alive = false
	autoCompleteGameEnabled = false
	autoClickEnabled = false
	autoUpgradeAllEnabled = false
	autoProgressionEnabled = false
	autoBlockCollectEnabled = false
	autoBlockWalkFallbackEnabled = false
	antiAfkEnabled = false
	autoProfileByWorldEnabled = false
	autoWorldRotateEnabled = false
	preferUpgradeWorldTargetEnabled = false
	preferHighestWorldFallbackEnabled = false

	for _, conn in ipairs(connections) do
		if conn and conn.Connected then
			conn:Disconnect()
		end
	end
	table.clear(connections)

	if Rayfield and Rayfield.Destroy then
		pcall(function()
			Rayfield:Destroy()
		end)
	end

	pcall(function()
		local rayfieldGui = CoreGui:FindFirstChild("Rayfield")
		if rayfieldGui then
			rayfieldGui:Destroy()
		end
	end)

	env.__CLICKER_HUB_CLEANUP = nil
	env.__CLICKER_HUB_RUNNING = false

	pcall(function()
		script:Destroy()
	end)
end

env.__CLICKER_HUB_CLEANUP = cleanup
env.__CLICKER_HUB_RUNNING = true

local function loadRayfield()
	local sources = {
		"https://sirius.menu/rayfield",
		"https://raw.githubusercontent.com/shlexware/Rayfield/main/source",
	}

	for _, source in ipairs(sources) do
		local ok, lib = pcall(function()
			return loadstring(game:HttpGet(source))()
		end)
		if ok and lib then
			return lib
		end
	end

	return nil
end

Rayfield = loadRayfield()
if not Rayfield then
	warn("Failed to load Rayfield.")
	return
end

upgradeOptions, upgradeInfoById, sortedUpgradeIds = buildUpgradeCatalog()
if #upgradeOptions == 0 then
	table.insert(upgradeOptions, "1 | Unknown | Cost:? | Max:? | Unl:? | Req:?")
	upgradeInfoById[1] = {
		id = 1,
		label = upgradeOptions[1],
		currency = "?",
		costDisplay = "?",
		maxDisplay = "?",
		unlockDisplay = "?",
		hasUnlockDisplay = "?",
		costRaw = nil,
		maxRaw = nil,
		unlockRaw = nil,
		hasUnlockRaw = nil,
	}
	sortedUpgradeIds = {1}
end

Window = Rayfield:CreateWindow({
	Name = "Almond Hub",
	LoadingTitle = "Untitled Game",
	LoadingSubtitle = "AutoFarm",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "UntitledTreeGame",
		FileName = "MainConfig"
	},
	Discord = {
		Enabled = false,
		Invite = "",
		RememberJoins = false
	},
	KeySystem = false,
})

local mainTab = Window:CreateTab("Main", 4483362458)
local upgradeTab = Window:CreateTab("Upgrades", 4483362458)
local progressionTab = Window:CreateTab("Progression", 4483362458)
local settingsTab = Window:CreateTab("Settings", 4483362458)

mainTab:CreateParagraph({
	Title = "Scan Summary",
	Content = string.format(
		"Scanned %d dump files | %d remotes | %d player fields | %d referenced upgrade IDs",
		SCAN_SUMMARY.files,
		SCAN_SUMMARY.remoteCount,
		SCAN_SUMMARY.playerDataFields,
		SCAN_SUMMARY.referencedUpgradeIds
	)
})

mainTab:CreateToggle({
	Name = "Auto Complete Game (Master)",
	CurrentValue = false,
	Flag = "auto_complete_game_master",
	Callback = function(value)
		setAutoCompleteGameState(value)
	end,
})

mainTab:CreateToggle({
	Name = "Auto Click",
	CurrentValue = false,
	Flag = "auto_click_toggle",
	Callback = function(value)
		autoClickEnabled = value
	end,
})

mainTab:CreateSlider({
	Name = "Auto Click Interval (s)",
	Range = {0.05, 1},
	Increment = 0.01,
	Suffix = "sec",
	CurrentValue = DEFAULT_CLICK_INTERVAL,
	Flag = "auto_click_interval",
	Callback = function(value)
		clickInterval = value
	end,
})

mainTab:CreateToggle({
	Name = "Auto Collect Blocks",
	CurrentValue = false,
	Flag = "auto_collect_blocks_toggle",
	Callback = function(value)
		autoBlockCollectEnabled = value
	end,
})

mainTab:CreateSlider({
	Name = "Block Collect Interval (s)",
	Range = {0.05, 1.5},
	Increment = 0.05,
	Suffix = "sec",
	CurrentValue = DEFAULT_BLOCK_COLLECT_INTERVAL,
	Flag = "block_collect_interval",
	Callback = function(value)
		blockCollectInterval = value
	end,
})

mainTab:CreateToggle({
	Name = "Walk To Blocks Fallback",
	CurrentValue = true,
	Flag = "block_walk_fallback_toggle",
	Callback = function(value)
		autoBlockWalkFallbackEnabled = value
	end,
})

mainTab:CreateSlider({
	Name = "Block Walk Interval (s)",
	Range = {0.2, 3},
	Increment = 0.1,
	Suffix = "sec",
	CurrentValue = DEFAULT_BLOCK_WALK_INTERVAL,
	Flag = "block_walk_interval",
	Callback = function(value)
		blockWalkInterval = value
	end,
})

upgradeTab:CreateToggle({
	Name = "Auto Upgrade All (Smart Sweep)",
	CurrentValue = false,
	Flag = "auto_upgrade_all_toggle",
	Callback = function(value)
		autoUpgradeAllEnabled = value
	end,
})

upgradeTab:CreateSlider({
	Name = "Upgrade Step Delay (s)",
	Range = {0.01, 0.5},
	Increment = 0.01,
	Suffix = "sec",
	CurrentValue = DEFAULT_AUTO_UPGRADE_STEP_DELAY,
	Flag = "auto_upgrade_step_delay",
	Callback = function(value)
		autoUpgradeStepDelay = value
	end,
})

upgradeTab:CreateSlider({
	Name = "Upgrade Sweep Delay (s)",
	Range = {0.05, 2},
	Increment = 0.05,
	Suffix = "sec",
	CurrentValue = DEFAULT_AUTO_UPGRADE_SWEEP_DELAY,
	Flag = "auto_upgrade_sweep_delay",
	Callback = function(value)
		autoUpgradeSweepDelay = value
	end,
})

upgradeTab:CreateSlider({
	Name = "Auto Buy Interval (s)",
	Range = {0.05, 1},
	Increment = 0.01,
	Suffix = "sec",
	CurrentValue = DEFAULT_BUY_INTERVAL,
	Flag = "auto_buy_interval",
	Callback = function(value)
		buyInterval = value
	end,
})

progressionTab:CreateParagraph({
	Title = "Auto Progression",
	Content = "Automates prestige-style remotes with unlock checks from PlayerData."
})

progressionTab:CreateDropdown({
	Name = "Priority Profile",
	Options = {
		PROFILE_FAST_REBIRTH,
		PROFILE_BALANCED,
		PROFILE_LATE_GAME,
	},
	CurrentOption = {priorityProfile},
	MultipleOptions = false,
	Flag = "priority_profile_dropdown",
	Callback = function(option)
		if type(option) == "table" then
			option = option[1]
		end
		if option == PROFILE_FAST_REBIRTH or option == PROFILE_BALANCED or option == PROFILE_LATE_GAME then
			priorityProfile = option
			notify("Priority Profile", priorityProfile .. ": " .. tostring(PROFILE_DESCRIPTIONS[priorityProfile]), 5)
		end
	end,
})

progressionTab:CreateToggle({
	Name = "Auto Recommend Profile By World",
	CurrentValue = false,
	Flag = "auto_profile_world_toggle",
	Callback = function(value)
		autoProfileByWorldEnabled = value
		if autoProfileByWorldEnabled then
			applyRecommendedProfile()
		end
	end,
})

progressionTab:CreateButton({
	Name = "Apply Recommended Profile Now",
	Callback = function()
		applyRecommendedProfile()
	end
})

progressionTab:CreateButton({
	Name = "Apply Timing Preset for Profile",
	Callback = function()
		if priorityProfile == PROFILE_FAST_REBIRTH then
			autoUpgradeStepDelay = 0.04
			autoUpgradeSweepDelay = 0.25
			progressionInterval = 0.6
		elseif priorityProfile == PROFILE_LATE_GAME then
			autoUpgradeStepDelay = 0.08
			autoUpgradeSweepDelay = 0.45
			progressionInterval = 1
		else
			autoUpgradeStepDelay = DEFAULT_AUTO_UPGRADE_STEP_DELAY
			autoUpgradeSweepDelay = DEFAULT_AUTO_UPGRADE_SWEEP_DELAY
			progressionInterval = DEFAULT_PROGRESSION_INTERVAL
		end
		notify(
			"Timing Preset Applied",
			string.format("step=%.2fs sweep=%.2fs progression=%.2fs", autoUpgradeStepDelay, autoUpgradeSweepDelay, progressionInterval),
			5
		)
	end
})

progressionTab:CreateToggle({
	Name = "Auto Progression (Master)",
	CurrentValue = false,
	Flag = "auto_progression_master",
	Callback = function(value)
		autoProgressionEnabled = value
	end,
})

progressionTab:CreateSlider({
	Name = "Progression Tick Interval (s)",
	Range = {0.2, 5},
	Increment = 0.1,
	Suffix = "sec",
	CurrentValue = DEFAULT_PROGRESSION_INTERVAL,
	Flag = "progression_interval",
	Callback = function(value)
		progressionInterval = value
	end,
})

progressionTab:CreateSlider({
	Name = "Daily Claim Cooldown (s)",
	Range = {5, 600},
	Increment = 1,
	Suffix = "sec",
	CurrentValue = DEFAULT_DAILY_CLAIM_INTERVAL,
	Flag = "daily_claim_interval",
	Callback = function(value)
		dailyClaimInterval = value
	end,
})

progressionTab:CreateButton({
	Name = "Run One Progression Tick",
	Callback = function()
		local previous = autoProgressionEnabled
		autoProgressionEnabled = true
		local attempted, fired = runProgressionTick()
		autoProgressionEnabled = previous
		notify("Progression Tick", "Attempted: " .. tostring(attempted) .. " | Fired: " .. tostring(fired), 5)
	end
})

progressionTab:CreateToggle({
	Name = "Auto Prestige",
	CurrentValue = progressionActionState.Prestige,
	Flag = "prog_prestige",
	Callback = function(value)
		progressionActionState.Prestige = value
	end,
})

progressionTab:CreateToggle({
	Name = "Auto Evil",
	CurrentValue = progressionActionState.Evil,
	Flag = "prog_evil",
	Callback = function(value)
		progressionActionState.Evil = value
	end,
})

progressionTab:CreateToggle({
	Name = "Auto DarkPrestige",
	CurrentValue = progressionActionState.DarkPrestige,
	Flag = "prog_darkprestige",
	Callback = function(value)
		progressionActionState.DarkPrestige = value
	end,
})

progressionTab:CreateToggle({
	Name = "Auto Token",
	CurrentValue = progressionActionState.Token,
	Flag = "prog_token",
	Callback = function(value)
		progressionActionState.Token = value
	end,
})

progressionTab:CreateToggle({
	Name = "Auto DarkEvil",
	CurrentValue = progressionActionState.DarkEvil,
	Flag = "prog_darkevil",
	Callback = function(value)
		progressionActionState.DarkEvil = value
	end,
})

progressionTab:CreateToggle({
	Name = "Auto AntiPrestige",
	CurrentValue = progressionActionState.AntiPrestige,
	Flag = "prog_antiprestige",
	Callback = function(value)
		progressionActionState.AntiPrestige = value
	end,
})

progressionTab:CreateToggle({
	Name = "Auto AntiEvil",
	CurrentValue = progressionActionState.AntiEvil,
	Flag = "prog_antievil",
	Callback = function(value)
		progressionActionState.AntiEvil = value
	end,
})

progressionTab:CreateToggle({
	Name = "Auto Supernova",
	CurrentValue = progressionActionState.Supernova,
	Flag = "prog_supernova",
	Callback = function(value)
		progressionActionState.Supernova = value
	end,
})

progressionTab:CreateToggle({
	Name = "Auto TowerPrestige",
	CurrentValue = progressionActionState.TowerPrestige,
	Flag = "prog_towerprestige",
	Callback = function(value)
		progressionActionState.TowerPrestige = value
	end,
})

progressionTab:CreateToggle({
	Name = "Auto Beta",
	CurrentValue = progressionActionState.Beta,
	Flag = "prog_beta",
	Callback = function(value)
		progressionActionState.Beta = value
	end,
})

progressionTab:CreateToggle({
	Name = "Auto Bigbang",
	CurrentValue = progressionActionState.Bigbang,
	Flag = "prog_bigbang",
	Callback = function(value)
		progressionActionState.Bigbang = value
	end,
})

progressionTab:CreateToggle({
	Name = "Auto Ascend",
	CurrentValue = progressionActionState.Ascend,
	Flag = "prog_ascend",
	Callback = function(value)
		progressionActionState.Ascend = value
	end,
})

progressionTab:CreateToggle({
	Name = "Auto Loop",
	CurrentValue = progressionActionState.Loop,
	Flag = "prog_loop",
	Callback = function(value)
		progressionActionState.Loop = value
	end,
})

progressionTab:CreateToggle({
	Name = "Auto Cycle",
	CurrentValue = progressionActionState.Cycle,
	Flag = "prog_cycle",
	Callback = function(value)
		progressionActionState.Cycle = value
	end,
})

progressionTab:CreateToggle({
	Name = "Auto UnlockedUnderwater",
	CurrentValue = progressionActionState.UnlockedUnderwater,
	Flag = "prog_unlockedunderwater",
	Callback = function(value)
		progressionActionState.UnlockedUnderwater = value
	end,
})

progressionTab:CreateToggle({
	Name = "Auto Daily Claim",
	CurrentValue = progressionActionState.Daily,
	Flag = "prog_daily",
	Callback = function(value)
		progressionActionState.Daily = value
	end,
})

settingsTab:CreateDropdown({
	Name = "UI Toggle Key",
	Options = {
		"RightShift",
		"LeftShift",
		"RightControl",
		"LeftControl",
		"F",
		"K",
		"P",
	},
	CurrentOption = {uiToggleKey.Name},
	MultipleOptions = false,
	Flag = "toggle_key_dropdown",
	Callback = function(option)
		if type(option) == "table" then
			option = option[1]
		end
		local parsed = parseKeyCode(option)
		if parsed then
			uiToggleKey = parsed
			notify("Toggle Key", "UI key set to " .. uiToggleKey.Name, 3)
		end
	end,
})

settingsTab:CreateToggle({
	Name = "Passive Anti AFK",
	CurrentValue = true,
	Flag = "anti_afk_toggle",
	Callback = function(value)
		antiAfkEnabled = value
	end,
})

settingsTab:CreateToggle({
	Name = "Auto World Rotate (Smart)",
	CurrentValue = true,
	Flag = "auto_world_rotate_toggle",
	Callback = function(value)
		autoWorldRotateEnabled = value
	end,
})

settingsTab:CreateToggle({
	Name = "Prefer Upgrade World Target",
	CurrentValue = true,
	Flag = "prefer_upgrade_world_target",
	Callback = function(value)
		preferUpgradeWorldTargetEnabled = value
	end,
})

settingsTab:CreateToggle({
	Name = "Use Highest World Fallback",
	CurrentValue = true,
	Flag = "prefer_highest_world_fallback",
	Callback = function(value)
		preferHighestWorldFallbackEnabled = value
	end,
})

settingsTab:CreateSlider({
	Name = "World Switch Cooldown (s)",
	Range = {3, 30},
	Increment = 1,
	Suffix = "sec",
	CurrentValue = DEFAULT_WORLD_SWITCH_COOLDOWN,
	Flag = "world_switch_cooldown",
	Callback = function(value)
		worldSwitchCooldown = value
	end,
})

settingsTab:CreateButton({
	Name = "Teleport To Best World Now",
	Callback = function()
		local moved = trySmartWorldRotation()
		if not moved then
			notify("Smart World", "No world switch made right now.", 3)
		end
	end
})

settingsTab:CreateButton({
	Name = "Destroy Script + UI",
	Callback = function()
		cleanup()
	end
})

local worldInObject = playerData:FindFirstChild("WorldIn")
if worldInObject then
	connect(worldInObject:GetPropertyChangedSignal("Value"), function()
		if autoProfileByWorldEnabled then
			applyRecommendedProfile()
		end
	end)
end

connect(player.Idled, function()
	if not alive or not antiAfkEnabled then
		return
	end
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new(0, 0))
end)

connect(UserInputService.InputBegan, function(input, gameProcessed)
	if not alive or gameProcessed then
		return
	end
	if UserInputService:GetFocusedTextBox() then
		return
	end

	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == uiToggleKey then
		if Rayfield and Rayfield.ToggleUI then
			pcall(function()
				Rayfield:ToggleUI()
			end)
		else
			local rayfieldGui = CoreGui:FindFirstChild("Rayfield")
			if rayfieldGui then
				rayfieldGui.Enabled = not rayfieldGui.Enabled
			end
		end
	end
end)

task.spawn(function()
	while alive do
		if autoClickEnabled then
			doClick()
		end
		task.wait(clickInterval)
	end
end)

task.spawn(function()
	while alive do
		if autoBlockCollectEnabled then
			tryCollectBlockRemote()
			if autoBlockWalkFallbackEnabled then
				local now = os.clock()
				if now - lastBlockWalkAt >= blockWalkInterval then
					walkToNearestBlock()
					lastBlockWalkAt = now
				end
			end
		end
		task.wait(blockCollectInterval)
	end
end)

task.spawn(function()
	while alive do
		if autoUpgradeAllEnabled then
			local attempted, _ = runAutoUpgradeSweep()
			if attempted == 0 then
				local firedProgression = 0
				if autoProgressionEnabled then
					local _, fired = runProgressionTick()
					firedProgression = fired
				end
				if firedProgression == 0 then
					trySmartWorldRotation()
				end
			end
			task.wait(autoUpgradeSweepDelay)
		else
			task.wait(0.2)
		end
	end
end)

task.spawn(function()
	while alive do
		if autoProgressionEnabled then
			runProgressionTick()
			task.wait(progressionInterval)
		else
			task.wait(0.25)
		end
	end
end)

notify(
	"Untitled Game Loaded",
	"Using Clicker/BuyUpg + progression remotes. Profile: " .. priorityProfile,
	5
)
