script_name("Delete textdraw in box") 
script_authors("dmitriyewich")
script_url("https://vk.com/dmitriyewichmods")
script_dependencies('SAMP.Lua')
script_properties('work-in-pause', 'forced-reloading-only')
script_version("1.0")

local lsampev, sampev = pcall(require, 'samp.events') -- https://github.com/THE-FYP/SAMP.Lua
assert(lsampev, 'Library \'SAMP.Lua\' not found. Download: https://github.com/THE-FYP/SAMP.Lua')

local dell_texdraw = {}

function main()
	
	if not isSampfuncsLoaded() or not isSampLoaded() then return end
	while not isSampAvailable() do wait(100) end
	
	local active, stop, bool, bool1 = false, true, false, false
	local x1, y1, x2, y2 = 0, 0, 0, 0
	
	sampRegisterChatCommand("tdd", function(arg)
		if arg ~= "4" then active = not active end
		if active then showCursor(true) end
		if arg == "1" then bool = true end
		if arg == "2" then bool1 = true end
		if arg == "3" then bool = true; bool1 = true end
		if arg == "4" then dell_texdraw = {} end
	end)

	while true do wait(0)
	
		if active then
			if not isKeyDown(1) and stop then
				x1, y1 = getCursorPos()
			end
			if isKeyDown(1) then
				x2, y2 = getCursorPos()
				renderDrawBox(x1, y1, 0+x2-x1, 0+y2-y1, 0xe5e5e5e5)
				stop = false
			end
		end
		if wasKeyReleased(1) then
			local tbl = IsOnBox(x1, y1, x2, y2, bool, bool1)
			for i = 1, #tbl do
				sampTextdrawDelete(tbl[i])
			end
			stop, active, bool, bool1 = true, false, false, false
			showCursor(false)
		end
	end
end

function IsOnBox(x, y, x1, y2, bool, bool2)
	local id = {}
	for i = 0, 4096 do
		if sampTextdrawIsExists(i) then
			local rX, rY = convertWindowScreenCoordsToGameScreenCoords(x, y)
			local rX2, rY2 = convertWindowScreenCoordsToGameScreenCoords(x1, y2)
			local tdX, tdY = sampTextdrawGetPos(i)
			if tdX >= rX and tdX <= rX2 and tdY >= rY and tdY <= rY2 then
				if bool then print(i) end
				if bool2 then dell_texdraw[#dell_texdraw+1] = i end
				id[#id+1] = i
			end
		end
	end
	return id
end

if lsampev then
	function sampev.onShowTextDraw(id, data) 
		for i = 1, #dell_texdraw do
			if id == dell_texdraw[i] then return false end
		end
	end
end