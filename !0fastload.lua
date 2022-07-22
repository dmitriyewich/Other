script_properties('work-in-pause', 'forced-reloading-only')
-- thx gennariarmando and LINK/2012 and KepchiK
local lmemory, memory = pcall(require, 'memory')

if memory.getuint32(0xC8D4C0, true) < 9 then
	-- memory.fill(0x748A8D, 0x90, 6, true) -- Allow Alt+Tab without pausing the game

	-- memory.setint8(0x53BC78, 0x00, true) -- Disable MENU AFTER alt + tab

	-- memory.setint8(0x74754A, 0xB8, true) -- // No DirectPlay dependency
	-- memory.setint32(0x74754B, 0x900, true) -- // Increase compatibility for Windows 8+

	if memory.getuint8(0x747483, true) == 0x89 then -- Initialize game state
		memory.fill(0x747483, 0x90, 6, true)
	elseif memory.getuint8(0x7474D3, true) == 0x89 then
		memory.fill(0x7474D3, 0x90, 6, true)
	end

	memory.setuint32(0xC8D4C0, 5, true) -- Skip ads

	memory.fill(0x561AF0, 0x90, 7, true) -- antipause

	if memory.getuint8(0x748C2B) == 0xE8 then -- Legal info fade-in
		memory.fill(0x748C2B, 0x90, 5, true)
	elseif memory.getuint8(0x748C7B) == 0xE8 then
		memory.fill(0x748C7B, 0x90, 5, true)
	end

	if memory.getuint8(0x5909AA, true) == 0xBE then -- Legal info
		memory.setuint32(0x5909AB, 1, true)
	end

	if memory.getuint8(0x590A1D, true) == 0xBE then -- Legal info fade-out
		memory.setuint8(0x590A1D, 0xE9, true)
		memory.setuint32(0x590A1E, 0x8D, 4, true)
	end

	memory.fill(0x748C23, 0x90, 5, true)

	memory.fill(0x748C9A, 0x90, 5, true) -- Hook the copyright screen fading in/out and simulates that it has happened
	memory.setint8(0x8D093C, 0, true) -- Previous splash index = copyright notice
	memory.setfloat(0xBAB340, 0, true)-- Decrease timeSinceLastScreen, so it will change immediately
	memory.setint8(0x8D093C, 1, true)--  First Loading Splash


	memory.setfloat(0x590DA4 + 2, 1.0, true) -- loadscreentime

	memory.fill(0x748CF1, 0x90, 10, true)

	memory.fill(0x5905B4, 0x90, 5, true) -- Disable loading bar rendering
	memory.fill(0x748CF6, 0x90, 5, true) -- Disable audio tune from loading screen
	memory.fill(0x590AC0, 0xC3, 1, true) -- Disable Loading Screen Patch
	memory.fill(0x590D9F, "C390909090", 5, true) -- Disable Loading Screen Patch

	-- if memory.getuint8(0x748C6B) == 0xC6 then -- Show load game
		-- memory.fill(0x748C6B, 0x90, 7, true)
	-- elseif memory.getuint8(0x748CBB) == 0xC6 then
		-- memory.fill(0x748CBB, 0x90, 7, true)
	-- end

	-- if memory.getuint8(0x5745DD) == 0xC6 then -- Show load game
		-- memory.setuint8(0x5745E3, 0x09, true)
	-- end

	-- if memory.getuint8(0x5737E0, true) == 0x74 then -- Skip confim
		-- memory.setuint8(0x5737E0, 0x75, true)
	-- end

	-- if memory.getuint8(0x590AF0, true) == 0xA1 then -- Skip loading
		-- memory.setuint8(0x590AF0, 0xE9, 1, true)
		-- memory.setuint32(0x590AF1, 0x140, 4, true)
	-- end
end
