local ConcordeLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Ali-lov3/ConcordeLib/refs/heads/main/ConcordeLib.lua"))()

local Example = ConcordeLib.new({
    Logo       = "rbxassetid://10723415903",
    Accent     = Color3.fromRGB(240, 45, 70),
    Background = Color3.fromRGB(11, 12, 16),
    Sidebar    = Color3.fromRGB(14, 15, 20),
    TextColor  = Color3.fromRGB(240, 240, 245),
    Subtitle   = "Example Subtitle",
    Keybind    = Enum.KeyCode.RightShift
})

local ExampleTab1 = Example:AddTab("swords", "Example Tab 1")
local ExampleTab2 = Example:AddTab("eye", "Example Tab 2")
local ExampleTab3 = Example:AddTab("user", "Example Tab 3")
local ExampleTab4 = Example:AddTab("layers", "Example Tab 4")
local ExampleTab5 = Example:AddTab("settings", "Example Tab 5")

local ExampleCol1, ExampleCol2 = ExampleTab1:AddSubPage("Example SubPage 1")

local ExampleTitle1 = Example:Title("Example Title 1", ExampleCol1)
local ExampleToggle1 = Example:Toggle("Example Toggle 1", false, ExampleCol1, { keybind = "E", color = Color3.fromRGB(240, 45, 70) })
local ExampleToggle2 = Example:Toggle("Example Toggle 2", true, ExampleCol1)
local ExampleToggle3 = Example:Toggle("Example Toggle 3", false, ExampleCol1)
local ExampleToggle4 = Example:Toggle("Example Toggle 4", false, ExampleCol1, { keybind = "Q" })
local ExampleDropdown1 = Example:Dropdown("Example Dropdown 1", "Example 1", {"Example 1", "Example 2", "Example 3"}, ExampleCol1)
local ExampleDropdown2 = Example:Dropdown("Example Dropdown 2", "Example 1", {"Example 1", "Example 2", "Example 3"}, ExampleCol1)
local ExampleSlider1 = Example:Slider("Example Slider 1", "°", ExampleCol1, 10, 360, 180)
local ExampleSlider2 = Example:Slider("Example Slider 2", "m", ExampleCol1, 50, 2000, 500)
local ExampleButton1 = Example:Button("Example Button 1", ExampleCol1, function() Example:Notify("Example Notification!") end)

local ExampleTitle2 = Example:Title("Example Title 2", ExampleCol2)
local ExampleToggle5 = Example:Toggle("Example Toggle 5", true, ExampleCol2, { color = Color3.fromRGB(0, 170, 255) })
local ExampleSlider3 = Example:Slider("Example Slider 3", "", ExampleCol2, 0, 1, 0.35)
local ExampleToggle6 = Example:Toggle("Example Toggle 6", true, ExampleCol2)
local ExampleRangeSlider1 = Example:RangeSlider("Example Range Slider 1", "", ExampleCol2, 0, 50, 8, 24)
local ExampleSlider4 = Example:Slider("Example Slider 4", "ms", ExampleCol2, 0, 500, 80)
local ExampleRangeSlider2 = Example:RangeSlider("Example Range Slider 2", "%", ExampleCol2, 0, 100, 60, 95)

local ExampleCol3, ExampleCol4 = ExampleTab1:AddSubPage("Example SubPage 2")

local ExampleTitle3 = Example:Title("Example Title 3", ExampleCol3)
local ExampleToggle7 = Example:Toggle("Example Toggle 7", false, ExampleCol3, { keybind = "V", color = Color3.fromRGB(255, 170, 0) })
local ExampleSlider5 = Example:Slider("Example Slider 5", "%", ExampleCol3, 0, 100, 100)

local ExampleCol5, ExampleCol6 = ExampleTab2:AddSubPage("Example SubPage 3")

local ExampleTitle4 = Example:Title("Example Title 4", ExampleCol5)
local ExampleToggle8 = Example:Toggle("Example Toggle 8", true, ExampleCol5, { color = Color3.fromRGB(255, 255, 255) })
local ExampleToggle9 = Example:Toggle("Example Toggle 9", false, ExampleCol5, { color = Color3.fromRGB(240, 45, 70) })
local ExampleToggle10 = Example:Toggle("Example Toggle 10", true, ExampleCol5)

local ExampleCol7, ExampleCol8 = ExampleTab2:AddSubPage("Example SubPage 4")

local ExampleTitle5 = Example:Title("Example Title 5", ExampleCol7)
local ExampleToggle11 = Example:Toggle("Example Toggle 11", true, ExampleCol7, { color = Color3.fromRGB(0, 255, 120) })

local ExampleCol9, ExampleCol10 = ExampleTab3:AddSubPage("Example SubPage 5")

local ExampleTitle6 = Example:Title("Example Title 6", ExampleCol9)
local ExampleToggle12 = Example:Toggle("Example Toggle 12", true, ExampleCol9)

local ExampleCol11, ExampleCol12 = ExampleTab4:AddSubPage("Example SubPage 6")

local ExampleTitle7 = Example:Title("Example Title 7", ExampleCol11)
local ExampleToggle13 = Example:Toggle("Example Toggle 13", false, ExampleCol11, { keybind = "Z" })
local ExampleToggle14 = Example:Toggle("Example Toggle 14", false, ExampleCol11, { keybind = "X" })

local ExampleCol13, ExampleCol14 = ExampleTab5:AddSubPage("Example SubPage 7")

local ExampleKeybindApply1 = Example:KeybindApply(ExampleCol13)
local ExampleThemeSettings1 = Example:ThemeSettingsApply(ExampleCol13, ExampleCol14)
local ExampleConfigApply1 = Example:ConfigApply(ExampleCol14, ExampleCol14, "ExampleConfigFolder")
