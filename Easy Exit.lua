script_name('Easy Exit')
script_properties('work-in-pause', 'forced-reloading-only')
require"lib.moonloader"

function main()
	
	local keydown, keyup = 0, 0

	while true do wait(0)
		if wasKeyPressed(VK_ESCAPE) then keydown = os.clock() end
		if isKeyDown(VK_ESCAPE) then
			keyup = os.clock()
			active = true
			if (keyup - keydown) >= 0.47 then os.execute('taskkill /IM gta_sa.exe /F') end
		end
		if  wasKeyReleased(VK_ESCAPE) then active = false end
	end
end


function onWindowMessage(msg, wparam, lparam)
	if msg == 0x100 or msg == 0x104 then
		if wparam == 27 and active then	
			consumeWindowMessage(true, true)
		end
	end
end
