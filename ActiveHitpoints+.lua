script_name("ActiveHitpoints+")
script_author("dmitriyewich")
script_url("https://vk.com/dmitriyewichmods")
script_properties('work-in-pause', 'forced-reloading-only')
script_version("1.5.2")

local memory = require("memory")
local ffi = require("ffi")

local entryPoint = {
    [0x31DF13] = 'R1', [0x3195DD] = 'R2', [0xCC490] = 'R3',
    [0xCC4D0] = 'R3-1', [0xCBCB0] = 'R4', [0xcbcd0] = 'R4-2', [0xFDB60] = 'DL-R1'
}

local main_offsets = {
    ['SAMP_INFO_OFFSET'] = {['R1'] = 0x21A0F8, ['R2'] = 0x21A100, ['R3-1'] = 0x26E8DC, ['R4'] = 0x26EA0C, ['R4-2'] = 0x26EA0C, ['DL-R1'] = 0x2ACA24},
    ['SAMP_INFO_OFFSET_Pools'] = {['R1'] = 0x3CD, ['R2'] = 0x3C5, ['R3-1'] = 0x3DE, ['R4'] = 0x3DE, ['R4-2'] = 0x3DE, ['DL-R1'] = 0x3DE},
    ['SAMP_INFO_OFFSET_Pools_Player'] = {['R1'] = 0x18, ['R2'] = 0x8, ['R3-1'] = 0x8, ['R4'] = 0x8, ['R4-2'] = 0x4, ['DL-R1'] = 0x8},
    ['SAMP_SLOCALPLAYERID_OFFSET'] = {['R1'] = 0x4, ['R2'] = 0x0, ['R3-1'] = 0x2F1C, ['R4'] = 0xC, ['R4-2'] = 0x4, ['DL-R1'] = 0x0},
    ['SAMP_PREMOTEPLAYER_OFFSET'] = {['R1'] = 0x2E, ['R2'] = 0x26, ['R3-1'] = 0x4, ['R4'] = 0x2E, ['R4-2'] = 0x1F8A, ['DL-R1'] = 0x26},
    ['SAMP_REMOTEPLAYERDATA_OFFSET'] = {['R1'] = 0x0, ['R2'] = 0xC, ['R3-1'] = 0x0, ['R4'] = 0x10, ['R4-2'] = 0x10, ['DL-R1'] = 0x8},
    ['SAMP_REMOTEPLAYERDATA_HEALTH_OFFSET'] = {['R1'] = 0x1BC, ['R2'] = 0x1BC, ['R3-1'] = 0x1B0, ['R4'] = 0x1B0, ['R4-2'] = 0x1B0, ['DL-R1'] = 0x1B0},
    ['ID_Find'] = {['R1'] = 0x10420, ['R2'] = 0x104C0, ['R3-1'] = 0x13570, ['R4'] = 0x13890, ['R4-2'] = 0x138C0, ['DL-R1'] = 0x137C0},
}

local ID_Find, sampModule, currentVersion

function main()
    repeat wait(100) until memory.read(0xC8D4C0, 4, false) == 9
    sampModule = getModuleHandle("samp.dll")

    repeat wait(100) until isSampLoadedLua()
    if currentVersion == 'UNKNOWN' or currentVersion == 'R3' then
        return thisScript():unload()
    end

    repeat wait(100) until isSAMPInitialized()
    ID_Find = ffi.cast("int (__thiscall *)(intptr_t, intptr_t)", sampModule + main_offsets.ID_Find[currentVersion])

    while true do
        wait(0)
        local result, ped = getCharPlayerIsTargeting(PLAYER_HANDLE)
        if result then
            local ok, id = getPedID(ped)
            if ok then
                local hp = getHealth(id)
                local r, g, b = getColorByHP(hp)
                set_triangle_color(math.floor(r + 0.5), math.floor(g + 0.5), math.floor(b + 0.5))
            end
        else
            set_triangle_color(25, 255, 25) -- стандартный зелёный
        end
    end
end

function isSampLoadedLua()
    if sampModule <= 0 then return false end
    if not currentVersion then
        local ep = memory.getuint32(sampModule + memory.getint32(sampModule + 0x3C) + 0x28)
        currentVersion = entryPoint[ep] or 'UNKNOWN'
    end
    return true
end

function isSAMPInitialized()
    local ptr = memory.getint32(sampModule + main_offsets.SAMP_INFO_OFFSET[currentVersion])
    return ptr ~= 0
end

function getPedPool()
    local base = memory.getint32(sampModule + main_offsets.SAMP_INFO_OFFSET[currentVersion])
    local pools = memory.getint32(base + main_offsets.SAMP_INFO_OFFSET_Pools[currentVersion])
    return memory.getint32(pools + main_offsets.SAMP_INFO_OFFSET_Pools_Player[currentVersion])
end

function getLocalID()
    return memory.getint16(getPedPool() + main_offsets.SAMP_SLOCALPLAYERID_OFFSET[currentVersion])
end

function getHealth(id)
    if id ~= getLocalID() then
        local pool = getPedPool()
        local remotePtr = memory.getint32(pool + main_offsets.SAMP_PREMOTEPLAYER_OFFSET[currentVersion] + id * 4)
        if remotePtr == 0 then return 0 end
        local data = memory.getuint32(remotePtr + main_offsets.SAMP_REMOTEPLAYERDATA_OFFSET[currentVersion])
        if data == 0 then return 0 end
        return memory.getfloat(data + main_offsets.SAMP_REMOTEPLAYERDATA_HEALTH_OFFSET[currentVersion])
    else
        local base = memory.getuint32(0xB6F5F0)
        if base == 0 then return 0 end
        return memory.getfloat(base + 0x540)
    end
end

function getPedID(handle)
    if handle == PLAYER_PED then return true, getLocalID() end
    local id = ID_Find(getPedPool(), getCharPointer(handle))
    return id ~= 65535, id
end

function getColorByHP(hp)
    if hp <= 1 then
        return 0, 0, 0 -- мёртв
    elseif hp <= 10 then
        return unpack(test(10, hp, 0, 0, 0, 255, 0, 0))
    elseif hp <= 50 then
        return unpack(test(50, hp, 255, 0, 0, 255, 255, 0))
    elseif hp <= 100 then
        return unpack(test(100, hp, 255, 255, 0, 25, 255, 25))
    else
        return 25, 255, 25 -- > 100
    end
end

function test(maxhp, curhp, fromR, fromG, fromB, toR, toG, toB)
    local deltaR = math.round((toR - fromR) / maxhp, 2)
    local deltaG = math.round((toG - fromG) / maxhp, 2)
    local deltaB = math.round((toB - fromB) / maxhp, 2)
    return {
        fromR + curhp * deltaR,
        fromG + curhp * deltaG,
        fromB + curhp * deltaB
    }
end

function math.round(num, idp)
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

function set_triangle_color(r, g, b)
    local bytes = "90909090909090909090909090C744240E00000000909090909090909090909090909090C744240F0000000090B300"
    memory.hex2bin(bytes, 0x60BB41, #bytes / 2)
    memory.setint8(0x60BB52, r)
    memory.setint8(0x60BB69, g)
    memory.setint8(0x60BB6F, b)
end
