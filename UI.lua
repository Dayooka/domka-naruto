-- ============================================================
--  NarutoBot  |  UI.lua
--  Felhasználói felület · Gombok · Togglek · Stat barok
-- ============================================================

local NB  = _G.NarutoBot
local VFX = NB.VFX
local C   = NB.COLORS
local CFG = NB.CONFIG
local ST  = NB.State
local UIS = NB.Services.UserInputService
local uiE = NB.uiElements

-- ======= GOMB =======
local function mkButton(text, cb, color)
	color = color or C.Secondary
	local cont = Instance.new("Frame")
	cont.Size               = UDim2.new(1, 0, 0, 46)
	cont.BackgroundTransparency = 1

	local btn = Instance.new("TextButton")
	btn.Size                   = UDim2.new(1, 0, 1, 0)
	btn.BackgroundColor3       = color
	btn.BackgroundTransparency = 0.5
	btn.TextColor3             = C.Text
	btn.Font                   = Enum.Font.GothamSemibold
	btn.TextSize               = 12
	btn.Text                   = text
	btn.Parent                 = cont
	btn.ZIndex                 = 5
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 16)

	local stroke = Instance.new("UIStroke", btn)
	stroke.Color       = color
	stroke.Transparency = 0.4
	stroke.Thickness   = 2

	local glow = Instance.new("Frame")
	glow.Size                   = UDim2.new(1.1, 0, 1.1, 0)
	glow.Position               = UDim2.new(-0.05, 0, -0.05, 0)
	glow.BackgroundColor3       = color
	glow.BorderSizePixel        = 0
	glow.BackgroundTransparency = 0.9
	glow.Parent                 = cont
	glow.ZIndex                 = 4
	Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 16)

	btn.MouseEnter:Connect(function()
		VFX.tween(btn,    0.2, {BackgroundTransparency = 0.2})
		VFX.tween(stroke, 0.2, {Transparency = 0.1})
		VFX.tween(glow,   0.2, {BackgroundTransparency = 0.7})
		VFX.createParticles(btn, color, 8)
	end)
	btn.MouseLeave:Connect(function()
		VFX.tween(btn,    0.2, {BackgroundTransparency = 0.5})
		VFX.tween(stroke, 0.2, {Transparency = 0.4})
		VFX.tween(glow,   0.2, {BackgroundTransparency = 0.9})
	end)
	btn.MouseButton1Down:Connect(function()
		VFX.createRipple(btn, color)
		VFX.tween(btn, 0.08, {Size = UDim2.new(0.95,0,0.95,0)}, Enum.EasingStyle.Back)
	end)
	btn.MouseButton1Up:Connect(function()
		VFX.tween(btn, 0.12, {Size = UDim2.new(1,0,1,0)}, Enum.EasingStyle.Back)
		task.wait(0.05)
		local res = cb()
		if typeof(res) == "string" and res ~= "" then
			local orig = text
			btn.Text = res
			task.spawn(function() task.wait(2) btn.Text = orig end)
		end
	end)
	return btn, cont
end

-- ======= TOGGLE =======
local function mkToggle(text, key)
	local cont = Instance.new("Frame")
	cont.Size               = UDim2.new(1, 0, 0, 46)
	cont.BackgroundTransparency = 1

	local bg = Instance.new("Frame")
	bg.Size                   = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3       = CFG[key] and C.Success or C.Secondary
	bg.BackgroundTransparency = 0.5
	bg.Parent                 = cont
	Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 16)

	local stroke = Instance.new("UIStroke", bg)
	stroke.Color       = CFG[key] and C.Success or C.Secondary
	stroke.Transparency = 0.4
	stroke.Thickness   = 2

	local glow = Instance.new("Frame")
	glow.Size                   = UDim2.new(1.1, 0, 1.1, 0)
	glow.Position               = UDim2.new(-0.05, 0, -0.05, 0)
	glow.BackgroundColor3       = CFG[key] and C.Success or C.Secondary
	glow.BorderSizePixel        = 0
	glow.BackgroundTransparency = 0.9
	glow.Parent                 = cont
	glow.ZIndex                 = -1
	Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 16)

	local btn = Instance.new("TextButton")
	btn.Size               = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.TextColor3         = C.Text
	btn.Font               = Enum.Font.GothamSemibold
	btn.TextSize           = 12
	btn.Text               = (CFG[key] and "✓ " or "○ ") .. text
	btn.Parent             = bg

	btn.MouseEnter:Connect(function()
		VFX.tween(bg,   0.2, {BackgroundTransparency = 0.3})
		VFX.tween(glow, 0.2, {BackgroundTransparency = 0.7})
		VFX.createParticles(bg, CFG[key] and C.Success or C.Secondary, 6)
	end)
	btn.MouseLeave:Connect(function()
		VFX.tween(bg,   0.2, {BackgroundTransparency = 0.5})
		VFX.tween(glow, 0.2, {BackgroundTransparency = 0.9})
	end)
	btn.MouseButton1Click:Connect(function()
		VFX.createRipple(bg, C.Primary)
		CFG[key] = not CFG[key]
		local nc = CFG[key] and C.Success or C.Secondary
		VFX.tween(bg,     0.3, {BackgroundColor3 = nc})
		VFX.tween(stroke, 0.3, {Color = nc})
		VFX.tween(glow,   0.3, {BackgroundColor3 = nc})
		btn.Text = (CFG[key] and "✓ " or "○ ") .. text
	end)
	return btn, cont
end

-- ======= STAT BAR =======
local function mkStatBar(label, getVal, getMax, color)
	local cont = Instance.new("Frame")
	cont.Size               = UDim2.new(1, 0, 0, 56)
	cont.BackgroundTransparency = 1

	local lbl = Instance.new("TextLabel")
	lbl.Size               = UDim2.new(1, 0, 0, 18)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3         = C.TextDim
	lbl.Font               = Enum.Font.GothamMedium
	lbl.TextSize           = 10
	lbl.Text               = label .. ": --/--"
	lbl.TextXAlignment     = Enum.TextXAlignment.Left
	lbl.Parent             = cont

	local barbg = Instance.new("Frame")
	barbg.Size                   = UDim2.new(1, 0, 0, 26)
	barbg.Position               = UDim2.new(0, 0, 0, 24)
	barbg.BackgroundColor3       = C.BgDark
	barbg.BackgroundTransparency = 0.4
	barbg.Parent                 = cont
	Instance.new("UICorner", barbg).CornerRadius = UDim.new(0, 12)
	local bst = Instance.new("UIStroke", barbg)
	bst.Color       = color
	bst.Transparency = 0.4
	bst.Thickness   = 1.5

	local fill = Instance.new("Frame")
	fill.Size             = UDim2.new(0.5, 0, 1, 0)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel  = 0
	fill.Parent           = barbg
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 12)

	task.spawn(function()
		while cont and cont.Parent do
			local cur = getVal()
			local max = getMax()
			local ratio = max > 0 and math.clamp(cur / max, 0, 1) or 0
			VFX.tween(fill, 0.4, {Size = UDim2.new(ratio, 0, 1, 0)})
			lbl.Text = label .. ": " .. math.floor(cur) .. "/" .. math.floor(max)
			task.wait(0.4)
		end
	end)
	return cont
end

-- ======= SECTION DIVIDER =======
local function mkDivider(text, parent)
	local d = Instance.new("Frame")
	d.Size               = UDim2.new(1, 0, 0, 45)
	d.BackgroundTransparency = 1
	d.Parent             = parent

	local line = Instance.new("Frame")
	line.Size                   = UDim2.new(1, 0, 0, 1.5)
	line.Position               = UDim2.new(0, 0, 0.5, -1)
	line.BackgroundColor3       = C.Primary
	line.BackgroundTransparency = 0.5
	line.BorderSizePixel        = 0
	line.Parent                 = d

	local lbl = Instance.new("TextLabel")
	lbl.Size                   = UDim2.new(1, -40, 0, 24)
	lbl.Position               = UDim2.new(0, 20, 0, 8)
	lbl.BackgroundColor3       = C.BgMedium
	lbl.BackgroundTransparency = 0.2
	lbl.BorderSizePixel        = 0
	lbl.TextColor3             = C.Primary
	lbl.Font                   = Enum.Font.GothamBlack
	lbl.TextSize               = 11
	lbl.Text                   = text
	lbl.Parent                 = d
	Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 8)
end

-- ======= MAIN GUI =======
local function createGUI()
	local player = NB.Player

	local targetParent = (type(gethui) == "function" and gethui())
		or game:GetService("CoreGui")
		or player:WaitForChild("PlayerGui")

	local existing = targetParent:FindFirstChild("NarutoBot")
	if existing then existing:Destroy() end

	-- ScreenGui
	local sg = Instance.new("ScreenGui")
	sg.Name         = "NarutoBot"
	sg.ResetOnSpawn = false
	sg.DisplayOrder = 999
	sg.Parent       = targetParent
	ST.screenGui    = sg

	-- Loading ScreenGui
	local lsg = Instance.new("ScreenGui")
	lsg.Name         = "LoadingScreen"
	lsg.ResetOnSpawn = false
	lsg.DisplayOrder = 10000
	lsg.Parent       = targetParent
	local lc = Instance.new("Frame")
	lc.BackgroundTransparency = 1
	lc.Size   = UDim2.new(1, 0, 1, 0)
	lc.Parent = lsg
	VFX.createLoadingScreen(lc)

	-- Main frame
	local mf = Instance.new("Frame")
	mf.Size                   = UDim2.new(0, 480, 0, 800)
	mf.Position               = UDim2.new(0.5, -240, 0.5, -400)
	mf.BackgroundColor3       = C.BgMedium
	mf.BackgroundTransparency = 0.05
	mf.BorderSizePixel        = 0
	mf.Parent                 = sg
	mf.ClipsDescendants       = true
	mf.ZIndex                 = 999
	Instance.new("UICorner", mf).CornerRadius = UDim.new(0, 35)
	local mStroke = Instance.new("UIStroke", mf)
	mStroke.Color       = C.Primary
	mStroke.Transparency = 0.15
	mStroke.Thickness   = 2.5
	VFX.createNeonGlow(mf, C.Primary, 0.8)
	ST.mainFrame = mf

	-- ======= TITLEBAR =======
	local tbar = Instance.new("Frame")
	tbar.Size                   = UDim2.new(1, 0, 0, 110)
	tbar.BackgroundColor3       = C.BgDark
	tbar.BackgroundTransparency = 0.2
	tbar.BorderSizePixel        = 0
	tbar.Parent                 = mf
	tbar.ZIndex                 = 100
	local tgrad = Instance.new("UIGradient", tbar)
	tgrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0,   C.Primary),
		ColorSequenceKeypoint.new(0.5, C.AccentAlt),
		ColorSequenceKeypoint.new(1,   C.Accent),
	})
	tgrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.87),
		NumberSequenceKeypoint.new(1, 0.93),
	})
	Instance.new("UICorner", tbar).CornerRadius = UDim.new(0, 35)

	local avatar = Instance.new("TextLabel")
	avatar.Size               = UDim2.new(0, 80, 0, 80)
	avatar.Position           = UDim2.new(0, 15, 0.5, -40)
	avatar.BackgroundTransparency = 1
	avatar.Text               = "⚡"
	avatar.TextSize           = 60
	avatar.Parent             = tbar
	avatar.ZIndex             = 110
	task.spawn(function()
		while avatar and avatar.Parent do
			VFX.tween(avatar, 3, {Rotation = 360}, Enum.EasingStyle.Linear)
			task.wait(3)
			if avatar and avatar.Parent then avatar.Rotation = 0 end
		end
	end)

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size               = UDim2.new(1, -180, 0, 40)
	titleLbl.Position           = UDim2.new(0, 100, 0, 10)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text               = "NARUTO BOT"
	titleLbl.TextColor3         = Color3.fromRGB(255, 255, 255)
	titleLbl.Font               = Enum.Font.GothamBlack
	titleLbl.TextSize           = 24
	titleLbl.TextXAlignment     = Enum.TextXAlignment.Left
	titleLbl.TextYAlignment     = Enum.TextYAlignment.Center
	titleLbl.Parent             = tbar
	titleLbl.ZIndex             = 110

	local subtitle = Instance.new("TextLabel")
	subtitle.Size               = UDim2.new(1, -180, 0, 35)
	subtitle.Position           = UDim2.new(0, 100, 0, 50)
	subtitle.BackgroundTransparency = 1
	subtitle.Text               = "✨ Premium Autofarm System ✨"
	subtitle.TextColor3         = C.Accent
	subtitle.Font               = Enum.Font.GothamMedium
	subtitle.TextSize           = 11
	subtitle.TextXAlignment     = Enum.TextXAlignment.Left
	subtitle.Parent             = tbar
	subtitle.ZIndex             = 110

	-- Minimize gomb
	local minBtn = Instance.new("TextButton")
	minBtn.Size                   = UDim2.new(0, 42, 0, 42)
	minBtn.Position               = UDim2.new(1, -95, 0.5, -21)
	minBtn.BackgroundColor3       = C.Secondary
	minBtn.BackgroundTransparency = 0.35
	minBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
	minBtn.Font                   = Enum.Font.GothamBold
	minBtn.TextSize               = 22
	minBtn.Text                   = "−"
	minBtn.Parent                 = tbar
	minBtn.ZIndex                 = 110
	Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 14)
	Instance.new("UIStroke", minBtn).Color = C.Secondary
	minBtn.MouseEnter:Connect(function() VFX.tween(minBtn, 0.2, {BackgroundTransparency=0.15}) VFX.createParticles(minBtn, C.Secondary, 6) end)
	minBtn.MouseLeave:Connect(function() VFX.tween(minBtn, 0.2, {BackgroundTransparency=0.35}) end)

	-- Close gomb
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size                   = UDim2.new(0, 42, 0, 42)
	closeBtn.Position               = UDim2.new(1, -42, 0.5, -21)
	closeBtn.BackgroundColor3       = C.Danger
	closeBtn.BackgroundTransparency = 0.35
	closeBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
	closeBtn.Font                   = Enum.Font.GothamBold
	closeBtn.TextSize               = 20
	closeBtn.Text                   = "✕"
	closeBtn.Parent                 = tbar
	closeBtn.ZIndex                 = 110
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 14)
	Instance.new("UIStroke", closeBtn).Color = C.Danger
	closeBtn.MouseEnter:Connect(function() VFX.tween(closeBtn, 0.2, {BackgroundTransparency=0.15}) VFX.createParticles(closeBtn, C.Danger, 6) end)
	closeBtn.MouseLeave:Connect(function() VFX.tween(closeBtn, 0.2, {BackgroundTransparency=0.35}) end)

	-- ======= SCROLL FRAME =======
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size                        = UDim2.new(1, -24, 1, -240)
	scroll.Position                    = UDim2.new(0, 12, 0, 120)
	scroll.BackgroundTransparency      = 1
	scroll.BorderSizePixel             = 0
	scroll.ScrollBarThickness          = 5
	scroll.ScrollBarImageColor3        = C.Primary
	scroll.ScrollBarImageTransparency  = 0.4
	scroll.Parent                      = mf
	scroll.CanvasSize                  = UDim2.new(0, 0, 0, 0)
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding   = UDim.new(0, 12)
	layout.Parent    = scroll
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 24)
	end)

	-- ======= CONTENT =======
	-- Célpontok
	mkDivider("🎯 CÉLPONTOK", scroll)
	local targetLabel = Instance.new("TextLabel")
	targetLabel.Size                   = UDim2.new(1, 0, 0, 50)
	targetLabel.BackgroundColor3       = C.Accent
	targetLabel.BackgroundTransparency = 0.65
	targetLabel.TextColor3             = C.Text
	targetLabel.Font                   = Enum.Font.GothamMedium
	targetLabel.TextSize               = 10
	targetLabel.Text                   = "🎯 Nincs kijelölt célpont"
	targetLabel.TextXAlignment         = Enum.TextXAlignment.Left
	targetLabel.TextWrapped            = true
	targetLabel.Parent                 = scroll
	targetLabel.ZIndex                 = 5
	Instance.new("UICorner", targetLabel).CornerRadius = UDim.new(0, 14)
	local tStroke = Instance.new("UIStroke", targetLabel)
	tStroke.Color       = C.Accent
	tStroke.Transparency = 0.3
	tStroke.Thickness   = 1.5
	local tPad = Instance.new("UIPadding", targetLabel)
	tPad.PaddingLeft   = UDim.new(0, 14) ; tPad.PaddingRight  = UDim.new(0, 14)
	tPad.PaddingTop    = UDim.new(0, 8)  ; tPad.PaddingBottom = UDim.new(0, 8)
	uiE.TargetLabel = targetLabel

	local _, selBtn = mkButton("🎯 CÉLPONTOK KIVÁLASZTÁSA", function()
		NB.scanNPCNames() ; uiE.ShowTargetMenu()
	end, C.Accent)
	selBtn.Parent = scroll

	-- Mozgás
	mkDivider("🚀 MOZGÁS", scroll)
	local _, moveBtn = mkButton("🚀 Mozgás: " .. CFG.MoveMode, function()
		CFG.MoveMode = (CFG.MoveMode == "Walk") and "Teleport" or "Walk"
		return "🚀 Mozgás: " .. CFG.MoveMode
	end, C.Tertiary)
	moveBtn.Parent = scroll

	-- Statisztikák
	mkDivider("⚡ STATISZTIKÁK", scroll)
	mkStatBar("⚡ Chakra",
		function() return (NB.getChakraData()) end,
		function() return (select(2, NB.getChakraData())) end,
		C.Secondary).Parent = scroll
	mkStatBar("❤ Élet",
		function()
			local hum = NB.Player.Character and NB.Player.Character:FindFirstChildOfClass("Humanoid")
			return hum and hum.Health or 0
		end,
		function()
			local hum = NB.Player.Character and NB.Player.Character:FindFirstChildOfClass("Humanoid")
			return hum and hum.MaxHealth or 100
		end,
		C.Danger).Parent = scroll

	-- Időzítés
	mkDivider("⏱ IDŐZÍTÉS & GYÓGYÍTÁS", scroll)
	local _, rdBtn = mkButton("⏱ Visszatérési késés: " .. CFG.ReturnDelay .. "s", function()
		CFG.ReturnDelay = CFG.ReturnDelay + 1
		if CFG.ReturnDelay > 10 then CFG.ReturnDelay = 0 end
		return "⏱ Visszatérési késés: " .. CFG.ReturnDelay .. "s"
	end, C.Warning)
	rdBtn.Parent = scroll

	local _, htBtn = mkButton("🏥 HP Küszöb: " .. math.floor(CFG.AutoHealthThreshold*100) .. "%", function()
		CFG.AutoHealthThreshold = CFG.AutoHealthThreshold + 0.1
		if CFG.AutoHealthThreshold > 0.9 then CFG.AutoHealthThreshold = 0.1 end
		return "🏥 HP Küszöb: " .. math.floor(CFG.AutoHealthThreshold*100) .. "%"
	end, C.Danger)
	htBtn.Parent = scroll

	local _, ctBtn = mkButton("⚡ Chakra Küszöb: " .. math.floor(CFG.AutoChakraThreshold*100) .. "%", function()
		CFG.AutoChakraThreshold = CFG.AutoChakraThreshold + 0.1
		if CFG.AutoChakraThreshold > 0.9 then CFG.AutoChakraThreshold = 0.1 end
		return "⚡ Chakra Küszöb: " .. math.floor(CFG.AutoChakraThreshold*100) .. "%"
	end, C.Secondary)
	ctBtn.Parent = scroll

	local _, hBtn = mkButton("💊 Gyógyszer Használata", function()
		local fn = _G.GlassFarmProUseHealthRefill
		if type(fn) ~= "function" then return "" end
		return fn() and "✓ Sikerült" or "✕ Sikertelen"
	end, C.Success)
	hBtn.Parent = scroll

	-- Opciók
	mkDivider("⚙ OPCIÓK", scroll)
	local _, t1 = mkToggle("Élet Visszatöltés",      "HealthEnabled")     ; t1.Parent = scroll
	local _, t2 = mkToggle("Gyógyítás Harc Közben",  "HealDuringCombat")  ; t2.Parent = scroll
	local _, t3 = mkToggle("Képességek Használata",  "AutoAbility")       ; t3.Parent = scroll
	local _, t4 = mkToggle("Anti AFK",               "AntiAFK")           ; t4.Parent = scroll

	-- ======= BOTTOM PANEL =======
	local bottom = Instance.new("Frame")
	bottom.Size                   = UDim2.new(1, 0, 0, 130)
	bottom.Position               = UDim2.new(0, 0, 1, -130)
	bottom.BackgroundColor3       = C.BgDark
	bottom.BackgroundTransparency = 0.2
	bottom.BorderSizePixel        = 0
	bottom.Parent                 = mf
	Instance.new("UICorner", bottom).CornerRadius = UDim.new(0, 35)
	local bStroke = Instance.new("UIStroke", bottom)
	bStroke.Color       = C.Primary
	bStroke.Transparency = 0.4
	bStroke.Thickness   = 2

	uiE.StatusLabel = Instance.new("TextLabel")
	uiE.StatusLabel.Size               = UDim2.new(1, -24, 0, 30)
	uiE.StatusLabel.Position           = UDim2.new(0, 12, 0, 8)
	uiE.StatusLabel.BackgroundTransparency = 1
	uiE.StatusLabel.TextColor3         = C.Primary
	uiE.StatusLabel.Text               = "💫 Parancsra vár..."
	uiE.StatusLabel.Font               = Enum.Font.GothamMedium
	uiE.StatusLabel.TextSize           = 12
	uiE.StatusLabel.TextXAlignment     = Enum.TextXAlignment.Left
	uiE.StatusLabel.Parent             = bottom

	uiE.ToggleBtn = Instance.new("TextButton")
	uiE.ToggleBtn.Size                   = UDim2.new(0.92, 0, 0, 52)
	uiE.ToggleBtn.Position               = UDim2.new(0.04, 0, 0, 44)
	uiE.ToggleBtn.BackgroundColor3       = C.Success
	uiE.ToggleBtn.BackgroundTransparency = 0.3
	uiE.ToggleBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
	uiE.ToggleBtn.Text                   = "▶ START"
	uiE.ToggleBtn.Font                   = Enum.Font.GothamBlack
	uiE.ToggleBtn.TextSize               = 14
	uiE.ToggleBtn.Parent                 = bottom
	uiE.ToggleBtn.ZIndex                 = 10
	Instance.new("UICorner", uiE.ToggleBtn).CornerRadius = UDim.new(0, 14)
	local tgStroke = Instance.new("UIStroke", uiE.ToggleBtn)
	tgStroke.Color       = C.Success
	tgStroke.Transparency = 0.2
	tgStroke.Thickness   = 2
	local tgGlow = Instance.new("Frame")
	tgGlow.Size                   = UDim2.new(1.08, 0, 1.08, 0)
	tgGlow.Position               = UDim2.new(-0.04, 0, -0.04, 0)
	tgGlow.BackgroundColor3       = C.Success
	tgGlow.BorderSizePixel        = 0
	tgGlow.BackgroundTransparency = 0.9
	tgGlow.Parent                 = uiE.ToggleBtn
	tgGlow.ZIndex                 = 9
	Instance.new("UICorner", tgGlow).CornerRadius = UDim.new(0, 14)
	uiE.ToggleBtn.MouseEnter:Connect(function()
		VFX.tween(uiE.ToggleBtn, 0.2, {BackgroundTransparency=0.1})
		VFX.tween(tgGlow, 0.2, {BackgroundTransparency=0.7})
		VFX.createParticles(uiE.ToggleBtn, C.Success, 10)
	end)
	uiE.ToggleBtn.MouseLeave:Connect(function()
		VFX.tween(uiE.ToggleBtn, 0.2, {BackgroundTransparency=0.3})
		VFX.tween(tgGlow, 0.2, {BackgroundTransparency=0.9})
	end)

	-- ======= CÉLPONT MENÜ =======
	local function createTargetMenu()
		local ex = targetParent:FindFirstChild("TargetMenu")
		if ex then ex:Destroy() end

		local mg = Instance.new("ScreenGui")
		mg.Name = "TargetMenu" ; mg.ResetOnSpawn = false ; mg.DisplayOrder = 2000 ; mg.Parent = targetParent

		local bd = Instance.new("Frame")
		bd.Size = UDim2.new(1,0,1,0) ; bd.BackgroundColor3 = C.BgDark
		bd.BackgroundTransparency = 0.5 ; bd.BorderSizePixel = 0 ; bd.Parent = mg ; bd.ZIndex = 1999

		local mf2 = Instance.new("Frame")
		mf2.Size = UDim2.new(0,440,0,580) ; mf2.Position = UDim2.new(0.5,-220,1.5,-290)
		mf2.BackgroundColor3 = C.BgMedium ; mf2.BackgroundTransparency = 0.08
		mf2.BorderSizePixel = 0 ; mf2.Parent = mg ; mf2.ZIndex = 2000 ; mf2.ClipsDescendants = true
		Instance.new("UICorner", mf2).CornerRadius = UDim.new(0,30)
		local ms2 = Instance.new("UIStroke", mf2)
		ms2.Color = C.Primary ; ms2.Transparency = 0.15 ; ms2.Thickness = 2.5
		VFX.createNeonGlow(mf2, C.Primary, 0.6)

		local mtitle = Instance.new("TextLabel")
		mtitle.Size = UDim2.new(1,0,0,70) ; mtitle.BackgroundColor3 = C.BgDark
		mtitle.BackgroundTransparency = 0.15 ; mtitle.TextColor3 = C.Primary
		mtitle.Font = Enum.Font.GothamBlack ; mtitle.TextSize = 18
		mtitle.Text = "🎯 CÉLPONT KIVÁLASZTÁS" ; mtitle.BorderSizePixel = 0
		mtitle.Parent = mf2 ; mtitle.ZIndex = 2001
		Instance.new("UICorner", mtitle).CornerRadius = UDim.new(0,30)

		local mscroll = Instance.new("ScrollingFrame")
		mscroll.Size = UDim2.new(1,-24,1,-160) ; mscroll.Position = UDim2.new(0,12,0,80)
		mscroll.BackgroundTransparency = 1 ; mscroll.BorderSizePixel = 0
		mscroll.ScrollBarThickness = 5 ; mscroll.ScrollBarImageColor3 = C.Primary
		mscroll.ScrollBarImageTransparency = 0.4 ; mscroll.Parent = mf2
		mscroll.ZIndex = 2001 ; mscroll.CanvasSize = UDim2.new(0,0,0,0)
		local ml = Instance.new("UIListLayout")
		ml.SortOrder = Enum.SortOrder.LayoutOrder ; ml.Padding = UDim.new(0,10) ; ml.Parent = mscroll
		ml:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			mscroll.CanvasSize = UDim2.new(0,0,0, ml.AbsoluteContentSize.Y + 20)
		end)

		for _, npcName in ipairs(NB.State.availableNPCs) do
			local isSel = table.find(CFG.TargetNPCs, npcName)
			local cc = Instance.new("Frame")
			cc.Size = UDim2.new(1,0,0,44) ; cc.BackgroundTransparency = 1 ; cc.Parent = mscroll

			local cb = Instance.new("TextButton")
			cb.Size = UDim2.new(1,0,1,0) ; cb.BackgroundColor3 = isSel and C.Success or C.Secondary
			cb.BackgroundTransparency = 0.5 ; cb.TextColor3 = C.Text
			cb.Font = Enum.Font.GothamSemibold ; cb.TextSize = 12
			cb.Text = (isSel and "✓ " or "  ") .. npcName
			cb.Parent = cc ; cb.ZIndex = 2002
			Instance.new("UICorner", cb).CornerRadius = UDim.new(0,14)
			local cbs = Instance.new("UIStroke", cb)
			cbs.Color = isSel and C.Success or C.Secondary ; cbs.Transparency = 0.4 ; cbs.Thickness = 1.5
			local cbg = Instance.new("Frame")
			cbg.Size = UDim2.new(1.08,0,1.08,0) ; cbg.Position = UDim2.new(-0.04,0,-0.04,0)
			cbg.BackgroundColor3 = isSel and C.Success or C.Secondary ; cbg.BorderSizePixel = 0
			cbg.BackgroundTransparency = 0.9 ; cbg.Parent = cc ; cbg.ZIndex = 2001
			Instance.new("UICorner", cbg).CornerRadius = UDim.new(0,14)

			cb.MouseEnter:Connect(function()
				VFX.tween(cb, 0.2, {BackgroundTransparency=0.3})
				VFX.tween(cbg, 0.2, {BackgroundTransparency=0.7})
			end)
			cb.MouseLeave:Connect(function()
				VFX.tween(cb, 0.2, {BackgroundTransparency=0.5})
				VFX.tween(cbg, 0.2, {BackgroundTransparency=0.9})
			end)
			cb.MouseButton1Click:Connect(function()
				VFX.createRipple(cb, C.Primary)
				local fi = table.find(CFG.TargetNPCs, npcName)
				if fi then table.remove(CFG.TargetNPCs, fi) else table.insert(CFG.TargetNPCs, npcName) end
				local ns = table.find(CFG.TargetNPCs, npcName)
				local nc = ns and C.Success or C.Secondary
				VFX.tween(cb, 0.2, {BackgroundColor3=nc}) ; VFX.tween(cbs, 0.2, {Color=nc}) ; VFX.tween(cbg, 0.2, {BackgroundColor3=nc})
				cb.Text = (ns and "✓ " or "  ") .. npcName
				uiE.UpdateTargetLabel()
			end)
		end

		local bc = Instance.new("Frame")
		bc.Size = UDim2.new(1,0,0,70) ; bc.Position = UDim2.new(0,0,1,-70)
		bc.BackgroundColor3 = C.BgDark ; bc.BackgroundTransparency = 0.3
		bc.BorderSizePixel = 0 ; bc.Parent = mf2 ; bc.ZIndex = 2001
		Instance.new("UICorner", bc).CornerRadius = UDim.new(0,30)

		local ok  = Instance.new("TextButton")
		ok.Size = UDim2.new(0.48,0,0,50) ; ok.Position = UDim2.new(0.02,0,0.5,-25)
		ok.BackgroundColor3 = C.Success ; ok.BackgroundTransparency = 0.3
		ok.TextColor3 = Color3.fromRGB(255,255,255) ; ok.Font = Enum.Font.GothamBlack
		ok.TextSize = 13 ; ok.Text = "✓ MEGERŐSÍTÉS" ; ok.BorderSizePixel = 0
		ok.Parent = bc ; ok.ZIndex = 2002
		Instance.new("UICorner", ok).CornerRadius = UDim.new(0,12)

		local ca = Instance.new("TextButton")
		ca.Size = UDim2.new(0.48,0,0,50) ; ca.Position = UDim2.new(0.5,0,0.5,-25)
		ca.BackgroundColor3 = C.Danger ; ca.BackgroundTransparency = 0.3
		ca.TextColor3 = Color3.fromRGB(255,255,255) ; ca.Font = Enum.Font.GothamBlack
		ca.TextSize = 13 ; ca.Text = "✕ MÉGSE" ; ca.BorderSizePixel = 0
		ca.Parent = bc ; ca.ZIndex = 2002
		Instance.new("UICorner", ca).CornerRadius = UDim.new(0,12)

		ok.MouseEnter:Connect(function() VFX.tween(ok, 0.2, {BackgroundTransparency=0.1}) VFX.createParticles(ok, C.Success, 8) end)
		ok.MouseLeave:Connect(function() VFX.tween(ok, 0.2, {BackgroundTransparency=0.3}) end)
		ca.MouseEnter:Connect(function() VFX.tween(ca, 0.2, {BackgroundTransparency=0.1}) VFX.createParticles(ca, C.Danger, 8) end)
		ca.MouseLeave:Connect(function() VFX.tween(ca, 0.2, {BackgroundTransparency=0.3}) end)
		ok.MouseButton1Click:Connect(function()
			VFX.createRipple(ok, C.Success)
			VFX.tween(mf2, 0.4, {Position=UDim2.new(0.5,-220,1.5,-290)}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			task.wait(0.4) ; mg:Destroy()
		end)
		ca.MouseButton1Click:Connect(function()
			VFX.createRipple(ca, C.Danger)
			CFG.TargetNPCs = {}
			VFX.tween(mf2, 0.4, {Position=UDim2.new(0.5,-220,1.5,-290)}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			task.wait(0.4) ; mg:Destroy() ; uiE.UpdateTargetLabel()
		end)

		VFX.tween(mf2, 0.5, {Position=UDim2.new(0.5,-220,0.5,-290)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end

	uiE.ShowTargetMenu = createTargetMenu
	uiE.UpdateTargetLabel = function()
		if #CFG.TargetNPCs == 0 then
			targetLabel.Text = "🎯 Nincs kijelölt célpont"
		else
			targetLabel.Text = "🎯 " .. table.concat(CFG.TargetNPCs, ", ")
		end
	end

	-- ======= DRAGGING =======
	tbar.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			ST.isDragging = true ; ST.dragStart = input.Position
			ST.startPos = mf.Position ; ST.dragInput = input
		end
	end)
	tbar.InputChanged:Connect(function(input)
		if input == ST.dragInput and ST.isDragging then
			local d = input.Position - ST.dragStart
			mf.Position = ST.startPos + UDim2.new(0, d.X, 0, d.Y)
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if input == ST.dragInput then ST.isDragging = false end
	end)

	-- ======= MINIMIZE / CLOSE =======
	minBtn.MouseButton1Click:Connect(function()
		VFX.createRipple(minBtn, C.Secondary)
		ST.uiVisible = not ST.uiVisible
		VFX.tween(mf, 0.5,
			{Size = ST.uiVisible and UDim2.new(0,480,0,800) or UDim2.new(0,480,0,110)},
			Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end)
	closeBtn.MouseButton1Click:Connect(function()
		VFX.createRipple(closeBtn, C.Danger)
		VFX.tween(mf, 0.5, {Position=UDim2.new(0.5,-240,0.5,-1200)}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.wait(0.5)
		uiE.Cleanup()
	end)

	-- ======= LOADING BEFEJEZÉSE =======
	task.wait(3)
	VFX.tween(lc, 0.6, {Size=UDim2.new(1,0,0,0)}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	task.wait(0.6)
	lsg:Destroy()
	VFX.tween(mf, 0.7, {Position=UDim2.new(0.5,-240,0.5,-400)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

createGUI()
