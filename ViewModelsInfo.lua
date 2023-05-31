script_name("{4baf4f}ViewModelsInfo")
script_author("dmitriyewich")
script_description("Displaying information about visible models.")
script_url("https://vk.com/dmitriyewichmods")
script_dependencies("ffi", "memory", "hooks", "vkeys")
script_properties('work-in-pause', 'forced-reloading-only')
script_version("1.0.1")

local memory = require("memory")
local ffi = require("ffi")
local vkeys = require 'vkeys'
local wm = require 'windows.message'

local lhook, hook = pcall(require, 'hooks') -- https://www.blast.hk/threads/55743/post-838589

if not lhook then
	hookslib = [[--[\[
    AUTHOR: RTD/RutreD(https://www.blast.hk/members/126461/)
]\]
local ffi = require 'ffi'
ffi.cdef[\[
    int VirtualProtect(void* lpAddress, unsigned long dwSize, unsigned long flNewProtect, unsigned long* lpflOldProtect);
    void* VirtualAlloc(void* lpAddress, unsigned long dwSize, unsigned long  flAllocationType, unsigned long flProtect);
    int VirtualFree(void* lpAddress, unsigned long dwSize, unsigned long dwFreeType);
]\]
local function copy(dst, src, len)
    return ffi.copy(ffi.cast('void*', dst), ffi.cast('const void*', src), len)
end
local buff = {free = {}}
local function VirtualProtect(lpAddress, dwSize, flNewProtect, lpflOldProtect)
    return ffi.C.VirtualProtect(ffi.cast('void*', lpAddress), dwSize, flNewProtect, lpflOldProtect)
end
local function VirtualAlloc(lpAddress, dwSize, flAllocationType, flProtect, blFree)
    local alloc = ffi.C.VirtualAlloc(lpAddress, dwSize, flAllocationType, flProtect)
    if blFree then
        table.insert(buff.free, alloc)
    end
    return ffi.cast('intptr_t', alloc)
end
--VMT HOOKS
local vmt_hook = {hooks = {}}
function vmt_hook.new(vt)
    local new_hook = {}
    local org_func = {}
    local old_prot = ffi.new('unsigned long[1]')
    local virtual_table = ffi.cast('intptr_t**', vt)[0]
    new_hook.this = virtual_table
    new_hook.hookMethod = function(cast, func, method)
        jit.off(func, true) --off jit compilation | thx FYP
        org_func[method] = virtual_table[method]
        VirtualProtect(virtual_table + method, 4, 0x4, old_prot)
        virtual_table[method] = ffi.cast('intptr_t', ffi.cast(cast, func))
        VirtualProtect(virtual_table + method, 4, old_prot[0], old_prot)
        return ffi.cast(cast, org_func[method])
    end
    new_hook.unHookMethod = function(method)
        VirtualProtect(virtual_table + method, 4, 0x4, old_prot)
        -- virtual_table[method] = org_func[method]
        local alloc_addr = VirtualAlloc(nil, 5, 0x1000, 0x40, false)
        local trampoline_bytes = ffi.new('uint8_t[?]', 5, 0x90)
        trampoline_bytes[0] = 0xE9
        ffi.cast('int32_t*', trampoline_bytes + 1)[0] = org_func[method] - tonumber(alloc_addr) - 5
        copy(alloc_addr, trampoline_bytes, 5)
        virtual_table[method] = ffi.cast('intptr_t', alloc_addr)
        VirtualProtect(virtual_table + method, 4, old_prot[0], old_prot)
        org_func[method] = nil
    end
    new_hook.unHookAll = function()
        for method, func in pairs(org_func) do
            new_hook.unHookMethod(method)
        end
    end
    table.insert(vmt_hook.hooks, new_hook.unHookAll)
    return new_hook
end
--VMT HOOKS
--JMP HOOKS
local jmp_hook = {hooks = {}}
function jmp_hook.new(cast, callback, hook_addr, size, trampoline, org_bytes_tramp)
    jit.off(callback, true) --off jit compilation | thx FYP
    local size = size or 5
    local trampoline = trampoline or false
    local new_hook, mt = {}, {}
    local detour_addr = tonumber(ffi.cast('intptr_t', ffi.cast(cast, callback)))
    local old_prot = ffi.new('unsigned long[1]')
    local org_bytes = ffi.new('uint8_t[?]', size)
    copy(org_bytes, hook_addr, size)
    if trampoline then
        local alloc_addr = VirtualAlloc(nil, size + 5, 0x1000, 0x40, true)
        local trampoline_bytes = ffi.new('uint8_t[?]', size + 5, 0x90)
        if org_bytes_tramp then
            local i = 0
            for byte in org_bytes_tramp:gmatch('(%x%x)') do
                trampoline_bytes[i] = tonumber(byte, 16)
                i = i + 1
            end
        else
            copy(trampoline_bytes, org_bytes, size)
        end
        trampoline_bytes[size] = 0xE9
        ffi.cast('int32_t*', trampoline_bytes + size + 1)[0] = hook_addr - tonumber(alloc_addr) - size + (size - 5)
        copy(alloc_addr, trampoline_bytes, size + 5)
        new_hook.call = ffi.cast(cast, alloc_addr)
        mt = {__call = function(self, ...)
            return self.call(...)
        end}
    else
        new_hook.call = ffi.cast(cast, hook_addr)
        mt = {__call = function(self, ...)
            self.stop()
            local res = self.call(...)
            self.start()
            return res
        end}
    end
    local hook_bytes = ffi.new('uint8_t[?]', size, 0x90)
    hook_bytes[0] = 0xE9
    ffi.cast('int32_t*', hook_bytes + 1)[0] = detour_addr - hook_addr - 5
    new_hook.status = false
    local function set_status(bool)
        new_hook.status = bool
        VirtualProtect(hook_addr, size, 0x40, old_prot)
        copy(hook_addr, bool and hook_bytes or org_bytes, size)
        VirtualProtect(hook_addr, size, old_prot[0], old_prot)
    end
    new_hook.stop = function() set_status(false) end
    new_hook.start = function() set_status(true) end
    new_hook.start()
    if org_bytes[0] == 0xE9 or org_bytes[0] == 0xE8 then
        print('[WARNING] rewrote another hook'.. (trampoline and ' (old hook was disabled, through trampoline)' or ''))
    end
    table.insert(jmp_hook.hooks, new_hook)
    return setmetatable(new_hook, mt)
end
--JMP HOOKS
--CALL HOOKS
local call_hook = {hooks = {}}
function call_hook.new(cast, callback, hook_addr)
	if ffi.cast('uint8_t*', hook_addr)[0] ~= 0xE8 then return end
    jit.off(callback, true) --off jit compilation | thx FYP
    local new_hook = {}
    local detour_addr = tonumber(ffi.cast('intptr_t', ffi.cast(cast, callback)))
    local void_addr = ffi.cast('void*', hook_addr)
    local old_prot = ffi.new('unsigned long[1]')
    local org_bytes = ffi.new('uint8_t[?]', 5)
    ffi.copy(org_bytes, void_addr, 5)
    local hook_bytes = ffi.new('uint8_t[?]', 5, 0xE8)
    ffi.cast('uint32_t*', hook_bytes + 1)[0] = detour_addr - hook_addr - 5
	new_hook.call = ffi.cast(cast, ffi.cast('intptr_t*', hook_addr + 1)[0] + hook_addr + 5)
    new_hook.status = false
    local function set_status(bool)
        new_hook.status = bool
        ffi.C.VirtualProtect(void_addr, 5, 0x40, old_prot)
        ffi.copy(void_addr, bool and hook_bytes or org_bytes, 5)
        ffi.C.VirtualProtect(void_addr, 5, old_prot[0], old_prot)
    end
    new_hook.stop = function() set_status(false) end
    new_hook.start = function() set_status(true) end
    new_hook.start()
    table.insert(call_hook.hooks, new_hook)
    return setmetatable(new_hook, {
        __call = function(self, ...)
            local res = self.call(...)
            return res
        end
    })
end
--CALL HOOKS
--DELETE HOOKS
addEventHandler('onScriptTerminate', function(scr)
    if scr == script.this then
        for i, hook in ipairs(jmp_hook.hooks) do
            if hook.status then
                hook.stop()
            end
        end
		for i, hook in ipairs(call_hook.hooks) do
			if hook.status then
				hook.stop()
			end
		end
        for i, addr in ipairs(buff.free) do
			ffi.C.VirtualFree(addr, 0, 0x8000)
        end
        for i, unHookFunc in ipairs(vmt_hook.hooks) do
            unHookFunc()
        end
    end
end)
--DELETE HOOKS

return {vmt = vmt_hook, jmp = jmp_hook, call = call_hook}]]
	local file_lib = getWorkingDirectory() .."\\lib\\hooks.lua"
	local file = io.open(file_lib, 'w+')
	local text = hookslib:gsub("%[\\%[", "%[%["):gsub("%]\\%]", "%]%]")
	file:write(text)
	file:close()
	script.load(getWorkingDirectory()..'\\'..file_lib)
	lhook, hook = pcall(require, 'hooks')
end

function json(filePath) -- by chapo
    local filePath = getWorkingDirectory()..'\\'..(filePath:find('(.+).json') and filePath or filePath..'.json')
    local class = {}
    if not doesDirectoryExist(getWorkingDirectory()..'\\') then
        createDirectory(getWorkingDirectory()..'\\')
    end

    function class:Save(tbl)
        if tbl then
            local F = io.open(filePath, 'w')
            F:write(encodeJson(tbl) or {})
            F:close()
            return true, 'ok'
        end
        return false, 'table = nil'
    end

    function class:Load(defaultTable)
        if not doesFileExist(filePath) then class:Save(defaultTable or {}) end
        local F = io.open(filePath, 'r+')
        local TABLE = decodeJson(F:read() or {})
        F:close()
        for def_k, def_v in next, defaultTable do
            if TABLE[def_k] == nil then  TABLE[def_k] = def_v end
        end
        return TABLE
    end

    return class
end

function onWindowMessage(msg, wparam, lparam)
	if bit.band(lparam, 0x40000000) == 0 then
		if msg == wm.WM_KEYDOWN or msg == wm.WM_SYSKEYDOWN then
			if wparam == vkeys.VK_F3 then
				local active1, active2, active3 = thread_chars:status(), thread_obj:status(), thread_veh:status()
				if active1 ~= 'yielded' or active2 ~= 'yielded' or active3 ~= 'yielded' then
					thread_chars:run(); thread_obj:run(); thread_veh:run()
				else
					thread_chars:terminate(); thread_obj:terminate(); thread_veh:terminate()
				end
			end
		end
	end
end

local models_table = {}

function loadPedObject_hook(loadstr)
	local id, name, txd = ffi.string(loadstr):match("^(%d+)%s+([%w%d]+)%s+([%w%d]+).*$")
	if tonumber(id) and name and txd then
		models_table[tonumber(id)] = {name = name, txd = txd}
	end
	return loadPedObject_hook(loadstr)
end
function LoadVehicleObject_hook(loadstr)
	local id, name, txd, type_model, name_car = ffi.string(loadstr):match("^(%d+)%s+([%w%d]+)%s+([%w%d]+)%s+([%w%d]+)%s+([%w%d]+).*$")
	if tonumber(id) and name and txd and type_model and name_car then
		models_table[tonumber(id)] = {name = name, txd = txd, type_model = type_model, name_car = name_car}
	end
	return LoadVehicleObject_hook(loadstr)
end
function LoadObject_hook(loadstr)
	local id, name, txd = ffi.string(loadstr):match("^(%d+)%s+([%w%d]+)%s+([%w%d]+).*$")
	if tonumber(id) and name and txd then
		models_table[tonumber(id)] = {name = name, txd = txd}
	end
	return LoadObject_hook(loadstr)
end
function LoadWeaponObject_hook(loadstr)
	local id, name, txd = ffi.string(loadstr):match("^(%d+)%s+([%w%d]+)%s+([%w%d]+).*$")
	if tonumber(id) and name and txd then
		models_table[tonumber(id)] = {name = name, txd = txd}
	end
	return LoadWeaponObject_hook(loadstr)
end
function LoadAnimatedClumpObject_hook(loadstr)
	local id, name, txd = ffi.string(loadstr):match("^(%d+)%s+([%w%d]+)%s+([%w%d]+).*$")
	if tonumber(id) and name and txd then
		models_table[tonumber(id)] = {name = name, txd = txd}
	end
	return LoadAnimatedClumpObject_hook(loadstr)
end
function LoadTimeObject_hook(loadstr)
	local id, name, txd = ffi.string(loadstr):match("^(%d+)%s+([%w%d]+)%s+([%w%d]+).*$")
	if tonumber(id) and name and txd then
		models_table[tonumber(id)] = {name = name, txd = txd}
	end
	return LoadTimeObject_hook(loadstr)
end

loadPedObject_hook = hook.jmp.new("int(__cdecl*)(const char*)", loadPedObject_hook, 0x5B7420)
LoadVehicleObject_hook = hook.jmp.new("int(__cdecl*)(const char*)", LoadVehicleObject_hook, 0x5B6F30)

LoadObject_hook = hook.jmp.new("int(__cdecl*)(const char*)", LoadObject_hook, 0x5B3C60)
LoadAnimatedClumpObject_hook = hook.jmp.new("int(__cdecl*)(const char*)", LoadAnimatedClumpObject_hook, 0x5B40C0)
LoadTimeObject_hook = hook.jmp.new("int(__cdecl*)(const char*)", LoadTimeObject_hook, 0x5B3DE0)

LoadWeaponObject_hook = hook.jmp.new("int(__cdecl*)(const char*)", LoadWeaponObject_hook, 0x5B3FB0)

local font = renderCreateFont("Arial", 8, 0x5)

local getBonePosition = ffi.cast("int(__thiscall*)(void*, float*, int, bool)", 0x5E4280)
function GetBodyPartCoordinates(id, handle)
	local pedptr, vec = getCharPointer(handle), ffi.new("float[3]")
	getBonePosition(ffi.cast("void*", pedptr), vec, id, true)
	return vec[0], vec[1], vec[2]
end

function main()
	repeat wait(100) until memory.getuint32(0xC8D4C0, true) == 9
	repeat wait(100) until fixed_camera_to_skin()
	if models_table[1] ~= nil then
		local status, code = json('ViewModelsInfo.json'):Save(models_table)
		wait(1000)
		models_table = json('ViewModelsInfo.json'):Load(models_table)
	else
		wait(1000)
		models_table = json('ViewModelsInfo.json'):Load(models_table)
	end

	thread_obj = lua_thread.create_suspended(function()
		while true do wait(0)
			local tbl_Obj = getAllObjects()
			for i = 1, #tbl_Obj do
				if doesObjectExist(tbl_Obj[i]) and isObjectOnScreen(tbl_Obj[i]) then
					local model = getObjectModel(tbl_Obj[i])
					local res, positionX, positionY, positionZ = getObjectCoordinates(tbl_Obj[i])
					if res and models_table[tostring(model)] ~= nil then
						local cx, cy = convert3DCoordsToScreen(positionX, positionY, positionZ)
						if drawClickableText(font,
							("Model ID: %d\nModel name: %s\nTxd name: %s"):format(model, models_table[tostring(model)].name, models_table[tostring(model)].txd),
							cx, cy,0xFFFFFFFF, 0xAAAAAAAA)
						then
							setClipboardText(("Model ID: %d\nModel name: %s\nTxd name: %s"):format(model, models_table[tostring(model)].name, models_table[tostring(model)].txd))
						end
					end
				end
			end
		end
	end)

	thread_veh = lua_thread.create_suspended(function()
		while true do wait(0)
			local tbl_Veh = getAllVehicles()
			for i = 1, #tbl_Veh do
				if doesVehicleExist(tbl_Veh[i]) and isCarOnScreen(tbl_Veh[i]) then
					local model = getCarModel(tbl_Veh[i])
					local cx, cy = convert3DCoordsToScreen(getCarCoordinates(tbl_Veh[i]))
					if models_table[tostring(model)] ~= nil then
						if drawClickableText(font,
							("Model ID: %d\nModel name: %s\nTxd name: %s\nType: %s\nName: %s"):format(model, models_table[tostring(model)].name, models_table[tostring(model)].txd, models_table[tostring(model)].type_model, models_table[tostring(model)].name_car),
							cx, cy,0xFFFFFFFF, 0xAAAAAAAA)
						then
							setClipboardText(("Model ID: %d\nModel name: %s\nTxd name: %s\nType: %s\nName: %s"):format(model, models_table[tostring(model)].name, models_table[tostring(model)].txd, models_table[tostring(model)].type_model, models_table[tostring(model)].name_car))
						end
					end
				end
			end
		end
	end)

	thread_chars = lua_thread.create_suspended(function()
		while true do wait(0)
			local tbl_Cha = getAllChars()
			for i = 1, #tbl_Cha do
				if doesCharExist(tbl_Cha[i]) and isCharOnScreen(tbl_Cha[i]) then
					local model = getCharModel(tbl_Cha[i])
					local cx, cy = convert3DCoordsToScreen(GetBodyPartCoordinates(4, tbl_Cha[i]))
					if models_table[tostring(model)] ~= nil then
						if drawClickableText(font,
							("Model ID: %d\nModel name: %s\nTxd name: %s"):format(model, models_table[tostring(model)].name, models_table[tostring(model)].txd),
							cx, cy,0xFFFFFFFF, 0xAAAAAAAA)
						then
							setClipboardText(("Model ID: %d\nModel name: %s\nTxd name: %s"):format(model, models_table[tostring(model)].name, models_table[tostring(model)].txd))
						end
					end
				end
			end
		end
	end)
	wait(-1)
end

function drawClickableText(font, text, posX, posY, color, colorA) -- by hnnssy
   renderFontDrawText(font, text, posX, posY, color)
   local textLenght = renderGetFontDrawTextLength(font, text)
   local textHeight = renderGetFontDrawHeight(font)
   local curX, curY = getCursorPos()

   if curX >= posX and curX <= posX + textLenght and curY >= posY and curY <= posY + textHeight then
     renderFontDrawText(font, text, posX, posY, colorA)
     if wasKeyPressed(1) then
       return true
     end
   end
end

function onScriptTerminate(sc, qg)
	if sc == thisScript() then
		loadPedObject_hook.stop(); LoadVehicleObject_hook.stop(); LoadObject_hook.stop(); LoadWeaponObject_hook.stop(); LoadTimeObject_hook.stop(); LoadAnimatedClumpObject_hook.stop();
		loadPedObject_hook, LoadVehicleObject_hook, LoadObject_hook, LoadWeaponObject_hook, LoadTimeObject_hook, LoadAnimatedClumpObject_hook = nil, nil, nil, nil, nil, nil
	end
end

function fixed_camera_to_skin() -- проверка на приклепление камеры к скину
	local res, i = pcall(memory.getint8, getModuleHandle('gta_sa.exe') + 0x76F053)
	return (res and (i >= 1 and true or false) or false)
end
