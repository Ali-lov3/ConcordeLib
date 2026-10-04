local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Ali-lov3/ConcordeLib/refs/heads/main/Source.lua"))()

local Window = Library:CreateWindow({
	Title = "Example",
	Logo = "hexagon",
	ConfigFolder = "Example",
	OpenKey = Enum.KeyCode.RightShift,
})

local ExampleTab = Window:AddTab({ Name = "Example Tab", Icon = "layout-dashboard" })
local ExampleTab2 = Window:AddTab({ Name = "Example Tab 2", Icon = "eye" })

local ExampleOptions = { "Example Option 1", "Example Option 2", "Example Option 3", "Example Option 4" }
local ExampleItems = {
	"Example Item 1", "Example Item 2", "Example Item 3", "Example Item 4",
	"Example Item 5", "Example Item 6", "Example Item 7", "Example Item 8",
}

local function Percent(Value)
	return string.format("%.0f%%", Value)
end

local Example1 = ExampleTab:AddGroupbox({ Name = "Example 1", Side = "Left" })
local Example2 = ExampleTab:AddGroupbox({ Name = "Example 2", Side = "Right" })

Example1:AddLabel("Example Label. Labels wrap automatically and can be updated.")

local ExampleToggle = Example1:AddToggle({
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

Example1:AddToggle({ Name = "Example Toggle 2", Flag = "ExampleToggle2", Default = true })
Example1:AddToggle({ Name = "Example Toggle 3", Flag = "ExampleToggle3", Default = false })

Example1:AddDropdown({
	Name = "Example Dropdown",
	Flag = "ExampleDropdown",
	Options = ExampleOptions,
	Default = "Example Option 1",
	Callback = function(Value)
		print("Example Dropdown", Value)
	end,
})

Example1:AddMultiDropdown({
	Name = "Example Multi Dropdown",
	Flag = "ExampleMultiDropdown",
	Options = ExampleOptions,
	Default = { "Example Option 1" },
	Callback = function(Values)
		print("Example Multi Dropdown", table.concat(Values, ", "))
	end,
})

Example1:AddSearchDropdown({
	Name = "Example Search Dropdown",
	Flag = "ExampleSearchDropdown",
	Options = ExampleItems,
	Default = "Example Item 1",
})

Example1:AddButton({
	Name = "Example Button",
	Callback = function()
		Window:Notify("Example", "Example Button was pressed.", 3, "Success")
	end,
})

Example2:AddLabel("Example Label 2. Put as many groupboxes as you like in each column.")

Example2:AddSlider({
	Name = "Example Slider",
	Flag = "ExampleSlider",
	Min = 0,
	Max = 100,
	Default = 50,
	Format = Percent,
})

Example2:AddSlider({
	Name = "Example Slider 2",
	Flag = "ExampleSlider2",
	Min = 0,
	Max = 10,
	Default = 5,
})

Example2:AddRangeSlider({
	Name = "Example Range Slider",
	FlagMin = "ExampleRangeMin",
	FlagMax = "ExampleRangeMax",
	Min = 0,
	Max = 100,
	DefaultMin = 20,
	DefaultMax = 80,
})

Example2:AddColor({
	Name = "Example Color",
	Flag = "ExampleColor",
	Default = Color3.fromRGB(240, 84, 88),
	Callback = function(Color)
		print("Example Color", Color)
	end,
})

Example2:AddInput({
	Name = "Example Input",
	Flag = "ExampleInput",
	Placeholder = "Example placeholder",
	Callback = function(Value)
		print("Example Input", Value)
	end,
})

Example2:AddToggle({ Name = "Example Toggle 4", Flag = "ExampleToggle4", Default = true })

Example2:AddButton({
	Name = "Example Button 2",
	Callback = function()
		Window:Notify("Example", "Example Button 2 was pressed.", 3, "Info")
	end,
})

local Example3 = ExampleTab2:AddGroupbox({ Name = "Example 3", Side = "Left" })
local Example4 = ExampleTab2:AddGroupbox({ Name = "Example 4", Side = "Right" })

Example3:AddToggle({ Name = "Example Toggle 5", Flag = "ExampleToggle5", Default = false })
Example3:AddToggle({ Name = "Example Toggle 6", Flag = "ExampleToggle6", Default = false })
Example3:AddColor({ Name = "Example Color 2", Flag = "ExampleColor2", Default = Color3.fromRGB(255, 255, 255) })

Example4:AddSlider({
	Name = "Example Slider 3",
	Flag = "ExampleSlider3",
	Min = 40,
	Max = 120,
	Default = 70,
})

Example4:AddToggle({ Name = "Example Toggle 7", Flag = "ExampleToggle7", Default = false })

Window:AddKeybind("Example Toggle", "Toggle", function() return ExampleToggle.Get() end)
Window:AddKeybind("Example Toggle 2", "Toggle", function() return Window.Flags.ExampleToggle2 end)

Window:ConfigManager()
Window:SettingManager()
Window:SearchManager()
Window:KeybindList()
