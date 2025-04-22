script_name("{4baf4f}ViewModelsInfo")
script_author("dmitriyewich, Ork")
script_description("Displaying information about visible models.")
script_dependencies("ffi", "memory", "hooks", "vkeys")
script_properties('work-in-pause', 'forced-reloading-only')
script_version("1.2")

local memory = require("memory")
local ffi = require("ffi")
local vkeys = require 'vkeys'
local hook = require 'hooks'
require "lib.moonloader"

local models_table = {}
local renderEnabled = false
local cursorRend = false

local config = {
	show_cursor_key = VK_F4,
	toggle_render_key = VK_F3,
	copy_on_lmb = true,
}

function json(filePath)
	local filePath = getWorkingDirectory()..'\\'..(filePath:find('(.+).json') and filePath or filePath..'.json')
	local class = {}

	function class:Save(tbl)
		if tbl then
			local f = io.open(filePath, 'w')
			f:write(encodeJson(tbl) or '{}')
			f:close()
			return true, 'ok'
		end
		return false, 'table = nil'
	end

	function class:Load(defaultTable)
		if not doesFileExist(filePath) then
			print("[ViewModelsInfo] JSON не найден, создаём новый.")
			self:Save(defaultTable or {})
			return defaultTable or {}
		end
		
		local f = io.open(filePath, 'r')
		if not f then print("[ViewModelsInfo] Ошибка открытия файла!") return defaultTable or {} end
		local contents = f:read("*a")
		f:close()
		
		local success, result = pcall(decodeJson, contents)
		if not success then
			print("[ViewModelsInfo] decodeJson вызвал ошибку:", result)
			return defaultTable or {}
		elseif type(result) ~= "table" then
			print("[ViewModelsInfo] decodeJson вернул не таблицу.")
			return defaultTable or {}
		end

		return result
	end

	return class
end

local function parseModel(str)
	return ffi.string(str):match("^(%d+)%s+([%w%d_]+)%s+([%w%d_]+)")
end

local function parseVehicle(str)
	return ffi.string(str):match("^(%d+)%s+([%w%d_]+)%s+([%w%d_]+)%s+([%w%d_]+)%s+([%w%d_]+)")
end

local original_loadPedObject
local original_loadVehicle
local original_loadObject
local original_loadWeapon
local original_loadTimeObj
local original_loadClump

function loadPedObject_hook(str)
	local id, name, txd = parseModel(str)
	if id then models_table[tonumber(id)] = {name = name, txd = txd} end
	return original_loadPedObject(str)
end

function LoadVehicleObject_hook(str)
	local id, name, txd, tmodel, cname = parseVehicle(str)
	if id then models_table[tonumber(id)] = {name = name, txd = txd, type_model = tmodel, name_car = cname} end
	return original_loadVehicle(str)
end

function LoadObject_hook(str)
	local id, name, txd = parseModel(str)
	if id then models_table[tonumber(id)] = {name = name, txd = txd} end
	return original_loadObject(str)
end

function LoadWeaponObject_hook(str)
	local id, name, txd = parseModel(str)
	if id then models_table[tonumber(id)] = {name = name, txd = txd} end
	return original_loadWeapon(str)
end

function LoadAnimatedClumpObject_hook(str)
	local id, name, txd = parseModel(str)
	if id then models_table[tonumber(id)] = {name = name, txd = txd} end
	return original_loadClump(str)
end

function LoadTimeObject_hook(str)
	local id, name, txd = parseModel(str)
	if id then models_table[tonumber(id)] = {name = name, txd = txd} end
	return original_loadTimeObj(str)
end

original_loadPedObject	 = hook.jmp.new("int(__cdecl*)(const char*)", loadPedObject_hook, 0x5B7420)
original_loadVehicle	   = hook.jmp.new("int(__cdecl*)(const char*)", LoadVehicleObject_hook, 0x5B6F30)
original_loadObject		= hook.jmp.new("int(__cdecl*)(const char*)", LoadObject_hook, 0x5B3C60)
original_loadClump		 = hook.jmp.new("int(__cdecl*)(const char*)", LoadAnimatedClumpObject_hook, 0x5B40C0)
original_loadTimeObj	   = hook.jmp.new("int(__cdecl*)(const char*)", LoadTimeObject_hook, 0x5B3DE0)
original_loadWeapon		= hook.jmp.new("int(__cdecl*)(const char*)", LoadWeaponObject_hook, 0x5B3FB0)

local font = renderCreateFont("Arial", 8, 5)
function drawClickableText(font, text, x, y, color, hoverColor, worldX, worldY, worldZ)
	if not font or not text or not x or not y then return end
	local success, err = pcall(function()
		renderFontDrawText(font, text, x, y, color)
		local w = renderGetFontDrawTextLength(font, text)
		local h = renderGetFontDrawHeight(font)
		local cx, cy = getCursorPos()
		if cx >= x and cx <= x + w and cy >= y and cy <= y + h then
			renderFontDrawText(font, text, x, y, hoverColor)
			if wasKeyPressed(1) and config.copy_on_lmb then
				local copy = string.format("%s\n[Coords: %.3f %.3f %.3f]", text, worldX or 0, worldY or 0, worldZ or 0)
				setClipboardText(text)
			end
		end
	end)
	if not success then
		print("[ViewModelsInfo] drawClickableText error: " .. tostring(err))
	end
end

local getBonePosition = ffi.cast("int(__thiscall*)(void*, float*, int, bool)", 0x5E4280)
function GetBodyPartCoordinates(id, ped)
	local ptr, vec = getCharPointer(ped), ffi.new("float[3]")
	getBonePosition(ffi.cast("void*", ptr), vec, id, true)
	return vec[0], vec[1], vec[2]
end

function fixed_camera_to_skin()
	local ok, byte = pcall(memory.getint8, getModuleHandle('gta_sa.exe') + 0x76F053)
	return ok and byte >= 1
end

function main()
	repeat wait(100) until memory.getuint32(0xC8D4C0, true) == 9
	repeat wait(100) until memory.getint8(getModuleHandle("gta_sa.exe") + 0x76F053) >= 1

	toggleRenderThread()

	if models_table[1] ~= nil then
		local status, code = json('ViewModelsInfo.json'):Save(models_table)
		wait(1000)
		models_table = json('ViewModelsInfo.json'):Load(models_table)
	else
		wait(1000)
		models_table = json('ViewModelsInfo.json'):Load(models_table)
	end
	
	local converted = {}
	for k, v in pairs(models_table) do
		converted[tonumber(k)] = v
	end
	models_table = converted

	createVehicleThread()
	createObjectThread()
	createCharThread()
	createCursorThread()

	wait(-1)
end

function createVehicleThread()
	return lua_thread.create(function()
		while true do wait(0)
			for _, v in ipairs(getAllVehicles()) do
				if not renderEnabled then goto continue end
				if doesVehicleExist(v) and isCarOnScreen(v) then
					local model = getCarModel(v)
					local x, y = convert3DCoordsToScreen(getCarCoordinates(v))
					local info = models_table[model]
					if x and y then
						local text = info and ("Model ID: %d\nName: %s\nTXD: %s\nType: %s\nCar: %s"):format(model, info.name, info.txd, info.type_model, info.name_car) or ("Model ID: %d"):format(model)
						drawClickableText(font, text, x, y, 0xFFFFFFFF, 0xAAAAAAFF)
					end
				end
				::continue::
			end
		end
	end)
end

function createObjectThread()
	return lua_thread.create(function()
		while true do wait(0)
			for _, obj in ipairs(getAllObjects()) do
				if not renderEnabled then goto continue end
				if doesObjectExist(obj) and isObjectOnScreen(obj) then
					local model = getObjectModel(obj)
					local res, x, y, z = getObjectCoordinates(obj)
					if res then
						local sx, sy = convert3DCoordsToScreen(x, y, z)
						local info = models_table[model]
						if sx and sy then
							local text = info and ("Model ID: %d\nName: %s\nTXD: %s"):format(model, info.name, info.txd) or ("Model ID: %d"):format(model)
							drawClickableText(font, text, sx, sy, 0xFFFFFFFF, 0xAAAAAAFF)
						end
					end
				end
				
				::continue::
			end
		end
	end)
end

function createCharThread()
	return lua_thread.create(function()
		while true do wait(0)
			for _, ped in ipairs(getAllChars()) do
				if not renderEnabled then goto continue end
				if doesCharExist(ped) and isCharOnScreen(ped) then
					local model = getCharModel(ped)
					local x, y = convert3DCoordsToScreen(GetBodyPartCoordinates(4, ped))
					local info = models_table[model]
					if x and y then
						local text = info and ("Model ID: %d\nName: %s\nTXD: %s"):format(model, info.name, info.txd) or ("Model ID: %d"):format(model)
						drawClickableText(font, text, x, y, 0xFFFFFFFF, 0xAAAAAAFF)
					end
				end
				::continue::
			end
		end
	end)
end

function createCursorThread()
	return lua_thread.create(function()
		while true do wait(0)
			if not cursorRend then goto continue end
			local cx, cy = getCursorPos()
			local wx, wy, wz = convertScreenCoordsToWorld3D(cx, cy, 700.0)
			local camX, camY, camZ = getActiveCameraCoordinates()
			local hit, c = processLineOfSight(camX, camY, camZ, wx, wy, wz, true, true, true, true, true, true, true)
			if hit and c then
				local text, model
				if c.entityType == 2 then
					local veh = getVehiclePointerHandle(c.entity)
					if doesVehicleExist(veh) then
						model = getCarModel(veh)
						local info = models_table[model]
						text = info and ("Model ID: %d\nName: %s\nTXD: %s\nType: %s\nCar: %s"):format(model, info.name, info.txd, info.type_model, info.name_car) or ("Model ID: %d"):format(model)
					end
				elseif c.entityType == 3 then
					local ped = getCharPointerHandle(c.entity)
					if doesCharExist(ped) then
						model = getCharModel(ped)
						local info = models_table[model]
						text = info and ("Model ID: %d\nName: %s\nTXD: %s"):format(model, info.name, info.txd) or ("Model ID: %d"):format(model)
					end
				elseif c.entityType == 1 or c.entityType == 4 then
					local obj = getObjectPointerHandle(c.entity)
					if doesObjectExist(obj) then
						model = getObjectModel(obj)
						local info = models_table[model]
						text = info and ("Model ID: %d\nName: %s\nTXD: %s"):format(model, info.name, info.txd) or ("Model ID: %d"):format(model)
					end
				end
				if text then drawClickableText(font, text, cx, cy, 0xFFFFFFFF, 0xAAAAAAFF) end
			end
			::continue::
		end
	end)
end

function toggleRenderThread()
	lua_thread.create(function()
		while true do wait(0)
			if isKeyJustPressed(config.toggle_render_key) then
				renderEnabled = not renderEnabled
			end
			if isKeyJustPressed(config.show_cursor_key) then
				cursorRend = not cursorRend
				showCursor(cursorRend, true)
			end
		end
	end)
end

function onScriptTerminate(scr)
	if scr == thisScript() then
		showCursor(false, false)
	end
end
