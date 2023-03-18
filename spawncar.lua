script_name("spawncar")
script_author("dmitriyewich")
script_url("https://vk.com/dmitriyewichmods")
script_properties('work-in-pause', 'forced-reloading-only')
script_version("0.2")

local lffi, ffi = pcall(require, 'ffi')
local lmemory, memory = pcall(require, 'memory')
local limgui, imgui = pcall(require, 'mimgui')
assert(limgui, 'Library \'mimgui\' not found. Download: https://github.com/THE-FYP/mimgui .')
local vkeys = require 'vkeys'
local wm = require 'windows.message'

local IsVehicleModelType = ffi.cast("int(__cdecl*)(int)", 0x4C5C80)

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
    function(spawncar_wind)
        imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2), imgui.Cond.Appearing, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(500, 400), imgui.Cond.Appearing)
        imgui.Begin("spawncar", spawncar_Window, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
			imgui.InputTextWithHint('##example 411', 'Example: 411', input_id, sizeof(input_id) - 1, imgui.InputTextFlags.AutoSelectAll)
			imgui.SameLine()
			if imgui.Button("Spawn model: "..str(input_id), imgui.ImVec2(0, 0)) then
				spawncar(tonumber(str(input_id)))
			end
			if isCharInAnyCar(PLAYER_PED) then
				imgui.SetCursorPosX((imgui.GetWindowWidth() - 147) / 2)
				if imgui.Button("Leave vehicle", imgui.ImVec2(147, 0)) then
					warpCharFromCarToCoord(PLAYER_PED, getCharCoordinates(PLAYER_PED))
					if doesVehicleExist(carhandle) then deleteCar(carhandle) end
				end		
			end
			if imgui.BeginTabBar('##1') then
				for k, v in pairs(cars) do
					if imgui.BeginTabItem(''..k) then
					local vehicle = 1
						for _, i in pairs(v) do
							if imgui.Button(""..i, imgui.ImVec2(45, 45)) then
								spawncar(i)
							end
							if vehicle % 10 ~= 0 and vehicle ~= #v then
								imgui.SameLine()
							end
							vehicle = vehicle + 1
						end
						imgui.EndTabItem()
					end
				end
				imgui.EndTabBar()
			end
		spawncar_wind.HideCursor = false
        imgui.End()
	end)

function main()
	repeat wait(0) until memory.read(0xC8D4C0, 4, false) == 9
	repeat wait(0) until fixed_camera_to_skin()

	for i = 1, 19999 do
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
			if wparam == vkeys.VK_ESCAPE and spawncar_Window[0] then
				consumeWindowMessage(true, false)
				spawncar_Window[0] = false
			end
        end
    end)
	wait(-1)
end

function onScriptTerminate(LuaScript, quitGame)
    if LuaScript == thisScript() and not quitGame then
		if doesVehicleExist(carhandle) then deleteCar(carhandle) end
    end
end

function spawncar(idmodel)
	if IsVehicleModelType(tonumber(idmodel)) >= 0 then
		lua_thread.create(function()
			if not hasModelLoaded(idmodel) then
				requestModel(idmodel)
				loadAllModelsNow()
			end
			repeat wait(0) until isModelAvailable(idmodel)
	
			x,y,z = getCharCoordinates(1)
			carhandle = createCar(idmodel, x + 3, y, z)
			warpCharIntoCar(1, carhandle)
		end)
	end
end
 
function fixed_camera_to_skin() -- проверка на приклепление камеры к скину
	return (memory.read(getModuleHandle('gta_sa.exe') + 0x76F053, 1, false) >= 1 and true or false)
end

function Standart()
	imgui.SwitchContext()
	local style = imgui.GetStyle()
	local colors, clr = style.Colors, imgui.Col
	local ImVec4, ImVec2 = imgui.ImVec4, imgui.ImVec2

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
