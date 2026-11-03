-- ============================================================
--  NarutoBot  |  VFX.lua
--  Vizuális effektek · Animációk · Loading screen
--  JAVÍTÁS: UIBlur eltávolítva (Frame-en belül nem érvényes)
-- ============================================================

local NB    = _G.NarutoBot
local C     = NB.COLORS
local TS    = NB.Services.TweenService

NB.VFX = {}
local VFX = NB.VFX

-- ======= TWEEN =======
function VFX.tween(obj, duration, props, style, dir)
	if not obj or not obj.Parent then return nil end
	style = style or Enum.EasingStyle.Quad
	dir   = dir   or Enum.EasingDirection.InOut
	local t = TS:Create(obj, TweenInfo.new(duration, style, dir), props)
	t:Play()
	return t
end

-- ======= NEON GLOW =======
-- ✅ FIX: UIBlur.Size hiba → UIBlur teljesen eltávolítva.
--    A Frame-ek belsejébe parented UIBlur nem támogatja a Size propertyt.
--    A glowhatás BackgroundTransparency-vel van megoldva.
function VFX.createNeonGlow(parent, color, intensity)
	intensity = intensity or 1
	local glow = Instance.new("Frame")
	glow.Size                   = UDim2.new(1.2, 0, 1.2, 0)
	glow.Position               = UDim2.new(-0.1, 0, -0.1, 0)
	glow.BackgroundColor3       = color
	glow.BorderSizePixel        = 0
	glow.BackgroundTransparency = math.clamp(0.78 - (intensity * 0.06), 0.5, 0.95)
	glow.Parent                 = parent
	glow.ZIndex                 = math.max(1, parent.ZIndex - 1)
	Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 50)
	return glow
end

-- ======= RIPPLE =======
function VFX.createRipple(parent, color)
	local r = Instance.new("Frame")
	r.Size                   = UDim2.new(0, 0, 0, 0)
	r.Position               = UDim2.new(0.5, 0, 0.5, 0)
	r.AnchorPoint            = Vector2.new(0.5, 0.5)
	r.BackgroundColor3       = color
	r.BorderSizePixel        = 0
	r.BackgroundTransparency = 0.5
	r.Parent                 = parent
	Instance.new("UICorner", r).CornerRadius = UDim.new(1, 0)
	task.spawn(function()
		VFX.tween(r, 0.6,
			{Size = UDim2.new(1.5,0,1.5,0), BackgroundTransparency = 1},
			Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		task.wait(0.7)
		if r and r.Parent then r:Destroy() end
	end)
end

-- ======= PARTICLES =======
function VFX.createParticles(parent, color, count)
	count = count or 12
	for i = 1, count do
		local p = Instance.new("Frame")
		p.Size                   = UDim2.new(0, 6, 0, 6)
		p.BackgroundColor3       = color
		p.BorderSizePixel        = 0
		p.BackgroundTransparency = 0.3
		p.Parent                 = parent
		Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)

		local angle = (i / count) * math.pi * 2
		local dist  = 60
		p.Position  = UDim2.new(0.5, math.cos(angle)*5 - 3, 0.5, math.sin(angle)*5 - 3)

		task.spawn(function()
			VFX.tween(p, 0.8, {
				Position = UDim2.new(
					0.5, math.cos(angle)*dist - 3,
					0.5, math.sin(angle)*dist - 3
				),
				BackgroundTransparency = 1,
			}, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
		end)
		task.delay(0.9, function()
			if p and p.Parent then p:Destroy() end
		end)
	end
end

-- ======= LOADING SCREEN =======
function VFX.createLoadingScreen(container)
	-- Háttér
	local bg = Instance.new("Frame")
	bg.Size             = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = C.BgDark
	bg.BorderSizePixel  = 0
	bg.Parent           = container
	bg.ZIndex           = 1
	local grad = Instance.new("UIGradient", bg)
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0,   C.BgDark),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 35, 80)),
		ColorSequenceKeypoint.new(1,   C.BgDark),
	})

	-- Betöltő doboz
	local box = Instance.new("Frame")
	box.Size                   = UDim2.new(0, 320, 0, 320)
	box.Position               = UDim2.new(0.5, -160, 0.5, -160)
	box.BackgroundColor3       = C.BgMedium
	box.BackgroundTransparency = 0.1
	box.BorderSizePixel        = 0
	box.Parent                 = container
	box.ZIndex                 = 2
	box.ClipsDescendants       = true
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 30)
	local stroke = Instance.new("UIStroke", box)
	stroke.Color       = C.Primary
	stroke.Thickness   = 3
	stroke.Transparency = 0.2

	VFX.createNeonGlow(box, C.Primary, 0.8)

	-- Forgó keretkijelző
	local border = Instance.new("Frame")
	border.Size               = UDim2.new(1, 0, 1, 0)
	border.BackgroundTransparency = 1
	border.Parent             = box
	border.ZIndex             = 2
	for i = 1, 4 do
		local seg = Instance.new("Frame")
		seg.Size             = UDim2.new(0.3, 0, 0.02, 0)
		seg.BackgroundColor3 = C.Primary
		seg.BorderSizePixel  = 0
		seg.Parent           = border
		seg.Rotation         = i * 90
		seg.Position         = UDim2.new(0.35, 0, -0.01, 0)
	end
	task.spawn(function()
		while border and border.Parent do
			VFX.tween(border, 3, {Rotation = 360}, Enum.EasingStyle.Linear)
			task.wait(3)
			if border and border.Parent then border.Rotation = 0 end
		end
	end)

	-- Pulzáló emoji
	local emoji = Instance.new("TextLabel")
	emoji.Size               = UDim2.new(0, 100, 0, 100)
	emoji.Position           = UDim2.new(0.5, -50, 0.5, -80)
	emoji.BackgroundTransparency = 1
	emoji.Text               = "⚡"
	emoji.TextSize           = 70
	emoji.Parent             = box
	emoji.ZIndex             = 3
	local emojis = {"⚡", "✨", "🌟", "💫"}
	local eidx = 1
	task.spawn(function()
		while emoji and emoji.Parent do
			task.wait(0.5)
			if emoji and emoji.Parent then
				emoji.Text = emojis[eidx]
				eidx = (eidx % #emojis) + 1
			end
		end
	end)
	task.spawn(function()
		while emoji and emoji.Parent do
			VFX.tween(emoji, 0.8, {TextTransparency=0.2, TextSize=85}, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			task.wait(0.8)
			if emoji and emoji.Parent then
				VFX.tween(emoji, 0.8, {TextTransparency=0, TextSize=70}, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
				task.wait(0.8)
			end
		end
	end)

	-- Betöltési szöveg
	local loadTxt = Instance.new("TextLabel")
	loadTxt.Size               = UDim2.new(1, 0, 0, 40)
	loadTxt.Position           = UDim2.new(0, 0, 0.65, 0)
	loadTxt.BackgroundTransparency = 1
	loadTxt.TextColor3         = C.Primary
	loadTxt.Font               = Enum.Font.GothamBlack
	loadTxt.TextSize           = 16
	loadTxt.Parent             = box
	loadTxt.ZIndex             = 3
	task.spawn(function()
		local dots = 0
		while loadTxt and loadTxt.Parent do
			dots = (dots + 1) % 4
			loadTxt.Text = "BETÖLTÉS" .. string.rep(".", dots)
			task.wait(0.4)
		end
	end)

	-- Százalék
	local pct = Instance.new("TextLabel")
	pct.Size               = UDim2.new(1, 0, 0, 30)
	pct.Position           = UDim2.new(0, 0, 0.82, 0)
	pct.BackgroundTransparency = 1
	pct.Text               = "0%"
	pct.TextColor3         = C.Secondary
	pct.Font               = Enum.Font.GothamMedium
	pct.TextSize           = 14
	pct.Parent             = box
	pct.ZIndex             = 3

	-- Progress bar
	local pbg = Instance.new("Frame")
	pbg.Size             = UDim2.new(0.8, 0, 0, 6)
	pbg.Position         = UDim2.new(0.1, 0, 0.9, 0)
	pbg.BackgroundColor3 = C.BgDark
	pbg.BorderSizePixel  = 0
	pbg.Parent           = box
	pbg.ZIndex           = 3
	Instance.new("UICorner", pbg).CornerRadius = UDim.new(1, 0)

	local pfill = Instance.new("Frame")
	pfill.Size             = UDim2.new(0, 0, 1, 0)
	pfill.BackgroundColor3 = C.Primary
	pfill.BorderSizePixel  = 0
	pfill.Parent           = pbg
	pfill.ZIndex           = 3
	Instance.new("UICorner", pfill).CornerRadius = UDim.new(1, 0)

	task.spawn(function()
		for prog = 0, 100, 2 do
			if pct and pct.Parent then
				pct.Text = prog .. "%"
				VFX.tween(pfill, 0.1, {Size = UDim2.new(prog / 100, 0, 1, 0)})
				task.wait(0.1)
			end
		end
	end)

	return container
end
