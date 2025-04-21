script_name('crosshair')
script_version("1.22")

local lmad, mad = pcall(require, 'MoonAdditions')
local lmemory, memory = pcall(require, 'memory')
local ffi = require("ffi")
local bit = require("bit")

if not lmemory or not ffi then
    print('Ошибка: необходимая библиотека не найдена.')
    return
end

local CROSSHAIR_COLOR_HIT = 0xFF3300FF
local CROSSHAIR_COLOR_DEFAULT = 0xFFFFFFFF

function main()
    repeat wait(0) until isSampAvailable() and isPlayerPlaying(playerHandle)

    memory.write(0x058E280, 0xEB, 1, true) -- отключаем дефолтную точку

    local sw, sh = getScreenResolution()
    local flags = {
        buildings = true, vehicles = true, peds = true,
        objects = true, dummies = true,
        seeThroughCheck = true, ignoreSomeObjectsCheck = true, shootThroughCheck = true
    }

    while true do
        wait(0)

        if not isPlayerPlaying(playerHandle) or not isCharOnFoot(playerPed) then
            goto continue
        end

        local camMode = memory.getint16(0xB6F1A8)
        if camMode == 4 or camMode == 18 then goto continue end -- исключаем вид от 1-го лица

        local sx = memory.getfloat(0xB6EC14, true) * sw
        local sy = memory.getfloat(0xB6EC10, true) * sh
        if sx < 0 or sy < 0 or sx >= sw or sy >= sh then goto continue end

        local pos = {convertScreenCoordsToWorld3D(sx, sy, 700.0)}
        local cam = {getRealCameraCoordinates()}

        if lmad then
            handleMoonAdditions(pos, cam, flags)
        else
            handleLegacy(pos, cam)
        end

        ::continue::
    end
end

function handleMoonAdditions(pos, cam, flags)
    local ent = isCharInAnyCar(playerPed) and getCarPointer(storeCarCharIsInNoSave(playerPed)) or getCharPointer(playerPed)
    local collision = mad.get_collision_between_points(cam[1], cam[2], cam[3], pos[1], pos[2], pos[3], flags, ent)

    local entityType
    if collision then
        entityType = mad.get_entity_type_and_class(collision.entity)
    end

    changeCrosshairColor(collision and entityType == 3 and CROSSHAIR_COLOR_HIT or CROSSHAIR_COLOR_DEFAULT)
end

function handleLegacy(pos, cam)
    local hit, col = processLineOfSight(cam[1], cam[2], cam[3], pos[1], pos[2], pos[3], true, true, true, true, false, false, false, false)
    local isEnemy = hit and col.entityType == 3 and getCharPointerHandle(col.entity) ~= playerPed
    changeCrosshairColor(isEnemy and CROSSHAIR_COLOR_HIT or CROSSHAIR_COLOR_DEFAULT)
end

function getRealCameraCoordinates()
    local cam = ffi.cast("float*", 0xB6F028)
    return cam[0xC7], cam[0xC8], cam[0xC9]
end

function changeCrosshairColor(rgba)
    local r = bit.band(bit.rshift(rgba, 24), 0xFF)
    local g = bit.band(bit.rshift(rgba, 16), 0xFF)
    local b = bit.band(bit.rshift(rgba, 8), 0xFF)
    local a = bit.band(rgba, 0xFF)

    local tbl = {
        0x58E301, 0x58E3DA, 0x58E433, 0x58E47C,
        0x58E2F6, 0x58E3D1, 0x58E42A, 0x58E473,
        0x58E2F1, 0x58E3C8, 0x58E425, 0x58E466,
        0x58E2EC, 0x58E3BF, 0x58E420, 0x58E461
    }

    local clr = {r, g, b, a}
    local k = 1
    for i = 1, #tbl do
        memory.setuint8(tbl[i], clr[k], true)
        if i % 4 == 0 then k = k + 1 end
    end
end
