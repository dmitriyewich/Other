script_properties('work-in-pause', 'forced-reloading-only')
-- thx gennariarmando and LINK/2012 and KepchiK
local lmemory, memory = pcall(require, 'memory')	
memory.setuint8(0x53E797, 0xEB, 1, true)
memory.fill(0x53EB85, 0x90, 2, true)
memory.fill(0x53E826, 0x90, 2, true)
memory.fill(0x748CE1, 0x90, 10, true)

memory.setuint8(0xC8D4C0, 5, 1, true)

memory.fill(0x747483, 0x90, 6, true)
	
memory.fill(0x748C9A, 0x90, 5, true)
	
memory.fill(0x748C23, 0x90, 5, true)
memory.fill(0x748C2B, 0x90, 5, true)

memory.fill(0x748CF1, 0x90, 10, true)

if memory.getuint8(0x5909AA) == 0xBE then
	memory.setuint8(0x5909AB, 1, 1, true)
end
if memory.getuint8(0x590A1D) == 0xBE then
	memory.setuint8(0x590A1D, 0xE9, 1, true)
	memory.setuint32(0x590A1E, 0x8D, 4, true)
end
if memory.getuint8(0x748C6B) == 0xC6 then
	memory.fill(0x748C6B, 0x90, 7, true)
elseif memory.getuint8(0x748CBB) == 0xC6 then
	memory.fill(0x748CBB, 0x90, 7, true)
end
if memory.getuint8(0x590AF0) == 0xA1 then
	memory.setuint8(0x590AF0, 0xE9, 1, true)
	memory.setuint32(0x590AF1, 0x140, 4, true)
end