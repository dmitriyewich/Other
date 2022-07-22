script_properties('work-in-pause', 'forced-reloading-only')
-- thx gennariarmando and LINK/2012 and KepchiK
local lmemory, memory = pcall(require, 'memory')

if memory.getuint32(0xC8D4C0, true) < 9 then

	if memory.getuint8(0x747483, true) == 0x89 then -- Initialize game state
		memory.fill(0x747483, 0x90, 6, true)
	elseif memory.getuint8(0x7474D3, true) == 0x89 then
		memory.fill(0x7474D3, 0x90, 6, true)
	end

	memory.setuint32(0xC8D4C0, 5, true) -- Skip ads

	memory.fill(0x748C23, 0x90, 5, true)

	if memory.getuint8(0x748C2B) == 0xE8 then -- Legal info fade-in
		memory.fill(0x748C2B, 0x90, 5, true)
	elseif memory.getuint8(0x748C7B) == 0xE8 then
		memory.fill(0x748C7B, 0x90, 5, true)
	end

	memory.fill(0x748C9A, 0x90, 5, true)

	memory.fill(0x748CF1, 0x90, 10, true)

	-- if memory.getuint8(0x5909AA, true) == 0xBE then -- Legal info
		-- memory.setuint32(0x5909AB, 1, true)
	-- end

	-- if memory.getuint8(0x590A1D, true) == 0xBE then -- Legal info fade-out
		-- memory.setuint8(0x590A1D, 0xE9, true)
		-- memory.setuint32(0x590A1E, 0x8D, 4, true)
	-- end

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
