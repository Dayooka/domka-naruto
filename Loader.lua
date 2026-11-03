-- ============================================================
--  NarutoBot  |  LOADER.lua
--  Ezt töltsd be az executorban!
--  loadstring(game:HttpGet("https://raw.githubusercontent.com/Dayooka/domka-modz-van/main/Loader.lua"))()
-- ============================================================

local BASE = "https://raw.githubusercontent.com/Dayooka/domka-modz-van/main/"

_G.NarutoBot = {}

local function loadModule(name)
	local ok, err = pcall(function()
		loadstring(game:HttpGet(BASE .. name .. ".lua"))()
	end)
	if ok then
		print("[NarutoBot] ✅ Betöltve: " .. name)
	else
		warn("[NarutoBot] ❌ Hiba: " .. name .. " → " .. tostring(err))
	end
end

-- Sorrendben töltődnek be (Config → VFX → UI → Gameplay)
loadModule("Config")
loadModule("VFX")
loadModule("UI")
loadModule("Gameplay")
