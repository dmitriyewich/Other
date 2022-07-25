script_name("ActiveHitpoints+")
script_author("dmitriyewich")
script_url("https://vk.com/dmitriyewichmods")
script_properties('work-in-pause', 'forced-reloading-only')
script_version("1.5")

local lmemory, memory = pcall(require, 'memory')

local entryPoint = {[0x31DF13] = 'R1', [0x3195DD] = 'R2', [0xCC490] = 'R3', [0xCC4D0] = 'R3-1', [0xCBCB0] = 'R4', [0xcbcd0] = 'R4-2', [0xFDB60] = 'DL-R1'}
local main_offsets = {
	['SAMP_INFO_OFFSET'] = {['R1'] = 0x21A0F8, ['R2'] = 0x21A100, ['R3-1'] = 0x26E8DC, ['R4'] = 0x26EA0C, ['R4-2'] = 0x26EA0C, ['DL-R1'] = 0x2ACA24},
	['SAMP_INFO_OFFSET_Pools'] = {['R1'] = 0x3CD, ['R2'] = 0x3C5, ['R3-1'] = 0x3DE, ['R4'] = 0x3DE, ['R4-2'] = 0x3DE, ['DL-R1'] = 0x3DE},
	['SAMP_INFO_OFFSET_Pools_Player'] = {['R1'] = 0x18, ['R2'] = 0x8, ['R3-1'] = 0x8, ['R4'] = 0x8, ['R4-2'] = 0x4, ['DL-R1'] = 0x8},
	['SAMP_SLOCALPLAYERID_OFFSET'] = {['R1'] = 0x4, ['R2'] = 0x0, ['R3-1'] = 0x2F1C, ['R4'] = 0xC, ['R4-2'] = 0x4, ['DL-R1'] = 0x0},
	['MAX_PLAYER_ID_STREAMED_ONLY_OFFSET'] = {['R1'] = 0xFB0, ['R2'] = 0x22, ['R3-1'] = 0x0, ['R4'] = 0x0, ['R4-2'] = 0x2F3A, ['DL-R1'] = 0x22},
	['SAMP_PREMOTEPLAYER_OFFSET'] = {['R1'] = 0x2E, ['R2'] = 0x26, ['R3-1'] = 0x4, ['R4'] = 0x2E, ['R4-2'] = 0x1F8A, ['DL-R1'] = 0x26},
	['SAMP_REMOTEPLAYERDATA_OFFSET'] = {['R1'] = 0x0, ['R2'] = 0xC, ['R3-1'] = 0x0, ['R4'] = 0x10, ['R4-2'] = 0x10, ['DL-R1'] = 0x8},
	['SAMP_REMOTEPLAYERDATA_ACTOR'] = {['R1'] = 0x0, ['R2'] = 0x1C, ['R3-1'] = 0x0, ['R4'] = 0x1DD, ['R4-2'] = 0x1DD, ['DL-R1'] = 0x4},
	['GTA_PED_HANDLE'] = {['R1'] = 0x44, ['R2'] = 0x44, ['R3-1'] = 0x44, ['R4'] = 0x44, ['R4-2'] = 0x44, ['DL-R1'] = 0x44},
	['SAMP_REMOTEPLAYERDATA_HEALTH_OFFSET'] = {['R1'] = 0x1BC, ['R2'] = 0x1BC, ['R3-1'] = 0x1B0, ['R4'] = 0x1B0, ['R4-2'] = 0x1B0, ['DL-R1'] = 0x1B0},
	['SAMP_REMOTEPLAYERDATA_ARMOR_OFFSET'] = {['R1'] = 0x1B8, ['R2'] = 0x1AC, ['R3-1'] = 0x1AC, ['R4'] = 0x1AC, ['R4-2'] = 0x1AC, ['DL-R1'] = 0x1AC},
}

function main()
	repeat wait(100) until memory.read(0xC8D4C0, 4, false) == 9
	currentVersion, sampModule = nil, getModuleHandle("samp.dll")
	repeat wait(100) until isSampLoadedLua()
	if currentVersion == 'UNKNOWN' or currentVersion == 'R3' then print('Samp version '.. currentVersion .. ' is not supported'); thisScript():unload() end
	repeat wait(100) until isSAMPInitilizeLua()
	repeat wait(100) until fixed_camera_to_skin()
    while true do wait(0)
		local result, ped = getCharPlayerIsTargeting(PLAYER_HANDLE)
		if result then
			local res, id = getPedID(ped)
			if res then
				local hp, arm = GetHealthAndArmour(id)
				local tbl = hp >= 50 and test((hp >= 101 and hp or 50), hp, 255, 255, 0, 25, 255, 25) or (hp <= 10 and test(10, hp, 0, 0, 0, 255, 0, 0) or test(50, hp, 255, 0, 0, 255, 255, 0))
				set_triangle_color(tbl[1], tbl[2], tbl[3])
			end
		else
			set_triangle_color(25, 255, 25)
		end
    end
end

function isSampLoadedLua()
    if sampModule <= 0 then return false end
    if not currentVersion then
        -- Getting version taken from SAMP-API (thx fyp)
        local ntheader = sampModule + memory.getint32(sampModule + 0x3C)
        local ep = memory.getuint32(ntheader + 0x28)
        currentVersion = entryPoint[ep]
        if not currentVersion then
            print(('WARNING: Unknown version of SA-MP (Entry point: 0x%08x)'):format(ep))
            currentVersion = 'UNKNOWN'
        end
    end
    return true
end

function isSAMPInitilizeLua()
	if sampModule <= 0 then return false end
	if memory.getint32(sampModule + main_offsets.SAMP_INFO_OFFSET[currentVersion]) ~= 0 and currentVersion ~= 'UNKNOWN' then return true end
    return false
end

function PedPool()
	local OFFSET_SampInfo = memory.getint32(sampModule + main_offsets.SAMP_INFO_OFFSET[currentVersion], true)
	local OFFSET_SampInfo_pPools = memory.getint32(OFFSET_SampInfo + main_offsets.SAMP_INFO_OFFSET_Pools[currentVersion], true)
	local OFFSET_SampInfo_pPools_Player = memory.getint32(OFFSET_SampInfo_pPools + main_offsets.SAMP_INFO_OFFSET_Pools_Player[currentVersion], true)
	return OFFSET_SampInfo_pPools_Player
end

function Local_ID()
	return memory.getint16(PedPool() + main_offsets.SAMP_SLOCALPLAYERID_OFFSET[currentVersion])
end

function fixed_camera_to_skin() -- проверка на приклепление камеры к скину
	local res, i = pcall(memory.getint8, getModuleHandle('gta_sa.exe') + 0x76F053)
	return (res and (i >= 1 and true or false) or false)
end

function GetHealthAndArmour(id)
	local fHP, fARM
	if id ~= Local_ID() then
		local dwRemoteplayer = memory.getint32(PedPool() + main_offsets.SAMP_PREMOTEPLAYER_OFFSET[currentVersion] + id * 4, true)
		local dw_remoteplayer_data = memory.getuint32(dwRemoteplayer + main_offsets.SAMP_REMOTEPLAYERDATA_OFFSET[currentVersion], true)
		fHP = memory.getfloat(dw_remoteplayer_data + main_offsets.SAMP_REMOTEPLAYERDATA_HEALTH_OFFSET[currentVersion], true)
		fARM = memory.getfloat(dw_remoteplayer_data + main_offsets.SAMP_REMOTEPLAYERDATA_ARMOR_OFFSET[currentVersion], true)
	else
		fHP = memory.getfloat(memory.getuint32(0xB6F5F0) + 0x540, true)
		fARM = memory.getfloat(memory.getuint32(0xB6F5F0) + 0x548, true)
	end
	return fHP, fARM
end

function getPedID(handle)
	local REMOTE_PLAYER, PLAYER_DATA, SAMP_ACTOR, GTA_PED_HANDLE
	if handle == PLAYER_PED then return true, Local_ID() end
	local MAX_PLAYER_ID = memory.getint32(PedPool() + main_offsets.MAX_PLAYER_ID_STREAMED_ONLY_OFFSET[currentVersion], true)
	for i = 1, MAX_PLAYER_ID do
		REMOTE_PLAYER = memory.getint32(PedPool() + main_offsets.SAMP_PREMOTEPLAYER_OFFSET[currentVersion] + i * 4, true)
		if REMOTE_PLAYER > 0 then
			PLAYER_DATA = memory.getuint32(REMOTE_PLAYER + main_offsets.SAMP_REMOTEPLAYERDATA_OFFSET[currentVersion], true)
			if PLAYER_DATA > 0 then
				SAMP_ACTOR = memory.getuint32(PLAYER_DATA + main_offsets.SAMP_REMOTEPLAYERDATA_ACTOR[currentVersion], true)
				if SAMP_ACTOR > 0 then
					GTA_PED_HANDLE = memory.getuint32(SAMP_ACTOR + main_offsets.GTA_PED_HANDLE[currentVersion], true)
					if GTA_PED_HANDLE == handle then
						return true, i
					end
				end
			end
		end
	end
	return false, -1
end

function set_triangle_color(r, g, b) -- by etereon
    local bytes= "90909090909090909090909090C744240E00000000909090909090909090909090909090C744240F0000000090B300"
    memory.hex2bin(bytes, 0x60BB41, bytes:len()/2)
    memory.setint8(0x60BB52, r, false)
    memory.setint8(0x60BB69, g, false)
    memory.setint8(0x60BB6F, b, false)
end

function math.round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function test(maxhp, curhp, fromR, fromG, fromB, toR, toG, toB)
	deltaR = math.round(((toR - fromR) / maxhp), 2);
	deltaG = math.round(((toG - fromG) / maxhp), 2);
	deltaB = math.round(((toB - fromB) / maxhp), 2);
	t = {(fromR + curhp * deltaR),	(fromG + curhp * deltaG), (fromB + curhp * deltaB)}
	return t
end
