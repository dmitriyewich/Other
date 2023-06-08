script_name('cam.set.lua')
script_author("SR_team(https://www.blast.hk/threads/5576/), Deeps (https://www.blast.hk/threads/127797/), edited by dmitriyewich")
script_url("https://vk.com/dmitriyewichmods")
script_properties("work-in-pause", "forced-reloading-only")
script_version('3.1')

local memory = require 'memory'
local ffi = require 'ffi'
local lhook, hook = pcall(require, 'hooks') -- https://www.blast.hk/threads/55743/post-838589
local lmad, mad = pcall(require, 'MoonAdditions') -- https://github.com/THE-FYP/MoonAdditions

function CPed__Render(this)
	if active and getCharPointer(1) == this then
		return false
	else
		jit.off(CPed__Render(this), true)
		return CPed__Render(this)
	end
end

function main()
	repeat wait(0) until memory.read(0xC8D4C0, 4, false) == 9
	repeat wait(0) until fixed_camera_to_skin()
	
	if lhook then CPed__Render = hook.jmp.new("void (__thiscall*)(uintptr_t)", CPed__Render, 0x5E7680) end

	while true do wait(0)
		local cam, myPos = {getActiveCameraCoordinates()}, {getCharCoordinates(PLAYER_PED)}
		local dist = getDistanceBetweenCoords3d(cam[1], cam[2], cam[3], myPos[1], myPos[2], myPos[3])
		if dist <= 0.9 then
			if not active then
				active = true
				if lmad then mad.set_char_model_alpha(PLAYER_PED, 0) end
				memory.setuint8(memory.getuint8(0xB6F5F0, true) + 0x474, 6, true)
				object_visible(false)
			end
		elseif active then
			active = false
			if lmad then mad.set_char_model_alpha(PLAYER_PED, 255) end
			memory.setuint8(memory.getuint8(0xB6F5F0, true) + 0x474, 4, true)
			object_visible(true)
		end
	end
end

function object_visible(bool)
	local tbl = getAllObjects()
	for i = 1, #tbl do
		local tObj = {getObjectCoordinates(tbl[i])}
		local x, y, z = getCharCoordinates(PLAYER_PED)
		if getDistanceBetweenCoords3d(tObj[2], tObj[3], tObj[4], x, y, z) < 0.9 then -- радиус измени на свой
			setObjectVisible(tbl[i], bool)
		end
	end
end

function fixed_camera_to_skin() -- проверка на приклепление камеры к скину
	return (memory.read(getModuleHandle('gta_sa.exe') + 0x76F053, 1, false) >= 1 and true or false)
end

function onScriptTerminate(LuaScript, quitGame)
    if LuaScript == thisScript() and not quitGame then
		object_visible(true)
		memory.setuint8(memory.getuint8(0xB6F5F0, true) + 0x474, 4, true)
		if lmad then mad.set_char_model_alpha(PLAYER_PED, 255) end
		collectgarbage("collect")
    end
end
