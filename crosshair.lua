script_name('crosshair')
local lmemory, memory = pcall(require, 'memory')
script_version("1.14")

function main()
	repeat wait(0) until memory.read(0xC8D4C0, 4, false) == 9
	repeat wait(0) until fixed_camera_to_skin()

	memory.write(0x058E280, 0xEB, 1, true) -- белая точка

	local sw, sh = getScreenResolution()
	local sx, sy = memory.getfloat(0xB6EC14) * sw, memory.getfloat(0xB6EC10) * sh

	while true do wait(0)
		-- local targetting, target_car = (memory.getint8(getCharPointer(playerPed) + 0x528, false) == 19), (memory.getint8(0xB6FC70) == 1)
		local test = memory.getint16((0xB6F19C + memory.getint8(0xB6F028 + 0x59) * 0x238) + 0x0C) ~= 4
		if (--[[targetting or target_car or]] test) and sx >= 0 and sy >= 0 and sx < sw and sy < sh then
			local pos, cam = {convertScreenCoordsToWorld3D(sx, sy, 700.0)}, {getActiveCameraCoordinates()}
			local result, colpoint = processLineOfSight(cam[1], cam[2], cam[3], pos[1], pos[2], pos[3], true, true, true, false, false, false, false, false)
			if result and (colpoint.entityType == 2 or colpoint.entityType == 3) and getCharPointerHandle(colpoint.entity) ~= PLAYER_PED then
				changeCrosshairColor("0xFF3300FF")
			else
				changeCrosshairColor("0xFFFFFFFF")
			end
		end
	end
end

function fixed_camera_to_skin() -- проверка на приклепление камеры к скину, мой аналог sampIsLocalPlayerSpawned
	return (memory.read(getModuleHandle('gta_sa.exe') + 0x76F053, 1, false) >= 1 and true or false)
end

function changeCrosshairColor(rgba)
    local r, g, b, a = bit.band(bit.rshift(rgba, 24), 0xFF), bit.band(bit.rshift(rgba, 16), 0xFF), bit.band(bit.rshift(rgba, 8), 0xFF), bit.band(rgba, 0xFF)

	local tbl, clr, k = {0x58E301, 0x58E3DA, 0x58E433, 0x58E47C, 0x58E2F6, 0x58E3D1, 0x58E42A, 0x58E473, 0x58E2F1, 0x58E3C8, 0x58E425, 0x58E466, 0x58E2EC, 0x58E3BF, 0x58E420, 0x58E461}, {r, g, b, a}, 1

	for i = 1, #tbl do
		memory.setuint8(tbl[i], clr[k], true)
		if i % 4 == 0 then k = k + 1 end
	end
end
