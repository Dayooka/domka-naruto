-- ============================================================
--  NarutoBot  |  CONFIG.lua
--  Beállítások · Konstansok · Megosztott állapot · Helperek
-- ============================================================

local NB = _G.NarutoBot

-- ======= SERVICES =======
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local VirtualUser       = game:GetService("VirtualUser")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

NB.Services = {
	Players           = Players,
	ReplicatedStorage = ReplicatedStorage,
	Workspace         = Workspace,
	VirtualUser       = VirtualUser,
	TweenService      = TweenService,
	UserInputService  = UserInputService,
}

NB.Player = Players.LocalPlayer

-- ======= CONFIGURATION =======
NB.CONFIG = {
	AutofarmActive        = false,
	TargetNPCs            = {},
	MoveMode              = "Teleport",
	AutoAbility           = true,
	AntiAFK               = true,
	SearchRadius          = 5000,
	ActionCooldown        = 0.1,
	ReturnDelay           = 2,
	HealthTeleportCFrame  = CFrame.new(
		-1687.72339, 2370.01538, 830.461548,
		-0.094668448, -9.03159574e-08,  0.99550885,
		-4.07600531e-08,  1,  8.6847308e-08,
		-0.99550885, -3.23552953e-08, -0.094668448
	),
	HealthEnabled         = false,
	AutoHealthThreshold   = 0.3,
	AutoChakraThreshold   = 0.2,
	LowChakraThreshold    = 0.15,
	MinAbilityChakraRatio = 0.2,
	HealthButtonCooldown  = 2,
	TeleportOffset        = Vector3.new(0, 6, 0),
	HealDuration          = 5,
	MaxTeleportDistance   = 1000,
	HealDuringCombat      = false,
}

-- ======= COLOR PALETTE =======
NB.COLORS = {
	BgDark    = Color3.fromRGB(15,  15,  25),
	BgMedium  = Color3.fromRGB(25,  28,  45),
	BgLight   = Color3.fromRGB(35,  38,  55),
	Primary   = Color3.fromRGB(220, 100, 200),
	Secondary = Color3.fromRGB(100, 200, 255),
	Tertiary  = Color3.fromRGB(255, 170, 100),
	Accent    = Color3.fromRGB(255, 150, 200),
	AccentAlt = Color3.fromRGB(150, 100, 255),
	Text      = Color3.fromRGB(240, 240, 255),
	TextDim   = Color3.fromRGB(180, 190, 220),
	TextMuted = Color3.fromRGB(130, 140, 170),
	Success   = Color3.fromRGB(100, 220, 150),
	Danger    = Color3.fromRGB(255, 100, 100),
	Warning   = Color3.fromRGB(255, 200, 100),
	Info      = Color3.fromRGB(100, 180, 255),
	Glow      = Color3.fromRGB(255, 150, 200),
	Purple    = Color3.fromRGB(200, 120, 255),
	Cyan      = Color3.fromRGB(100, 220, 255),
}

-- ======= SHARED STATE =======
NB.State = {
	myTurn                 = false,
	availableNPCs          = {},
	scriptRunning          = true,
	allConnections         = {},
	savedReturnCFrame      = nil,
	lastCombatState        = false,
	fightStartedAt         = 0,
	abilityCooldownMemory  = {},
	healthActionBusy       = false,
	lastHealthUse          = 0,
	returnTaskId           = 0,
	autofarmPausedForHealth = false,
	isDragging             = false,
	dragInput              = nil,
	dragStart              = nil,
	startPos               = nil,
	uiVisible              = true,
	mainFrame              = nil,
	screenGui              = nil,
}

NB.uiElements = {}

-- ======= REMOTES =======
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
NB.Remotes = {
	turnEvent         = remoteEvents and remoteEvents:WaitForChild("TurnEvent", 5),
	combatRemoteEvent = remoteEvents and remoteEvents:WaitForChild("CombatRemoteEvent", 5),
}

-- ======= HELPER FUNCTIONS =======
NB.updateStatus = function(text)
	if NB.uiElements.StatusLabel then
		NB.uiElements.StatusLabel.Text = text
	end
end

NB.getChakraValues = function()
	local p      = NB.Player
	local data   = p:FindFirstChild("Data")
	local stats  = data   and data:FindFirstChild("Stats")
	local mana   = stats  and stats:FindFirstChild("Mana")
	local maxM   = stats  and stats:FindFirstChild("MaxMana")
	return (mana and mana.Value) or 0,
	       (maxM and maxM.Value) or 100,
	       mana, maxM
end

NB.getChakraData = function()
	local c, m = NB.getChakraValues()
	return c, m
end

NB.getHealthRatio = function()
	local char = NB.Player.Character
	local hum  = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.MaxHealth <= 0 then return 1 end
	return hum.Health / hum.MaxHealth
end

NB.getChakraRatio = function()
	local c, m = NB.getChakraData()
	if m <= 0 then return 1 end
	return c / m
end

NB.scanNPCNames = function()
	local names  = {}
	local folder = NB.Services.Workspace:FindFirstChild("NPCs")
	if folder then
		for _, npc in ipairs(folder:GetChildren()) do
			if npc:IsA("Model") and npc:GetAttribute("IsNPC") == true then
				if not table.find(names, npc.Name) then
					table.insert(names, npc.Name)
				end
			end
		end
	end
	table.sort(names)
	NB.State.availableNPCs = names
end
