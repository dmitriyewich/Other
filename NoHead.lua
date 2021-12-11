function main()
	repeat wait(0) until isSampfuncsLoaded()

	sampRegisterChatCommand("nohead", function()
		active = not active
		require("ffi").cast("void (__thiscall *)(uint32_t, int, char)", 0x5F0140)(getCharPointer(PLAYER_PED), tonumber(active and 2 or 1), 0)
	end)
	wait(-1)
end
