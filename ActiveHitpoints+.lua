script_name("ActiveHitpoints+")
script_author("dmitriyewich")
script_url("https://vk.com/dmitriyewichmods")
script_properties('work-in-pause', 'forced-reloading-only')
script_dependencies("ffi", "memory", "SAMPFUNCS")
script_version("0.11")

local lffi, ffi = pcall(require, 'ffi')
local lmemory, memory = pcall(require, 'memory')

function main()
	if not isSampfuncsLoaded() or not isSampLoaded() then return end
	while not isSampAvailable() do wait(100) end
    while true do wait(0)
		local result, ped = getCharPlayerIsTargeting(PLAYER_HANDLE)
		if result then
			local res, id = sampGetPlayerIdByCharHandle(ped)
			if res then
				local hp = sampGetPlayerHealth(id)
				local tbl = hp >= 50 and test((hp >= 101 and hp or 50), hp, 255, 255, 0, 25, 255, 25) or (hp <= 10 and test(10, hp, 0, 0, 0, 255, 0, 0) or test(50, hp, 255, 0, 0, 255, 255, 0))
				set_triangle_color(tbl[1], tbl[2], tbl[3])
			end
		else
			set_triangle_color(25, 255, 25)
		end
    end
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
