local ZenithUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/yourname/zenith-ui/main/src/ZenithUI.lua"))()

local Window = ZenithUI.new({
	Title = "Zenith UI",
	Subtitle = "minimalist runtime panel",
	ConfigFolder = "ZenithUI",
	ToggleKey = Enum.KeyCode.RightShift,
})

local MainTab = Window:AddTab({
	Title = "Main",
})

local Combat = MainTab:AddSection("Combat")
Combat:AddToggle({
	Id = "aimbot",
	Title = "Silent Aim",
	Default = false,
	Callback = function(value)
		print("Silent Aim:", value)
	end,
})

Combat:AddSlider({
	Id = "fov",
	Title = "FOV Radius",
	Min = 40,
	Max = 280,
	Default = 120,
	Callback = function(value)
		print("FOV:", value)
	end,
})

local VisualsTab = Window:AddTab({
	Title = "Visuals",
})

local Visuals = VisualsTab:AddSection("Visuals")
Visuals:AddDropdown({
	Id = "accent_mode",
	Title = "Accent Preset",
	Values = {"Ocean", "Graphite", "Ice", "Mint"},
	Default = "Ocean",
	Callback = function(value)
		print("Accent:", value)
	end,
})

Visuals:AddInput({
	Id = "watermark",
	Title = "Watermark",
	Placeholder = "type label",
	Default = "Zenith",
	Callback = function(value)
		print("Watermark:", value)
	end,
})

Visuals:AddButton({
	Title = "Notify",
	Callback = function()
		Window:Notify({
			Title = "Zenith UI",
			Content = "Library still listening.",
		})
	end,
})

