script_name("spawncar")
script_author("dmitriyewich")
script_url("https://vk.com/dmitriyewichmods")
script_properties('work-in-pause', 'forced-reloading-only')
script_version("0.1")

local lffi, ffi = pcall(require, 'ffi')
local lmemory, memory = pcall(require, 'memory')

-- local imgui = require 'mimgui'
local limgui, imgui = pcall(require, 'mimgui')
assert(limgui, 'Library \'mimgui\' not found. Download: https://github.com/THE-FYP/mimgui .')
local vkeys = require 'vkeys'
local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local wm = require 'windows.message'

-- AUTHOR main hooks lib: RTD/RutreD(https://www.blast.hk/members/126461/)
ffi.cdef[[
    int VirtualProtect(void* lpAddress, unsigned long dwSize, unsigned long flNewProtect, unsigned long* lpflOldProtect);
    void* VirtualAlloc(void* lpAddress, unsigned long dwSize, unsigned long  flAllocationType, unsigned long flProtect);
    int VirtualFree(void* lpAddress, unsigned long dwSize, unsigned long dwFreeType);
	void free(void *ptr);
]]
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
        table.insert(buff.free, function()
            ffi.C.VirtualFree(alloc, 0, 0x8000)
        end)
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
        for i, free in ipairs(buff.free) do
            free()
        end
        for i, unHookFunc in ipairs(vmt_hook.hooks) do
            unHookFunc()
        end
    end
end)
--DELETE HOOKS

local cars = {['car'] = {}, ['moster'] = {}, ['heli'] = {}, ['boat'] = {}, ['trailer'] = {}, 
	['bike'] = {}, ['train'] = {}, ['plane'] = {}, ['quad'] = {}, ['bmx'] = {}}

local new, str, sizeof = imgui.new, ffi.string, ffi.sizeof

local spawncar_Window = new.bool()
local input_id = new.char[256]()
local sizeX, sizeY = getScreenResolution()


imgui.OnInitialize(function()
	Standart()
	imgui.GetIO().IniFilename = nil
end)

local spawncar_onframe = imgui.OnFrame(
    function() return spawncar_Window[0] end,
    function(player)
        imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2), imgui.Cond.Appearing, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(500, 400), imgui.Cond.Appearing)
        imgui.Begin("spawncar", spawncar_Window, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
		
        imgui.InputText("", input_id, sizeof(input_id), imgui.InputTextFlags.AutoSelectAll)
		imgui.SameLine()
		if imgui.Button("Спавн модели: "..str(input_id), imgui.ImVec2(0, 0)) then
			if IsVehicleModelType(tonumber(str(input_id))) >= 0 then
				spawncar(tonumber(str(input_id)))
			end
		end
		if imgui.Button("выйти из т/с") then
				local mx, my, mz = getCharCoordinates(PLAYER_PED)
				warpCharFromCarToCoord(PLAYER_PED, mx, my, mz)
		end		

		if imgui.BeginTabBar('##1') then

			for k, v in pairs(cars) do
				if imgui.BeginTabItem(''..k) then
				local transport = 1
					for _, i in pairs(v) do
						
						if imgui.Button(""..i, imgui.ImVec2(45, 45)) then
							spawncar(i)
						end
						if transport % 10 ~= 0 and transport ~= #v then
							imgui.SameLine()
						end
						transport = transport + 1
					end
					imgui.EndTabItem()
				end

			end
			imgui.EndTabBar()
		end
        imgui.End()
    end
)

function IsVehicleModelType(index)
	return IsVehicleModelType(index)
end

function main()
	repeat wait(0) until memory.read(0xC8D4C0, 4, false) == 9
	repeat wait(0) until fixed_camera_to_skin()
	
	IsVehicleModelType = jmp_hook.new("int(__cdecl*)(int)", IsVehicleModelType, 0x4C5C80)
	
	for i = 1, 20000 do
		if IsVehicleModelType(i) == 0 then
			cars.car[#cars.car+1] = i
		end
		if IsVehicleModelType(i) == 1 then
			cars.moster[#cars.moster+1] = i
		end
		if IsVehicleModelType(i) == 2 then
			cars.quad[#cars.quad+1] = i
		end
		if IsVehicleModelType(i) == 3 then
			cars.heli[#cars.heli+1] = i
		end
		if IsVehicleModelType(i) == 4 then
			cars.plane[#cars.plane+1] = i
		end
		if IsVehicleModelType(i) == 5 then
			cars.boat[#cars.boat+1] = i
		end
		if IsVehicleModelType(i) == 6 then
			cars.train[#cars.train+1] = i
		end
		if IsVehicleModelType(i) == 9 then
			cars.bike[#cars.bike+1] = i
		end
		if IsVehicleModelType(i) == 10 then
			cars.bmx[#cars.bmx+1] = i
		end
		if IsVehicleModelType(i) == 11 then
			cars.trailer[#cars.trailer+1] = i
		end
	end
    addEventHandler('onWindowMessage', function(msg, wparam, lparam)
        if msg == wm.WM_KEYDOWN or msg == wm.WM_SYSKEYDOWN then
            if wparam == vkeys.VK_F10 then
                spawncar_Window[0] = not spawncar_Window[0]
            end
        end
    end)

	wait(-1)
end
 
function spawncar(idmodel)
	lua_thread.create(function()
		requestModel(idmodel) -- запрос модели
		loadAllModelsNow()
		repeat wait(0) until isModelAvailable(idmodel)

		x,y,z = getCharCoordinates(1)
		carhandle = createCar(idmodel, x + 3, y, z)
		warpCharIntoCar(1, carhandle)
	end)
end
 
function fixed_camera_to_skin() -- проверка на приклепление камеры к скину
	return (memory.read(getModuleHandle('gta_sa.exe') + 0x76F053, 1, false) >= 1 and true or false)
end

function Standart()
	imgui.SwitchContext()
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	local ImVec4 = imgui.ImVec4
	local ImVec2 = imgui.ImVec2

    style.WindowPadding = ImVec2(15, 15)
	style.WindowRounding = 4.7
    style.WindowBorderSize = 1.0
	style.WindowMinSize = ImVec2(1.5, 1.5)
	style.WindowTitleAlign = ImVec2(0.5, 0.5)
	style.ChildRounding = 4.7
	style.ChildBorderSize = 1
	style.PopupRounding = 4.7
	style.PopupBorderSize  = 1
	style.FramePadding = ImVec2(5, 5)
	style.FrameRounding = 4.7
	style.FrameBorderSize  = 1.0
	style.ItemSpacing = ImVec2(2, 7)
	style.ItemInnerSpacing = ImVec2(8, 6)
	style.ScrollbarSize = 8.0
	style.ScrollbarRounding = 15.0
	style.GrabMinSize = 15.0
	style.GrabRounding = 4.7
	style.IndentSpacing = 25.0
	style.ButtonTextAlign = ImVec2(0.5, 0.5)
	style.SelectableTextAlign = ImVec2(0.5, 0.5)
	style.TouchExtraPadding = ImVec2(0.00, 0.00)
	style.TabBorderSize = 1
	style.TabRounding = 4

	colors[clr.Text] = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.TextDisabled] = ImVec4(0.50, 0.50, 0.50, 1.00)
	colors[clr.WindowBg] = ImVec4(0.15, 0.15, 0.15, 1.00)
	colors[clr.ChildBg] = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.PopupBg] = ImVec4(0.19, 0.19, 0.19, 0.92)
	colors[clr.Border] = ImVec4(0.19, 0.19, 0.19, 0.29)
	colors[clr.BorderShadow] = ImVec4(0.00, 0.00, 0.00, 0.24)
	colors[clr.FrameBg] = ImVec4(0.05, 0.05, 0.05, 0.54)
	colors[clr.FrameBgHovered] = ImVec4(0.19, 0.19, 0.19, 0.54)
	colors[clr.FrameBgActive] = ImVec4(0.20, 0.22, 0.23, 1.00)
	colors[clr.TitleBg] = ImVec4(0.00, 0.00, 0.00, 1.00)
	colors[clr.TitleBgActive] = ImVec4(0.06, 0.06, 0.06, 1.00)
	colors[clr.TitleBgCollapsed] = ImVec4(0.00, 0.00, 0.00, 1.00)
	colors[clr.MenuBarBg] = ImVec4(0.14, 0.14, 0.14, 1.00)
	colors[clr.ScrollbarBg] = ImVec4(0.05, 0.05, 0.05, 0.54)
	colors[clr.ScrollbarGrab] = ImVec4(0.34, 0.34, 0.34, 0.54)
	colors[clr.ScrollbarGrabHovered] = ImVec4(0.40, 0.40, 0.40, 0.54)
	colors[clr.ScrollbarGrabActive] = ImVec4(0.56, 0.56, 0.56, 0.54)
	colors[clr.CheckMark] = ImVec4(0.33, 0.67, 0.86, 1.00)
	colors[clr.SliderGrab] = ImVec4(0.34, 0.34, 0.34, 0.54)
	colors[clr.SliderGrabActive] = ImVec4(0.56, 0.56, 0.56, 0.54)
	colors[clr.Button] = ImVec4(0.05, 0.05, 0.05, 0.54)
	colors[clr.ButtonHovered] = ImVec4(0.19, 0.19, 0.19, 0.54)
	colors[clr.ButtonActive] = ImVec4(0.20, 0.22, 0.23, 1.00)
	colors[clr.Header] = ImVec4(0.00, 0.00, 0.00, 0.52)
	colors[clr.HeaderHovered] = ImVec4(0.00, 0.00, 0.00, 0.36)
	colors[clr.HeaderActive] = ImVec4(0.20, 0.22, 0.23, 0.33)
	colors[clr.Separator] = ImVec4(0.28, 0.28, 0.28, 0.29)
	colors[clr.SeparatorHovered] = ImVec4(0.44, 0.44, 0.44, 0.29)
	colors[clr.SeparatorActive] = ImVec4(0.40, 0.44, 0.47, 1.00)
	colors[clr.ResizeGrip] = ImVec4(0.28, 0.28, 0.28, 0.29)
	colors[clr.ResizeGripHovered] = ImVec4(0.44, 0.44, 0.44, 0.29)
	colors[clr.ResizeGripActive] = ImVec4(0.40, 0.44, 0.47, 1.00)
	colors[clr.Tab]  = ImVec4(0.00, 0.00, 0.00, 0.52)
	colors[clr.TabHovered] = ImVec4(0.14, 0.14, 0.14, 1.00)
	colors[clr.TabActive] = ImVec4(0.20, 0.20, 0.20, 0.36)
	colors[clr.TabUnfocused] = ImVec4(0.00, 0.00, 0.00, 0.52)
	colors[clr.TabUnfocusedActive] = ImVec4(0.14, 0.14, 0.14, 1.00)
	colors[clr.PlotLines] = ImVec4(1.00, 0.00, 0.00, 1.00)
	colors[clr.PlotLinesHovered] = ImVec4(1.00, 0.00, 0.00, 1.00)
	colors[clr.PlotHistogram] = ImVec4(1.00, 0.00, 0.00, 1.00)
	colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.00, 0.00, 1.00)
	colors[clr.TextSelectedBg] = ImVec4(0.20, 0.22, 0.23, 1.00)
	colors[clr.DragDropTarget] = ImVec4(0.33, 0.67, 0.86, 1.00)
	colors[clr.NavHighlight] = ImVec4(1.00, 0.00, 0.00, 1.00)
	colors[clr.NavWindowingHighlight]  = ImVec4(1.00, 0.00, 0.00, 0.70)
	colors[clr.NavWindowingDimBg] = ImVec4(1.00, 0.00, 0.00, 0.20)
	colors[clr.ModalWindowDimBg] = ImVec4(1.00, 0.00, 0.00, 0.35)
end