if not game:IsLoaded() then
	game.Loaded:Wait()
end

local PLACE_OK = game.GameId == 9271890694 or game.PlaceId == 94264573845314
if not PLACE_OK then
	warn(string.format("[Faith Increment] Untested place/game: %s / %s", tostring(game.PlaceId), tostring(game.GameId)))
end

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "Almond Hub",
	LoadingTitle = "Faith Incremental | 1.0",
	LoadingSubtitle = "Auto Farm",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "FaithIncrement",
		FileName = "Main"
	},
	Discord = {
		Enabled = false
	},
	KeySystem = false
})

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function requirePath(...)
	local parts = { ... }
	local node = ReplicatedStorage
	for _, part in ipairs(parts) do
		node = node:FindFirstChild(part)
		if not node then
			return nil
		end
	end
	local ok, result = pcall(require, node)
	if ok then
		return result
	end
	warn("[Faith Increment] Failed require: " .. table.concat(parts, ".") .. " -> " .. tostring(result))
	return nil
end

local Missing = {}
local function track(name, moduleValue)
	if not moduleValue then
		table.insert(Missing, name)
	end
	return moduleValue
end

local Packets = track("modules.net.Packets", requirePath("modules", "net", "Packets"))
local GameEnum = track("modules.constants.GameEnum", requirePath("modules", "constants", "GameEnum"))
local UpgradeTreesSchema = track("modules.schemas.UpgradeTrees", requirePath("modules", "schemas", "UpgradeTrees"))
local DefaultCodesConfig = track("modules.constants.DefaultCodesConfig", requirePath("modules", "constants", "DefaultCodesConfig"))

local StatService = track("Services.StatService.StatServiceClient", requirePath("Services", "StatService", "StatServiceClient"))
local UpgradeBoardService = track("Services.UpgradeBoardService.UpgradeBoardServiceClient", requirePath("Services", "UpgradeBoardService", "UpgradeBoardServiceClient"))
local UpgradeTreeService = track("Services.UpgradeTreeService.UpgradeTreeServiceClient", requirePath("Services", "UpgradeTreeService", "UpgradeTreeServiceClient"))
local ReincarnationService = track("Services.ReincarnationService.ReincarnationServiceClient", requirePath("Services", "ReincarnationService", "ReincarnationServiceClient"))
local AscensionService = track("Services.AscensionService.AscensionServiceClient", requirePath("Services", "AscensionService", "AscensionServiceClient"))
local RelicService = track("Services.RelicService.RelicServiceClient", requirePath("Services", "RelicService", "RelicServiceClient"))
local BibleService = track("Services.BibleService.BibleServiceClient", requirePath("Services", "BibleService", "BibleServiceClient"))
local DailySpinService = track("Services.DailySpinService.DailySpinServiceClient", requirePath("Services", "DailySpinService", "DailySpinServiceClient"))
local SpinService = track("Services.SpinService.SpinServiceClient", requirePath("Services", "SpinService", "SpinServiceClient"))
local TempleService = track("Services.TempleService.TempleServiceClient", requirePath("Services", "TempleService", "TempleServiceClient"))
local TeleportService = track("Services.TeleportService.TeleportServiceClient", requirePath("Services", "TeleportService", "TeleportServiceClient"))
local TrialService = track("Services.TrialService.TrialServiceClient", requirePath("Services", "TrialService", "TrialServiceClient"))
local CodesService = track("Services.CodesService.CodesServiceClient", requirePath("Services", "CodesService", "CodesServiceClient"))

local function notify(title, content, duration)
	pcall(function()
		Rayfield:Notify({
			Title = title,
			Content = content,
			Duration = duration or 4
		})
	end)
end

local ZONE_CHURCH = GameEnum and GameEnum.ZoneId and GameEnum.ZoneId.Zone1_Church or "Zone_1_Church"
local ZONE_2 = GameEnum and GameEnum.ZoneId and GameEnum.ZoneId.Zone2 or "Zone_2"
local ZONE_3 = GameEnum and GameEnum.ZoneId and GameEnum.ZoneId.Zone3 or "Zone_3"

local Flags = {
	AutoPrayInteract = false,
	PrayDelay = 0.45,
	AutoChurchUpgrades = false,
	AutoZone2Upgrades = false,
	AutoZone3Upgrades = false,
	AutoRebirth = false,
	AutoReincarnation = false,
	AutoAscension = false,
	AutoTreeBuy = false,
	AutoRelicClick = false,
	RelicDelay = 0.12,
	AutoDailySpin = false,
	DailySpinDelay = 8,
	AutoTemple = false,
	AutoTempleDP = false,
	AutoTempleDeposit = false,
	TempleDelay = 0.75,
	DepositCurrency = "Faith",
	DepositPercent = 25,
	AutoTrial = false
}

local Loops = {}

local function startLoop(name, callback, delayGetter)
	if Loops[name] then
		return
	end
	Loops[name] = task.spawn(function()
		while Flags[name] do
			local ok, err = pcall(callback)
			if not ok then
				warn(string.format("[Faith Increment][%s] %s", name, tostring(err)))
			end
			local waitTime = 0.25
			if type(delayGetter) == "function" then
				local got = delayGetter()
				if type(got) == "number" then
					waitTime = got
				end
			elseif type(delayGetter) == "number" then
				waitTime = delayGetter
			end
			task.wait(math.max(0.05, waitTime))
		end
		Loops[name] = nil
	end)
end

local function setLoop(name, enabled, callback, delayGetter)
	Flags[name] = enabled
	if enabled then
		startLoop(name, callback, delayGetter)
	end
end

local function requestTreeSync()
	if Packets and Packets.RequestTreeStateSync then
		pcall(function()
			Packets.RequestTreeStateSync:Fire({})
		end)
	end
end

local function requestTempleSync()
	if TempleService and TempleService.RequestSync then
		pcall(TempleService.RequestSync)
	end
end

local function doPrayInteract()
	local fired = 0

	if fireproximityprompt then
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("ProximityPrompt") then
				local actionText = string.lower(obj.ActionText or "")
				local objectText = string.lower(obj.ObjectText or "")
				local nameText = string.lower(obj.Name or "")
				if actionText:find("pray") or objectText:find("pray") or nameText:find("pray") or objectText:find("altar") or nameText:find("altar") or nameText:find("church") then
					pcall(fireproximityprompt, obj, 0)
					fired = fired + 1
				end
			end
		end
	end

	if fireclickdetector then
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("ClickDetector") then
				local nameText = string.lower(obj.Name or "")
				local parentName = obj.Parent and string.lower(obj.Parent.Name or "") or ""
				if nameText:find("pray") or parentName:find("pray") or parentName:find("altar") or parentName:find("church") then
					pcall(fireclickdetector, obj)
					fired = fired + 1
				end
			end
		end
	end

	return fired
end

local BoardSets = {
	Church = { "FaithFlatGain", "PraySpeed", "FaithMultiplier", "RebirthMultiplier" },
	Zone2 = { "BibleSpawnSpeed", "BibleFlatGain", "BibleMaxSpawn", "BibleMultiplier", "BibleFaithMultiplier", "BibleRebirthMultiplier" },
	Zone3 = { "RelicFaithMultiplier", "RelicRebirthMultiplier", "RelicAutoClick", "GoldSpiritChance", "SoulFaithMultiplier", "SpiritDamage", "SoulPerKill", "AutoRebirthThreshold" }
}

local function buyBoards(zoneId, boardIds)
	if not (UpgradeBoardService and UpgradeBoardService.RequestPurchase) then
		return
	end
	for _, boardId in ipairs(boardIds) do
		pcall(UpgradeBoardService.RequestPurchase, zoneId, boardId, 1)
	end
end

local function buyVisibleTreeNodes()
	if not (UpgradeTreeService and UpgradeTreeService.RequestPurchase and UpgradeTreesSchema and UpgradeTreesSchema.Zones) then
		return
	end
	requestTreeSync()
	for zoneId, zoneData in pairs(UpgradeTreesSchema.Zones) do
		local trees = zoneData.Trees
		if type(trees) == "table" then
			for treeId, treeData in pairs(trees) do
				local nodes = treeData.Nodes
				if type(nodes) == "table" then
					for nodeId, nodeData in pairs(nodes) do
						if not nodeData.ComingSoon then
							local visible = false
							local purchased = false
							if UpgradeTreeService.IsNodeVisible then
								local okVisible, valueVisible = pcall(UpgradeTreeService.IsNodeVisible, zoneId, treeId, nodeId)
								visible = okVisible and valueVisible or false
							end
							if UpgradeTreeService.IsNodePurchased then
								local okPurchased, valuePurchased = pcall(UpgradeTreeService.IsNodePurchased, zoneId, treeId, nodeId)
								purchased = okPurchased and valuePurchased or false
							end
							if visible and not purchased then
								pcall(UpgradeTreeService.RequestPurchase, zoneId, treeId, nodeId)
								task.wait(0.05)
							end
						end
					end
				end
			end
		end
	end
end

local TempleIds = { "MainTemple", "BibleTemple", "RelicsTemple", "SoulsTemple" }
local DivineBoards = { "BibleDivineBoost", "RelicsDivineBoost", "SoulsDivineBoost" }

local function templeStep()
	if not TempleService then
		return
	end
	for _, templeId in ipairs(TempleIds) do
		local level = 0
		if TempleService.GetTempleLevel then
			local okLevel, valueLevel = pcall(TempleService.GetTempleLevel, templeId)
			if okLevel then
				level = tonumber(valueLevel) or 0
			end
		end
		if level <= 0 and TempleService.RequestBuildTemple then
			pcall(TempleService.RequestBuildTemple, templeId)
		elseif level > 0 and TempleService.RequestUpgradeTemple then
			pcall(TempleService.RequestUpgradeTemple, templeId, 1)
		end
	end
end

local function templeBoardStep()
	if not (TempleService and TempleService.RequestUpgradeDPBoard) then
		return
	end
	for _, boardId in ipairs(DivineBoards) do
		pcall(TempleService.RequestUpgradeDPBoard, boardId, 1)
	end
end

local function templeDepositStep()
	if TempleService and TempleService.RequestDeposit then
		pcall(TempleService.RequestDeposit, Flags.DepositCurrency, Flags.DepositPercent)
	end
end

local function getStatText(statName)
	if not StatService then
		return "N/A"
	end
	local value = "N/A"
	if StatService.GetStatFormatted then
		local okFormatted, resultFormatted = pcall(StatService.GetStatFormatted, statName)
		if okFormatted and resultFormatted ~= nil then
			return tostring(resultFormatted)
		end
	end
	local okRaw, resultRaw = pcall(StatService.GetStat, statName)
	if okRaw and resultRaw ~= nil then
		value = tostring(resultRaw)
	end
	return value
end

local MainTab = Window:CreateTab("Main", 4483362458)
local ProgressionTab = Window:CreateTab("Progression", 4483362458)
local TempleTab = Window:CreateTab("Temple/Tree", 4483362458)
local UtilityTab = Window:CreateTab("Utility", 4483362458)

MainTab:CreateParagraph({
	Title = "Detected",
	Content = string.format("Faith: %s | Rebirths: %s | Level: %s", getStatText("Faith"), getStatText("Rebirths"), getStatText("Level"))
})

MainTab:CreateToggle({
	Name = "Auto Pray Interact (Experimental)",
	CurrentValue = false,
	Flag = "auto_pray_interact",
	Callback = function(value)
		setLoop("AutoPrayInteract", value, function()
			doPrayInteract()
		end, function()
			return Flags.PrayDelay
		end)
	end
})

MainTab:CreateSlider({
	Name = "Pray Scan Delay",
	Range = { 1, 50 },
	Increment = 1,
	Suffix = "x0.01s",
	CurrentValue = 45,
	Flag = "pray_delay",
	Callback = function(value)
		Flags.PrayDelay = value / 100
	end
})

MainTab:CreateToggle({
	Name = "Auto Church Upgrades",
	CurrentValue = false,
	Flag = "auto_church_upgrades",
	Callback = function(value)
		setLoop("AutoChurchUpgrades", value, function()
			buyBoards(ZONE_CHURCH, BoardSets.Church)
		end, 0.3)
	end
})

MainTab:CreateToggle({
	Name = "Auto Zone 2 Upgrades",
	CurrentValue = false,
	Flag = "auto_zone2_upgrades",
	Callback = function(value)
		setLoop("AutoZone2Upgrades", value, function()
			buyBoards(ZONE_2, BoardSets.Zone2)
		end, 0.4)
	end
})

MainTab:CreateToggle({
	Name = "Auto Zone 3 Upgrades",
	CurrentValue = false,
	Flag = "auto_zone3_upgrades",
	Callback = function(value)
		setLoop("AutoZone3Upgrades", value, function()
			buyBoards(ZONE_3, BoardSets.Zone3)
		end, 0.45)
	end
})

MainTab:CreateToggle({
	Name = "Auto Rebirth",
	CurrentValue = false,
	Flag = "auto_rebirth",
	Callback = function(value)
		setLoop("AutoRebirth", value, function()
			if UpgradeBoardService and UpgradeBoardService.RequestPurchase then
				pcall(UpgradeBoardService.RequestPurchase, ZONE_CHURCH, "Rebirth", 1)
			end
		end, 0.3)
	end
})

MainTab:CreateToggle({
	Name = "Auto Relic Click",
	CurrentValue = false,
	Flag = "auto_relic_click",
	Callback = function(value)
		setLoop("AutoRelicClick", value, function()
			if RelicService and RelicService.IsUnlocked and RelicService.Click and RelicService.IsUnlocked() then
				RelicService.Click()
			end
		end, function()
			return Flags.RelicDelay
		end)
	end
})

MainTab:CreateSlider({
	Name = "Relic Click Delay",
	Range = { 5, 100 },
	Increment = 1,
	Suffix = "x0.01s",
	CurrentValue = 12,
	Flag = "relic_delay",
	Callback = function(value)
		Flags.RelicDelay = value / 100
	end
})

MainTab:CreateToggle({
	Name = "Auto Bible Collect",
	CurrentValue = false,
	Flag = "auto_bible_collect",
	Callback = function(value)
		if BibleService then
			if value then
				if BibleService.StartAutoCollect then
					pcall(BibleService.StartAutoCollect)
				end
			elseif BibleService.StopAutoCollect then
				pcall(BibleService.StopAutoCollect)
			end
		end
	end
})

ProgressionTab:CreateToggle({
	Name = "Auto Reincarnation",
	CurrentValue = false,
	Flag = "auto_reincarnation",
	Callback = function(value)
		setLoop("AutoReincarnation", value, function()
			if ReincarnationService and ReincarnationService.RequestReincarnation then
				ReincarnationService.RequestReincarnation()
			end
		end, 1.2)
	end
})

ProgressionTab:CreateToggle({
	Name = "Auto Ascension",
	CurrentValue = false,
	Flag = "auto_ascension",
	Callback = function(value)
		setLoop("AutoAscension", value, function()
			if AscensionService and AscensionService.RequestAscension then
				local canAscend = true
				if AscensionService.CanAscend then
					local okCan, valueCan = pcall(AscensionService.CanAscend)
					canAscend = okCan and valueCan or false
				end
				if canAscend then
					AscensionService.RequestAscension()
				end
			end
		end, 1.5)
	end
})

ProgressionTab:CreateToggle({
	Name = "Auto Daily Spin Claim",
	CurrentValue = false,
	Flag = "auto_daily_spin",
	Callback = function(value)
		setLoop("AutoDailySpin", value, function()
			if DailySpinService and DailySpinService.CanClaimDailySpin and DailySpinService.RequestClaim then
				local okCan, canClaim = pcall(DailySpinService.CanClaimDailySpin)
				if okCan and canClaim then
					DailySpinService.RequestClaim()
				end
			end
		end, function()
			return Flags.DailySpinDelay
		end)
	end
})

ProgressionTab:CreateSlider({
	Name = "Daily Spin Check Delay",
	Range = { 2, 30 },
	Increment = 1,
	Suffix = "s",
	CurrentValue = 8,
	Flag = "daily_spin_delay",
	Callback = function(value)
		Flags.DailySpinDelay = value
	end
})

ProgressionTab:CreateToggle({
	Name = "Auto Spin (Built-in)",
	CurrentValue = false,
	Flag = "auto_spin_builtin",
	Callback = function(value)
		if SpinService and SpinService.SetAutoSpin then
			SpinService.SetAutoSpin(value)
			if value and SpinService.RequestSpin and SpinService.IsSpinning and not SpinService.IsSpinning() then
				pcall(SpinService.RequestSpin)
			end
		end
	end
})

ProgressionTab:CreateToggle({
	Name = "Auto Trial Join/Complete",
	CurrentValue = false,
	Flag = "auto_trial",
	Callback = function(value)
		setLoop("AutoTrial", value, function()
			if not TrialService then
				return
			end
			if TrialService.CanParticipate and TrialService.JoinTrial then
				local okCan, canParticipate = pcall(TrialService.CanParticipate)
				if okCan and canParticipate then
					TrialService.JoinTrial()
				end
			end
			if TrialService.IsParticipating and TrialService.ReportCompletion then
				local okPart, participating = pcall(TrialService.IsParticipating)
				if okPart and participating then
					TrialService.ReportCompletion()
				end
			end
		end, 3)
	end
})

TempleTab:CreateToggle({
	Name = "Auto Buy Visible Tree Nodes",
	CurrentValue = false,
	Flag = "auto_tree_buy",
	Callback = function(value)
		setLoop("AutoTreeBuy", value, buyVisibleTreeNodes, 1.3)
	end
})

TempleTab:CreateToggle({
	Name = "Auto Temple Build/Upgrade",
	CurrentValue = false,
	Flag = "auto_temple",
	Callback = function(value)
		setLoop("AutoTemple", value, templeStep, function()
			return Flags.TempleDelay
		end)
	end
})

TempleTab:CreateToggle({
	Name = "Auto Divine Boards",
	CurrentValue = false,
	Flag = "auto_temple_dp",
	Callback = function(value)
		setLoop("AutoTempleDP", value, templeBoardStep, function()
			return Flags.TempleDelay
		end)
	end
})

TempleTab:CreateToggle({
	Name = "Auto Main Temple Deposit",
	CurrentValue = false,
	Flag = "auto_temple_deposit",
	Callback = function(value)
		setLoop("AutoTempleDeposit", value, templeDepositStep, function()
			return Flags.TempleDelay
		end)
	end
})

TempleTab:CreateSlider({
	Name = "Temple Loop Delay",
	Range = { 25, 300 },
	Increment = 5,
	Suffix = "x0.01s",
	CurrentValue = 75,
	Flag = "temple_delay",
	Callback = function(value)
		Flags.TempleDelay = value / 100
	end
})

TempleTab:CreateDropdown({
	Name = "Deposit Currency",
	Options = { "Faith", "Rebirths", "Bible", "Relics", "Souls", "EliteSouls", "Sigils" },
	CurrentOption = { Flags.DepositCurrency },
	MultipleOptions = false,
	Flag = "deposit_currency",
	Callback = function(option)
		if type(option) == "table" then
			option = option[1]
		end
		if option then
			Flags.DepositCurrency = tostring(option)
		end
	end
})

TempleTab:CreateSlider({
	Name = "Deposit Percentage",
	Range = { 1, 100 },
	Increment = 1,
	Suffix = "%",
	CurrentValue = Flags.DepositPercent,
	Flag = "deposit_percent",
	Callback = function(value)
		Flags.DepositPercent = value
	end
})

UtilityTab:CreateButton({
	Name = "Redeem Known Default Codes",
	Callback = function()
		local redeemedCount = 0
		if CodesService and CodesService.RedeemCode and DefaultCodesConfig then
			local allCodes = DefaultCodesConfig.GetAllCodes and DefaultCodesConfig.GetAllCodes() or DefaultCodesConfig
			for code, data in pairs(allCodes) do
				if type(data) == "table" and data.RewardType then
					pcall(CodesService.RedeemCode, code)
					redeemedCount = redeemedCount + 1
					task.wait(0.15)
				end
			end
		end
		notify("Codes", "Redeem requests sent: " .. tostring(redeemedCount), 4)
	end
})

UtilityTab:CreateButton({
	Name = "Claim Daily Spin Now",
	Callback = function()
		if DailySpinService and DailySpinService.RequestClaim then
			pcall(DailySpinService.RequestClaim)
		end
	end
})

UtilityTab:CreateButton({
	Name = "Spin Once Now",
	Callback = function()
		if SpinService and SpinService.RequestSpin then
			pcall(SpinService.RequestSpin)
		end
	end
})

UtilityTab:CreateButton({
	Name = "Reincarnate Once",
	Callback = function()
		if ReincarnationService and ReincarnationService.RequestReincarnation then
			pcall(ReincarnationService.RequestReincarnation)
		end
	end
})

UtilityTab:CreateButton({
	Name = "Ascend Once",
	Callback = function()
		if AscensionService and AscensionService.RequestAscension then
			pcall(AscensionService.RequestAscension)
		end
	end
})

UtilityTab:CreateButton({
	Name = "Sync Tree State",
	Callback = requestTreeSync
})

UtilityTab:CreateButton({
	Name = "Sync Temple State",
	Callback = requestTempleSync
})

if TeleportService and TeleportService.GetLocations and TeleportService.RequestTeleport then
	for _, locationData in ipairs(TeleportService.GetLocations()) do
		local locationId = locationData.id
		local locationName = locationData.name or locationId
		UtilityTab:CreateButton({
			Name = "Teleport: " .. tostring(locationName),
			Callback = function()
				pcall(TeleportService.RequestTeleport, locationId)
			end
		})
	end
end

if #Missing > 0 then
	notify("Partial Load", "Missing modules: " .. table.concat(Missing, ", "), 8)
else
	notify("Faith Incremental", "Loaded all target modules.", 5)
end
