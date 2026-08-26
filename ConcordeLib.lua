local ConcordeLib = {}
ConcordeLib.__index = ConcordeLib

local cg = game:GetService("CoreGui")
local p = game:GetService("Players").LocalPlayer
local uis = game:GetService("UserInputService")
local ts = game:GetService("TweenService")

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

function ConcordeLib.new(config)
	config = config or {}
	local self = setmetatable({}, ConcordeLib)

	local LOGO = config.Logo or "rbxassetid://0"
	local ACCENT = config.Accent or Color3.fromRGB(240, 45, 70)
	local BG = config.Background or Color3.fromRGB(11, 12, 16)
	local SIDEBAR_COL = config.Sidebar or Color3.fromRGB(14, 15, 20)
	local TEXT_COL = config.TextColor or Color3.fromRGB(240, 240, 245)
	local TOGGLE_KEY = config.Keybind or Enum.KeyCode.RightShift

	local sg = Instance.new("ScreenGui")
	sg.Name = "ConcordeUi"
	sg.ResetOnSpawn = false
	pcall(function() sg.Parent = cg end)
	if not sg.Parent then sg.Parent = p:WaitForChild("PlayerGui") end
	self._sg = sg

	local notifHolder = Instance.new("Frame")
	notifHolder.Size = UDim2.new(0, 220, 1, -20)
	notifHolder.Position = UDim2.new(1, -230, 0, 10)
	notifHolder.BackgroundTransparency = 1
	notifHolder.Parent = sg

	local notifList = Instance.new("UIListLayout")
	notifList.SortOrder = Enum.SortOrder.LayoutOrder
	notifList.VerticalAlignment = Enum.VerticalAlignment.Bottom
	notifList.Padding = UDim.new(0, 6)
	notifList.Parent = notifHolder

	local function notify(msg)
		local n = Instance.new("Frame")
		n.Size = UDim2.new(1, 0, 0, 34)
		n.BackgroundColor3 = Color3.fromRGB(15, 16, 22)
		n.BackgroundTransparency = 1
		n.Parent = notifHolder
		Instance.new("UICorner", n).CornerRadius = UDim.new(0, 8)
		local ns = Instance.new("UIStroke", n)
		ns.Color = Color3.fromRGB(32, 35, 48)
		ns.Thickness = 1.2
		local bar = Instance.new("Frame", n)
		bar.Size = UDim2.new(0, 3, 0.6, 0)
		bar.Position = UDim2.new(0, 10, 0.2, 0)
		bar.BackgroundColor3 = ACCENT
		bar.BorderSizePixel = 0
		Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
		local nt = Instance.new("TextLabel", n)
		nt.Size = UDim2.new(1, -26, 1, 0)
		nt.Position = UDim2.new(0, 20, 0, 0)
		nt.BackgroundTransparency = 1
		nt.Text = msg
		nt.TextColor3 = Color3.fromRGB(235, 238, 245)
		nt.Font = Enum.Font.Ubuntu
		nt.TextSize = 11.5
		nt.TextXAlignment = Enum.TextXAlignment.Left
		ts:Create(n, TweenInfo.new(0.25), {BackgroundTransparency = 0}):Play()
		task.delay(2.5, function()
			local t = ts:Create(n, TweenInfo.new(0.25), {BackgroundTransparency = 1})
			ts:Create(nt, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
			ts:Create(bar, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
			ts:Create(ns, TweenInfo.new(0.25), {Transparency = 1}):Play()
			t:Play()
			t.Completed:Connect(function() n:Destroy() end)
		end)
	end
	self.Notify = notify

	local cpModal = Instance.new("Frame")
	cpModal.Size = UDim2.new(0, 240, 0, 220)
	cpModal.BackgroundColor3 = Color3.fromRGB(16, 17, 24)
	cpModal.Position = UDim2.new(0.5, -120, 0.5, -110)
	cpModal.Visible = false
	cpModal.ZIndex = 500
	cpModal.Parent = sg
	Instance.new("UICorner", cpModal).CornerRadius = UDim.new(0, 8)
	local cpStroke = Instance.new("UIStroke", cpModal)
	cpStroke.Color = Color3.fromRGB(32, 34, 48)
	cpStroke.Thickness = 1.2

	local svBox = Instance.new("Frame", cpModal)
	svBox.Size = UDim2.new(0, 180, 0, 180)
	svBox.Position = UDim2.new(0, 10, 0, 10)
	svBox.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	svBox.BorderSizePixel = 0
	svBox.ZIndex = 501

	local satFrame = Instance.new("Frame", svBox)
	satFrame.Size = UDim2.new(1, 0, 1, 0)
	satFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	satFrame.BorderSizePixel = 0
	satFrame.ZIndex = 502
	local satGrad = Instance.new("UIGradient", satFrame)
	satGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})

	local valFrame = Instance.new("Frame", svBox)
	valFrame.Size = UDim2.new(1, 0, 1, 0)
	valFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	valFrame.BorderSizePixel = 0
	valFrame.ZIndex = 503
	local valGrad = Instance.new("UIGradient", valFrame)
	valGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
	valGrad.Rotation = 90

	local svCursor = Instance.new("Frame", svBox)
	svCursor.Size = UDim2.new(0, 10, 0, 10)
	svCursor.Position = UDim2.new(1, -5, 0, -5)
	svCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	svCursor.ZIndex = 504
	Instance.new("UICorner", svCursor).CornerRadius = UDim.new(1, 0)
	local svCS = Instance.new("UIStroke", svCursor)
	svCS.Color = Color3.fromRGB(0, 0, 0)
	svCS.Thickness = 1

	local hueBox = Instance.new("Frame", cpModal)
	hueBox.Size = UDim2.new(0, 24, 0, 180)
	hueBox.Position = UDim2.new(0, 205, 0, 10)
	hueBox.BorderSizePixel = 0
	hueBox.ZIndex = 501
	local hueGrad = Instance.new("UIGradient", hueBox)
	hueGrad.Rotation = 90
	hueGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
		ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
		ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
	})

	local hueCursor = Instance.new("Frame", hueBox)
	hueCursor.Size = UDim2.new(1, 6, 0, 6)
	hueCursor.Position = UDim2.new(0, -3, 0, -3)
	hueCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	hueCursor.ZIndex = 504
	local huCS = Instance.new("UIStroke", hueCursor)
	huCS.Color = Color3.fromRGB(0, 0, 0)
	huCS.Thickness = 1

	local cpConfirm = Instance.new("TextButton", cpModal)
	cpConfirm.Size = UDim2.new(1, -20, 0, 22)
	cpConfirm.Position = UDim2.new(0, 10, 1, -28)
	cpConfirm.BackgroundColor3 = ACCENT
	cpConfirm.Text = "Done"
	cpConfirm.TextColor3 = Color3.fromRGB(255, 255, 255)
	cpConfirm.Font = Enum.Font.Ubuntu
	cpConfirm.TextSize = 13
	cpConfirm.ZIndex = 505
	Instance.new("UICorner", cpConfirm).CornerRadius = UDim.new(0, 4)

	local activeColorCallback = nil
	local currH, currS, currV = 0, 1, 1

	local function updateColor()
		svBox.BackgroundColor3 = Color3.fromHSV(currH, 1, 1)
		if activeColorCallback then activeColorCallback(Color3.fromHSV(currH, currS, currV)) end
	end

	local dragSV, dragHue = false, false

	svBox.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragSV = true
			local absP, absS = svBox.AbsolutePosition, svBox.AbsoluteSize
			currS = math.clamp((i.Position.X - absP.X) / absS.X, 0, 1)
			currV = 1 - math.clamp((i.Position.Y - absP.Y) / absS.Y, 0, 1)
			svCursor.Position = UDim2.new(currS, -5, 1 - currV, -5)
			updateColor()
		end
	end)

	hueBox.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragHue = true
			local absP, absS = hueBox.AbsolutePosition, hueBox.AbsoluteSize
			currH = math.clamp((i.Position.Y - absP.Y) / absS.Y, 0, 1)
			hueCursor.Position = UDim2.new(0, -3, currH, -3)
			updateColor()
		end
	end)

	uis.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragSV = false
			dragHue = false
		end
	end)

	uis.InputChanged:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
			if dragSV then
				local absP, absS = svBox.AbsolutePosition, svBox.AbsoluteSize
				currS = math.clamp((i.Position.X - absP.X) / absS.X, 0, 1)
				currV = 1 - math.clamp((i.Position.Y - absP.Y) / absS.Y, 0, 1)
				svCursor.Position = UDim2.new(currS, -5, 1 - currV, -5)
				updateColor()
			elseif dragHue then
				local absP, absS = hueBox.AbsolutePosition, hueBox.AbsoluteSize
				currH = math.clamp((i.Position.Y - absP.Y) / absS.Y, 0, 1)
				hueCursor.Position = UDim2.new(0, -3, currH, -3)
				updateColor()
			end
		end
	end)

	cpConfirm.MouseButton1Click:Connect(function() cpModal.Visible = false end)

	local function openColorPicker(initCol, callback)
		currH, currS, currV = Color3.toHSV(initCol or ACCENT)
		svBox.BackgroundColor3 = Color3.fromHSV(currH, 1, 1)
		svCursor.Position = UDim2.new(currS, -5, 1 - currV, -5)
		hueCursor.Position = UDim2.new(0, -3, currH, -3)
		activeColorCallback = callback
		cpModal.Visible = true
	end
	self._openColorPicker = openColorPicker

	local ob = Instance.new("ImageButton", sg)
	ob.Size = UDim2.new(0, 42, 0, 42)
	ob.Position = UDim2.new(0, 20, 0, 20)
	ob.BackgroundColor3 = Color3.fromRGB(15, 16, 22)
	ob.AutoButtonColor = false
	ob.Visible = uis.TouchEnabled
	Instance.new("UICorner", ob).CornerRadius = UDim.new(0, 10)
	local obs = Instance.new("UIStroke", ob)
	obs.Color = ACCENT
	obs.Thickness = 1.2
	self._accentStroke = obs

	local obIcon = Instance.new("ImageLabel", ob)
	obIcon.Size = UDim2.new(0, 22, 0, 22)
	obIcon.Position = UDim2.new(0.5, -11, 0.5, -11)
	obIcon.BackgroundTransparency = 1
	obIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
	ApplyIcon(obIcon, LOGO)

	local mf = Instance.new("Frame", sg)
	mf.Size = UDim2.new(0, 620, 0, 360)
	mf.Position = UDim2.new(0.5, -310, 0.5, -180)
	mf.BackgroundColor3 = BG
	mf.BorderSizePixel = 0
	mf.Visible = true
	Instance.new("UICorner", mf).CornerRadius = UDim.new(0, 10)
	local mfs = Instance.new("UIStroke", mf)
	mfs.Color = Color3.fromRGB(25, 27, 36)
	mfs.Thickness = 1.2
	self._mf = mf

	uis.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == TOGGLE_KEY then
			mf.Visible = not mf.Visible
		end
	end)

	local dt, di, ds, sp
	mf.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dt = true
			ds = i.Position
			sp = mf.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then dt = false end
			end)
		end
	end)
	mf.InputChanged:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then di = i end
	end)
	uis.InputChanged:Connect(function(i)
		if i == di and dt then
			local d = i.Position - ds
			mf.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
		end
	end)

	ob.MouseButton1Click:Connect(function() mf.Visible = not mf.Visible end)

	local sb = Instance.new("Frame", mf)
	sb.Size = UDim2.new(0, 52, 1, 0)
	sb.BackgroundColor3 = SIDEBAR_COL
	sb.BorderSizePixel = 0
	Instance.new("UICorner", sb).CornerRadius = UDim.new(0, 10)
	local sbf = Instance.new("Frame", sb)
	sbf.Size = UDim2.new(0, 10, 1, 0)
	sbf.Position = UDim2.new(1, -10, 0, 0)
	sbf.BackgroundColor3 = SIDEBAR_COL
	sbf.BorderSizePixel = 0
	self._sb = sb
	self._sbf = sbf

	local logoLabel = Instance.new("ImageLabel", sb)
	logoLabel.Size = UDim2.new(0, 24, 0, 24)
	logoLabel.Position = UDim2.new(0.5, -12, 0, 14)
	logoLabel.BackgroundTransparency = 1
	logoLabel.ImageColor3 = Color3.fromRGB(240, 240, 245)
	ApplyIcon(logoLabel, LOGO)

	local av = Instance.new("ImageLabel", sb)
	av.Size = UDim2.new(0, 26, 0, 26)
	av.Position = UDim2.new(0.5, -13, 1, -36)
	av.BackgroundColor3 = Color3.fromRGB(22, 23, 30)
	Instance.new("UICorner", av).CornerRadius = UDim.new(1, 0)
	pcall(function()
		av.Image = game:GetService("Players"):GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end)

	local mc = Instance.new("Frame", mf)
	mc.Size = UDim2.new(1, -64, 1, -12)
	mc.Position = UDim2.new(0, 58, 0, 6)
	mc.BackgroundTransparency = 1

	local ht = Instance.new("TextLabel", mc)
	ht.Size = UDim2.new(1, -140, 0, 16)
	ht.Position = UDim2.new(0, 4, 0, 4)
	ht.BackgroundTransparency = 1
	ht.Text = "Home"
	ht.TextColor3 = TEXT_COL
	ht.Font = Enum.Font.Ubuntu
	ht.TextSize = 14
	ht.TextXAlignment = Enum.TextXAlignment.Left
	self._ht = ht

	local st = Instance.new("TextLabel", mc)
	st.Size = UDim2.new(1, -140, 0, 14)
	st.Position = UDim2.new(0, 4, 0, 22)
	st.BackgroundTransparency = 1
	st.Text = config.Subtitle or "Powered by ConcordeLib"
	st.TextColor3 = Color3.fromRGB(110, 112, 128)
	st.Font = Enum.Font.Ubuntu
	st.TextSize = 12
	st.TextXAlignment = Enum.TextXAlignment.Left

	local topDrop = Instance.new("TextButton", mc)
	topDrop.Size = UDim2.new(0, 115, 0, 26)
	topDrop.Position = UDim2.new(1, -119, 0, 8)
	topDrop.BackgroundColor3 = Color3.fromRGB(16, 17, 23)
	topDrop.Text = ""
	topDrop.ZIndex = 50
	topDrop.Visible = false
	Instance.new("UICorner", topDrop).CornerRadius = UDim.new(0, 5)
	local tds = Instance.new("UIStroke", topDrop)
	tds.Color = Color3.fromRGB(26, 28, 38)
	tds.Thickness = 1

	local tdt = Instance.new("TextLabel", topDrop)
	tdt.Size = UDim2.new(1, -22, 1, 0)
	tdt.Position = UDim2.new(0, 8, 0, 0)
	tdt.BackgroundTransparency = 1
	tdt.Text = "SubPage"
	tdt.TextColor3 = Color3.fromRGB(240, 240, 245)
	tdt.Font = Enum.Font.Ubuntu
	tdt.TextSize = 12
	tdt.TextXAlignment = Enum.TextXAlignment.Left
	tdt.ZIndex = 51

	local tdArrow = Instance.new("ImageLabel", topDrop)
	tdArrow.Size = UDim2.new(0, 12, 0, 12)
	tdArrow.Position = UDim2.new(1, -16, 0.5, -6)
	tdArrow.BackgroundTransparency = 1
	tdArrow.ImageColor3 = Color3.fromRGB(120, 122, 138)
	tdArrow.ZIndex = 51
	ApplyIcon(tdArrow, "chevron-down")

	local topDropList = Instance.new("Frame", topDrop)
	topDropList.Size = UDim2.new(1, 0, 0, 0)
	topDropList.Position = UDim2.new(0, 0, 1, 4)
	topDropList.BackgroundColor3 = Color3.fromRGB(18, 19, 26)
	topDropList.Visible = false
	topDropList.ZIndex = 100
	Instance.new("UICorner", topDropList).CornerRadius = UDim.new(0, 5)
	local tdls = Instance.new("UIStroke", topDropList)
	tdls.Color = Color3.fromRGB(30, 32, 44)
	tdls.Thickness = 1
	Instance.new("UIListLayout", topDropList).SortOrder = Enum.SortOrder.LayoutOrder

	topDrop.MouseButton1Click:Connect(function()
		topDropList.Visible = not topDropList.Visible
	end)

	local tabContainer = Instance.new("Frame", mc)
	tabContainer.Size = UDim2.new(1, 0, 1, -44)
	tabContainer.Position = UDim2.new(0, 0, 0, 44)
	tabContainer.BackgroundTransparency = 1

	local sidebarTabs = {}
	local sidebarBtns = {}
	local currentActiveTab = nil

	local function updateTopDropMenu()
		for _, child in ipairs(topDropList:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end
		if not currentActiveTab or #currentActiveTab.SubPages <= 1 then
			topDrop.Visible = false
			return
		end
		topDrop.Visible = true
		topDropList.Size = UDim2.new(1, 0, 0, #currentActiveTab.SubPages * 28)
		for idx, subObj in ipairs(currentActiveTab.SubPages) do
			local b = Instance.new("TextButton", topDropList)
			b.Size = UDim2.new(1, 0, 0, 28)
			b.BackgroundTransparency = 1
			b.Text = "  " .. subObj.Name
			b.TextColor3 = Color3.fromRGB(200, 202, 215)
			b.Font = Enum.Font.Ubuntu
			b.TextSize = 12
			b.TextXAlignment = Enum.TextXAlignment.Left
			b.ZIndex = 101
			b.MouseButton1Click:Connect(function()
				for _, s in ipairs(currentActiveTab.SubPages) do s.Frame.Visible = false end
				subObj.Frame.Visible = true
				currentActiveTab.ActiveSubIndex = idx
				tdt.Text = subObj.Name
				ht.Text = currentActiveTab.Title .. " / " .. subObj.Name
				topDropList.Visible = false
			end)
		end
	end

	local tabIndex = 0

	function self:AddTab(iconName, titleText)
		tabIndex += 1
		local idx = tabIndex

		local btn = Instance.new("ImageButton", sb)
		btn.Size = UDim2.new(0, 24, 0, 24)
		btn.Position = UDim2.new(0.5, -12, 0, 50 + (idx - 1) * 42)
		btn.BackgroundTransparency = 1
		btn.ImageColor3 = idx == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 102, 118)
		ApplyIcon(btn, iconName)

		local tabData = {
			Index = idx,
			Title = titleText,
			SubPages = {},
			ActiveSubIndex = 1
		}

		sidebarTabs[idx] = tabData
		sidebarBtns[idx] = btn

		function tabData:AddSubPage(subName)
			local tFrame = Instance.new("Frame", tabContainer)
			tFrame.Size = UDim2.new(1, 0, 1, 0)
			tFrame.BackgroundTransparency = 1
			tFrame.Visible = false

			local function makeCol(xPos)
				local col = Instance.new("Frame", tFrame)
				col.Size = UDim2.new(0.49, 0, 1, 0)
				col.Position = UDim2.new(xPos, 0, 0, 0)
				col.BackgroundColor3 = Color3.fromRGB(14, 15, 20)
				col.ClipsDescendants = true
				Instance.new("UICorner", col).CornerRadius = UDim.new(0, 8)
				local cs = Instance.new("UIStroke", col)
				cs.Color = Color3.fromRGB(22, 23, 31)
				cs.Thickness = 1
				local scrl = Instance.new("ScrollingFrame", col)
				scrl.Size = UDim2.new(1, 0, 1, 0)
				scrl.BackgroundTransparency = 1
				scrl.ScrollBarThickness = 2
				scrl.ScrollBarImageColor3 = Color3.fromRGB(45, 48, 62)
				scrl.AutomaticCanvasSize = Enum.AutomaticSize.Y
				scrl.CanvasSize = UDim2.new(0, 0, 0, 0)
				scrl.BorderSizePixel = 0
				local pad = Instance.new("UIPadding", scrl)
				pad.PaddingLeft   = UDim.new(0, 12)
				pad.PaddingRight  = UDim.new(0, 14)
				pad.PaddingTop    = UDim.new(0, 10)
				pad.PaddingBottom = UDim.new(0, 10)
				local layout = Instance.new("UIListLayout", scrl)
				layout.SortOrder = Enum.SortOrder.LayoutOrder
				layout.Padding = UDim.new(0, 10)
				layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
					scrl.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
				end)
				return scrl
			end

			local c1 = makeCol(0)
			local c2 = makeCol(0.51)

			local subObj = { Name = subName, Frame = tFrame, Col1 = c1, Col2 = c2 }
			table.insert(tabData.SubPages, subObj)

			if #tabData.SubPages == 1 and tabData.Index == 1 then
				tFrame.Visible = true
				currentActiveTab = tabData
				tdt.Text = subName
				ht.Text = titleText .. " / " .. subName
				updateTopDropMenu()
			end

			return c1, c2
		end

		btn.MouseButton1Click:Connect(function()
			for i, t in ipairs(sidebarTabs) do
				sidebarBtns[i].ImageColor3 = (i == idx) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 102, 118)
				for _, sub in ipairs(t.SubPages) do sub.Frame.Visible = false end
			end
			currentActiveTab = tabData
			local activeSub = tabData.SubPages[tabData.ActiveSubIndex] or tabData.SubPages[1]
			if activeSub then
				activeSub.Frame.Visible = true
				tdt.Text = activeSub.Name
				ht.Text = titleText .. " / " .. activeSub.Name
			end
			updateTopDropMenu()
		end)

		return tabData
	end

	function self:Title(text, parent)
		local container = Instance.new("Frame", parent)
		container.Size = UDim2.new(1, 0, 0, 32)
		container.BackgroundTransparency = 1

		local l = Instance.new("TextLabel", container)
		l.Size = UDim2.new(1, 0, 1, -6)
		l.BackgroundTransparency = 1
		l.Text = text
		l.TextColor3 = Color3.fromRGB(255, 255, 255)
		l.Font = Enum.Font.Ubuntu
		l.TextSize = 15
		l.TextXAlignment = Enum.TextXAlignment.Left

		local line = Instance.new("Frame", container)
		line.Size = UDim2.new(1, 0, 0, 1)
		line.Position = UDim2.new(0, 0, 1, -1)
		line.BackgroundColor3 = Color3.fromRGB(34, 36, 48)
		line.BorderSizePixel = 0
	end

	function self:Toggle(text, state, parent, extraConfig)
		local f = Instance.new("Frame", parent)
		f.Size = UDim2.new(1, 0, 0, 32)
		f.BackgroundTransparency = 1

		local l = Instance.new("TextLabel", f)
		l.Size = UDim2.new(1, -120, 1, 0)
		l.BackgroundTransparency = 1
		l.Text = text
		l.TextColor3 = Color3.fromRGB(200, 202, 215)
		l.Font = Enum.Font.Ubuntu
		l.TextSize = 14
		l.TextXAlignment = Enum.TextXAlignment.Left

		local rightContainer = Instance.new("Frame", f)
		rightContainer.Size = UDim2.new(0, 115, 1, 0)
		rightContainer.Position = UDim2.new(1, -115, 0, 0)
		rightContainer.BackgroundTransparency = 1
		local rList = Instance.new("UIListLayout", rightContainer)
		rList.FillDirection = Enum.FillDirection.Horizontal
		rList.HorizontalAlignment = Enum.HorizontalAlignment.Right
		rList.VerticalAlignment = Enum.VerticalAlignment.Center
		rList.Padding = UDim.new(0, 8)

		local btn = Instance.new("TextButton", rightContainer)
		btn.Size = UDim2.new(0, 42, 0, 24)
		btn.BackgroundColor3 = state and ACCENT or Color3.fromRGB(35, 36, 46)
		btn.Text = ""
		btn.LayoutOrder = 10
		Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

		local ind = Instance.new("Frame", btn)
		ind.Size = UDim2.new(0, 18, 0, 18)
		ind.Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
		ind.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Instance.new("UICorner", ind).CornerRadius = UDim.new(1, 0)

		if extraConfig then
			if extraConfig.color then
				local cBox = Instance.new("TextButton", rightContainer)
				cBox.Size = UDim2.new(0, 24, 0, 24)
				cBox.BackgroundColor3 = extraConfig.color
				cBox.Text = ""
				cBox.LayoutOrder = 1
				Instance.new("UICorner", cBox).CornerRadius = UDim.new(0, 4)
				cBox.MouseButton1Click:Connect(function()
					openColorPicker(cBox.BackgroundColor3, function(newColor)
						cBox.BackgroundColor3 = newColor
						if extraConfig.onColorChanged then extraConfig.onColorChanged(newColor) end
					end)
				end)
			end
			if extraConfig.keybind then
				local kb = Instance.new("TextButton", rightContainer)
				kb.Size = UDim2.new(0, 38, 0, 24)
				kb.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
				kb.Text = extraConfig.keybind
				kb.TextColor3 = Color3.fromRGB(150, 152, 168)
				kb.Font = Enum.Font.Ubuntu
				kb.TextSize = 12
				kb.LayoutOrder = 2
				Instance.new("UICorner", kb).CornerRadius = UDim.new(0, 4)
				local kbs = Instance.new("UIStroke", kb)
				kbs.Color = Color3.fromRGB(32, 34, 46)
				kbs.Thickness = 1
				local listening = false
				kb.MouseButton1Click:Connect(function()
					if listening then return end
					listening = true
					kb.Text = "..."
					local conn
					conn = uis.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.Keyboard then
							kb.Text = input.KeyCode.Name
							listening = false
							conn:Disconnect()
						end
					end)
				end)
			end
		end

		local on = state
		btn.MouseButton1Click:Connect(function()
			on = not on
			btn.BackgroundColor3 = on and ACCENT or Color3.fromRGB(35, 36, 46)
			ind:TweenPosition(on and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9), "Out", "Sine", 0.12, true)
			notify(text .. ": " .. tostring(on))
		end)

		return function() return on end
	end

	function self:ColorTile(text, initCol, parent, callback)
		local f = Instance.new("Frame", parent)
		f.Size = UDim2.new(1, 0, 0, 32)
		f.BackgroundTransparency = 1

		local l = Instance.new("TextLabel", f)
		l.Size = UDim2.new(1, -40, 1, 0)
		l.BackgroundTransparency = 1
		l.Text = text
		l.TextColor3 = Color3.fromRGB(200, 202, 215)
		l.Font = Enum.Font.Ubuntu
		l.TextSize = 14
		l.TextXAlignment = Enum.TextXAlignment.Left

		local cBox = Instance.new("TextButton", f)
		cBox.Size = UDim2.new(0, 26, 0, 26)
		cBox.Position = UDim2.new(1, -26, 0.5, -13)
		cBox.BackgroundColor3 = initCol
		cBox.Text = ""
		Instance.new("UICorner", cBox).CornerRadius = UDim.new(0, 5)
		cBox.MouseButton1Click:Connect(function()
			openColorPicker(cBox.BackgroundColor3, function(newColor)
				cBox.BackgroundColor3 = newColor
				if callback then callback(newColor) end
			end)
		end)
	end

	function self:Dropdown(text, default, options, parent, callback)
		local wrap = Instance.new("Frame", parent)
		wrap.Size = UDim2.new(1, 0, 0, 54)
		wrap.BackgroundTransparency = 1
		wrap.ZIndex = 10

		local l = Instance.new("TextLabel", wrap)
		l.Size = UDim2.new(1, 0, 0, 18)
		l.BackgroundTransparency = 1
		l.Text = text
		l.TextColor3 = Color3.fromRGB(110, 112, 128)
		l.Font = Enum.Font.Ubuntu
		l.TextSize = 13
		l.TextXAlignment = Enum.TextXAlignment.Left

		local f = Instance.new("TextButton", wrap)
		f.Size = UDim2.new(1, 0, 0, 32)
		f.Position = UDim2.new(0, 0, 0, 22)
		f.BackgroundColor3 = Color3.fromRGB(20, 21, 28)
		f.Text = ""
		f.ZIndex = 11
		Instance.new("UICorner", f).CornerRadius = UDim.new(0, 5)
		local fs = Instance.new("UIStroke", f)
		fs.Color = Color3.fromRGB(28, 30, 40)
		fs.Thickness = 1

		local vl = Instance.new("TextLabel", f)
		vl.Size = UDim2.new(1, -28, 1, 0)
		vl.Position = UDim2.new(0, 10, 0, 0)
		vl.BackgroundTransparency = 1
		vl.Text = default
		vl.TextColor3 = Color3.fromRGB(240, 240, 245)
		vl.Font = Enum.Font.Ubuntu
		vl.TextSize = 13
		vl.TextXAlignment = Enum.TextXAlignment.Left
		vl.ZIndex = 12

		local arr = Instance.new("ImageLabel", f)
		arr.Size = UDim2.new(0, 14, 0, 14)
		arr.Position = UDim2.new(1, -18, 0.5, -7)
		arr.BackgroundTransparency = 1
		arr.ImageColor3 = Color3.fromRGB(110, 112, 128)
		arr.ZIndex = 12
		ApplyIcon(arr, "chevron-down")

		local dropList = Instance.new("Frame", f)
		dropList.Size = UDim2.new(1, 0, 0, 0)
		dropList.Position = UDim2.new(0, 0, 1, 4)
		dropList.BackgroundColor3 = Color3.fromRGB(22, 23, 31)
		dropList.Visible = false
		dropList.ZIndex = 30
		Instance.new("UICorner", dropList).CornerRadius = UDim.new(0, 5)
		local dls = Instance.new("UIStroke", dropList)
		dls.Color = Color3.fromRGB(32, 34, 46)
		dls.Thickness = 1
		Instance.new("UIListLayout", dropList).SortOrder = Enum.SortOrder.LayoutOrder

		f.MouseButton1Click:Connect(function() dropList.Visible = not dropList.Visible end)

		local function refreshOptions(newOptions)
			for _, child in ipairs(dropList:GetChildren()) do
				if child:IsA("TextButton") then child:Destroy() end
			end
			dropList.Size = UDim2.new(1, 0, 0, #newOptions * 30)
			for _, opt in ipairs(newOptions) do
				local obtn = Instance.new("TextButton", dropList)
				obtn.Size = UDim2.new(1, 0, 0, 30)
				obtn.BackgroundTransparency = 1
				obtn.Text = "  " .. opt
				obtn.TextColor3 = Color3.fromRGB(200, 202, 215)
				obtn.Font = Enum.Font.Ubuntu
				obtn.TextSize = 13
				obtn.TextXAlignment = Enum.TextXAlignment.Left
				obtn.ZIndex = 31
				obtn.MouseButton1Click:Connect(function()
					vl.Text = opt
					dropList.Visible = false
					notify(text .. " -> " .. opt)
					if callback then callback(opt) end
				end)
			end
		end

		refreshOptions(options)

		return { Refresh = refreshOptions }
	end

	function self:Slider(label, unit, parent, min, max, default, callback)
		unit = unit or ""
		local f = Instance.new("Frame", parent)
		f.Size = UDim2.new(1, 0, 0, 32)
		f.BackgroundTransparency = 1

		local l = Instance.new("TextLabel", f)
		l.Size = UDim2.new(1, -155, 1, 0)
		l.BackgroundTransparency = 1
		l.Text = label
		l.TextColor3 = Color3.fromRGB(150, 152, 168)
		l.Font = Enum.Font.Ubuntu
		l.TextSize = 14
		l.TextXAlignment = Enum.TextXAlignment.Left

		local vl = Instance.new("TextLabel", f)
		vl.Size = UDim2.new(0, 50, 1, 0)
		vl.Position = UDim2.new(1, -145, 0, 0)
		vl.BackgroundTransparency = 1
		vl.Text = tostring(default) .. unit
		vl.TextColor3 = Color3.fromRGB(240, 240, 245)
		vl.Font = Enum.Font.Ubuntu
		vl.TextSize = 13
		vl.TextXAlignment = Enum.TextXAlignment.Right

		local bg = Instance.new("TextButton", f)
		bg.Size = UDim2.new(0, 90, 0, 8)
		bg.Position = UDim2.new(1, -90, 0.5, -4)
		bg.BackgroundColor3 = Color3.fromRGB(24, 25, 33)
		bg.AutoButtonColor = false
		bg.Text = ""
		Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

		local fil = Instance.new("Frame", bg)
		fil.Size = UDim2.new(math.clamp((default - min) / (max - min), 0, 1), 0, 1, 0)
		fil.BackgroundColor3 = ACCENT
		fil.BorderSizePixel = 0
		Instance.new("UICorner", fil).CornerRadius = UDim.new(1, 0)

		local kn = Instance.new("Frame", fil)
		kn.Size = UDim2.new(0, 14, 0, 14)
		kn.Position = UDim2.new(1, -7, 0.5, -7)
		kn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Instance.new("UICorner", kn).CornerRadius = UDim.new(1, 0)

		local dragging = false
		local function update(input)
			local pct = math.clamp((input.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
			fil.Size = UDim2.new(pct, 0, 1, 0)
			local cur = (max - min) < 10 and math.floor((min + (max - min) * pct) * 100) / 100 or math.floor(min + (max - min) * pct)
			vl.Text = tostring(cur) .. unit
			if callback then callback(cur) end
		end

		bg.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				update(i)
			end
		end)
		uis.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
		end)
		uis.InputChanged:Connect(function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then update(i) end
		end)
	end

	function self:RangeSlider(label, unit, parent, min, max, defaultLow, defaultHigh, callback)
		unit = unit or ""
		local f = Instance.new("Frame", parent)
		f.Size = UDim2.new(1, 0, 0, 32)
		f.BackgroundTransparency = 1

		local l = Instance.new("TextLabel", f)
		l.Size = UDim2.new(1, -165, 1, 0)
		l.BackgroundTransparency = 1
		l.Text = label
		l.TextColor3 = Color3.fromRGB(150, 152, 168)
		l.Font = Enum.Font.Ubuntu
		l.TextSize = 14
		l.TextXAlignment = Enum.TextXAlignment.Left

		local vl = Instance.new("TextLabel", f)
		vl.Size = UDim2.new(0, 65, 1, 0)
		vl.Position = UDim2.new(1, -160, 0, 0)
		vl.BackgroundTransparency = 1
		vl.Text = tostring(defaultLow) .. unit .. " - " .. tostring(defaultHigh) .. unit
		vl.TextColor3 = Color3.fromRGB(240, 240, 245)
		vl.Font = Enum.Font.Ubuntu
		vl.TextSize = 13
		vl.TextXAlignment = Enum.TextXAlignment.Right

		local track = Instance.new("Frame", f)
		track.Size = UDim2.new(0, 90, 0, 8)
		track.Position = UDim2.new(1, -90, 0.5, -4)
		track.BackgroundColor3 = Color3.fromRGB(24, 25, 33)
		Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

		local lowPct  = math.clamp((defaultLow  - min) / (max - min), 0, 1)
		local highPct = math.clamp((defaultHigh - min) / (max - min), 0, 1)
		local valLow, valHigh = defaultLow, defaultHigh

		local fill = Instance.new("Frame", track)
		fill.Position = UDim2.new(lowPct, 0, 0, 0)
		fill.Size = UDim2.new(highPct - lowPct, 0, 1, 0)
		fill.BackgroundColor3 = ACCENT
		fill.BorderSizePixel = 0
		Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

		local function makeKnob(parent2, pos)
			local kn = Instance.new("TextButton", parent2)
			kn.Size = UDim2.new(0, 14, 0, 14)
			kn.Position = pos
			kn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			kn.Text = ""
			kn.AutoButtonColor = false
			Instance.new("UICorner", kn).CornerRadius = UDim.new(1, 0)
			return kn
		end

		local kn1 = makeKnob(fill, UDim2.new(0, -7, 0.5, -7))
		local kn2 = makeKnob(fill, UDim2.new(1, -7, 0.5, -7))

		local d1, d2 = false, false

		local function syncFill()
			fill.Position = UDim2.new(lowPct, 0, 0, 0)
			fill.Size = UDim2.new(highPct - lowPct, 0, 1, 0)
			vl.Text = tostring(valLow) .. unit .. " - " .. tostring(valHigh) .. unit
			if callback then callback(valLow, valHigh) end
		end

		kn1.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then d1 = true end
		end)
		kn2.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then d2 = true end
		end)
		uis.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then d1 = false; d2 = false end
		end)
		uis.InputChanged:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
				local pct = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
				if d1 then
					lowPct = math.min(pct, highPct)
					valLow = math.floor(min + (max - min) * lowPct)
					syncFill()
				elseif d2 then
					highPct = math.max(pct, lowPct)
					valHigh = math.floor(min + (max - min) * highPct)
					syncFill()
				end
			end
		end)
	end

	function self:Button(text, parent, callback)
		local b = Instance.new("TextButton", parent)
		b.Size = UDim2.new(1, 0, 0, 36)
		b.BackgroundColor3 = Color3.fromRGB(20, 21, 28)
		b.Text = text
		b.TextColor3 = Color3.fromRGB(240, 240, 245)
		b.Font = Enum.Font.Ubuntu
		b.TextSize = 14
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
		local bs = Instance.new("UIStroke", b)
		bs.Color = Color3.fromRGB(28, 30, 40)
		bs.Thickness = 1
		b.MouseButton1Click:Connect(function()
			if callback then callback() end
			notify(text .. " executed!")
		end)
	end

	function self:TextBox(placeholder, parent, callback)
		local b = Instance.new("TextBox", parent)
		b.Size = UDim2.new(1, 0, 0, 36)
		b.BackgroundColor3 = Color3.fromRGB(20, 21, 28)
		b.Text = ""
		b.PlaceholderText = placeholder
		b.PlaceholderColor3 = Color3.fromRGB(80, 82, 98)
		b.TextColor3 = Color3.fromRGB(240, 240, 245)
		b.Font = Enum.Font.Ubuntu
		b.TextSize = 14
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
		local bs = Instance.new("UIStroke", b)
		bs.Color = Color3.fromRGB(28, 30, 40)
		bs.Thickness = 1
		b.FocusLost:Connect(function(enter)
			if enter and b.Text ~= "" then
				notify("Input: " .. b.Text)
				if callback then callback(b.Text) end
			end
		end)
		return b
	end

	function self:ThemeSettingsApply(col1, col2)
		self:Title("Theme", col1)
		self:ColorTile("Accent Color", ACCENT, col1, function(c)
			obs.Color = c
			cpConfirm.BackgroundColor3 = c
		end)
		self:ColorTile("Background Color", BG, col1, function(c)
			mf.BackgroundColor3 = c
		end)
		self:ColorTile("Sidebar Color", SIDEBAR_COL, col1, function(c)
			sb.BackgroundColor3 = c
			sbf.BackgroundColor3 = c
		end)
		self:ColorTile("Text Color", TEXT_COL, col1, function(c)
			ht.TextColor3 = c
		end)
		self:Button("Reset Theme", col1, function()
			obs.Color = Color3.fromRGB(240, 45, 70)
			cpConfirm.BackgroundColor3 = Color3.fromRGB(240, 45, 70)
			mf.BackgroundColor3 = Color3.fromRGB(11, 12, 16)
			sb.BackgroundColor3 = Color3.fromRGB(14, 15, 20)
			sbf.BackgroundColor3 = Color3.fromRGB(14, 15, 20)
			ht.TextColor3 = Color3.fromRGB(240, 240, 245)
			notify("Theme reset!")
		end)
	end

	function self:KeybindApply(parent)
		self:Title("Menu Toggle", parent)
		local f = Instance.new("Frame", parent)
		f.Size = UDim2.new(1, 0, 0, 32)
		f.BackgroundTransparency = 1

		local l = Instance.new("TextLabel", f)
		l.Size = UDim2.new(1, -120, 1, 0)
		l.BackgroundTransparency = 1
		l.Text = "Menu Keybind"
		l.TextColor3 = Color3.fromRGB(200, 202, 215)
		l.Font = Enum.Font.Ubuntu
		l.TextSize = 14
		l.TextXAlignment = Enum.TextXAlignment.Left

		local kb = Instance.new("TextButton", f)
		kb.Size = UDim2.new(0, 80, 0, 24)
		kb.Position = UDim2.new(1, -80, 0.5, -12)
		kb.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
		kb.Text = TOGGLE_KEY.Name
		kb.TextColor3 = Color3.fromRGB(150, 152, 168)
		kb.Font = Enum.Font.Ubuntu
		kb.TextSize = 12
		Instance.new("UICorner", kb).CornerRadius = UDim.new(0, 4)
		local kbs = Instance.new("UIStroke", kb)
		kbs.Color = Color3.fromRGB(32, 34, 46)
		kbs.Thickness = 1

		local listening = false
		kb.MouseButton1Click:Connect(function()
			if listening then return end
			listening = true
			kb.Text = "..."
			local conn
			conn = uis.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Keyboard then
					TOGGLE_KEY = input.KeyCode
					kb.Text = TOGGLE_KEY.Name
					listening = false
					conn:Disconnect()
				end
			end)
		end)
	end

	function self:ConfigApply(col1, col2, folderName)
		folderName = folderName or "ConcordeConfigs"
		if makefolder and isfolder and not isfolder(folderName) then
			makefolder(folderName)
		end

		local function getConfigs()
			local cfgs = {}
			if isfolder and listfiles and isfolder(folderName) then
				for _, file in ipairs(listfiles(folderName)) do
					local fileName = file:match("([^/\\]+)%.json$")
					if fileName then
						table.insert(cfgs, fileName)
					end
				end
			end
			if #cfgs == 0 then
				table.insert(cfgs, "Default")
			end
			return cfgs
		end

		self:Title("Config", col1)
		local cfgInput = self:TextBox("Config Name", col1)
		local configsList = getConfigs()
		local currentConfig = configsList[1] or "Default"

		local cfgDrop = self:Dropdown("Select Config", currentConfig, configsList, col1, function(selected)
			currentConfig = selected
		end)

		self:Button("Save Config", col1, function()
			local name = (cfgInput.Text ~= "" and cfgInput.Text or currentConfig)
			if writefile then
				writefile(folderName .. "/" .. name .. ".json", "{}")
			end
			notify("Saved: " .. name)
			cfgDrop.Refresh(getConfigs())
		end)

		self:Button("Load Config", col1, function() notify("Loaded: " .. currentConfig) end)
		self:Button("Overwrite Config", col1, function()
			if writefile then
				writefile(folderName .. "/" .. currentConfig .. ".json", "{}")
			end
			notify("Overwrote: " .. currentConfig)
		end)
		self:Button("Set as Autoload", col1, function()
			if writefile then
				writefile(folderName .. "/autoload.txt", currentConfig)
			end
			notify("Autoload set: " .. currentConfig)
		end)
		self:Button("Remove Autoload", col1, function()
			if delfile and isfile and isfile(folderName .. "/autoload.txt") then
				delfile(folderName .. "/autoload.txt")
			end
			notify("Removed autoload")
		end)
		self:Button("Delete Config", col1, function()
			if delfile and isfile and isfile(folderName .. "/" .. currentConfig .. ".json") then
				delfile(folderName .. "/" .. currentConfig .. ".json")
			end
			notify("Deleted: " .. currentConfig)
			local newConfigs = getConfigs()
			cfgDrop.Refresh(newConfigs)
			currentConfig = newConfigs[1] or "Default"
		end)
	end

	return self
end

return ConcordeLib
