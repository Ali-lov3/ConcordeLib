local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/USERNAME/REPO/main/Source.lua"))()

local Window = Library:CreateWindow({
	Title = "Example Hub",
	Logo = "hexagon",
	ConfigFolder = "ExampleHub",
	OpenKey = Enum.KeyCode.RightShift,
})

local MainTab = Window:AddTab({ Name = "Main", Icon = "layout-dashboard" })
local VisualsTab = Window:AddTab({ Name = "Visuals", Icon = "eye" })

local Options = { "Example Option 1", "Example Option 2", "Example Option 3", "Example Option 4" }
local Items = {
	"Example Item 1", "Example Item 2", "Example Item 3", "Example Item 4",
	"Example Item 5", "Example Item 6", "Example Item 7", "Example Item 8",
}

local function Percent(Value)
	return string.format("%.0f%%", Value)
end

local Combat = MainTab:AddGroupbox({ Name = "Combat", Side = "Left" })
local Extras = MainTab:AddGroupbox({ Name = "Extras", Side = "Right" })

Combat:AddLabel("Labels wrap automatically and can be updated.")

local Aim = Combat:AddToggle({
	Name = "Example Toggle",
	Flag = "ExampleToggle",
	Default = false,
	Callback = function(State)
		print("Example Toggle", State)
	end,
	SettingsTitle = "Example Toggle settings",
	Settings = function(Pop)
		Pop:AddToggle({ Name = "Example Toggle Option", Flag = "ExampleToggleOption", Default = true })
		Pop:AddDropdown({
			Name = "Example Dropdown Option",
			Flag = "ExampleDropdownOption",
			Options = { "Example 1", "Example 2", "Example 3" },
			Default = "Example 1",
		})
		Pop:AddSlider({
			Name = "Example Slider Option",
			Flag = "ExampleSliderOption",
			Min = 0,
			Max = 100,
			Default = 50,
			Format = Percent,
		})
	end,
})

Combat:AddToggle({ Name = "Example Toggle 2", Flag = "ExampleToggle2", Default = true })
Combat:AddToggle({ Name = "Example Toggle 3", Flag = "ExampleToggle3", Default = false })

Combat:AddDropdown({
	Name = "Example Dropdown",
	Flag = "ExampleDropdown",
	Options = Options,
	Default = "Example Option 1",
	Callback = function(Value)
		print("Dropdown", Value)
	end,
})

Combat:AddMultiDropdown({
	Name = "Example Multi Dropdown",
	Flag = "ExampleMultiDropdown",
	Options = Options,
	Default = { "Example Option 1" },
	Callback = function(Values)
		print("Multi", table.concat(Values, ", "))
	end,
})

Combat:AddSearchDropdown({
	Name = "Example Search Dropdown",
	Flag = "ExampleSearchDropdown",
	Options = Items,
	Default = "Example Item 1",
})

Combat:AddButton({
	Name = "Example Button",
	Callback = function()
		Window:Notify("Example", "Example Button was pressed.", 3, "Success")
	end,
})

Extras:AddLabel("Put as many groupboxes as you like in each column.")

Extras:AddSlider({
	Name = "Example Slider",
	Flag = "ExampleSlider",
	Min = 0,
	Max = 100,
	Default = 50,
	Format = Percent,
})

Extras:AddSlider({
	Name = "Example Slider 2",
	Flag = "ExampleSlider2",
	Min = 0,
	Max = 10,
	Default = 5,
})

Extras:AddRangeSlider({
	Name = "Example Range Slider",
	FlagMin = "ExampleRangeMin",
	FlagMax = "ExampleRangeMax",
	Min = 0,
	Max = 100,
	DefaultMin = 20,
	DefaultMax = 80,
})

Extras:AddColor({
	Name = "Example Color",
	Flag = "ExampleColor",
	Default = Color3.fromRGB(240, 84, 88),
	Callback = function(Color)
		print("Color", Color)
	end,
})

Extras:AddInput({
	Name = "Example Input",
	Flag = "ExampleInput",
	Placeholder = "Example placeholder",
	Callback = function(Value)
		print("Input", Value)
	end,
})

Extras:AddToggle({ Name = "Example Toggle 4", Flag = "ExampleToggle4", Default = true })

Extras:AddButton({
	Name = "Example Button 2",
	Callback = function()
		Window:Notify("Example", "Example Button 2 was pressed.", 3, "Info")
	end,
})

local Esp = VisualsTab:AddGroupbox({ Name = "Players", Side = "Left" })
local World = VisualsTab:AddGroupbox({ Name = "World", Side = "Right" })

Esp:AddToggle({ Name = "Boxes", Flag = "Boxes", Default = false })
Esp:AddToggle({ Name = "Names", Flag = "Names", Default = false })
Esp:AddColor({ Name = "Box Color", Flag = "BoxColor", Default = Color3.fromRGB(255, 255, 255) })

World:AddSlider({
	Name = "Field Of View",
	Flag = "FieldOfView",
	Min = 40,
	Max = 120,
	Default = 70,
})

World:AddToggle({ Name = "Fullbright", Flag = "Fullbright", Default = false })

Window:AddKeybind("Example Toggle", "Toggle", function() return Aim.Get() end)
Window:AddKeybind("Example Toggle 2", "Toggle", function() return Window.Flags.ExampleToggle2 end)

Window:ConfigManager()
Window:SettingManager()
Window:SearchManager()
Window:KeybindList()
