script_name('cam.set.lua')
script_author("SR_team(https://www.blast.hk/threads/5576/), Deeps (https://www.blast.hk/threads/127797/), edited by dmitriyewich")
script_url("https://vk.com/dmitriyewichmods")
script_properties("work-in-pause", "forced-reloading-only")
script_version('3.0')

local lmemory, memory = pcall(require, 'memory')

function main()
	repeat wait(0) until memory.read(0xC8D4C0, 4, false) == 9
	repeat wait(0) until fixed_camera_to_skin()
	
	while true do wait(0)
		local cam, myPos = {getActiveCameraCoordinates()}, {getCharCoordinates(PLAYER_PED)}
		local dist = getDistanceBetweenCoords3d(cam[1], cam[2], cam[3], myPos[1], myPos[2], myPos[3])
		if dist <= 0.9 then
			if not active then
				active = true
				memory.setuint8(memory.read(0xB6F5F0, 4) + 0x474, 2, true)
				object_visible(false)
			end
		elseif active then
			active = false
			memory.setuint8(memory.read(0xB6F5F0, 4) + 0x474, 1, true)
			object_visible(true)
		end
	end
end

function object_visible(params1) 
	local tbl = getAllObjects()
	for i = 1, #tbl do
		local _, objPosX, objPosY, objPosZ = getObjectCoordinates(tbl[i])
		local x, y, z = getCharCoordinates(PLAYER_PED)
		if getDistanceBetweenCoords3d(objPosX, objPosY, objPosZ, x, y, z) < 0.9 then -- радиус измени на свой
			setObjectVisible(tbl[i], params1)
		end
	end
end

function fixed_camera_to_skin() -- проверка на приклепление камеры к скину
	return (memory.read(getModuleHandle('gta_sa.exe') + 0x76F053, 1, false) >= 1 and true or false)
end

function onScriptTerminate(LuaScript, quitGame)
    if LuaScript == thisScript() and not quitGame then
		object_visible(true)
		memory.setuint8(memory.read(0xB6F5F0, 4) + 0x474, 1, true)
    end
end
