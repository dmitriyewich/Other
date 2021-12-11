local ffi = require("ffi")

function main()
	repeat wait(0) until isSampfuncsLoaded()
    repeat wait(0) until isSampAvailable()
	
	local active = false
	sampRegisterChatCommand("nohead", function()
		active = not active
		if active then arg = 2 else arg = 1 end
		ffi.cast("void (__thiscall *)(uint32_t, int, char)", 0x5F0140)(getCharPointer(PLAYER_PED), tonumber(arg), 0)
	end)
	wait(-1)
end