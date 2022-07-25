script_properties('work-in-pause', 'forced-reloading-only')
-- thx gennariarmando and LINK/2012 and KepchiK
local lmemory, memory = pcall(require, 'memory')

if memory.getuint32(0xC8D4C0, true) < 9 then
	memory.setuint32(0xC8D4C0, 5, true) -- gGameState to 6

	memory.fill(0x747483, 0x90, 6, true) -- Initialize game state US 1.0
	
	memory.fill(0x748AA8, 0x90, 6, true)
	memory.fill(0x748AA8, "C705C0D4C80005000000", 10, true)
	memory.fill(0x748C23, 0x90, 5, true)

	if getModuleHandle("sampfuncs.asi") ~= 0 then
		memory.fill(0x748C9A, 0x90, 5, true) -- copyright screen fading in/out and simulates that it has happened
	end

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

	memory.fill(0x5905B4, 0x90, 5, true) -- Disable loading bar rendering
	memory.fill(0x748CF6, 0x90, 5, true) -- Disable audio tune from loading screen
	memory.fill(0x590D7C, 0x90, 5, true) -- Do not render the loading screen.
	memory.fill(0x590DB3, 0x90, 5, true)
	memory.fill(0x590AC0, 0xC3, 1, true) -- Disable Loading Screen Patch
	memory.fill(0x590D9F, "C390909090", 5, true) -- Disable Loading Screen Patch
end
