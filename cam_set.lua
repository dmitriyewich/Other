script_name('cam.set.lua')
script_author("SR_team(blast.hk/threads/5576/), Deeps (blast.hk/threads/127797/), edited by dmitriyewich")
script_url("vk.com/dmitriyewichmods")
script_version('3.1.2')

local memory = require 'memory'
local ffi = require 'ffi'
local lhook, hook = pcall(require, 'hooks') -- blast.hk/threads/55743/post-838589
local lmad, mad = pcall(require, 'MoonAdditions') -- github.com/THE-FYP/MoonAdditions

function CPed__Render(this)
	if active and getCharPointer(PLAYER_PED) == this then
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

	SetRwObjectAlpha = ffi.cast("void (__thiscall *)(uintptr_t, int)", 0x5332C0)
	memory.setuint32(0xB6F0DC, 3, false)
	back = memory.getuint32(getCharPointer(PLAYER_PED) + 0x474, false)

	while true do wait(0)
		local cam, myPos = {getActiveCameraCoordinates()}, {getCharCoordinates(PLAYER_PED)}
		local dist = getDistanceBetweenCoords3d(cam[1], cam[2], cam[3], myPos[1], myPos[2], myPos[3])
		active = dist <= 0.9 and true or false
		if lmad then mad.set_char_model_alpha(PLAYER_PED, dist <= 0.9 and 0 or 255) end
		SetAlpha(PLAYER_PED, dist <= 0.9 and 0 or 255)
		memory.setint32(getCharPointer(PLAYER_PED) + 0x474, dist <= 0.9 and 2 or back, false)
		objVisible(not active)
	end
end

function SetAlpha(handle, alpha) -- by blast.hk/members/374442/
    local ped = getCharPointer(handle)
    if ped ~= 0 then SetRwObjectAlpha(ped, alpha) end
end

function objVisible(bool)
	local tbl = getAllObjects()
	for i = 1, #tbl do
		local tObj, tC = {getObjectCoordinates(tbl[i])}, {getCharCoordinates(PLAYER_PED)}
		if getDistanceBetweenCoords3d(tObj[2], tObj[3], tObj[4], tC[1], tC[2], tC[3]) < 0.9 then
			setObjectVisible(tbl[i], bool)
		end
	end
end

function fixed_camera_to_skin() -- проверка на приклепление камеры к скину
	return (memory.getint8(0xB6F053) >= 1 and true or false)
end

function onScriptTerminate(script, quit)
    if script == thisScript() and not quit then
		objVisible(true)
		if lhook then CPed__Render.stop() end
		SetAlpha(PLAYER_PED, 255)
		memory.setint32(getCharPointer(PLAYER_PED) + 0x474, back, true)
		if lmad then mad.set_char_model_alpha(PLAYER_PED, 255) end
		collectgarbage("collect")
    end
end
