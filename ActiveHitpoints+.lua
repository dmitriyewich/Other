script_name("ActiveHitpoints+")
script_author("dmitriyewich")
script_url("https://vk.com/dmitriyewichmods")
script_properties('work-in-pause', 'forced-reloading-only')
script_dependencies("memory")
script_version("1.0")

local lmemory, memory = pcall(require, 'memory')

function main()
	repeat wait(0) until memory.read(0xC8D4C0, 4, false) == 9
	repeat wait(0) until fixed_camera_to_skin()
	
	samp_v = samp_ver()
	
	pedpool = memory.getint32(memory.getint32(memory.getint32(samp_handle() + (samp_v == 'R1' and 0x21A0F8 or 0x26E8DC), false) + (samp_v == 'R1' and 0x3CD or 0x3DE), false) + (samp_v == 'R1' and 0x18 or 0x8), false)
	
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

function fixed_camera_to_skin() -- проверка на приклепление камеры к скину
	local res, i = pcall(memory.getint8, getModuleHandle('gta_sa.exe') + 0x76F053)
	return (res and (i >= 1 and true or false) or false)
end

function samp_handle()
	return getModuleHandle('samp.dll')
end

function samp_ver()
	local samp = samp_handle()
	local entry = samp ~= 0 and memory.getuint32((samp + memory.getint32(samp + 0x3C)) + 0x28)
	local samp_ver = (entry == 0x31DF13 and 'R1') or (entry == 0xCC4D0 and 'R3') or 'unknown'
	return samp_ver
end

function GetHealthAndArmour(id)
	local fHP, fARM
	if id ~= memory.getint16(pedpool + (samp_v == 'R1' and 0x4 or 0x2F1C)) then
		local dwRemoteplayer = memory.getint32(pedpool + (samp_v == 'R1' and 0x2E or 0x4) + id * 4)
		local dwRemoteplayerData = memory.getuint32(dwRemoteplayer + 0x0)
		fHP = memory.getfloat(dwRemoteplayerData + (samp_v == 'R1' and 444 or 432))
		fARM = memory.getfloat(dwRemoteplayerData + (samp_v == 'R1' and 440 or 428)) 
	else
		fHP = memory.getfloat(memory.getuint32(0xB6F5F0) + 0x540)
		fARM = memory.getfloat(memory.getuint32(0xB6F5F0) + 0x548)
	end
	return fHP, fARM
end

function getPedID(handle)
	if handle == PLAYER_PED then 
			return memory.getint16(pedpool + (samp_v == 'R1' and 0x4 or 0x2F1C))
	end
	for i = 1, 1004 do
		local dwRemoteplayer = memory.getint32(pedpool + (samp_v == 'R1' and 0x2E or 0x4) + i * 4)
		if dwRemoteplayer <= 1 then goto continue end
			local dw_remoteplayer_data = memory.getuint32(dwRemoteplayer + 0x0 )
			::continue::
		if dw_remoteplayer_data == 0 then goto continue2 end
			local dw_samp_actor = memory.getuint32(dw_remoteplayer_data + 0x0 )
			::continue2::
		if dw_samp_actor == 0 then goto continue3 end
			local dw_ped = memory.getuint32(dw_samp_actor + 0x2A4 )
			if getCharPointerHandle(dw_ped) == handle then
				return true, i
			end
			::continue3::	
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
