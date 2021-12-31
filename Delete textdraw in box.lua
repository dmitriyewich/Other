script_name("Delete textdraw in box")
script_authors("dmitriyewich")
script_url("https://vk.com/dmitriyewichmods")
script_properties('work-in-pause', 'forced-reloading-only')
script_version("2.0")

local lsampev, sampev = pcall(require, 'samp.events') -- https://github.com/THE-FYP/SAMP.Lua
assert(lsampev, 'Library \'SAMP.Lua\' not found. Download: https://github.com/THE-FYP/SAMP.Lua')
local lffi, ffi = pcall(require, 'ffi')
assert(lffi, 'Library \'ffi\' not found.')
local lwm, wm = pcall(require, 'windows.message')
assert(lwm, 'Library \'windows.message\' not found.')
local lencoding, encoding = pcall(require, 'encoding')
assert(lencoding, 'Library \'encoding\' not found.')
encoding.default = 'CP1251'
u8 = encoding.UTF8

changelog = [[
	Delete textdraw in box v1.0
		- Релиз
	Delete textdraw in box v2.0
		- Код стал большим, лучше на него не смотреть, когда-нибудь оптимизирую
		- Выделение работает из под любого угла
		- Добавлен конфиг
		- Добавлен автоперезапуск скрипта, если изменен конфиг(чтобы вручную во время игры вводить в конфиг нужные иды, мне так удобнее ¯\_(ツ)_/¯)
		- Добавлены новые функции, подбронее /tdd help
		- если /tdd активен, отключить можно на ESC
]]

local dell_texdraw, active, stop, bool, bool1, show, always = {}, false, true, false, false, false, false

ffi.cdef[[
	typedef void* HANDLE;
	typedef void* LPSECURITY_ATTRIBUTES;
	typedef unsigned long DWORD;
	typedef int BOOL;
	typedef const char *LPCSTR;
	typedef struct _FILETIME {
    DWORD dwLowDateTime;
    DWORD dwHighDateTime;
	} FILETIME, *PFILETIME, *LPFILETIME;

	BOOL __stdcall GetFileTime(HANDLE hFile, LPFILETIME lpCreationTime, LPFILETIME lpLastAccessTime, LPFILETIME lpLastWriteTime);
	HANDLE __stdcall CreateFileA(LPCSTR lpFileName, DWORD dwDesiredAccess, DWORD dwShareMode, LPSECURITY_ATTRIBUTES lpSecurityAttributes, DWORD dwCreationDisposition, DWORD dwFlagsAndAttributes, HANDLE hTemplateFile);
	BOOL __stdcall CloseHandle(HANDLE hObject);
]]

local function isarray(t, emptyIsObject) -- by Phrogz, сортировка
	if type(t)~='table' then return false end
	if not next(t) then return not emptyIsObject end
	local len = #t
	for k,_ in pairs(t) do
		if type(k)~='number' then
			return false
		else
			local _,frac = math.modf(k)
			if frac~=0 or k<1 or k>len then
				return false
			end
		end
	end
	return true
end

local function map(t,f)
	local r={}
	for i,v in ipairs(t) do r[i]=f(v) end
	return r
end

local keywords = {["and"]=1,["break"]=1,["do"]=1,["else"]=1,["elseif"]=1,["end"]=1,["false"]=1,["for"]=1,["function"]=1,["goto"]=1,["if"]=1,["in"]=1,["local"]=1,["nil"]=1,["not"]=1,["or"]=1,["repeat"]=1,["return"]=1,["then"]=1,["true"]=1,["until"]=1,["while"]=1}

local function neatJSON(value, opts) -- by Phrogz, сортировка
	opts = opts or {}
	if opts.wrap==nil  then opts.wrap = 80 end
	if opts.wrap==true then opts.wrap = -1 end
	opts.indent         = opts.indent         or "  "
	opts.arrayPadding  = opts.arrayPadding  or opts.padding      or 0
	opts.objectPadding = opts.objectPadding or opts.padding      or 0
	opts.afterComma    = opts.afterComma    or opts.aroundComma  or 0
	opts.beforeComma   = opts.beforeComma   or opts.aroundComma  or 0
	opts.beforeColon   = opts.beforeColon   or opts.aroundColon  or 0
	opts.afterColon    = opts.afterColon    or opts.aroundColon  or 0
	opts.beforeColon1  = opts.beforeColon1  or opts.aroundColon1 or opts.beforeColon or 0
	opts.afterColon1   = opts.afterColon1   or opts.aroundColon1 or opts.afterColon  or 0
	opts.beforeColonN  = opts.beforeColonN  or opts.aroundColonN or opts.beforeColon or 0
	opts.afterColonN   = opts.afterColonN   or opts.aroundColonN or opts.afterColon  or 0

	local colon  = opts.lua and '=' or ':'
	local array  = opts.lua and {'{','}'} or {'[',']'}
	local apad   = string.rep(' ', opts.arrayPadding)
	local opad   = string.rep(' ', opts.objectPadding)
	local comma  = string.rep(' ',opts.beforeComma)..','..string.rep(' ',opts.afterComma)
	local colon1 = string.rep(' ',opts.beforeColon1)..colon..string.rep(' ',opts.afterColon1)
	local colonN = string.rep(' ',opts.beforeColonN)..colon..string.rep(' ',opts.afterColonN)

	local build
	local function rawBuild(o,indent)
		if o==nil then
			return indent..'null'
		else
			local kind = type(o)
			if kind=='number' then
				local _,frac = math.modf(o)
				return indent .. string.format( frac~=0 and opts.decimals and ('%.'..opts.decimals..'f') or '%g', o)
			elseif kind=='boolean' or kind=='nil' then
				return indent..tostring(o)
			elseif kind=='string' then
				return indent..string.format('%q', o):gsub('\\\n','\\n')
			elseif isarray(o, opts.emptyTablesAreObjects) then
				if #o==0 then return indent..array[1]..array[2] end
				local pieces = map(o, function(v) return build(v,'') end)
				local oneLine = indent..array[1]..apad..table.concat(pieces,comma)..apad..array[2]
				if opts.wrap==false or #oneLine<=opts.wrap then return oneLine end
				if opts.short then
					local indent2 = indent..' '..apad;
					pieces = map(o, function(v) return build(v,indent2) end)
					pieces[1] = pieces[1]:gsub(indent2,indent..array[1]..apad, 1)
					pieces[#pieces] = pieces[#pieces]..apad..array[2]
					return table.concat(pieces, ',\n')
				else
					local indent2 = indent..opts.indent
					return indent..array[1]..'\n'..table.concat(map(o, function(v) return build(v,indent2) end), ',\n')..'\n'..(opts.indentLast and indent2 or indent)..array[2]
				end
			elseif kind=='table' then
				if not next(o) then return indent..'{}' end

				local sortedKV = {}
				local sort = opts.sort or opts.sorted
				for k,v in pairs(o) do
					local kind = type(k)
					if kind=='string' or kind=='number' then
						sortedKV[#sortedKV+1] = {k,v}
						if sort==true then
							sortedKV[#sortedKV][3] = tostring(k)
						elseif type(sort)=='function' then
							sortedKV[#sortedKV][3] = sort(k,v,o)
						end
					end
				end
				if sort then table.sort(sortedKV, function(a,b) return a[3]<b[3] end) end
				local keyvals
				if opts.lua then
					keyvals=map(sortedKV, function(kv)
						if type(kv[1])=='string' and not keywords[kv[1]] and string.match(kv[1],'^[%a_][%w_]*$') then
							return string.format('%s%s%s',kv[1],colon1,build(kv[2],''))
						else
							return string.format('[%q]%s%s',kv[1],colon1,build(kv[2],''))
						end
					end)
				else
					keyvals=map(sortedKV, function(kv) return string.format('%q%s%s',kv[1],colon1,build(kv[2],'')) end)
				end
				keyvals=table.concat(keyvals, comma)
				local oneLine = indent.."{"..opad..keyvals..opad.."}"
				if opts.wrap==false or #oneLine<opts.wrap then return oneLine end
				if opts.short then
					keyvals = map(sortedKV, function(kv) return {indent..' '..opad..string.format('%q',kv[1]), kv[2]} end)
					keyvals[1][1] = keyvals[1][1]:gsub(indent..' ', indent..'{', 1)
					if opts.aligned then
						local longest = math.max(table.unpack(map(keyvals, function(kv) return #kv[1] end)))
						local padrt   = '%-'..longest..'s'
						for _,kv in ipairs(keyvals) do kv[1] = padrt:format(kv[1]) end
					end
					for i,kv in ipairs(keyvals) do
						local k,v = kv[1], kv[2]
						local indent2 = string.rep(' ',#(k..colonN))
						local oneLine = k..colonN..build(v,'')
						if opts.wrap==false or #oneLine<=opts.wrap or not v or type(v)~='table' then
							keyvals[i] = oneLine
						else
							keyvals[i] = k..colonN..build(v,indent2):gsub('^%s+','',1)
						end
					end
					return table.concat(keyvals, ',\n')..opad..'}'
				else
					local keyvals
					if opts.lua then
						keyvals=map(sortedKV, function(kv)
							if type(kv[1])=='string' and not keywords[kv[1]] and string.match(kv[1],'^[%a_][%w_]*$') then
								return {table.concat{indent,opts.indent,kv[1]}, kv[2]}
							else
								return {string.format('%s%s[%q]',indent,opts.indent,kv[1]), kv[2]}
							end
						end)
					else
						keyvals = {}
						for i,kv in ipairs(sortedKV) do
							keyvals[i] = {indent..opts.indent..string.format('%q',kv[1]), kv[2]}
						end
					end
					if opts.aligned then
						local longest = math.max(table.unpack(map(keyvals, function(kv) return #kv[1] end)))
						local padrt   = '%-'..longest..'s'
						for _,kv in ipairs(keyvals) do kv[1] = padrt:format(kv[1]) end
					end
					local indent2 = indent..opts.indent
					for i,kv in ipairs(keyvals) do
						local k,v = kv[1], kv[2]
						local oneLine = k..colonN..build(v,'')
						if opts.wrap==false or #oneLine<=opts.wrap or not v or type(v)~='table' then
							keyvals[i] = oneLine
						else
							keyvals[i] = k..colonN..build(v,indent2):gsub('^%s+','',1)
						end
					end
					return indent..'{\n'..table.concat(keyvals, ',\n')..'\n'..(opts.indentLast and indent2 or indent)..'}'
				end
			end
		end
	end

	local function memoize()
		local memo = setmetatable({},{_mode='k'})
		return function(o,indent)
			if o==nil then
				return indent..(opts.lua and 'nil' or 'null')
			elseif o~=o then
				return indent..(opts.lua and '0/0' or '"NaN"')
			elseif o==math.huge then
				return indent..(opts.lua and '1/0' or '9e9999')
			elseif o==-math.huge then
				return indent..(opts.lua and '-1/0' or '-9e9999')
			end
			local byIndent = memo[o]
			if not byIndent then
				byIndent = setmetatable({},{_mode='k'})
				memo[o] = byIndent
			end
			if not byIndent[indent] then
				byIndent[indent] = rawBuild(o,indent)
			end
			return byIndent[indent]
		end
	end

	build = memoize()
	return build(value,'')
end

function savejson(table, path)
    local f = io.open(path, "w")
    f:write(table)
    f:close()
end

function convertTableToJsonString(config)
	return (neatJSON(config, { wrap = 40, short = true, sort = false, aligned = true, arrayPadding = 1, afterComma = 1, beforeColon1 = 1 }))
end

local config = {}

function defalut_config()
	config = {
		['global_del'] = true,
		["ids"] = {};
	}
    savejson(convertTableToJsonString(config), "moonloader/config/Delete textdraw in box.json")
end

if doesFileExist("moonloader/config/Delete textdraw in box.json") then
    local f = io.open("moonloader/config/Delete textdraw in box.json")
    config = decodeJson(f:read("*a"))
    f:close()
else
	defalut_config()
end

local font = renderCreateFont('Arial', 10, 1 + 4 + 8)

function main()

	if not isSampfuncsLoaded() or not isSampLoaded() then return end
	while not isSampAvailable() do wait(100) end

	local x1, y1, x2, y2, sw, sh = 0, 0, 0, 0, getScreenResolution()

	sampRegisterChatCommand("tdd", function(arg)
		if not arg:match("help") and not arg:match("active") and not arg:match("dtemp") and not arg:match("add 1") and not arg:match("dell") then active = not active end
		if active then showCursor(true) end
		if arg:match("active") then
			config.global_del = not config.global_del
			savejson(convertTableToJsonString(config), "moonloader/config/Delete textdraw in box.json")
		end
		if arg:match("temp") then bool, bool1 = true, true end
		if arg:match("help") then help() end
		if arg:match("dtemp") then dell_texdraw = {} end
		if arg:match("show") then show, bool = true, true end
		if arg:match("add") then
			local arg = split(arg:gsub("add ", ""), '%s+', false)
			if arg[1] == "2" then
				for i = 2, #arg do
					config.ids[#config.ids+1] = tonumber(arg[i])
					savejson(convertTableToJsonString(config), "moonloader/config/Delete textdraw in box.json")
				end

			end
			if arg[1] == "1" then always = true end
		end
		if arg:match("dell") then
			local arg = split(arg:gsub("dell ", ""), '%s+', false)
			if arg[1] == "all" then
					config.ids = {}
					savejson(convertTableToJsonString(config), "moonloader/config/Delete textdraw in box.json")
			end
			if arg[1] == "sel" and arg[2] ~= nil and arg[2] ~= '' then
				for i = 2, #arg do
					table.remove(config.ids, tonumber(arg[i]))
					savejson(convertTableToJsonString(config), "moonloader/config/Delete textdraw in box.json")
				end
			end
			if arg[1] == "sid" and arg[2] ~= nil and arg[2] ~= '' then
				for i = 2, #arg do
					for k, val in ipairs(config.ids) do
						if val == tonumber(arg[i]) then
							table.remove(config.ids, k)
							savejson(convertTableToJsonString(config), "moonloader/config/Delete textdraw in box.json")
						end
					end
				end
			end
			if arg[1] == "dell" then
				for i = 1, #config.ids do
					print("Element: " .. i .. '  |  ID Texdraw: ' .. config.ids[i])
				end
			end
		end
	end)
	sampSetClientCommandDescription("tdd", string.format(u8:decode"Активация %s, /tdd help - открыть окно подсказку. Файл: %s", thisScript().name, thisScript().filename))

	files = {}
	local time = get_file_modify_time(string.format("%s/config/Delete textdraw in box.json",getWorkingDirectory()))
	if time ~= nil then
	  files[string.format("%s/config/Delete textdraw in box.json",getWorkingDirectory())] = time
	end
	lua_thread.create(function() -- отдельный поток для проверки изменений конфига
		while true do wait(274)
			if files ~= nil and not files_check_window and not pos_active then  -- by FYP
				for fpath, saved_time in pairs(files) do
					local file_time = get_file_modify_time(fpath)
					if file_time ~= nil and (file_time[1] ~= saved_time[1] or file_time[2] ~= saved_time[2]) then
						print('Reloading "' .. thisScript().name .. '"...')
						thisScript():reload()
						files[fpath] = file_time -- update time
					end
				end
			end
		end
	end)

	while true do wait(0)
		if active then
			if not isKeyDown(1) and stop then
				x1, y1 = getCursorPos()
			elseif isKeyDown(1) then
				x2, y2 = getCursorPos()
				renderDrawBoxWithBorder(x1, y1, x2-x1, y2-y1, 0x78e5e5e5, 2.74, 0xe5e5e5e5)
				IsOnBox(x1, y1, x2, y2, false, false, false, true, false)
				stop = false
			end
			if show then
				IsOnBox(0, 0, sw, sh, false, false, false, true, false)
			end
			if wasKeyReleased(1) then
				local tbl = IsOnBox(x1, y1, x2, y2, true, bool, bool1, false, always)
				if not show then
					for i = 1, #tbl do
						sampTextdrawDelete(tbl[i])
					end
				end
				stop, active, bool, bool1, show, always = true, false, false, false, false, false
				showCursor(false)
			end
		end
	end
end

function IsOnBox(x, y, x1, y2, add, print_id, temp_add, render, always_f)
	local id = {}
	for i = 0, 2304 do
		if sampTextdrawIsExists(i) then
			local tdX, tdY = sampTextdrawGetPos(i)
			local tddX, tddY = convert(1, tdX).x, convert(1, tdY).y
			local rX, rY, rX2, rY2 = convert(2, x).x, convert(2, y).y, convert(2, x1).x, convert(2, y2).y
			if (tdX <= rX and tdY <= rY and tdX >= rX2 and tdY >= rY2) or (tdX >= rX and tdY >= rY and tdX <= rX2 and tdY <= rY2)
			or (tdX <= rX2 and tdY <= rY and tdX >= rX and tdY >= rY2) or (tdX >= rX2 and tdY >= rY and tdX <= rX and tdY <= rY2) then
				if add then id[#id+1] = i end
				if print_id then print(i) end
				if temp_add then dell_texdraw[#dell_texdraw+1] = i end
				if render then renderFontDrawText(font, i, tddX, tddY, 0xFFBEBEBE) end
				if always_f then
					config.ids[#config.ids+1] = i
					savejson(convertTableToJsonString(config), "moonloader/config/Delete textdraw in box.json")
				end
			end
		end
	end
	return id
end

function convert(typed, xy)
	local posX, posY
	if typed == 1 then
		posX, posY = convertGameScreenCoordsToWindowScreenCoords(xy, xy)
	elseif typed == 2 then
		posX, posY = convertWindowScreenCoordsToGameScreenCoords(xy, xy)
	end
	return {['x'] = posX, ['y'] = posY}
end

function split(str, delim, plain)
	local tokens, pos, plain = {}, 1, not (plain == false)
	repeat
		local npos, epos = string.find(str, delim, pos, plain)
		table.insert(tokens, string.sub(str, pos, npos and npos - 1))
		pos = epos and epos + 1
	until not pos
	return tokens
end

function get_file_modify_time(path) -- by FYP
	local handle = ffi.C.CreateFileA(path,
		0x80000000, -- GENERIC_READ
		0x00000001 + 0x00000002, -- FILE_SHARE_READ | FILE_SHARE_WRITE
		nil,
		3, -- OPEN_EXISTING
		0x00000080, -- FILE_ATTRIBUTE_NORMAL
		nil)
	local filetime = ffi.new('FILETIME[3]')
	if handle ~= -1 then
		local result = ffi.C.GetFileTime(handle, filetime, filetime + 1, filetime + 2)
		ffi.C.CloseHandle(handle)
		if result ~= 0 then
			return {tonumber(filetime[2].dwLowDateTime), tonumber(filetime[2].dwHighDateTime)}
		end
	end
	return nil
end

function onWindowMessage(msg, wparam, lparam)
	if msg == wm.WM_KEYDOWN and wparam == 0x1B and active then
		stop, active, bool, bool1, show, always = true, false, false, false, false, false
		showCursor(false)
		consumeWindowMessage(true, false)
	end
end

function help()
    sampShowDialog(15574, u8:decode"{FFFFFF}Delete textdraw in box", u8:decode"{FFFFFF}/tdd{a9c4e4} - обычное удаление, без привязки.\n{FFFFFF}/tdd help{a9c4e4} - открыть список команд\n{FFFFFF}/tdd temp{a9c4e4} - удалить с временным запоминанием(до перезахода в игру).\n{FFFFFF}/tdd dtemp{a9c4e4} - очистить временный список\n{FFFFFF}/tdd show{a9c4e4} - показывает все текстдравы на экране + оправляет в консоль SF выбранные иды\n{FFFFFF}/tdd add 1{a9c4e4} - добавление в постоянный список из выбранной области\n{FFFFFF}/tdd add 2{a9c4e4} - ручное обавление в постоянный список( пример: {FFFFFF}/tdd add 1 436 437 435)\n{FFFFFF}/tdd active{a9c4e4} - включение/выключение постоянного списка({FFFFFF}сейчас: " ..tostring(config.global_del and u8:decode"Включен" or u8:decode"Выключен")..u8:decode"{a9c4e4})\n{FFFFFF}/tdd dell{a9c4e4} - отправляет в консоль SF номера элементов и иды постоянных текстдравов\n{FFFFFF}/tdd dell all{a9c4e4} - очищает постоянный список\n{FFFFFF}/tdd dell sel 1 2 3 4 и т.д{a9c4e4} - удаление ида по номеру элемента.\n{FFFFFF}/tdd dell sid 435 436 437 и т.д{a9c4e4} - удаление ида по иду текстрава.", u8:decode"ОК", _, 0)
end

if lsampev then
	function sampev.onShowTextDraw(id, data)
		for i = 1, #dell_texdraw do
			if id == dell_texdraw[i] then return false end
		end
		if config.global_del then
			for i = 1, #config.ids do
				if id == config.ids[i] then return false end
			end
		end
	end
end
