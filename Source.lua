local Library = {}

local Lucide
pcall(function()
	Lucide = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/icons.lua"))()
end)

local function ResolveIcon(Icon)
	if type(Icon) == "number" then return "rbxassetid://" .. Icon end
	if type(Icon) == "string" then
		if string.match(Icon, "^rbxassetid://") then return Icon end
		if string.match(Icon, "^%d+$") then return "rbxassetid://" .. Icon end
		local Name = string.lower(Icon)
		if type(Lucide) == "function" then
			local ok, Data = pcall(Lucide, Name)
			if ok and type(Data) == "table" then
				local Id = Data.id or Data.Id or Data[1]
				local Size = Data.imageRectSize or Data.ImageRectSize or Data[2]
				local Offset = Data.imageRectOffset or Data.imageRectPosition or Data.ImageRectOffset or Data[3]
				if Id then return "rbxassetid://" .. tostring(Id), Offset, Size end
			end
		elseif type(Lucide) == "table" then
			for _, Set in { Lucide["48px"], Lucide["256px"], Lucide } do
				if type(Set) == "table" then
					local Data = Set[Name]
					if type(Data) == "table" and Data[1] then
						return "rbxassetid://" .. tostring(Data[1]), Data[3], Data[2]
					end
				end
			end
		end
	end
	return "rbxassetid://0"
end

local function PickIcon(Names)
	for _, Name in ipairs(Names) do
		local Id = ResolveIcon(Name)
		if Id ~= "rbxassetid://0" then return Name end
	end
	return Names[1]
end

local function ToVector2(Value)
	if typeof(Value) == "Vector2" then return Value end
	if type(Value) == "table" then return Vector2.new(Value[1] or Value.X or 0, Value[2] or Value.Y or 0) end
	return Vector2.new(0, 0)
end

local function ApplyIcon(Object, Icon)
	if not Icon then return end
	local Image, Offset, Size = ResolveIcon(Icon)
	Object.Image = Image
	if Offset then Object.ImageRectOffset = ToVector2(Offset) end
	if Size then Object.ImageRectSize = ToVector2(Size) end
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local BaseTheme = {
	Window = Color3.fromRGB(15, 16, 21),
	Panel = Color3.fromRGB(18, 19, 25),
	Section = Color3.fromRGB(22, 23, 30),
	Field = Color3.fromRGB(28, 29, 37),
	Track = Color3.fromRGB(40, 41, 52),
	Stroke = Color3.fromRGB(34, 35, 44),
	Accent = Color3.fromRGB(240, 84, 88),
	Text = Color3.fromRGB(238, 239, 243),
	Dim = Color3.fromRGB(100, 103, 117),
	IconDim = Color3.fromRGB(135, 138, 152),
	Placeholder = Color3.fromRGB(88, 91, 105),
	Knob = Color3.fromRGB(107, 110, 124),
	White = Color3.fromRGB(255, 255, 255),
}

local KindColors = {
	Success = Color3.fromRGB(80, 220, 140),
	Warning = Color3.fromRGB(255, 200, 70),
	Error = Color3.fromRGB(240, 84, 88),
}

local KindIcons = {
	Info = { "info" },
	Success = { "check-circle", "circle-check", "check" },
	Warning = { "alert-triangle", "triangle-alert", "alert-circle" },
	Error = { "x-circle", "circle-x", "x" },
}

local FontPath = "rbxasset://fonts/families/GothamSSm.json"
local function Face(Weight)
	return Font.new(FontPath, Enum.FontWeight[Weight or "Regular"])
end

local function New(Class, Props, Children)
	local Object = Instance.new(Class)
	for Key, Value in pairs(Props) do
		if Key ~= "Parent" then Object[Key] = Value end
	end
	if Children then
		for _, Child in ipairs(Children) do Child.Parent = Object end
	end
	if Props.Parent then Object.Parent = Props.Parent end
	return Object
end

local function Corner(Radius)
	return New("UICorner", { CornerRadius = UDim.new(0, Radius) })
end

local function Full()
	return New("UICorner", { CornerRadius = UDim.new(1, 0) })
end

local function Stroke(Color, Thickness, Transparency)
	return New("UIStroke", {
		Color = Color,
		Thickness = Thickness or 1,
		Transparency = Transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function Grad(A, B, Rotation)
	return New("UIGradient", { Color = ColorSequence.new(A, B), Rotation = Rotation or 90 })
end

local function Tween(Object, Props, Time)
	TweenService:Create(Object, TweenInfo.new(Time or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), Props):Play()
end

local function Text(Parent, Content, Size, Color, Weight, Align)
	return New("TextLabel", {
		BackgroundTransparency = 1,
		Text = Content,
		TextSize = Size,
		TextColor3 = Color,
		FontFace = Face(Weight),
		TextXAlignment = Align or Enum.TextXAlignment.Left,
		Size = UDim2.fromScale(1, 1),
		Parent = Parent,
	})
end

local function Icon(Parent, Name, Size, Color, Position, Anchor)
	local Image = New("ImageLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(Size, Size),
		ImageColor3 = Color,
		AnchorPoint = Anchor or Vector2.zero,
		Position = Position or UDim2.new(),
		Parent = Parent,
	})
	ApplyIcon(Image, Name)
	return Image
end

local Counter = 0
local function Next()
	Counter += 1
	return Counter
end

local function IsPress(Input)
	return Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch
end

local function IsMove(Input)
	return Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch
end

local YOffsets = {}

local function ScreenPos(Input, Target)
	local Kind = Input.UserInputType == Enum.UserInputType.Touch and "Touch" or "Mouse"
	local Inset = GuiService:GetGuiInset()
	local RawY = Input.Position.Y
	if Target then
		local Top = Target.AbsolutePosition.Y
		local Bottom = Top + Target.AbsoluteSize.Y
		local InPlain = RawY >= Top and RawY <= Bottom
		local InShifted = RawY + Inset.Y >= Top and RawY + Inset.Y <= Bottom
		if InPlain and not InShifted then
			YOffsets[Kind] = 0
		elseif InShifted and not InPlain then
			YOffsets[Kind] = Inset.Y
		end
	end
	local OffsetY = YOffsets[Kind]
	if OffsetY == nil then
		OffsetY = Kind == "Touch" and 0 or Inset.Y
	end
	return Vector2.new(Input.Position.X, RawY + OffsetY)
end

local function BindDrag2D(Target, OnUpdate)
	local Dragging = false
	local Active = nil
	Target.InputBegan:Connect(function(Input)
		if IsPress(Input) and not Dragging then
			Dragging = true
			Active = Input
			OnUpdate(ScreenPos(Input, Target))
		end
	end)
	UserInputService.InputChanged:Connect(function(Input)
		if not Dragging then return end
		if Input.UserInputType == Enum.UserInputType.Touch then
			if Input == Active then OnUpdate(ScreenPos(Input)) end
		elseif Input.UserInputType == Enum.UserInputType.MouseMovement then
			OnUpdate(ScreenPos(Input))
		end
	end)
	UserInputService.InputEnded:Connect(function(Input)
		if Dragging and IsPress(Input) and (Input == Active or Input.UserInputType == Enum.UserInputType.MouseButton1) then
			Dragging = false
			Active = nil
		end
	end)
end

local function Snap(Value, Step)
	return math.floor(Value / Step + 0.5) * Step
end

local function Trim(Value)
	return string.match(tostring(Value or ""), "^%s*(.-)%s*$")
end

local function Short(Value)
	return tostring(math.floor(Value * 1000 + 0.5) / 1000)
end

local TrackW, TrackH, TrackPad = 142, 18, 9

local function KnobX(Alpha)
	return UDim2.new(Alpha, TrackPad * (1 - 2 * Alpha), 0.5, 0)
end

local function NewKnob(Track)
	return New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = BaseTheme.White,
		ZIndex = 2,
		Parent = Track,
	}, { Full() })
end

function Library:CreateWindow(Options)
	Options = Options or {}

	local TitleText = Options.Title or "ConcordeLib"
	local LogoIcon = Options.Logo or "hexagon"
	local Folder = Options.ConfigFolder or "ConcordeLib"
	local ConfigFolder = Folder .. "/configs"
	local MetaPath = Folder .. "/meta.json"
	local MenuKey = Options.OpenKey or Enum.KeyCode.RightShift
	if type(MenuKey) == "string" then
		local ok, Key = pcall(function() return Enum.KeyCode[MenuKey] end)
		MenuKey = ok and Key or Enum.KeyCode.RightShift
	end

	local Theme = table.clone(BaseTheme)

	local Config = {
		_Watermark = Options.Watermark ~= false,
		_GuiScale = 100,
		_Accent = Theme.Accent,
		Notifications = true,
	}

	local Window = {}
	local Methods = {}
	local Registry = {}
	local SearchIndex = {}
	local Tabs = {}
	local Columns = {}
	local ChangeHook
	local KeybindRefresh

	local function NotifyChange()
		if ChangeHook then ChangeHook() end
		if KeybindRefresh then KeybindRefresh() end
	end

	local AccentTargets = {}
	local AccentHooks = {}

	local function Accented(Object, Property)
		table.insert(AccentTargets, { Object, Property })
		Object[Property] = Theme.Accent
		return Object
	end

	local function OnAccent(Fn)
		table.insert(AccentHooks, Fn)
	end

	local function SetAccent(Color, Instant)
		Theme.Accent = Color
		Config._Accent = Color
		for _, Target in ipairs(AccentTargets) do
			local Object, Property = Target[1], Target[2]
			if Object.Parent then
				if Instant then
					Object[Property] = Color
				else
					Tween(Object, { [Property] = Color }, 0.15)
				end
			end
		end
		for _, Fn in ipairs(AccentHooks) do Fn(Color) end
	end

	local GuiName = "ConcordeLib_" .. Folder

	local Gui = New("ScreenGui", {
		Name = GuiName,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
	})
	pcall(function()
		Gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
	end)
	if not Gui.Parent then
		Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end

	for _, Holder in ipairs({ Gui.Parent, LocalPlayer:FindFirstChild("PlayerGui") }) do
		pcall(function()
			for _, Child in ipairs(Holder:GetChildren()) do
				if Child ~= Gui and Child.Name == GuiName then Child:Destroy() end
			end
		end)
	end

	local BaseW, BaseH = 780, 517

	local Root = New("Frame", {
		Name = "Root",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.56),
		Size = UDim2.fromOffset(BaseW, BaseH),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = Gui,
	})

	local Scale = New("UIScale", { Parent = Root })

	local WindowStroke = Stroke(Theme.White, 1)
	Grad(Color3.fromRGB(46, 47, 60), Theme.Stroke, 90).Parent = WindowStroke

	local Frame = New("Frame", {
		Name = "Window",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.White,
		BorderSizePixel = 0,
		Parent = Root,
	}, {
		Corner(20),
		WindowStroke,
		Grad(Color3.fromRGB(19, 20, 27), Color3.fromRGB(13, 14, 19), 90),
	})

	local HudValue = 1
	local HudScales = {}

	local function Rescale()
		local Camera = Workspace.CurrentCamera
		if not Camera then return end
		local View = Camera.ViewportSize
		local Fit = math.clamp(math.min(View.X * 0.9 / BaseW, View.Y * 0.82 / BaseH), 0.3, 1.25)
		Scale.Scale = math.clamp(Fit * (Config._GuiScale / 100), 0.3, 2)
		HudValue = math.clamp(math.min(View.X / 900, View.Y / 450), 0.75, 1.15)
		for _, Object in ipairs(HudScales) do Object.Scale = HudValue end
	end

	local function AddHudScale(Parent)
		local Object = New("UIScale", { Scale = HudValue, Parent = Parent })
		table.insert(HudScales, Object)
	end

	Rescale()
	if Workspace.CurrentCamera then
		Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(Rescale)
	end

	local function MakeDraggable(Handle, Target)
		local Dragging, Start, Origin
		Handle.InputBegan:Connect(function(Input)
			if IsPress(Input) then
				Dragging = true
				Start = Input.Position
				Origin = Target.Position
				Input.Changed:Connect(function()
					if Input.UserInputState == Enum.UserInputState.End then Dragging = false end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(Input)
			if Dragging and IsMove(Input) then
				local Delta = (Input.Position - Start) / Scale.Scale
				Target.Position = UDim2.new(Origin.X.Scale, Origin.X.Offset + Delta.X, Origin.Y.Scale, Origin.Y.Offset + Delta.Y)
			end
		end)
	end

	local OpenPopup = nil

	local Catcher = New("TextButton", {
		Name = "Catcher",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(20000, 20000),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		ZIndex = 25,
		Parent = Root,
	})

	local function ClosePopup()
		if OpenPopup then
			OpenPopup.Frame.Visible = false
			if OpenPopup.OnClose then OpenPopup.OnClose() end
			OpenPopup = nil
		end
		Catcher.Visible = false
	end
	Catcher.Activated:Connect(ClosePopup)

	local function NewContainer(Parent, Extra)
		local Container = Extra or {}
		Container.Frame = Parent
		return setmetatable(Container, { __index = Methods })
	end

	local function MakePopup(Width, Heading, Gap)
		local Pop = New("Frame", {
			Size = UDim2.fromOffset(Width, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Theme.White,
			BorderSizePixel = 0,
			Active = true,
			Visible = false,
			ZIndex = 30,
			Parent = Root,
		}, {
			Corner(10),
			Stroke(Theme.Stroke, 1),
			Grad(Color3.fromRGB(31, 32, 41), Color3.fromRGB(23, 24, 31), 90),
			New("UIPadding", {
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}),
			New("UIListLayout", { Padding = UDim.new(0, Gap or 6), SortOrder = Enum.SortOrder.LayoutOrder }),
		})
		if Heading then
			local Head = Text(Pop, Heading, 13, Theme.Text, "Medium")
			Head.LayoutOrder = 0
			Head.Size = UDim2.new(1, 0, 0, 22)
		end
		return Pop, NewContainer(Pop, { Compact = true })
	end

	local function TogglePopup(Pop, Anchor, OnClose)
		if OpenPopup and OpenPopup.Frame == Pop then
			ClosePopup()
			return false
		end
		ClosePopup()
		local S = Scale.Scale
		local RootPos = Root.AbsolutePosition
		local Right = (Anchor.AbsolutePosition.X + Anchor.AbsoluteSize.X - RootPos.X) / S
		local Top = (Anchor.AbsolutePosition.Y - RootPos.Y) / S
		local Bottom = (Anchor.AbsolutePosition.Y + Anchor.AbsoluteSize.Y - RootPos.Y) / S
		local Up = (Top + Bottom) / 2 > BaseH * 0.5
		Pop.AnchorPoint = Vector2.new(1, Up and 1 or 0)
		Pop.Position = UDim2.fromOffset(math.max(Right, Pop.Size.X.Offset + 8), Up and (Top - 6) or (Bottom + 6))
		Pop.Visible = true
		Catcher.Visible = true
		OpenPopup = { Frame = Pop, OnClose = OnClose }
		return true
	end

	local Sidebar = New("Frame", {
		Size = UDim2.new(0, 86, 1, 0),
		BackgroundTransparency = 1,
		Parent = Frame,
	})
	MakeDraggable(Sidebar, Root)

	Icon(Sidebar, LogoIcon, 44, Theme.White, UDim2.fromOffset(21, 20))

	local MainStroke = Stroke(Theme.White, 1)
	Grad(Color3.fromRGB(46, 47, 60), Theme.Stroke, 90).Parent = MainStroke

	local Main = New("Frame", {
		Position = UDim2.fromOffset(86, 15),
		Size = UDim2.new(1, -102, 1, -30),
		BackgroundColor3 = Theme.White,
		BorderSizePixel = 0,
		Parent = Frame,
	}, {
		Corner(10),
		MainStroke,
		Grad(Color3.fromRGB(21, 22, 29), Color3.fromRGB(15, 16, 22), 90),
	})

	local Header = New("Frame", {
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundTransparency = 1,
		Parent = Main,
	})
	MakeDraggable(Header, Root)

	local Title = Text(Header, TitleText, 14, Theme.Text, "Medium")
	Title.Position = UDim2.fromOffset(12, 6)
	Title.Size = UDim2.new(1, -170, 0, 20)
	Title.TextTruncate = Enum.TextTruncate.AtEnd

	local Subtitle = Text(Header, "", 12, Theme.Dim, "Regular")
	Subtitle.Position = UDim2.fromOffset(12, 22)
	Subtitle.Size = UDim2.new(1, -170, 0, 18)
	Subtitle.TextTruncate = Enum.TextTruncate.AtEnd

	New("Frame", {
		Position = UDim2.fromOffset(0, 50),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Theme.Stroke,
		BorderSizePixel = 0,
		Parent = Main,
	})

	local PageHolder = New("Frame", {
		Position = UDim2.fromOffset(0, 51),
		Size = UDim2.new(1, 0, 1, -51),
		BackgroundTransparency = 1,
		Parent = Main,
	})

	local Tools = New("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 11),
		Size = UDim2.fromOffset(0, 28),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = Main,
	}, {
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}),
	})

	local function FitTitle()
		local Width = Tools.AbsoluteSize.X / math.max(Scale.Scale, 0.01) + 28
		Title.Size = UDim2.new(1, -Width, 0, 20)
		Subtitle.Size = UDim2.new(1, -Width, 0, 18)
	end
	Tools:GetPropertyChangedSignal("AbsoluteSize"):Connect(FitTitle)
	FitTitle()

	local function ToolButton(Order, Names, Tint)
		local Button = New("TextButton", {
			LayoutOrder = Order,
			Size = UDim2.fromOffset(28, 28),
			BackgroundColor3 = Theme.Field,
			AutoButtonColor = false,
			Text = "",
			ZIndex = 5,
			Parent = Tools,
		}, { Corner(7) })
		local Glyph = Icon(Button, PickIcon(Names), 16, Tint or Theme.IconDim, UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
		Glyph.ZIndex = 5
		return Button, Glyph
	end

	local function PopupTool(Order, Names, Pop, Hooks)
		Hooks = Hooks or {}
		local Button, Glyph = ToolButton(Order, Names)
		Button.MouseEnter:Connect(function()
			if not (OpenPopup and OpenPopup.Frame == Pop) then Tween(Glyph, { ImageColor3 = Theme.Text }) end
		end)
		Button.MouseLeave:Connect(function()
			if not (OpenPopup and OpenPopup.Frame == Pop) then Tween(Glyph, { ImageColor3 = Theme.IconDim }) end
		end)
		Button.MouseButton1Click:Connect(function()
			if Hooks.Before then Hooks.Before() end
			local Opened = TogglePopup(Pop, Button, function()
				Tween(Glyph, { ImageColor3 = Theme.IconDim })
				if Hooks.Spin then Tween(Glyph, { Rotation = 0 }, 0.2) end
				if Hooks.Close then Hooks.Close() end
			end)
			if Opened then
				Tween(Glyph, { ImageColor3 = Theme.Accent })
				if Hooks.Spin then Tween(Glyph, { Rotation = 60 }, 0.2) end
				if Hooks.Open then Hooks.Open() end
			end
		end)
		return Button, Glyph
	end

	local function AddSearch(Container, Name, Object)
		if not Container.Scroller or not Container.Section then return end
		table.insert(SearchIndex, {
			Name = Name,
			Kind = "Option",
			Object = Object,
			Scroller = Container.Scroller,
			Page = Container.Page,
			Mode = Container.Mode,
			Reveal = Container.Reveal,
			Path = Container.Mode .. " / " .. Container.Section,
		})
	end

	local function MakeRow(Container, Height, Name)
		local Row = New("Frame", {
			LayoutOrder = Next(),
			Size = UDim2.new(1, 0, 0, Height or 24),
			BackgroundTransparency = 1,
			Parent = Container.Frame,
		})
		if Name then AddSearch(Container, Name, Row) end
		return Row
	end

	local function Block(Container, Name)
		local Holder = New("Frame", {
			LayoutOrder = Next(),
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Parent = Container.Frame,
		}, {
			New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
			New("UIPadding", { PaddingBottom = UDim.new(0, 8) }),
		})
		AddSearch(Container, Name, Holder)
		local Caption = Text(Holder, Name, 13, Theme.Dim, "Regular")
		Caption.LayoutOrder = 1
		Caption.Size = UDim2.new(1, 0, 0, 18)
		return Holder
	end

	local function Handle(Key, Setter)
		return {
			Set = Setter,
			Get = function() return Config[Key] end,
		}
	end

	local function AlphaFrom(X, Track)
		local S = Scale.Scale
		local Width = math.max(Track.AbsoluteSize.X - TrackPad * 2 * S, 1)
		return math.clamp((X - Track.AbsolutePosition.X - TrackPad * S) / Width, 0, 1)
	end

	local function BindDrag(Track, Container, OnUpdate, OnBegin)
		local Dragging = false
		local function Lock(State)
			local Target = Container.Scroller
			if Target and Target:IsA("ScrollingFrame") then Target.ScrollingEnabled = not State end
		end
		Track.InputBegan:Connect(function(Input)
			if IsPress(Input) then
				Dragging = true
				Lock(true)
				if OnBegin then OnBegin(Input.Position.X) end
				OnUpdate(Input.Position.X)
			end
		end)
		UserInputService.InputChanged:Connect(function(Input)
			if Dragging and IsMove(Input) then OnUpdate(Input.Position.X) end
		end)
		UserInputService.InputEnded:Connect(function(Input)
			if Dragging and IsPress(Input) then
				Dragging = false
				Lock(false)
			end
		end)
	end

	local function SliderBase(Container, Name)
		local Forced = Container.Compact == true
		local Row = MakeRow(Container, Forced and 44 or 24, Name)
		local Caption = Text(Row, Name, 13, Theme.Dim, "Regular")
		Caption.TextTruncate = Enum.TextTruncate.AtEnd
		local Value = Text(Row, "", 13, Theme.Text, "Medium", Enum.TextXAlignment.Right)
		Value.ZIndex = 2
		local Track = New("Frame", {
			BackgroundColor3 = Theme.Track,
			Parent = Row,
		}, { Full() })

		local Stacked = nil
		local function Layout(Stack)
			if Stack == Stacked then return end
			Stacked = Stack
			if Stack then
				Row.Size = UDim2.new(1, 0, 0, 44)
				Caption.Size = UDim2.new(1, -80, 0, 20)
				Value.AnchorPoint = Vector2.new(1, 0)
				Value.Position = UDim2.new(1, 0, 0, 0)
				Value.Size = UDim2.fromOffset(72, 20)
				Track.AnchorPoint = Vector2.new(0, 1)
				Track.Position = UDim2.new(0, 0, 1, 0)
				Track.Size = UDim2.new(1, 0, 0, TrackH)
			else
				Row.Size = UDim2.new(1, 0, 0, 24)
				Value.AnchorPoint = Vector2.new(1, 0.5)
				Value.Position = UDim2.new(1, -(TrackW + 12), 0.5, 0)
				Value.Size = UDim2.fromOffset(72, 24)
				Track.AnchorPoint = Vector2.new(1, 0.5)
				Track.Position = UDim2.new(1, 0, 0.5, 0)
				Track.Size = UDim2.fromOffset(TrackW, TrackH)
			end
		end

		local function Evaluate()
			if Forced then
				Layout(true)
				return
			end
			local Available = Row.AbsoluteSize.X / math.max(Scale.Scale, 0.01)
			if Available <= 0 then
				Layout(false)
				Caption.Size = UDim2.new(1, -(TrackW + 12 + 80), 1, 0)
				return
			end
			local Need = Caption.TextBounds.X + Value.TextBounds.X + TrackW + 12 + 14
			local Stack = Need > Available
			Layout(Stack)
			if not Stack then
				Caption.Size = UDim2.new(1, -(TrackW + 12 + Value.TextBounds.X + 8), 1, 0)
			end
		end

		Layout(Forced)
		if not Forced then
			Layout(false)
			Caption.Size = UDim2.new(1, -(TrackW + 12 + 80), 1, 0)
			Row:GetPropertyChangedSignal("AbsoluteSize"):Connect(Evaluate)
			Value:GetPropertyChangedSignal("Text"):Connect(Evaluate)
			Caption:GetPropertyChangedSignal("TextBounds"):Connect(Evaluate)
			Value:GetPropertyChangedSignal("TextBounds"):Connect(Evaluate)
		end

		local Fill = New("Frame", {
			BackgroundColor3 = Theme.Accent,
			Size = UDim2.fromOffset(0, TrackH),
			Parent = Track,
		}, {
			Full(),
			Grad(Color3.fromRGB(255, 255, 255), Color3.fromRGB(215, 180, 180), 90),
			New("UISizeConstraint", { MinSize = Vector2.new(TrackH, 0) }),
		})
		Accented(Fill, "BackgroundColor3")
		return Value, Track, Fill
	end

	local function BuildPicker(Pop, Start, OnChange, SVHeight)
		local H, S, V = Start:ToHSV()

		local SV = New("Frame", {
			LayoutOrder = Next(),
			Size = UDim2.new(1, 0, 0, SVHeight or 120),
			BackgroundColor3 = Color3.fromHSV(H, 1, 1),
			BorderSizePixel = 0,
			Active = true,
			Parent = Pop,
		}, { Corner(6) })
		New("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Theme.White,
			BorderSizePixel = 0,
			Parent = SV,
		}, {
			Corner(6),
			New("UIGradient", { Transparency = NumberSequence.new(0, 1), Rotation = 0 }),
		})
		New("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
			Parent = SV,
		}, {
			Corner(6),
			New("UIGradient", { Transparency = NumberSequence.new(1, 0), Rotation = 90 }),
		})
		local Cursor = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(12, 12),
			BackgroundTransparency = 1,
			ZIndex = 3,
			Parent = SV,
		}, { Full(), Stroke(Theme.White, 2) })

		local Hue = New("Frame", {
			LayoutOrder = Next(),
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundColor3 = Theme.White,
			BorderSizePixel = 0,
			Active = true,
			Parent = Pop,
		}, {
			Full(),
			New("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
					ColorSequenceKeypoint.new(1 / 6, Color3.fromHSV(1 / 6, 1, 1)),
					ColorSequenceKeypoint.new(2 / 6, Color3.fromHSV(2 / 6, 1, 1)),
					ColorSequenceKeypoint.new(3 / 6, Color3.fromHSV(3 / 6, 1, 1)),
					ColorSequenceKeypoint.new(4 / 6, Color3.fromHSV(4 / 6, 1, 1)),
					ColorSequenceKeypoint.new(5 / 6, Color3.fromHSV(5 / 6, 1, 1)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(0, 1, 1)),
				}),
			}),
		})
		local HueKnob = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = Theme.White,
			ZIndex = 2,
			Parent = Hue,
		}, { Full(), Stroke(Theme.Window, 2) })

		local Hex = New("TextBox", {
			LayoutOrder = Next(),
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundColor3 = Theme.Field,
			Text = "",
			PlaceholderText = "#RRGGBB",
			PlaceholderColor3 = Theme.Placeholder,
			TextColor3 = Theme.Text,
			TextSize = 13,
			FontFace = Face("Medium"),
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			Parent = Pop,
		}, { Corner(7), New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 30) }) })
		local Swatch = New("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			BackgroundColor3 = Start,
			Parent = Hex,
		}, { Full() })

		local function Refresh()
			local Color = Color3.fromHSV(H, S, V)
			SV.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
			Cursor.Position = UDim2.fromScale(S, 1 - V)
			HueKnob.Position = UDim2.new(H, 0, 0.5, 0)
			HueKnob.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
			Swatch.BackgroundColor3 = Color
			if not Hex:IsFocused() then Hex.Text = "#" .. string.upper(Color:ToHex()) end
			return Color
		end
		Refresh()

		BindDrag2D(SV, function(Pos)
			S = math.clamp((Pos.X - SV.AbsolutePosition.X) / math.max(SV.AbsoluteSize.X, 1), 0, 1)
			V = 1 - math.clamp((Pos.Y - SV.AbsolutePosition.Y) / math.max(SV.AbsoluteSize.Y, 1), 0, 1)
			OnChange(Refresh())
		end)
		BindDrag2D(Hue, function(Pos)
			H = math.clamp((Pos.X - Hue.AbsolutePosition.X) / math.max(Hue.AbsoluteSize.X, 1), 0, 0.999)
			OnChange(Refresh())
		end)
		Hex.FocusLost:Connect(function()
			local Code = string.gsub(Hex.Text, "[^%x]", "")
			if #Code == 3 then
				Code = Code:sub(1, 1):rep(2) .. Code:sub(2, 2):rep(2) .. Code:sub(3, 3):rep(2)
			end
			if #Code == 6 then
				local ok, Color = pcall(Color3.fromHex, Code)
				if ok then H, S, V = Color:ToHSV() end
			end
			OnChange(Refresh())
		end)

		return function(Color)
			H, S, V = Color:ToHSV()
			Refresh()
		end
	end

	function Methods:AddLabel(Content, Color, Weight)
		local Row = New("Frame", {
			LayoutOrder = Next(),
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Parent = self.Frame,
		}, {
			New("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }),
		})
		local Item = New("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = tostring(Content),
			TextWrapped = true,
			TextSize = 12,
			TextColor3 = Color or Theme.Dim,
			FontFace = Face(Weight or "Regular"),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Parent = Row,
		})
		return function(NewText, NewColor)
			if NewText ~= nil then Item.Text = tostring(NewText) end
			if NewColor then Item.TextColor3 = NewColor end
		end
	end

	function Methods:AddToggle(Opt)
		local Name = Opt.Name
		local Key = Opt.Flag or Name
		local Row = MakeRow(self, nil, Name)
		local Caption = Text(Row, Name, 13, Theme.Text, "Medium")
		Caption.Size = UDim2.new(1, -60, 1, 0)

		if Opt.Settings then
			local Gear = New("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -36, 0.5, 0),
				Size = UDim2.fromOffset(24, 24),
				BackgroundTransparency = 1,
				AutoButtonColor = false,
				Text = "",
				Parent = Row,
			})
			local Glyph = Icon(Gear, Opt.SettingsIcon or "settings", 16, Theme.IconDim, UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
			local Pop, PopContainer = MakePopup(214, Opt.SettingsTitle or (Name .. " settings"))
			Opt.Settings(PopContainer)
			Gear.MouseEnter:Connect(function()
				if not (OpenPopup and OpenPopup.Frame == Pop) then Tween(Glyph, { ImageColor3 = Theme.Text }) end
			end)
			Gear.MouseLeave:Connect(function()
				if not (OpenPopup and OpenPopup.Frame == Pop) then Tween(Glyph, { ImageColor3 = Theme.IconDim }) end
			end)
			Gear.MouseButton1Click:Connect(function()
				local Opened = TogglePopup(Pop, Gear, function()
					Tween(Glyph, { ImageColor3 = Theme.IconDim })
					Tween(Glyph, { Rotation = 0 }, 0.2)
				end)
				if Opened then
					Tween(Glyph, { ImageColor3 = Theme.Accent })
					Tween(Glyph, { Rotation = 60 }, 0.2)
				end
			end)
		end

		local Track = New("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(30, 16),
			AutoButtonColor = false,
			Text = "",
			BackgroundColor3 = Theme.Track,
			Parent = Row,
		}, { Full() })
		local Aura = Stroke(Theme.Accent, 2, 1)
		Aura.Parent = Track
		Accented(Aura, "Color")
		local Knob = New("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.fromOffset(12, 12),
			Position = UDim2.new(0, 2, 0.5, 0),
			BackgroundColor3 = Theme.Knob,
			ZIndex = 2,
			Parent = Track,
		}, { Full() })

		local State = Opt.Default == true
		local function Set(Value, Instant, Silent)
			State = Value
			local Time = Instant and 0 or 0.15
			Tween(Track, { BackgroundColor3 = State and Theme.Accent or Theme.Track }, Time)
			Tween(Aura, { Transparency = State and 0.65 or 1 }, Time)
			Tween(Knob, {
				Position = State and UDim2.new(0, 16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
				BackgroundColor3 = State and Theme.White or Theme.Knob,
			}, Time)
			Config[Key] = State
			if not Silent then
				if not Opt.Internal then NotifyChange() end
				if Opt.Callback then task.spawn(Opt.Callback, State) end
			end
		end
		Set(State, true, true)
		Track.MouseButton1Click:Connect(function() Set(not State) end)
		OnAccent(function(Color)
			if State then Track.BackgroundColor3 = Color end
		end)

		local function Setter(Value, Silent)
			Set(Value and true or false, false, Silent)
		end
		if not Opt.Internal then Registry[Key] = Setter end
		return Handle(Key, Setter)
	end

	function Methods:AddSlider(Opt)
		local Key = Opt.Flag or Opt.Name
		local Min, Max = Opt.Min or 0, Opt.Max or 100
		local Step = Opt.Step or 1
		local Format = Opt.Format or function(Number) return Short(Number) .. (Opt.Suffix or "") end
		local Value, Track, Fill = SliderBase(self, Opt.Name)
		local Knob = NewKnob(Track)
		local function Set(Number, Silent)
			Number = math.clamp(Snap(Number, Step), Min, Max)
			local A = (Number - Min) / (Max - Min)
			Fill.Size = UDim2.new(A, TrackPad * (2 - 2 * A), 0, TrackH)
			Knob.Position = KnobX(A)
			Value.Text = Format(Number)
			Config[Key] = Number
			if not Silent then
				NotifyChange()
				if Opt.Callback then task.spawn(Opt.Callback, Number) end
			end
		end
		Set(Opt.Default or Min, true)
		BindDrag(Track, self, function(X)
			Set(Min + AlphaFrom(X, Track) * (Max - Min))
		end)
		local function Setter(Number, Silent)
			if type(Number) == "number" then Set(Number, Silent) end
		end
		Registry[Key] = Setter
		return Handle(Key, Setter)
	end

	function Methods:AddRangeSlider(Opt)
		local KeyMin = Opt.FlagMin or (Opt.Name .. " Min")
		local KeyMax = Opt.FlagMax or (Opt.Name .. " Max")
		local Min, Max = Opt.Min or 0, Opt.Max or 100
		local Step = Opt.Step or 1
		local Format = Opt.Format or function(A, B) return Short(A) .. " - " .. Short(B) end
		local Value, Track, Fill = SliderBase(self, Opt.Name)
		local KnobLow = NewKnob(Track)
		local KnobHigh = NewKnob(Track)
		local Low, High = Opt.DefaultMin or Min, Opt.DefaultMax or Max
		local Active = "High"
		local function Render(Silent)
			local AL = (Low - Min) / (Max - Min)
			local AH = (High - Min) / (Max - Min)
			Fill.Position = UDim2.new(AL, TrackPad * (1 - 2 * AL) - TrackPad + 2, 0, 0)
			Fill.Size = UDim2.new(math.max(AH - AL, 0), 2 * TrackPad * (1 - math.max(AH - AL, 0)) - 4, 0, TrackH)
			KnobLow.Position = KnobX(AL)
			KnobHigh.Position = KnobX(AH)
			Value.Text = Format(Low, High)
			Config[KeyMin] = Low
			Config[KeyMax] = High
			if not Silent then
				NotifyChange()
				if Opt.Callback then task.spawn(Opt.Callback, Low, High) end
			end
		end
		Render(true)
		BindDrag(Track, self, function(X)
			local Number = math.clamp(Snap(Min + AlphaFrom(X, Track) * (Max - Min), Step), Min, Max)
			if Active == "Low" then
				Low = math.min(Number, High)
			else
				High = math.max(Number, Low)
			end
			Render()
		end, function(X)
			local Number = Min + AlphaFrom(X, Track) * (Max - Min)
			Active = math.abs(Number - Low) < math.abs(Number - High) and "Low" or "High"
			if Low == High then Active = Number < Low and "Low" or "High" end
		end)
		Registry[KeyMin] = function(Number, Silent)
			if type(Number) == "number" then
				Low = math.clamp(Snap(Number, Step), Min, Max)
				Render(Silent)
			end
		end
		Registry[KeyMax] = function(Number, Silent)
			if type(Number) == "number" then
				High = math.clamp(Snap(Number, Step), Min, Max)
				Render(Silent)
			end
		end
		return {
			Set = function(A, B, Silent)
				Low = math.clamp(Snap(A, Step), Min, Max)
				High = math.clamp(Snap(B, Step), Min, Max)
				Render(Silent)
			end,
			Get = function() return Low, High end,
		}
	end

	function Methods:AddDropdown(Opt)
		local Key = Opt.Flag or Opt.Name
		local Options = Opt.Options or {}
		local Default = table.find(Options, Opt.Default) and Opt.Default or Options[1] or ""
		local Holder = Block(self, Opt.Name)
		local Box = New("Frame", {
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = Theme.White,
			ClipsDescendants = true,
			Parent = Holder,
		}, { Corner(8), Grad(Color3.fromRGB(32, 33, 42), Color3.fromRGB(25, 26, 34), 90) })
		local Head = New("TextButton", {
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundTransparency = 1,
			Text = "",
			Parent = Box,
		})
		local Current = Text(Head, Default, 13, Theme.Text, "Medium")
		Current.Position = UDim2.fromOffset(11, 0)
		Current.Size = UDim2.new(1, -40, 1, 0)
		local Chevron = Icon(Head, "chevron-down", 14, Theme.IconDim, UDim2.new(1, -16, 0.5, 0), Vector2.new(0.5, 0.5))
		local List = New("Frame", {
			Position = UDim2.fromOffset(0, 32),
			Size = UDim2.new(1, 0, 0, #Options * 26),
			BackgroundTransparency = 1,
			Parent = Box,
		}, { New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }) })

		local Open = false
		local function SetOpen(State)
			Open = State
			Tween(Box, { Size = UDim2.new(1, 0, 0, State and (32 + #Options * 26) or 32) })
			Tween(Chevron, { Rotation = State and 180 or 0 })
		end

		local function SetValue(Value, Silent)
			Current.Text = Value
			Config[Key] = Value
			if not Silent then
				NotifyChange()
				if Opt.Callback then task.spawn(Opt.Callback, Value) end
			end
		end

		for Index, Entry in ipairs(Options) do
			local Item = New("TextButton", {
				LayoutOrder = Index,
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundTransparency = 1,
				AutoButtonColor = false,
				Text = "",
				Parent = List,
			})
			local ItemLabel = Text(Item, Entry, 13, Theme.Dim, "Regular")
			ItemLabel.Position = UDim2.fromOffset(11, 0)
			ItemLabel.Size = UDim2.new(1, -11, 1, 0)
			Item.MouseEnter:Connect(function() Tween(ItemLabel, { TextColor3 = Theme.Text }) end)
			Item.MouseLeave:Connect(function() Tween(ItemLabel, { TextColor3 = Theme.Dim }) end)
			Item.MouseButton1Click:Connect(function()
				SetValue(Entry)
				SetOpen(false)
			end)
		end

		Config[Key] = Default
		Head.MouseButton1Click:Connect(function() SetOpen(not Open) end)
		local function Setter(Value, Silent)
			if table.find(Options, Value) then SetValue(Value, Silent) end
		end
		Registry[Key] = Setter
		return Handle(Key, Setter)
	end

	function Methods:AddMultiDropdown(Opt)
		local Key = Opt.Flag or Opt.Name
		local Options = Opt.Options or {}
		local RowH = 26
		local Holder = Block(self, Opt.Name)
		local Box = New("Frame", {
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = Theme.White,
			ClipsDescendants = true,
			Parent = Holder,
		}, { Corner(8), Grad(Color3.fromRGB(32, 33, 42), Color3.fromRGB(25, 26, 34), 90) })
		local Head = New("TextButton", {
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundTransparency = 1,
			Text = "",
			Parent = Box,
		})
		local Current = Text(Head, "None", 13, Theme.Text, "Medium")
		Current.Position = UDim2.fromOffset(11, 0)
		Current.Size = UDim2.new(1, -40, 1, 0)
		Current.TextTruncate = Enum.TextTruncate.AtEnd
		local Chevron = Icon(Head, "chevron-down", 14, Theme.IconDim, UDim2.new(1, -16, 0.5, 0), Vector2.new(0.5, 0.5))
		local List = New("Frame", {
			Position = UDim2.fromOffset(0, 32),
			Size = UDim2.new(1, 0, 0, #Options * RowH),
			BackgroundTransparency = 1,
			Parent = Box,
		}, { New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }) })

		local Picked = {}
		for _, Value in ipairs(Opt.Default or {}) do
			if table.find(Options, Value) then Picked[Value] = true end
		end

		local Open = false
		local Marks = {}

		local function Collect()
			local Result = {}
			for _, Entry in ipairs(Options) do
				if Picked[Entry] then table.insert(Result, Entry) end
			end
			return Result
		end

		local function Render()
			local Result = Collect()
			Current.Text = #Result > 0 and table.concat(Result, ", ") or "None"
			Current.TextColor3 = #Result > 0 and Theme.Text or Theme.Placeholder
			for Entry, UI in pairs(Marks) do
				local On = Picked[Entry] == true
				Tween(UI.Dot, { BackgroundTransparency = On and 0 or 1 })
				Tween(UI.Label, { TextColor3 = On and Theme.Text or Theme.Dim })
			end
			return Result
		end

		local function Commit(Silent)
			local Result = Render()
			Config[Key] = Result
			if not Silent then
				NotifyChange()
				if Opt.Callback then task.spawn(Opt.Callback, Result) end
			end
		end

		local function SetOpen(State)
			Open = State
			Tween(Box, { Size = UDim2.new(1, 0, 0, State and (32 + #Options * RowH) or 32) })
			Tween(Chevron, { Rotation = State and 180 or 0 })
		end

		for Index, Entry in ipairs(Options) do
			local Item = New("TextButton", {
				LayoutOrder = Index,
				Size = UDim2.new(1, 0, 0, RowH),
				BackgroundTransparency = 1,
				AutoButtonColor = false,
				Text = "",
				Parent = List,
			})
			local ItemLabel = Text(Item, Entry, 13, Theme.Dim, "Regular")
			ItemLabel.Position = UDim2.fromOffset(11, 0)
			ItemLabel.Size = UDim2.new(1, -44, 1, 0)
			ItemLabel.TextTruncate = Enum.TextTruncate.AtEnd
			local Check = New("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -11, 0.5, 0),
				Size = UDim2.fromOffset(16, 16),
				BackgroundColor3 = Theme.Track,
				BorderSizePixel = 0,
				Parent = Item,
			}, { Corner(4) })
			local Dot = New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(8, 8),
				BackgroundColor3 = Theme.Accent,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Parent = Check,
			}, { Corner(2) })
			Accented(Dot, "BackgroundColor3")
			Marks[Entry] = { Dot = Dot, Label = ItemLabel }
			Item.MouseEnter:Connect(function()
				if not Picked[Entry] then Tween(ItemLabel, { TextColor3 = Theme.Text }) end
			end)
			Item.MouseLeave:Connect(function()
				if not Picked[Entry] then Tween(ItemLabel, { TextColor3 = Theme.Dim }) end
			end)
			Item.MouseButton1Click:Connect(function()
				Picked[Entry] = not Picked[Entry] or nil
				Commit(false)
			end)
		end

		Commit(true)
		Head.MouseButton1Click:Connect(function() SetOpen(not Open) end)
		local function Setter(Value, Silent)
			if type(Value) ~= "table" then return end
			Picked = {}
			for _, Entry in ipairs(Value) do
				if table.find(Options, Entry) then Picked[Entry] = true end
			end
			Commit(Silent)
		end
		Registry[Key] = Setter
		return Handle(Key, Setter)
	end

	function Methods:AddSearchDropdown(Opt)
		local Key = Opt.Flag or Opt.Name
		local Holder = Block(self, Opt.Name)
		local RowH = 26
		local MaxRows = 5
		local Items = {}
		for _, Entry in ipairs(Opt.Options or {}) do table.insert(Items, tostring(Entry)) end
		local Shown = {}
		local Value = table.find(Items, Opt.Default) and Opt.Default or (Items[1] or "")
		local Open = false

		local Box = New("Frame", {
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = Theme.White,
			ClipsDescendants = true,
			Parent = Holder,
		}, { Corner(8), Grad(Color3.fromRGB(32, 33, 42), Color3.fromRGB(25, 26, 34), 90) })
		local Head = New("TextButton", {
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundTransparency = 1,
			Text = "",
			Parent = Box,
		})
		local Current = Text(Head, Value, 13, Theme.Text, "Medium")
		Current.Position = UDim2.fromOffset(11, 0)
		Current.Size = UDim2.new(1, -40, 1, 0)
		Current.TextTruncate = Enum.TextTruncate.AtEnd
		local Chevron = Icon(Head, "chevron-down", 14, Theme.IconDim, UDim2.new(1, -16, 0.5, 0), Vector2.new(0.5, 0.5))

		local SearchField = New("TextBox", {
			Position = UDim2.fromOffset(6, 36),
			Size = UDim2.new(1, -12, 0, 26),
			BackgroundColor3 = Theme.Field,
			Text = "",
			PlaceholderText = "Search...",
			PlaceholderColor3 = Theme.Placeholder,
			TextColor3 = Theme.Text,
			TextSize = 12,
			FontFace = Face("Medium"),
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			Parent = Box,
		}, { Corner(6), New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }) })
		local FieldStroke = Stroke(Theme.Accent, 1, 1)
		FieldStroke.Parent = SearchField
		Accented(FieldStroke, "Color")
		SearchField.Focused:Connect(function() Tween(FieldStroke, { Transparency = 0.5 }) end)
		SearchField.FocusLost:Connect(function() Tween(FieldStroke, { Transparency = 1 }) end)

		local List = New("ScrollingFrame", {
			Position = UDim2.fromOffset(0, 66),
			Size = UDim2.new(1, 0, 1, -66),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 0,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Parent = Box,
		}, { New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }) })

		local function OpenHeight()
			return 66 + math.max(1, math.min(#Shown, MaxRows)) * RowH + 4
		end

		local SetOpen
		local SetValue

		local function Rebuild()
			for _, Child in ipairs(List:GetChildren()) do
				if not Child:IsA("UIListLayout") then Child:Destroy() end
			end
			local Query = string.lower(Trim(SearchField.Text))
			Shown = {}
			for _, Entry in ipairs(Items) do
				if Query == "" or string.find(string.lower(Entry), Query, 1, true) then
					table.insert(Shown, Entry)
				end
			end
			if #Shown == 0 then
				local Empty = Text(List, "No results", 13, Theme.Dim, "Regular")
				Empty.Position = UDim2.fromOffset(11, 0)
				Empty.Size = UDim2.new(1, -11, 0, RowH)
			end
			for Index, Entry in ipairs(Shown) do
				local Item = New("TextButton", {
					LayoutOrder = Index,
					Size = UDim2.new(1, 0, 0, RowH),
					BackgroundTransparency = 1,
					AutoButtonColor = false,
					Text = "",
					Parent = List,
				})
				local ItemLabel = Text(Item, Entry, 13, Entry == Value and Theme.Text or Theme.Dim, "Regular")
				ItemLabel.Position = UDim2.fromOffset(11, 0)
				ItemLabel.Size = UDim2.new(1, -30, 1, 0)
				ItemLabel.TextTruncate = Enum.TextTruncate.AtEnd
				local Dot = New("Frame", {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -11, 0.5, 0),
					Size = UDim2.fromOffset(6, 6),
					BackgroundColor3 = Theme.Accent,
					BackgroundTransparency = Entry == Value and 0 or 1,
					BorderSizePixel = 0,
					Parent = Item,
				}, { Full() })
				Accented(Dot, "BackgroundColor3")
				Item.MouseEnter:Connect(function() Tween(ItemLabel, { TextColor3 = Theme.Text }) end)
				Item.MouseLeave:Connect(function()
					Tween(ItemLabel, { TextColor3 = Entry == Value and Theme.Text or Theme.Dim })
				end)
				Item.MouseButton1Click:Connect(function()
					SetValue(Entry)
					SetOpen(false)
				end)
			end
			if Open then Tween(Box, { Size = UDim2.new(1, 0, 0, OpenHeight()) }) end
		end

		SetOpen = function(State)
			Open = State
			if State then
				SearchField.Text = ""
				Rebuild()
				Tween(Box, { Size = UDim2.new(1, 0, 0, OpenHeight()) })
			else
				SearchField:ReleaseFocus()
				Tween(Box, { Size = UDim2.new(1, 0, 0, 32) })
			end
			Tween(Chevron, { Rotation = State and 180 or 0 })
		end

		SetValue = function(NewValue, Silent)
			Value = NewValue
			Current.Text = Value
			Config[Key] = Value
			if Open then Rebuild() end
			if not Silent then
				NotifyChange()
				if Opt.Callback then task.spawn(Opt.Callback, Value) end
			end
		end

		SearchField:GetPropertyChangedSignal("Text"):Connect(function()
			if Open then Rebuild() end
		end)
		Head.MouseButton1Click:Connect(function() SetOpen(not Open) end)

		Config[Key] = Value
		Rebuild()

		local function Setter(NewValue, Silent)
			if table.find(Items, NewValue) then SetValue(NewValue, Silent) end
		end
		Registry[Key] = Setter

		local Result = Handle(Key, Setter)
		Result.Refresh = function(NewOptions, NewDefault)
			Items = {}
			for _, Entry in ipairs(NewOptions) do table.insert(Items, tostring(Entry)) end
			if not table.find(Items, Value) then
				Value = table.find(Items, NewDefault) and NewDefault or (Items[1] or "")
				Current.Text = Value
				Config[Key] = Value
			end
			Rebuild()
		end
		return Result
	end

	function Methods:AddColor(Opt)
		local Key = Opt.Flag or Opt.Name
		local Row = MakeRow(self, nil, Opt.Name)
		local Caption = Text(Row, Opt.Name, 13, Theme.Text, "Medium")
		Caption.Size = UDim2.new(1, -40, 1, 0)

		local Start = Opt.Default or Theme.Accent
		Config[Key] = Start

		local Ring = New("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(20, 20),
			BackgroundColor3 = Start:Lerp(Color3.new(0, 0, 0), 0.55),
			AutoButtonColor = false,
			Text = "",
			Parent = Row,
		}, { Full() })
		local Aura = Stroke(Start, 3, 0.6)
		Aura.Parent = Ring
		local Dot = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(13, 13),
			BackgroundColor3 = Start,
			ZIndex = 2,
			Parent = Ring,
		}, { Full() })

		local function Apply(Color, Silent)
			Dot.BackgroundColor3 = Color
			Aura.Color = Color
			Ring.BackgroundColor3 = Color:Lerp(Color3.new(0, 0, 0), 0.55)
			Config[Key] = Color
			if not Silent then
				NotifyChange()
				if Opt.Callback then task.spawn(Opt.Callback, Color) end
			end
		end

		local Pop, PopContainer = MakePopup(214, Opt.Name)
		local SetPicker = BuildPicker(PopContainer.Frame, Start, function(Color)
			Apply(Color)
		end)

		local function Setter(Value, Silent)
			if typeof(Value) == "Color3" then
				SetPicker(Value)
				Apply(Value, Silent)
			end
		end
		Registry[Key] = Setter

		Ring.MouseButton1Click:Connect(function()
			TogglePopup(Pop, Ring)
		end)
		return Handle(Key, Setter)
	end

	function Methods:AddButton(Opt)
		local Holder = New("Frame", {
			LayoutOrder = Next(),
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = Theme.White,
			BorderSizePixel = 0,
			Parent = self.Frame,
		}, { Corner(8), Grad(Color3.fromRGB(32, 33, 42), Color3.fromRGB(25, 26, 34), 90) })
		AddSearch(self, Opt.Name, Holder)
		local Hit = New("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = Opt.Name,
			TextColor3 = Theme.Text,
			TextSize = 13,
			FontFace = Face("Medium"),
			ZIndex = 2,
			Parent = Holder,
		})
		local Rest = Color3.fromRGB(255, 255, 255)
		local Hover = Color3.fromRGB(205, 205, 218)
		Hit.MouseEnter:Connect(function() Tween(Holder, { BackgroundColor3 = Hover }) end)
		Hit.MouseLeave:Connect(function() Tween(Holder, { BackgroundColor3 = Rest }) end)
		Hit.MouseButton1Click:Connect(function()
			Holder.BackgroundColor3 = Color3.fromRGB(255, 170, 170)
			Tween(Holder, { BackgroundColor3 = Hover }, 0.25)
			if Opt.Callback then task.spawn(Opt.Callback) end
		end)
	end

	function Methods:AddInput(Opt)
		local Key = Opt.Flag or Opt.Name
		local Holder = Block(self, Opt.Name)
		local Box = New("TextBox", {
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = Theme.Field,
			Text = Opt.Default or "",
			PlaceholderText = Opt.Placeholder or "",
			PlaceholderColor3 = Theme.Placeholder,
			TextColor3 = Theme.Text,
			TextSize = 13,
			FontFace = Face("Medium"),
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			Parent = Holder,
		}, { Corner(8), New("UIPadding", { PaddingLeft = UDim.new(0, 11), PaddingRight = UDim.new(0, 11) }) })
		local BoxStroke = Stroke(Theme.Accent, 1, 1)
		BoxStroke.Parent = Box
		Accented(BoxStroke, "Color")
		Config[Key] = Box.Text
		Box.Focused:Connect(function() Tween(BoxStroke, { Transparency = 0.5 }) end)
		Box.FocusLost:Connect(function()
			Tween(BoxStroke, { Transparency = 1 })
			Config[Key] = Box.Text
			NotifyChange()
			if Opt.Callback then task.spawn(Opt.Callback, Box.Text) end
		end)
		local function Setter(Value, Silent)
			Box.Text = tostring(Value)
			Config[Key] = Box.Text
			if not Silent then
				NotifyChange()
				if Opt.Callback then task.spawn(Opt.Callback, Box.Text) end
			end
		end
		Registry[Key] = Setter
		return Handle(Key, Setter)
	end

	local WatermarkFrame = New("Frame", {
		Name = "Watermark",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 14),
		Size = UDim2.fromOffset(0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Theme.White,
		BorderSizePixel = 0,
		Visible = Config._Watermark,
		ZIndex = 10,
		Parent = Gui,
	}, {
		Corner(9),
		Stroke(Theme.Stroke, 1),
		Grad(Color3.fromRGB(27, 28, 36), Color3.fromRGB(17, 18, 24), 90),
		New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 12) }),
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}),
	})
	AddHudScale(WatermarkFrame)

	local function HudLabel(Content, Color, Weight, Order)
		return New("TextLabel", {
			LayoutOrder = Order,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 30),
			Text = Content,
			TextSize = 13,
			TextColor3 = Color,
			FontFace = Face(Weight),
			Parent = WatermarkFrame,
		})
	end

	local WIcon = Icon(WatermarkFrame, LogoIcon, 18, Theme.Accent)
	WIcon.LayoutOrder = 1
	Accented(WIcon, "ImageColor3")
	local WTitle = HudLabel(TitleText, Theme.Text, "Medium", 2)
	local function Separator(Order)
		return New("Frame", {
			LayoutOrder = Order,
			Size = UDim2.fromOffset(1, 14),
			BackgroundColor3 = Theme.Track,
			BorderSizePixel = 0,
			Parent = WatermarkFrame,
		})
	end
	Separator(3)
	local WFps = HudLabel("-- fps", Theme.Text, "Regular", 4)
	Separator(5)
	local WPing = HudLabel("-- ms", Theme.Text, "Regular", 6)

	local Frames, Clock = 0, os.clock()
	RunService.RenderStepped:Connect(function()
		Frames += 1
		local Now = os.clock()
		if Now - Clock >= 0.5 then
			local Fps = math.floor(Frames / (Now - Clock) + 0.5)
			Frames, Clock = 0, Now
			if WatermarkFrame.Visible then
				local Ping = 0
				local ok, Value = pcall(function()
					return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
				end)
				if ok and Value then
					Ping = Value
				else
					pcall(function() Ping = LocalPlayer:GetNetworkPing() * 2000 end)
				end
				WFps.Text = Fps .. " fps"
				WPing.Text = math.floor(Ping + 0.5) .. " ms"
			end
		end
	end)

	local NotifyHolder = New("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 58),
		Size = UDim2.fromOffset(290, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 10,
		Parent = Gui,
	}, {
		New("UIListLayout", {
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
		}),
	})
	AddHudScale(NotifyHolder)

	local function Notify(Head, Body, Duration, Kind, IconName)
		if type(Head) == "table" then
			local Data = Head
			Head, Body, Duration = Data.Title or Data.Head, Data.Text or Data.Body, Data.Duration
			Kind, IconName = Data.Type or Data.Kind, Data.Icon
		end
		if Config.Notifications == false then return end
		Duration = Duration or 4
		local Color
		if typeof(Kind) == "Color3" then
			Color = Kind
			Kind = "Info"
		else
			Kind = KindIcons[Kind or "Info"] and (Kind or "Info") or "Info"
			Color = KindColors[Kind] or Theme.Accent
		end
		IconName = IconName or PickIcon(KindIcons[Kind])

		local Wrap = New("Frame", {
			LayoutOrder = -Next(),
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Parent = NotifyHolder,
		})
		local Card = New("Frame", {
			Position = UDim2.new(1, 90, 0, 0),
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Theme.White,
			BorderSizePixel = 0,
			Parent = Wrap,
		}, {
			Corner(12),
			Stroke(Color, 1, 0.7),
			Grad(Color3.fromRGB(31, 32, 41), Color3.fromRGB(19, 20, 27), 90),
			New("UISizeConstraint", { MinSize = Vector2.new(0, 62) }),
		})

		local Badge = New("Frame", {
			Position = UDim2.fromOffset(12, 12),
			Size = UDim2.fromOffset(34, 34),
			BackgroundColor3 = Color,
			BackgroundTransparency = 0.82,
			BorderSizePixel = 0,
			Parent = Card,
		}, { Corner(10), Stroke(Color, 1, 0.75) })
		if ResolveIcon(IconName) ~= "rbxassetid://0" then
			Icon(Badge, IconName, 18, Color, UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
		else
			New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(8, 8),
				BackgroundColor3 = Color,
				BorderSizePixel = 0,
				Parent = Badge,
			}, { Full() })
		end

		local Content = New("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Parent = Card,
		}, {
			New("UIPadding", {
				PaddingTop = UDim.new(0, 13),
				PaddingBottom = UDim.new(0, 18),
				PaddingLeft = UDim.new(0, 58),
				PaddingRight = UDim.new(0, 32),
			}),
			New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
		})
		local HeadLabel = Text(Content, Head or "", 13, Theme.Text, "Medium")
		HeadLabel.LayoutOrder = 1
		HeadLabel.Size = UDim2.new(1, 0, 0, 18)
		New("TextLabel", {
			LayoutOrder = 2,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = Body or "",
			TextWrapped = true,
			TextSize = 12,
			TextColor3 = Theme.Dim,
			FontFace = Face("Regular"),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Parent = Content,
		})

		local BarTrack = New("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 14, 1, -8),
			Size = UDim2.new(1, -28, 0, 3),
			BackgroundColor3 = Theme.Track,
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			Parent = Card,
		}, { Full() })
		local BarFill = New("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color,
			BorderSizePixel = 0,
			Parent = BarTrack,
		}, { Full() })

		local Close = New("TextButton", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -8, 0, 8),
			Size = UDim2.fromOffset(22, 22),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			ZIndex = 2,
			Parent = Card,
		})
		local CloseGlyph = Icon(Close, "x", 12, Theme.Dim, UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
		Close.MouseEnter:Connect(function() Tween(CloseGlyph, { ImageColor3 = Theme.Text }) end)
		Close.MouseLeave:Connect(function() Tween(CloseGlyph, { ImageColor3 = Theme.Dim }) end)

		local Closed = false
		local function Dismiss()
			if Closed then return end
			Closed = true
			Tween(Card, { Position = UDim2.new(1, 90, 0, 0) }, 0.25)
			task.wait(0.3)
			Wrap:Destroy()
		end
		Close.MouseButton1Click:Connect(function() task.spawn(Dismiss) end)

		TweenService:Create(Card, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0, 0, 0, 0),
		}):Play()
		TweenService:Create(BarFill, TweenInfo.new(Duration, Enum.EasingStyle.Linear), {
			Size = UDim2.fromScale(0, 1),
		}):Play()
		task.delay(Duration, Dismiss)
	end

	local MenuOpen = true

	local ToggleBtn = New("TextButton", {
		Name = "OpenClose",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 16, 0.5, 0),
		Size = UDim2.fromOffset(52, 52),
		BackgroundColor3 = Theme.White,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 10,
		Parent = Gui,
	}, {
		Full(),
		Grad(Color3.fromRGB(32, 33, 42), Color3.fromRGB(16, 17, 23), 90),
	})
	local BtnStroke = Stroke(Theme.Accent, 2, 0)
	BtnStroke.Parent = ToggleBtn
	Icon(ToggleBtn, LogoIcon, 28, Theme.White, UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
	AddHudScale(ToggleBtn)

	local function SetMenu(State)
		MenuOpen = State
		if not State then ClosePopup() end
		Root.Visible = State
		Tween(BtnStroke, { Color = State and Theme.Accent or Theme.Stroke })
	end
	OnAccent(function(Color)
		if MenuOpen then BtnStroke.Color = Color end
	end)

	do
		local Dragging, Moved, StartPos, Origin = false, false, nil, nil
		ToggleBtn.InputBegan:Connect(function(Input)
			if IsPress(Input) then
				Dragging, Moved = true, false
				StartPos = Input.Position
				Origin = ToggleBtn.Position
			end
		end)
		UserInputService.InputChanged:Connect(function(Input)
			if Dragging and IsMove(Input) then
				local Delta = Input.Position - StartPos
				if Delta.Magnitude > 8 then Moved = true end
				if Moved then
					ToggleBtn.Position = UDim2.new(Origin.X.Scale, Origin.X.Offset + Delta.X, Origin.Y.Scale, Origin.Y.Offset + Delta.Y)
				end
			end
		end)
		UserInputService.InputEnded:Connect(function(Input)
			if Dragging and IsPress(Input) then
				Dragging = false
				if not Moved then SetMenu(not MenuOpen) end
			end
		end)
	end

	local Listening = false

	UserInputService.InputBegan:Connect(function(Input, Processed)
		if not Processed and not Listening and Input.KeyCode == MenuKey then SetMenu(not MenuOpen) end
	end)

	local HasFs = type(writefile) == "function"
		and type(readfile) == "function"
		and type(isfile) == "function"
		and type(listfiles) == "function"
	local CanDelete = type(delfile) == "function"

	local Meta = { Autoload = "", AutoSave = false, Keybinds = true, MenuKey = MenuKey.Name }
	local CurrentConfig = nil
	local Loading = false
	local AutoToken = 0
	local Selected = nil
	local RefreshList
	local UpdateAutoloadLabel

	local function Ensure()
		for _, Path in ipairs({ Folder, ConfigFolder }) do
			pcall(function()
				if isfolder then
					if not isfolder(Path) then makefolder(Path) end
				else
					makefolder(Path)
				end
			end)
		end
	end

	local function SaveMeta()
		if not HasFs then return end
		Ensure()
		pcall(writefile, MetaPath, HttpService:JSONEncode(Meta))
	end

	if HasFs then
		Ensure()
		local ok, Data = pcall(function()
			if isfile(MetaPath) then return HttpService:JSONDecode(readfile(MetaPath)) end
		end)
		if ok and type(Data) == "table" then
			Meta.Autoload = type(Data.Autoload) == "string" and Data.Autoload or ""
			Meta.AutoSave = Data.AutoSave == true
			Meta.Keybinds = Data.Keybinds ~= false
			if type(Data.MenuKey) == "string" then
				local KeyOk, Key = pcall(function() return Enum.KeyCode[Data.MenuKey] end)
				if KeyOk and Key then
					MenuKey = Key
					Meta.MenuKey = Key.Name
				end
			end
		end
	end

	local function CleanName(Value)
		Value = string.gsub(tostring(Value or ""), "[^%w _%-]", "")
		return Trim(Value)
	end

	local function ConfigPath(Name)
		return ConfigFolder .. "/" .. Name .. ".json"
	end

	local function ListConfigs()
		local Names = {}
		if not HasFs then return Names end
		local ok, Files = pcall(listfiles, ConfigFolder)
		if ok and type(Files) == "table" then
			for _, Path in ipairs(Files) do
				local Name = string.match((string.gsub(Path, "\\", "/")), "([^/]+)%.json$")
				if Name then table.insert(Names, Name) end
			end
		end
		table.sort(Names, function(A, B) return string.lower(A) < string.lower(B) end)
		return Names
	end

	local function Serialize()
		local Data = {}
		for Key in pairs(Registry) do
			local Value = Config[Key]
			if typeof(Value) == "Color3" then
				Data[Key] = { __color = Value:ToHex() }
			elseif Value ~= nil then
				Data[Key] = Value
			end
		end
		return HttpService:JSONEncode(Data)
	end

	local function ApplyData(Data)
		Loading = true
		for Key, Value in pairs(Data) do
			local Setter = Registry[Key]
			if Setter then
				if type(Value) == "table" and Value.__color then
					local ok, Color = pcall(Color3.fromHex, Value.__color)
					Value = ok and Color or nil
				end
				if Value ~= nil then pcall(Setter, Value, false) end
			end
		end
		Loading = false
		Rescale()
	end

	local function WriteConfig(Name)
		Ensure()
		return (pcall(writefile, ConfigPath(Name), Serialize()))
	end

	local function NotifyCfg(Message, Kind)
		Notify("Config Manager", Message, 3, Kind or "Info")
	end

	local function RequireFs()
		if HasFs then return true end
		NotifyCfg("Your executor does not support file functions.", "Error")
		return false
	end

	local function SaveConfig(Name, Overwrite)
		if not HasFs then return false, "unsupported" end
		Name = CleanName(Name)
		if Name == "" then return false, "empty" end
		if not Overwrite and isfile(ConfigPath(Name)) then return false, "exists" end
		if not WriteConfig(Name) then return false, "failed" end
		CurrentConfig = Name
		Selected = Name
		if RefreshList then RefreshList() end
		return true
	end

	local function LoadConfig(Name, Auto)
		if not HasFs then return false end
		if not Name or Name == "" or not isfile(ConfigPath(Name)) then
			NotifyCfg("Config not found.", "Warning")
			return false
		end
		local ok, Data = pcall(function()
			return HttpService:JSONDecode(readfile(ConfigPath(Name)))
		end)
		if not ok or type(Data) ~= "table" then
			NotifyCfg('Could not read "' .. Name .. '".', "Error")
			return false
		end
		ApplyData(Data)
		CurrentConfig = Name
		Selected = Name
		if RefreshList then RefreshList() end
		NotifyCfg((Auto and 'Autoloaded "' or 'Loaded "') .. Name .. '".', "Success")
		return true
	end

	local Keybinds = {}
	local KeybindPanel
	local KeybindGlyph

	local function BuildKeybindRow(Entry)
		if Entry.Row then Entry.Row:Destroy() end
		local Row = New("Frame", {
			LayoutOrder = Entry.Order,
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundTransparency = 1,
			Parent = KeybindPanel,
		})
		local Dot = New("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(6, 6),
			BackgroundColor3 = Theme.Track,
			BorderSizePixel = 0,
			Parent = Row,
		}, { Full() })
		local NameLabel = Text(Row, Entry.Name, 13, Theme.Dim, "Medium")
		NameLabel.Position = UDim2.fromOffset(16, 0)
		NameLabel.Size = UDim2.new(1, -96, 1, 0)
		NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		local Pill = New("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(0, 18),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = Theme.Field,
			BorderSizePixel = 0,
			Text = "",
			TextSize = 11,
			TextColor3 = Theme.Dim,
			FontFace = Face("Medium"),
			Parent = Row,
		}, {
			Corner(5),
			New("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }),
		})
		Entry.Row = Row
		Entry.Update = function()
			local KeyText = type(Entry.Key) == "function" and Entry.Key() or Entry.Key
			local On = true
			if type(Entry.Active) == "function" then
				On = Entry.Active() and true or false
			elseif Entry.Active ~= nil then
				On = Entry.Active == true
			end
			Pill.Text = tostring(KeyText)
			Pill.TextColor3 = On and Theme.Text or Theme.Dim
			NameLabel.TextColor3 = On and Theme.Text or Theme.Dim
			Dot.BackgroundColor3 = On and Theme.Accent or Theme.Track
		end
		Entry.Update()
	end

	KeybindRefresh = function()
		for _, Entry in pairs(Keybinds) do
			if Entry.Update then Entry.Update() end
		end
	end
	OnAccent(function() KeybindRefresh() end)

	function Window:AddKeybind(Name, Key, Active)
		local Existing = Keybinds[Name]
		if Existing and Existing.Row then Existing.Row:Destroy() end
		local Entry = { Name = Name, Key = Key, Active = Active, Order = Existing and Existing.Order or Next() }
		Keybinds[Name] = Entry
		if KeybindPanel then BuildKeybindRow(Entry) end
	end

	function Window:RemoveKeybind(Name)
		local Entry = Keybinds[Name]
		if Entry then
			if Entry.Row then Entry.Row:Destroy() end
			Keybinds[Name] = nil
		end
	end

	local function SetKeybinds(State)
		Meta.Keybinds = State and true or false
		if KeybindPanel then KeybindPanel.Visible = Meta.Keybinds end
		if KeybindGlyph then Tween(KeybindGlyph, { ImageColor3 = Meta.Keybinds and Theme.Accent or Theme.IconDim }) end
		SaveMeta()
	end

	local SelectedIndex = 0

	local function Select(Index)
		ClosePopup()
		SelectedIndex = Index
		for I, Tab in ipairs(Tabs) do
			Tab.Page.Visible = I == Index
			if Tab.Bar then Tab.Bar.Visible = I == Index end
			Tween(Tab.Button, { BackgroundTransparency = I == Index and 0 or 1 })
			Tween(Tab.Glyph, { ImageColor3 = I == Index and Theme.White or Theme.IconDim })
		end
		if Tabs[Index] then Subtitle.Text = Tabs[Index].Name end
	end

	local function GetColumn(Page, Side)
		local Set = Columns[Page]
		if not Set then
			Set = {}
			Columns[Page] = Set
			for _, ColumnName in ipairs({ "Left", "Right" }) do
				Set[ColumnName] = New("ScrollingFrame", {
					Name = ColumnName .. "Column",
					Position = ColumnName == "Left" and UDim2.fromOffset(12, 9) or UDim2.new(0.5, 6, 0, 9),
					Size = UDim2.new(0.5, -18, 1, -19),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ScrollBarThickness = 0,
					CanvasSize = UDim2.new(),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					ClipsDescendants = true,
					Parent = Page,
				}, {
					New("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
					New("UIPadding", { PaddingBottom = UDim.new(0, 4) }),
				})
			end
		end
		return Set[Side]
	end

	function Window:AddTab(Opt)
		if type(Opt) == "string" then Opt = { Name = Opt } end
		local Index = #Tabs + 1
		local Page = New("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Visible = false,
			Parent = PageHolder,
		})
		local Button = New("TextButton", {
			Position = UDim2.fromOffset(16, 81 + (Index - 1) * 60),
			Size = UDim2.fromOffset(54, 54),
			BackgroundColor3 = Color3.fromRGB(30, 31, 40),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			Parent = Sidebar,
		}, { Corner(12) })
		local Glyph = Icon(
			Button,
			Opt.Icon or PickIcon({ "layout-dashboard", "box", "hexagon" }),
			24,
			Theme.IconDim,
			UDim2.fromScale(0.5, 0.5),
			Vector2.new(0.5, 0.5)
		)
		Tabs[Index] = { Name = Opt.Name, Page = Page, Button = Button, Glyph = Glyph }
		Button.MouseButton1Click:Connect(function() Select(Index) end)
		table.insert(SearchIndex, { Name = Opt.Name, Kind = "Page", Page = Index, Path = "Page" })
		if Index == 1 then Select(1) end

		local Tab = { Name = Opt.Name, Index = Index, Page = Page }

		local function Attach(Target, TargetPage, ModeName, RevealFn)
			function Target:AddGroupbox(GroupOpt)
				if type(GroupOpt) == "string" then GroupOpt = { Name = GroupOpt } end
				local Side = string.lower(tostring(GroupOpt.Side or "left")) == "right" and "Right" or "Left"
				local Column = GetColumn(TargetPage, Side)
				local Box = New("Frame", {
					LayoutOrder = Next(),
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundColor3 = Theme.White,
					BorderSizePixel = 0,
					Parent = Column,
				}, {
					Corner(8),
					Grad(Color3.fromRGB(27, 28, 36), Color3.fromRGB(20, 21, 28), 90),
					New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
				})
				local Head = Text(Box, GroupOpt.Name, 14, Theme.Text, "Medium")
				Head.LayoutOrder = 1
				Head.Size = UDim2.new(1, 0, 0, 35)
				New("UIPadding", { PaddingLeft = UDim.new(0, 11), Parent = Head })
				New("Frame", {
					LayoutOrder = 2,
					Size = UDim2.new(1, 0, 0, 1),
					BackgroundColor3 = Theme.Stroke,
					BorderSizePixel = 0,
					Parent = Box,
				})
				local Body = New("Frame", {
					LayoutOrder = 3,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Parent = Box,
				}, {
					New("UIPadding", {
						PaddingTop = UDim.new(0, 8),
						PaddingBottom = UDim.new(0, 10),
						PaddingLeft = UDim.new(0, 16),
						PaddingRight = UDim.new(0, 16),
					}),
					New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
				})
				table.insert(SearchIndex, {
					Name = GroupOpt.Name,
					Kind = "Section",
					Object = Box,
					Scroller = Column,
					Page = Index,
					Mode = ModeName,
					Reveal = RevealFn,
					Path = ModeName,
				})
				return NewContainer(Body, {
					Scroller = Column,
					Section = GroupOpt.Name,
					Page = Index,
					Mode = ModeName,
					Reveal = RevealFn,
				})
			end
		end

		Attach(Tab, Page, Opt.Name, nil)

		local Subs = {}
		local Bar

		local function PickSub(Target)
			for _, Sub in ipairs(Subs) do
				local On = Sub == Target
				Sub.Page.Visible = On
				Tween(Sub.Button, { BackgroundTransparency = On and 0 or 1 })
				Tween(Sub.Label, { TextColor3 = On and Theme.Text or Theme.Dim })
			end
		end

		function Tab:AddTabbox(SubOpt)
			if type(SubOpt) == "string" then SubOpt = { Name = SubOpt } end
			if not Bar then
				Bar = New("Frame", {
					LayoutOrder = 0,
					Size = UDim2.fromOffset(0, 28),
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundColor3 = Theme.Field,
					BorderSizePixel = 0,
					Visible = SelectedIndex == Index,
					Parent = Tools,
				}, {
					Corner(7),
					New("UIPadding", {
						PaddingTop = UDim.new(0, 3),
						PaddingBottom = UDim.new(0, 3),
						PaddingLeft = UDim.new(0, 3),
						PaddingRight = UDim.new(0, 3),
					}),
					New("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 2),
					}),
				})
				Tabs[Index].Bar = Bar
			end

			local Sub = {}
			Sub.Page = New("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Visible = false,
				Parent = Page,
			})
			Sub.Button = New("TextButton", {
				LayoutOrder = #Subs + 1,
				Size = UDim2.fromOffset(0, 22),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundColor3 = Theme.Track,
				BackgroundTransparency = 1,
				AutoButtonColor = false,
				Text = "",
				Parent = Bar,
			}, {
				Corner(5),
				New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
			})
			Sub.Label = New("TextLabel", {
				Size = UDim2.fromOffset(0, 22),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				Text = SubOpt.Name,
				TextSize = 12,
				TextColor3 = Theme.Dim,
				FontFace = Face("Medium"),
				Parent = Sub.Button,
			})
			table.insert(Subs, Sub)

			local function Reveal() PickSub(Sub) end
			Sub.Button.MouseButton1Click:Connect(Reveal)
			table.insert(SearchIndex, {
				Name = SubOpt.Name,
				Kind = "Page",
				Page = Index,
				Path = Opt.Name,
				Reveal = Reveal,
			})
			if #Subs == 1 then Reveal() end

			local SubTab = { Name = SubOpt.Name, Page = Sub.Page }
			Attach(SubTab, Sub.Page, Opt.Name .. " / " .. SubOpt.Name, Reveal)
			return SubTab
		end
		Tab.AddSubTab = Tab.AddTabbox

		return Tab
	end

	local ConfigReady = false

	function Window:ConfigManager()
		if ConfigReady then return end
		ConfigReady = true

		local ConfigPop, PopContainer = MakePopup(244, "Config Manager")

		local NameBox = New("TextBox", {
			LayoutOrder = Next(),
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundColor3 = Theme.Field,
			Text = "",
			PlaceholderText = "Config name",
			PlaceholderColor3 = Theme.Placeholder,
			TextColor3 = Theme.Text,
			TextSize = 13,
			FontFace = Face("Medium"),
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			Parent = ConfigPop,
		}, { Corner(7), New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) })
		local NameStroke = Stroke(Theme.Accent, 1, 1)
		NameStroke.Parent = NameBox
		Accented(NameStroke, "Color")
		NameBox.Focused:Connect(function() Tween(NameStroke, { Transparency = 0.5 }) end)
		NameBox.FocusLost:Connect(function() Tween(NameStroke, { Transparency = 1 }) end)

		local RowH = 26
		local MaxRows = 4
		local Names = {}
		local ListOpen = false

		local CfgBox = New("Frame", {
			LayoutOrder = Next(),
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = Theme.White,
			ClipsDescendants = true,
			Parent = ConfigPop,
		}, { Corner(8), Grad(Color3.fromRGB(32, 33, 42), Color3.fromRGB(25, 26, 34), 90) })
		local CfgHead = New("TextButton", {
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundTransparency = 1,
			Text = "",
			Parent = CfgBox,
		})
		local CfgCurrent = Text(CfgHead, "Select config", 13, Theme.Placeholder, "Medium")
		CfgCurrent.Position = UDim2.fromOffset(11, 0)
		CfgCurrent.Size = UDim2.new(1, -40, 1, 0)
		CfgCurrent.TextTruncate = Enum.TextTruncate.AtEnd
		local CfgChevron = Icon(CfgHead, "chevron-down", 14, Theme.IconDim, UDim2.new(1, -16, 0.5, 0), Vector2.new(0.5, 0.5))
		local CfgList = New("ScrollingFrame", {
			Position = UDim2.fromOffset(0, 32),
			Size = UDim2.new(1, 0, 1, -32),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 0,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Parent = CfgBox,
		}, { New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }) })

		local function ListHeight()
			return math.max(1, math.min(#Names, MaxRows)) * RowH
		end

		local function SetListOpen(State)
			ListOpen = State
			Tween(CfgBox, { Size = UDim2.new(1, 0, 0, State and (32 + ListHeight()) or 32) })
			Tween(CfgChevron, { Rotation = State and 180 or 0 })
		end

		RefreshList = function()
			Names = ListConfigs()
			for _, Child in ipairs(CfgList:GetChildren()) do
				if not Child:IsA("UIListLayout") then Child:Destroy() end
			end
			if Selected and not table.find(Names, Selected) then Selected = nil end
			if #Names == 0 then
				local Empty = Text(CfgList, "No configs saved", 13, Theme.Dim, "Regular")
				Empty.Position = UDim2.fromOffset(11, 0)
				Empty.Size = UDim2.new(1, -11, 0, RowH)
			end
			for Index, Name in ipairs(Names) do
				local Option = New("TextButton", {
					LayoutOrder = Index,
					Size = UDim2.new(1, 0, 0, RowH),
					BackgroundTransparency = 1,
					AutoButtonColor = false,
					Text = "",
					Parent = CfgList,
				})
				local Caption = Text(Option, Name, 13, Name == Selected and Theme.Text or Theme.Dim, "Regular")
				Caption.Position = UDim2.fromOffset(11, 0)
				Caption.Size = UDim2.new(1, -11, 1, 0)
				Caption.TextTruncate = Enum.TextTruncate.AtEnd
				Option.MouseEnter:Connect(function() Tween(Caption, { TextColor3 = Theme.Text }) end)
				Option.MouseLeave:Connect(function()
					Tween(Caption, { TextColor3 = Name == Selected and Theme.Text or Theme.Dim })
				end)
				Option.MouseButton1Click:Connect(function()
					Selected = Name
					RefreshList()
					SetListOpen(false)
				end)
			end
			CfgCurrent.Text = Selected or "Select config"
			CfgCurrent.TextColor3 = Selected and Theme.Text or Theme.Placeholder
			if ListOpen then
				Tween(CfgBox, { Size = UDim2.new(1, 0, 0, 32 + ListHeight()) })
			end
		end

		CfgHead.MouseButton1Click:Connect(function()
			SetListOpen(not ListOpen)
		end)

		local function PopButton(Parent, Label, Order, OnClick)
			local Btn = New("TextButton", {
				LayoutOrder = Order,
				BackgroundColor3 = Theme.Field,
				AutoButtonColor = false,
				Text = Label,
				TextColor3 = Theme.Text,
				TextSize = 12,
				FontFace = Face("Medium"),
				Parent = Parent,
			}, { Corner(7) })
			Btn.MouseEnter:Connect(function() Tween(Btn, { BackgroundColor3 = Theme.Track }) end)
			Btn.MouseLeave:Connect(function() Tween(Btn, { BackgroundColor3 = Theme.Field }) end)
			Btn.MouseButton1Click:Connect(function()
				Btn.BackgroundColor3 = Theme.Accent
				Tween(Btn, { BackgroundColor3 = Theme.Field }, 0.25)
				OnClick()
			end)
			return Btn
		end

		local Grid = New("Frame", {
			LayoutOrder = Next(),
			Size = UDim2.new(1, 0, 0, 96),
			BackgroundTransparency = 1,
			Parent = ConfigPop,
		}, {
			New("UIGridLayout", {
				CellSize = UDim2.new(0.5, -3, 0, 28),
				CellPadding = UDim2.fromOffset(6, 6),
				FillDirectionMaxCells = 2,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		})

		local SaveErrors = {
			empty = "Enter a config name first.",
			exists = "That name already exists. Select it and use Overwrite.",
			failed = "Could not write the config file.",
			unsupported = "Your executor does not support file functions.",
		}

		PopButton(Grid, "Save", 1, function()
			if not RequireFs() then return end
			local Name = CleanName(NameBox.Text)
			local ok, Reason = SaveConfig(Name, false)
			if ok then
				NotifyCfg('Saved "' .. Name .. '".', "Success")
			else
				NotifyCfg(SaveErrors[Reason] or "Save failed.", "Warning")
			end
		end)

		PopButton(Grid, "Load", 2, function()
			if not RequireFs() then return end
			if not Selected then
				NotifyCfg("Select a config first.", "Warning")
				return
			end
			LoadConfig(Selected)
		end)

		PopButton(Grid, "Overwrite", 3, function()
			if not RequireFs() then return end
			if not Selected then
				NotifyCfg("Select a config first.", "Warning")
				return
			end
			local ok, Reason = SaveConfig(Selected, true)
			if ok then
				NotifyCfg('Overwrote "' .. Selected .. '".', "Success")
			else
				NotifyCfg(SaveErrors[Reason] or "Overwrite failed.", "Error")
			end
		end)

		PopButton(Grid, "Delete", 4, function()
			if not RequireFs() then return end
			if not Selected then
				NotifyCfg("Select a config first.", "Warning")
				return
			end
			if not CanDelete then
				NotifyCfg("Your executor does not support deleting files.", "Error")
				return
			end
			local Name = Selected
			local ok = pcall(delfile, ConfigPath(Name))
			if not ok then
				NotifyCfg("Could not delete the config.", "Error")
				return
			end
			if Meta.Autoload == Name then
				Meta.Autoload = ""
				SaveMeta()
				UpdateAutoloadLabel()
			end
			if CurrentConfig == Name then CurrentConfig = nil end
			Selected = nil
			RefreshList()
			NotifyCfg('Deleted "' .. Name .. '".', "Success")
		end)

		PopButton(Grid, "Set autoload", 5, function()
			if not RequireFs() then return end
			if not Selected then
				NotifyCfg("Select a config first.", "Warning")
				return
			end
			Meta.Autoload = Selected
			SaveMeta()
			UpdateAutoloadLabel()
			NotifyCfg('"' .. Selected .. '" will load on startup.', "Success")
		end)

		PopButton(Grid, "Remove autoload", 6, function()
			if not RequireFs() then return end
			if Meta.Autoload == "" then
				NotifyCfg("No autoload is set.", "Info")
				return
			end
			Meta.Autoload = ""
			SaveMeta()
			UpdateAutoloadLabel()
			NotifyCfg("Autoload removed.", "Success")
		end)

		PopContainer:AddToggle({
			Name = "Auto save",
			Flag = "_AutoSave",
			Default = Meta.AutoSave,
			Internal = true,
			Callback = function(State)
				Meta.AutoSave = State
				SaveMeta()
				if State and not CurrentConfig then
					NotifyCfg("Save or load a config first. Auto save writes to it.", "Info")
				end
			end,
		})

		local AutoRow = MakeRow(PopContainer, 24)
		local AutoLabel = Text(AutoRow, "Autoload", 13, Theme.Dim, "Regular")
		AutoLabel.Size = UDim2.new(0.4, 0, 1, 0)
		local AutoValue = Text(AutoRow, "None", 13, Theme.Dim, "Medium", Enum.TextXAlignment.Right)
		AutoValue.Position = UDim2.fromScale(0.4, 0)
		AutoValue.Size = UDim2.fromScale(0.6, 1)
		AutoValue.TextTruncate = Enum.TextTruncate.AtEnd

		UpdateAutoloadLabel = function()
			local HasAutoload = Meta.Autoload ~= ""
			AutoValue.Text = HasAutoload and Meta.Autoload or "None"
			AutoValue.TextColor3 = HasAutoload and Theme.Accent or Theme.Dim
		end
		UpdateAutoloadLabel()
		OnAccent(function() UpdateAutoloadLabel() end)

		ChangeHook = function()
			if Loading or not Meta.AutoSave or not CurrentConfig then return end
			AutoToken += 1
			local Token = AutoToken
			local Target = CurrentConfig
			task.delay(0.75, function()
				if Token == AutoToken and Meta.AutoSave and CurrentConfig == Target then
					WriteConfig(Target)
				end
			end)
		end

		PopupTool(2, { "save", "folder", "file" }, ConfigPop, {
			Before = function() RefreshList() end,
			Close = function() SetListOpen(false) end,
		})

		RefreshList()

		if HasFs and Meta.Autoload ~= "" then
			task.delay(0.5, function()
				LoadConfig(Meta.Autoload, true)
			end)
		end
	end

	local SettingsReady = false

	function Window:SettingManager()
		if SettingsReady then return end
		SettingsReady = true

		local SettingsPop, PopContainer = MakePopup(244, TitleText .. " Settings")

		local MenuKeyRow = MakeRow(PopContainer, 28)
		MenuKeyRow.LayoutOrder = 1
		local MenuKeyLabel = Text(MenuKeyRow, "Menu key", 13, Theme.Dim, "Regular")
		MenuKeyLabel.Size = UDim2.new(1, -96, 1, 0)
		local MenuKeyBtn = New("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(88, 24),
			BackgroundColor3 = Theme.Field,
			AutoButtonColor = false,
			Text = MenuKey.Name,
			TextColor3 = Theme.Text,
			TextSize = 12,
			FontFace = Face("Medium"),
			Parent = MenuKeyRow,
		}, { Corner(6) })
		MenuKeyBtn.MouseButton1Click:Connect(function()
			if Listening then return end
			Listening = true
			MenuKeyBtn.Text = "Press key"
			MenuKeyBtn.TextColor3 = Theme.Accent
			local Connection
			Connection = UserInputService.InputBegan:Connect(function(Input)
				if Input.UserInputType ~= Enum.UserInputType.Keyboard or Input.KeyCode == Enum.KeyCode.Unknown then return end
				Connection:Disconnect()
				if Input.KeyCode ~= Enum.KeyCode.Escape then
					MenuKey = Input.KeyCode
					Meta.MenuKey = Input.KeyCode.Name
					SaveMeta()
				end
				MenuKeyBtn.Text = MenuKey.Name
				MenuKeyBtn.TextColor3 = Theme.Text
				if KeybindRefresh then KeybindRefresh() end
				task.defer(function() Listening = false end)
			end)
		end)

		PopContainer:AddToggle({
			Name = "Watermark",
			Flag = "_Watermark",
			Default = Config._Watermark,
			Callback = function(State) WatermarkFrame.Visible = State end,
		})

		local ScalePending = false
		PopContainer:AddSlider({
			Name = "GUI scale",
			Flag = "_GuiScale",
			Min = 50,
			Max = 150,
			Default = Config._GuiScale,
			Step = 5,
			Format = function(Number) return string.format("%.0f%%", Number) end,
			Callback = function() ScalePending = true end,
		})
		UserInputService.InputEnded:Connect(function(Input)
			if ScalePending and IsPress(Input) then
				ScalePending = false
				Rescale()
			end
		end)

		local AccentLabel = Text(SettingsPop, "Accent color", 13, Theme.Dim, "Regular")
		AccentLabel.LayoutOrder = Next()
		AccentLabel.Size = UDim2.new(1, 0, 0, 18)
		local SetAccentPicker = BuildPicker(SettingsPop, Theme.Accent, function(Color)
			SetAccent(Color, true)
			NotifyChange()
		end, 100)
		Registry._Accent = function(Value)
			if typeof(Value) == "Color3" then
				SetAccentPicker(Value)
				SetAccent(Value, true)
			end
		end

		PopupTool(3, { "sliders-horizontal", "settings-2", "settings" }, SettingsPop, { Spin = true })
	end

	function Window:KeybindList()
		if KeybindPanel then return end

		KeybindPanel = New("Frame", {
			Name = "Keybinds",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(0, -10, 0, 15),
			Size = UDim2.fromOffset(196, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Theme.White,
			BorderSizePixel = 0,
			Visible = Meta.Keybinds,
			Parent = Root,
		}, {
			Corner(12),
			Stroke(Theme.Stroke, 1),
			Grad(Color3.fromRGB(27, 28, 36), Color3.fromRGB(17, 18, 24), 90),
			New("UIPadding", {
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}),
			New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
		})
		MakeDraggable(KeybindPanel, Root)

		local Head = Text(KeybindPanel, "Keybinds", 13, Theme.Text, "Medium")
		Head.LayoutOrder = -2
		Head.Size = UDim2.new(1, 0, 0, 22)

		New("Frame", {
			LayoutOrder = -1,
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = Theme.Stroke,
			BorderSizePixel = 0,
			Parent = KeybindPanel,
		})

		if not Keybinds.Menu then
			Window:AddKeybind("Menu", function() return MenuKey.Name end)
		end
		for _, Entry in pairs(Keybinds) do BuildKeybindRow(Entry) end

		local Button
		Button, KeybindGlyph = ToolButton(1, { "keyboard", "command", "list" }, Meta.Keybinds and Theme.Accent or Theme.IconDim)

		OnAccent(function(Color)
			if Meta.Keybinds then KeybindGlyph.ImageColor3 = Color end
		end)

		Button.MouseEnter:Connect(function()
			if not Meta.Keybinds then Tween(KeybindGlyph, { ImageColor3 = Theme.Text }) end
		end)
		Button.MouseLeave:Connect(function()
			if not Meta.Keybinds then Tween(KeybindGlyph, { ImageColor3 = Theme.IconDim }) end
		end)
		Button.MouseButton1Click:Connect(function()
			SetKeybinds(not Meta.Keybinds)
		end)
	end

	local SearchReady = false

	function Window:SearchManager()
		if SearchReady then return end
		SearchReady = true

		local function Score(Name, Query)
			local Lower = string.lower(Name)
			if Lower == Query then return 0 end
			local Start = string.find(Lower, Query, 1, true)
			if not Start then return nil end
			if Start == 1 then return 1 end
			local Best = 3
			while Start do
				if string.match(string.sub(Lower, Start - 1, Start - 1), "[%s/%-_]") then
					Best = 2
					break
				end
				Start = string.find(Lower, Query, Start + 1, true)
			end
			return Best
		end

		local function Flash(Object)
			if not Object or not Object.Parent then return end
			local Glow = Stroke(Theme.Accent, 2, 1)
			Glow.Parent = Object
			Tween(Glow, { Transparency = 0.15 }, 0.2)
			task.delay(1, function()
				Tween(Glow, { Transparency = 1 }, 0.4)
				task.delay(0.5, function() Glow:Destroy() end)
			end)
		end

		local function GoTo(Entry)
			Select(Entry.Page)
			if Entry.Reveal then Entry.Reveal() end
			if Entry.Object then
				task.spawn(function()
					task.wait(0.1)
					local Scroller = Entry.Scroller
					if Scroller and Scroller.Parent and Entry.Object.Parent then
						local Offset = (Entry.Object.AbsolutePosition.Y - Scroller.AbsolutePosition.Y) / Scale.Scale
						local Target = Offset + Scroller.CanvasPosition.Y - 8
						Tween(Scroller, { CanvasPosition = Vector2.new(0, math.max(Target, 0)) }, 0.25)
					end
					Flash(Entry.Object)
				end)
			end
		end

		local SearchPop = MakePopup(244, nil, 6)

		local SearchBox = New("Frame", {
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = Theme.Field,
			Parent = SearchPop,
		}, { Corner(8) })
		Icon(SearchBox, PickIcon({ "search", "magnifying-glass", "zoom-in" }), 16, Theme.IconDim, UDim2.new(0, 10, 0.5, 0), Vector2.new(0, 0.5))
		local SearchStroke = Stroke(Theme.Accent, 1, 1)
		SearchStroke.Parent = SearchBox
		Accented(SearchStroke, "Color")
		local SearchInput = New("TextBox", {
			Position = UDim2.fromOffset(34, 0),
			Size = UDim2.new(1, -44, 1, 0),
			BackgroundTransparency = 1,
			Text = "",
			PlaceholderText = "Search...",
			PlaceholderColor3 = Theme.Placeholder,
			TextColor3 = Theme.Text,
			TextSize = 13,
			FontFace = Face("Medium"),
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			Parent = SearchBox,
		})

		local ResultList = New("Frame", {
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Parent = SearchPop,
		}, { New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }) })

		local FirstEntry = nil

		local function RenderResults()
			for _, Child in ipairs(ResultList:GetChildren()) do
				if not Child:IsA("UIListLayout") then Child:Destroy() end
			end
			FirstEntry = nil
			local Query = string.lower(Trim(SearchInput.Text))
			if Query == "" then return end
			local Found = {}
			for _, Entry in ipairs(SearchIndex) do
				local Rank = Score(Entry.Name, Query)
				if Rank then table.insert(Found, { Entry = Entry, Rank = Rank }) end
			end
			table.sort(Found, function(A, B)
				if A.Rank ~= B.Rank then return A.Rank < B.Rank end
				local NameA, NameB = string.lower(A.Entry.Name), string.lower(B.Entry.Name)
				if NameA ~= NameB then return NameA < NameB end
				return (A.Entry.Path or "") < (B.Entry.Path or "")
			end)
			if #Found == 0 then
				local Empty = Text(ResultList, "No results", 12, Theme.Dim, "Regular")
				Empty.LayoutOrder = 1
				Empty.Size = UDim2.new(1, 0, 0, 26)
				return
			end
			FirstEntry = Found[1].Entry
			for Position = 1, math.min(#Found, 6) do
				local Entry = Found[Position].Entry
				local Item = New("TextButton", {
					LayoutOrder = Position,
					Size = UDim2.new(1, 0, 0, 38),
					BackgroundColor3 = Theme.Field,
					BackgroundTransparency = 1,
					AutoButtonColor = false,
					Text = "",
					Parent = ResultList,
				}, { Corner(7) })
				local NameLabel = Text(Item, Entry.Name, 13, Theme.Text, "Medium")
				NameLabel.Position = UDim2.fromOffset(10, 3)
				NameLabel.Size = UDim2.new(1, -20, 0, 18)
				NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
				local PathLabel = Text(Item, Entry.Path or "", 11, Theme.Dim, "Regular")
				PathLabel.Position = UDim2.fromOffset(10, 20)
				PathLabel.Size = UDim2.new(1, -20, 0, 14)
				PathLabel.TextTruncate = Enum.TextTruncate.AtEnd
				Item.MouseEnter:Connect(function() Tween(Item, { BackgroundTransparency = 0 }) end)
				Item.MouseLeave:Connect(function() Tween(Item, { BackgroundTransparency = 1 }) end)
				Item.MouseButton1Click:Connect(function() GoTo(Entry) end)
			end
		end

		SearchInput:GetPropertyChangedSignal("Text"):Connect(RenderResults)
		SearchInput.Focused:Connect(function() Tween(SearchStroke, { Transparency = 0.5 }) end)
		SearchInput.FocusLost:Connect(function(EnterPressed)
			Tween(SearchStroke, { Transparency = 1 })
			if EnterPressed and FirstEntry then GoTo(FirstEntry) end
		end)

		PopupTool(4, { "search", "magnifying-glass", "zoom-in" }, SearchPop, {
			Open = function()
				task.defer(function() SearchInput:CaptureFocus() end)
			end,
			Close = function()
				SearchInput:ReleaseFocus()
				SearchInput.Text = ""
			end,
		})
	end

	local AvatarStroke = Stroke(Theme.White, 1)
	local AvatarGradient = Grad(Theme.Accent, Theme.Stroke, 90)
	AvatarGradient.Parent = AvatarStroke
	OnAccent(function(Color)
		AvatarGradient.Color = ColorSequence.new(Color, Theme.Stroke)
	end)

	local Avatar = New("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0, 43, 1, -24),
		Size = UDim2.fromOffset(34, 34),
		BackgroundColor3 = Theme.Field,
		Parent = Sidebar,
	}, { Full(), AvatarStroke })
	task.spawn(function()
		local ok, Image = pcall(function()
			return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end)
		if ok then Avatar.Image = Image end
	end)

	Window.Name = TitleText
	Window.Gui = Gui
	Window.Root = Root
	Window.Flags = Config
	Window.Notify = function(_, ...) return Notify(...) end
	Window.SetMenu = function(_, State) SetMenu(State) end
	Window.SetAccent = function(_, Color) SetAccent(Color, false) end
	Window.Watermark = WatermarkFrame
	Window.SetWatermarkTitle = function(_, Value) WTitle.Text = Value end
	Window.ListConfigs = function() return ListConfigs() end
	Window.SaveConfig = function(_, Name, Overwrite) return SaveConfig(Name, Overwrite) end
	Window.LoadConfig = function(_, Name) return LoadConfig(Name) end
	Window.SetKeybinds = function(_, State) SetKeybinds(State) end
	Window.Destroy = function() Gui:Destroy() end

	Notify(TitleText, "Loaded. Tap the round button (or " .. MenuKey.Name .. ") to show or hide the menu.", 5, "Success")

	return Window
end

return Library
