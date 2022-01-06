script_name('crosshair')
require("lib.moonloader")
local lmemory, memory = pcall(require, 'memory')
script_properties('work-in-pause', 'forced-reloading-only')
script_version("1.1")

function main()
	repeat wait(0) until memory.read(0xC8D4C0, 4, false) == 9
	repeat wait(0) until fixed_camera_to_skin()

	memory.write(0x058E280, 0xEB, 1, true) -- белая точка

	local sx, sy = getCrosshairPosition()
	local sw, sh = getScreenResolution()

	while true do wait(0)
		local targetting = memory.getint8(getCharPointer(playerPed) + 0x528, false) == 19
		local target_car = memory.getint8(0xB6FC70) == 1
		if targetting or target_car then
            if sx >= 0 and sy >= 0 and sx < sw and sy < sh then
                local posX, posY, posZ = convertScreenCoordsToWorld3D(sx, sy, 700.0)
                local camX, camY, camZ = getActiveCameraCoordinates()
                local result, colpoint = processLineOfSight(camX, camY, camZ, posX, posY, posZ, true, true, true, true, true, true, true, true)
				if result and (colpoint.entityType == 2 or colpoint.entityType == 3) then
					changeCrosshairColor("0xFF3300FF")
				else
					changeCrosshairColor("0xFFFFFFFF")
				end
            end
		end
	end
end

function fixed_camera_to_skin() -- проверка на приклепление камеры к скину
	return (memory.read(getModuleHandle('gta_sa.exe') + 0x76F053, 1, false) >= 1 and true or false)
end

function getCrosshairPosition()
	local chOff1 = memory.getfloat(0xB6EC10)
	local chOff2 = memory.getfloat(0xB6EC14)
	local szx, szy = getScreenResolution()
	return szx * chOff2, szy * chOff1
end

function changeCrosshairColor(rgba)
    local r = bit.band(bit.rshift(rgba, 24), 0xFF)
    local g = bit.band(bit.rshift(rgba, 16), 0xFF)
    local b = bit.band(bit.rshift(rgba, 8), 0xFF)
    local a = bit.band(rgba, 0xFF)

    memory.setuint8(0x58E301, r, true)
    memory.setuint8(0x58E3DA, r, true)
    memory.setuint8(0x58E433, r, true)
    memory.setuint8(0x58E47C, r, true)

    memory.setuint8(0x58E2F6, g, true)
    memory.setuint8(0x58E3D1, g, true)
    memory.setuint8(0x58E42A, g, true)
    memory.setuint8(0x58E473, g, true)

    memory.setuint8(0x58E2F1, b, true)
    memory.setuint8(0x58E3C8, b, true)
    memory.setuint8(0x58E425, b, true)
    memory.setuint8(0x58E466, b, true)

    memory.setuint8(0x58E2EC, a, true)
    memory.setuint8(0x58E3BF, a, true)
    memory.setuint8(0x58E420, a, true)
    memory.setuint8(0x58E461, a, true)
end
