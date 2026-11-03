-- ============================================================
--  NarutoBot  |  GAMEPLAY.lua
--  Játéklogika · Harc · Autofarm · Main loop · Anti-AFK
-- ============================================================

local NB     = _G.NarutoBot
local CFG    = NB.CONFIG
local ST     = NB.State
local uiE    = NB.uiElements
local VFX    = NB.VFX
local C      = NB.COLORS
local WS     = NB.Services.Workspace
local VU     = NB.Services.VirtualUser
local player = NB.Player

-- ======= ÁLLAPOT HELPEREK =======
local function isInCombat() return player:GetAttribute("CS_InCombat") == true end
local function hasActed()   return player:GetAttribute("ClientActedThisTurn") == true end
local function isDead()
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	return not hum or hum.Health <= 0
end

local function savePosition()
	local char = player.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if hrp and not ST.healthActionBusy then ST.savedReturnCFrame = hrp.CFrame end
end

local function teleportBack()
	local char = player.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if char and hrp and ST.savedReturnCFrame then
		char:PivotTo(ST.savedReturnCFrame)
		return true
	end
	return false
end

local function resetCooldowns()
	ST.abilityCooldownMemory = {}
	ST.fightStartedAt = os.clock()
end

local function setPausedForHealth(val)
	ST.autofarmPausedForHealth = val
	if val then
		ST.myTurn = false
		player:SetAttribute("ClientActedThisTurn", false)
	end
end

-- ======= HEALTH REFILL =======
local function useHealthRefill(ignoreCheck)
	if not ignoreCheck and not CFG.HealthEnabled then return false end
	if ST.healthActionBusy then return false end

	local now = os.clock()
	if now - ST.lastHealthUse < CFG.HealthButtonCooldown then return false end

	local char = player.Character
	local hum  = char and char:FindFirstChildOfClass("Humanoid")
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if not char or not hrp or not hum or not CFG.HealthTeleportCFrame then return false end

	local safeCF = CFG.HealthTeleportCFrame * CFrame.new(CFG.TeleportOffset)
	ST.healthActionBusy = true
	ST.lastHealthUse    = now
	ST.returnTaskId     = ST.returnTaskId + 1
	local taskId = ST.returnTaskId

	if CFG.AutofarmActive then setPausedForHealth(true) end

	local ok = pcall(function()
		if hum.Sit then hum.Sit = false end
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		ST.savedReturnCFrame = hrp.CFrame
		char:PivotTo(safeCF)
		task.wait(0.2)
		if (hrp.Position - safeCF.Position).Magnitude > 12 then
			hrp.CFrame = safeCF
			task.wait(0.15)
		end
	end)

	if not ok then
		ST.healthActionBusy = false
		setPausedForHealth(false)
		return false
	end

	NB.updateStatus("💊 Gyógyítás...")

	task.delay(math.max(CFG.HealDuration, 0), function()
		if taskId ~= ST.returnTaskId then
			ST.healthActionBusy = false
			setPausedForHealth(false)
			return
		end
		local rc  = player.Character
		local rhrp = rc and rc:FindFirstChild("HumanoidRootPart")
		if rc and rhrp and ST.savedReturnCFrame then
			rc:PivotTo(ST.savedReturnCFrame)
			task.wait(0.15)
		end
		ST.healthActionBusy = false
		setPausedForHealth(false)
	end)
	return true
end

_G.GlassFarmProUseHealthRefill = function()
	return useHealthRefill(true)
end

-- ======= HARC =======
local function fireActionSignal(action)
	local pg = player:FindFirstChild("PlayerGui")
	local at = pg  and pg:FindFirstChild("Attacks")
	local be = at  and at:FindFirstChild("ClientActionTaken")
	if be and be:IsA("BindableEvent") then be:Fire(action) end
end

local function processTurn()
	if not CFG.AutofarmActive or not ST.scriptRunning or ST.healthActionBusy or ST.autofarmPausedForHealth then return end
	local tv = NB.Remotes.turnEvent
	local cr = NB.Remotes.combatRemoteEvent
	if not tv or not cr then return end

	player:SetAttribute("ClientActedThisTurn", true)

	local cc, mc = NB.getChakraData()
	local ratio  = mc > 0 and (cc / mc) or 0
	local used   = false

	if CFG.AutoAbility and ratio >= CFG.MinAbilityChakraRatio then
		local data = player:FindFirstChild("Data")
		local eq   = data and data:FindFirstChild("EquippedAbilities")
		if eq then
			local best, bestScore = nil, -math.huge
			for s = 1, 8 do
				local slot = eq:FindFirstChild(tostring(s))
				if slot and slot.Value ~= "" and slot.Value ~= "None" then
					local cd    = slot:GetAttribute("Cooldown") or 0
					local last  = ST.abilityCooldownMemory[s] or math.huge
					local ready = cd <= 0 and last > 0
					ST.abilityCooldownMemory[s] = cd
					if cd <= 0 then
						local sc = 10 - s + (ready and 5 or 0) + (s <= 3 and 2 or 0)
						if sc > bestScore then bestScore = sc ; best = s end
					end
				end
			end
			if best then
				fireActionSignal("Ability")
				cr:FireServer("Ability", best)
				used = true
			end
		end
	end

	if not used then
		fireActionSignal("Attack")
		tv:FireServer("Attack")
	end
end

-- Turn events
if NB.Remotes.turnEvent then
	local c = NB.Remotes.turnEvent.OnClientEvent:Connect(function(msg, scope)
		if not CFG.AutofarmActive or not ST.scriptRunning then return end
		if msg == "Your Turn" then
			ST.myTurn = (scope == nil or scope == player or scope == player.Character)
			if ST.myTurn then task.spawn(processTurn) end
		elseif msg == "Enemy Turn" or msg == "BattleEnded" then
			ST.myTurn = false
		end
	end)
	table.insert(ST.allConnections, c)
end

-- ======= OVERWORLD =======
local function findNPC()
	local char = player.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	local folder = WS:FindFirstChild("NPCs")
	if not folder then return nil end

	local best, bestDist = nil, CFG.SearchRadius
	for _, npc in ipairs(folder:GetChildren()) do
		if npc:IsA("Model") and npc:GetAttribute("IsNPC") == true then
			if #CFG.TargetNPCs == 0 or table.find(CFG.TargetNPCs, npc.Name) then
				local hum  = npc:FindFirstChildOfClass("Humanoid")
				local nhp  = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
				if hum and hum.Health > 0 and nhp then
					local d = (nhp.Position - hrp.Position).Magnitude
					if d < bestDist then bestDist = d ; best = npc end
				end
			end
		end
	end
	return best
end

local function travelTo(npc)
	local char = player.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	local nhp  = npc and (npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart)
	local hum  = char and char:FindFirstChildOfClass("Humanoid")
	if not (hrp and nhp and hum) then return end

	local dist = (nhp.Position - hrp.Position).Magnitude
	if CFG.MoveMode == "Walk" or dist > CFG.MaxTeleportDistance then
		hum:MoveTo(nhp.Position)
		NB.updateStatus("🚶 Séta: " .. npc.Name)
	else
		hrp.CFrame = nhp.CFrame
		NB.updateStatus("🎯 Vadász: " .. npc.Name)
	end
end

-- ======= HARC ESEMÉNYEK =======
local function onFightStart()
	savePosition()
	resetCooldowns()
	NB.updateStatus("⚔ Harc elkezdődött!")
end

local function onFightEnd()
	ST.returnTaskId = ST.returnTaskId + 1
	local taskId = ST.returnTaskId

	if CFG.HealthEnabled and not ST.healthActionBusy then
		if NB.getHealthRatio() <= CFG.AutoHealthThreshold
			or NB.getChakraRatio() <= CFG.AutoChakraThreshold then
			NB.updateStatus("📍 Spawn felé...")
			useHealthRefill(false)
			return
		end
	end

	if CFG.ReturnDelay > 0 then
		NB.updateStatus("⏳ Visszatérés " .. CFG.ReturnDelay .. "s múlva")
		task.delay(CFG.ReturnDelay, function()
			if taskId ~= ST.returnTaskId then return end
			if ST.scriptRunning and not isInCombat() and not ST.healthActionBusy then
				teleportBack()
			end
		end)
	else
		if not ST.healthActionBusy then teleportBack() end
	end
end

-- ======= MAIN LOOP =======
local function mainLoop()
	while CFG.AutofarmActive and ST.scriptRunning do
		task.wait(0.15)

		local combat = isInCombat()
		if combat and not ST.lastCombatState then onFightStart()
		elseif not combat and ST.lastCombatState then onFightEnd() end
		ST.lastCombatState = combat

		if ST.healthActionBusy or ST.autofarmPausedForHealth then
			NB.updateStatus("🏥 Gyógyhelyen...")
			continue
		end

		local canHeal = not combat or CFG.HealDuringCombat
		if canHeal and CFG.HealthEnabled then
			if NB.getHealthRatio() <= CFG.AutoHealthThreshold
				or NB.getChakraRatio() <= CFG.AutoChakraThreshold then
				if useHealthRefill(false) then continue end
			end
		end

		if isDead() then
			NB.updateStatus("💀 Visszatérés...")
			task.wait(2)
			continue
		end

		if combat then
			if ST.myTurn and not hasActed() then
				processTurn()
				task.wait(CFG.ActionCooldown)
			else
				NB.updateStatus("⏳ Kör várása...")
			end
		else
			if #CFG.TargetNPCs == 0 then
				NB.updateStatus("📍 Válassz célpontot!")
			else
				local t = findNPC()
				if t then travelTo(t) else NB.updateStatus("🔍 Keresés...") end
			end
		end
	end
end

-- ======= START / STOP GOMB =======
uiE.ToggleBtn.MouseButton1Click:Connect(function()
	if #CFG.TargetNPCs == 0 and not CFG.AutofarmActive then
		NB.updateStatus("⚠ Válassz célpontot!")
		return
	end

	CFG.AutofarmActive = not CFG.AutofarmActive

	if CFG.AutofarmActive then
		uiE.ToggleBtn.Text = "⏹ STOP"
		VFX.tween(uiE.ToggleBtn, 0.3, {BackgroundColor3 = C.Danger})
		VFX.tween(uiE.ToggleBtn:FindFirstChildOfClass("UIStroke"), 0.3, {Color = C.Danger})
		NB.scanNPCNames()
		ST.lastCombatState = isInCombat()
		if not ST.lastCombatState then savePosition() ; resetCooldowns() end
		NB.updateStatus("✓ Fut!")
		task.spawn(mainLoop)
	else
		uiE.ToggleBtn.Text = "▶ START"
		VFX.tween(uiE.ToggleBtn, 0.3, {BackgroundColor3 = C.Success})
		VFX.tween(uiE.ToggleBtn:FindFirstChildOfClass("UIStroke"), 0.3, {Color = C.Success})
		NB.updateStatus("⏹ Leállítva")
		local char = player.Character
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		if hum then hum:MoveTo(char:GetPivot().Position) end
		teleportBack()
	end
end)

-- ======= ANTI-AFK =======
local c = player.Idled:Connect(function()
	if CFG.AntiAFK and CFG.AutofarmActive then
		VU:CaptureController()
		VU:ClickButton2(Vector2.new())
	end
end)
table.insert(ST.allConnections, c)

-- ======= CLEANUP =======
uiE.Cleanup = function()
	ST.scriptRunning   = false
	CFG.AutofarmActive = false
	for _, conn in ipairs(ST.allConnections) do
		if conn and conn.Connected then conn:Disconnect() end
	end
	ST.allConnections = {}
	local char = player.Character
	local hum  = char and char:FindFirstChildOfClass("Humanoid")
	if hum then hum:MoveTo(char:GetPivot().Position) end
	local sg = ST.screenGui
	if sg and sg.Parent then sg:Destroy() end
end

-- ======= INICIALIZÁLÁS =======
task.spawn(function()
	task.wait(1.5)
	NB.scanNPCNames()
	uiE.UpdateTargetLabel()
end)
