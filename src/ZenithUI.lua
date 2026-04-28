local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local ZenithUI = {}
ZenithUI.__index = ZenithUI

local DEFAULT_THEME = {
	Background = Color3.fromRGB(20, 24, 31),
	Surface = Color3.fromRGB(24, 29, 37),
	SurfaceAlt = Color3.fromRGB(31, 38, 49),
	Stroke = Color3.fromRGB(55, 66, 83),
	Text = Color3.fromRGB(247, 248, 251),
	Muted = Color3.fromRGB(153, 160, 173),
	Accent = Color3.fromRGB(255, 122, 154),
	Success = Color3.fromRGB(114, 214, 149),
	Danger = Color3.fromRGB(255, 102, 120),
}

local ACCENT_PRESETS = {
	Ocean = Color3.fromRGB(96, 168, 255),
	Graphite = Color3.fromRGB(162, 172, 186),
	Mint = Color3.fromRGB(102, 214, 181),
	Rose = Color3.fromRGB(255, 128, 156),
	Amber = Color3.fromRGB(255, 191, 94),
}

local function mergeTheme(base, override)
	local result = {}
	for key, value in pairs(base) do
		result[key] = value
	end
	for key, value in pairs(override or {}) do
		result[key] = value
	end
	return result
end

local function create(className, props)
	local instance = Instance.new(className)
	for key, value in pairs(props or {}) do
		instance[key] = value
	end
	return instance
end

local function corner(radius)
	return create("UICorner", {
		CornerRadius = UDim.new(0, radius),
	})
end

local function stroke(color, thickness, transparency)
	return create("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
	})
end

local function padding(top, right, bottom, left)
	return create("UIPadding", {
		PaddingTop = UDim.new(0, top),
		PaddingRight = UDim.new(0, right),
		PaddingBottom = UDim.new(0, bottom),
		PaddingLeft = UDim.new(0, left),
	})
end

local function formatValue(value, decimals)
	if typeof(value) == "number" then
		if decimals and decimals > 0 then
			return string.format("%." .. decimals .. "f", value)
		end
		return tostring(math.floor(value + 0.5))
	end
	return tostring(value)
end

local function cloneTable(source)
	local result = {}
	for key, value in pairs(source) do
		if type(value) == "table" then
			result[key] = cloneTable(value)
		else
			result[key] = value
		end
	end
	return result
end

local function supportsFiles()
	return type(isfolder) == "function"
		and type(makefolder) == "function"
		and type(isfile) == "function"
		and type(writefile) == "function"
		and type(readfile) == "function"
end

local function safeJSONDecode(payload)
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(payload)
	end)
	return ok and decoded or nil
end

local function safeJSONEncode(payload)
	local ok, encoded = pcall(function()
		return HttpService:JSONEncode(payload)
	end)
	return ok and encoded or "{}"
end

local ConfigStore = {}
ConfigStore.__index = ConfigStore

function ConfigStore.new(rootFolder)
	local self = setmetatable({}, ConfigStore)
	self.rootFolder = rootFolder or "ZenithUI"
	self.runtime = {
		configs = {},
		meta = {
			autoload = nil,
		},
	}

	if supportsFiles() then
		if not isfolder(self.rootFolder) then
			makefolder(self.rootFolder)
		end
		local configFolder = self.rootFolder .. "/configs"
		if not isfolder(configFolder) then
			makefolder(configFolder)
		end
	end

	return self
end

function ConfigStore:getConfigPath(name)
	return string.format("%s/configs/%s.json", self.rootFolder, name)
end

function ConfigStore:getMetaPath()
	return string.format("%s/meta.json", self.rootFolder)
end

function ConfigStore:list()
	if supportsFiles() and type(listfiles) == "function" then
		local files = listfiles(self.rootFolder .. "/configs")
		local names = {}
		for _, filePath in ipairs(files) do
			local name = filePath:match("([^/\\]+)%.json$")
			if name then
				table.insert(names, name)
			end
		end
		table.sort(names)
		return names
	end

	local names = {}
	for name in pairs(self.runtime.configs) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function ConfigStore:save(name, payload)
	if supportsFiles() then
		writefile(self:getConfigPath(name), safeJSONEncode(payload))
	else
		self.runtime.configs[name] = cloneTable(payload)
	end
end

function ConfigStore:load(name)
	if supportsFiles() then
		local path = self:getConfigPath(name)
		if not isfile(path) then
			return nil
		end
		return safeJSONDecode(readfile(path))
	end

	local payload = self.runtime.configs[name]
	return payload and cloneTable(payload) or nil
end

function ConfigStore:delete(name)
	if supportsFiles() then
		local path = self:getConfigPath(name)
		if isfile(path) and type(delfile) == "function" then
			delfile(path)
		end
	else
		self.runtime.configs[name] = nil
	end
end

function ConfigStore:getMeta()
	if supportsFiles() then
		local path = self:getMetaPath()
		if not isfile(path) then
			return {
				autoload = nil,
			}
		end
		return safeJSONDecode(readfile(path)) or {
			autoload = nil,
		}
	end

	return cloneTable(self.runtime.meta)
end

function ConfigStore:setMeta(meta)
	if supportsFiles() then
		writefile(self:getMetaPath(), safeJSONEncode(meta))
	else
		self.runtime.meta = cloneTable(meta)
	end
end

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

local function makeButton(theme, text, size)
	local button = create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = theme.SurfaceAlt,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamMedium,
		Size = size or UDim2.new(1, 0, 0, 34),
		Text = text,
		TextColor3 = theme.Text,
		TextSize = 13,
	})
	corner(8).Parent = button
	stroke(theme.Stroke, 1, 0.15).Parent = button

	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.15), {
			BackgroundColor3 = theme.Accent,
			TextColor3 = Color3.fromRGB(255, 255, 255),
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.15), {
			BackgroundColor3 = theme.SurfaceAlt,
			TextColor3 = theme.Text,
		}):Play()
	end)

	return button
end

local function draggable(handle, target)
	local dragging = false
	local dragStart
	local startPos

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = target.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

local function createLabel(theme, text, color, size)
	return create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Size = size or UDim2.new(1, 0, 0, 18),
		Text = text,
		TextColor3 = color or theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
end

function ZenithUI.new(options)
	options = options or {}

	local self = setmetatable({}, Window)
	self.Theme = mergeTheme(DEFAULT_THEME, options.Theme)
	self.Title = options.Title or "Zenith UI"
	self.Subtitle = options.Subtitle or "runtime panel"
	self.SidebarTitle = options.SidebarTitle or "navigation"
	self.SettingsTitle = options.SettingsTitle or "Settings"
	self.SettingsSubtitle = options.SettingsSubtitle or "theme, config and session controls"
	self.SettingsButtonText = options.SettingsButtonText or "Settings"
	self.ToggleKey = options.ToggleKey or Enum.KeyCode.RightShift
	self.ConfigRoot = options.ConfigFolder or "ZenithUI"
	self.ConfigName = options.DefaultConfig or "default"
	self.SelectedTab = nil
	self.Flags = {}
	self.Controls = {}
	self.Tabs = {}
	self.Notifications = {}
	self.SurfaceObjects = {}
	self.BackgroundObjects = {}
	self.SurfaceAltObjects = {}
	self.StrokeObjects = {}
	self.TextObjects = {}
	self.MutedTextObjects = {}
	self.AccentObjects = {}
	self.ButtonObjects = {}
	self.ConfigStore = ConfigStore.new(self.ConfigRoot)
	self._connections = {}
	self._lastAutoloadState = nil

	self:_build()
	self:_wireToggleKey()
	self:TryAutoload()

	return self
end

function Window:_track(listName, instance, property)
	table.insert(self[listName], {
		Instance = instance,
		Property = property,
	})
	return instance
end

function Window:_applyThemeGroup(group, value)
	for _, item in ipairs(group) do
		if item.Instance and item.Instance.Parent then
			item.Instance[item.Property] = value
		end
	end
end

function Window:_refreshTheme()
	self:_applyThemeGroup(self.SurfaceObjects, self.Theme.Surface)
	self:_applyThemeGroup(self.BackgroundObjects, self.Theme.Background)
	self:_applyThemeGroup(self.SurfaceAltObjects, self.Theme.SurfaceAlt)
	self:_applyThemeGroup(self.StrokeObjects, self.Theme.Stroke)
	self:_applyThemeGroup(self.TextObjects, self.Theme.Text)
	self:_applyThemeGroup(self.MutedTextObjects, self.Theme.Muted)
	self:_applyThemeGroup(self.AccentObjects, self.Theme.Accent)

	for _, button in ipairs(self.ButtonObjects) do
		if button and button.Parent then
			button.BackgroundColor3 = self.Theme.SurfaceAlt
			button.TextColor3 = self.Theme.Text
		end
	end

	for _, tab in ipairs(self.Tabs) do
		if tab.Button and tab.Button.Parent then
			if tab == self.SelectedTab then
				tab.Button.BackgroundColor3 = self.Theme.Accent
				tab.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
			else
				tab.Button.BackgroundColor3 = self.Theme.Background
				tab.Button.TextColor3 = self.Theme.Muted
			end
		end
	end

	for id, control in pairs(self.Controls) do
		if control.SetVisual then
			control.SetVisual(self.Flags[id])
		end
	end
end

function Window:SetAccentColor(color)
	self.Theme.Accent = color
	self:_refreshTheme()
end

function Window:SetTitle(text)
	self.Title = text
	if self.TitleLabel then
		self.TitleLabel.Text = text
	end
end

function Window:SetSubtitle(text)
	self.Subtitle = text
	if self.SubtitleLabel then
		self.SubtitleLabel.Text = text
	end
end

function Window:SetSidebarTitle(text)
	self.SidebarTitle = text
	if self.SidebarLabel then
		self.SidebarLabel.Text = text
	end
end

function Window:SetSettingsTitle(text)
	self.SettingsTitle = text
	if self.SettingsTitleLabel then
		self.SettingsTitleLabel.Text = text
	end
end

function Window:SetSettingsSubtitle(text)
	self.SettingsSubtitle = text
	if self.SettingsSubtitleLabel then
		self.SettingsSubtitleLabel.Text = text
	end
end

function Window:_build()
	local theme = self.Theme

	self.Gui = create("ScreenGui", {
		Name = "ZenithUI_" .. HttpService:GenerateGUID(false),
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = PlayerGui,
	})

	self.Root = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(760, 470),
		Parent = self.Gui,
	})
	corner(14).Parent = self.Root
	self:_track("BackgroundObjects", self.Root, "BackgroundColor3")
	self:_track("StrokeObjects", stroke(theme.Stroke, 1, 0), "Color").Parent = self.Root

	local shadow = create("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Image = "rbxassetid://1316045217",
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.9,
		Position = UDim2.fromScale(0.5, 0.5),
		ScaleType = Enum.ScaleType.Slice,
		Size = UDim2.new(1, 12, 1, 12),
		SliceCenter = Rect.new(10, 10, 118, 118),
		ZIndex = 0,
		Parent = self.Root,
	})
	shadow.Name = "Shadow"

	local accentLine = create("Frame", {
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(18, 54),
		Size = UDim2.new(1, -36, 0, 2),
		Parent = self.Root,
	})
	self:_track("AccentObjects", accentLine, "BackgroundColor3")

	local topbar = create("Frame", {
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 54),
		Parent = self.Root,
	})
	self:_track("SurfaceObjects", topbar, "BackgroundColor3")
	corner(14).Parent = topbar

	local topCover = create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 14),
		Parent = topbar,
	})
	self:_track("SurfaceObjects", topCover, "BackgroundColor3")

	local titleHolder = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -150, 1, 0),
		Parent = topbar,
	})
	padding(10, 18, 10, 18).Parent = titleHolder

	local title = createLabel(theme, self.Title, theme.Text, UDim2.new(1, 0, 0, 18))
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.Parent = titleHolder
	self.TitleLabel = title
	self:_track("TextObjects", title, "TextColor3")

	local subtitle = createLabel(theme, self.Subtitle, theme.Muted, UDim2.new(1, 0, 0, 16))
	subtitle.Position = UDim2.fromOffset(0, 20)
	subtitle.TextSize = 11
	subtitle.Parent = titleHolder
	self.SubtitleLabel = subtitle
	self:_track("MutedTextObjects", subtitle, "TextColor3")

	local topButtons = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(172, 30),
		Parent = topbar,
	})

	local topLayout = create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = topButtons,
	})
	topLayout.VerticalAlignment = Enum.VerticalAlignment.Center

	local hideButton = makeButton(theme, "_", UDim2.fromOffset(38, 30))
	hideButton.LayoutOrder = 1
	hideButton.Parent = topButtons
	table.insert(self.ButtonObjects, hideButton)

	local configButton = makeButton(theme, self.SettingsButtonText, UDim2.fromOffset(118, 30))
	configButton.LayoutOrder = 2
	configButton.Parent = topButtons
	table.insert(self.ButtonObjects, configButton)

	local sidebar = create("Frame", {
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(12, 66),
		Size = UDim2.new(0, 180, 1, -78),
		Parent = self.Root,
	})
	self:_track("SurfaceObjects", sidebar, "BackgroundColor3")
	corner(12).Parent = sidebar
	self:_track("StrokeObjects", stroke(theme.Stroke, 1, 0.1), "Color").Parent = sidebar
	padding(14, 12, 14, 12).Parent = sidebar

	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = sidebar,
	})

	local brand = createLabel(theme, self.SidebarTitle, theme.Muted, UDim2.new(1, 0, 0, 16))
	brand.TextSize = 11
	brand.LayoutOrder = 0
	brand.Parent = sidebar
	self.SidebarLabel = brand
	self:_track("MutedTextObjects", brand, "TextColor3")

	local content = create("Frame", {
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(204, 66),
		Size = UDim2.new(1, -216, 1, -78),
		Parent = self.Root,
	})
	self:_track("SurfaceObjects", content, "BackgroundColor3")
	corner(12).Parent = content
	self:_track("StrokeObjects", stroke(theme.Stroke, 1, 0.1), "Color").Parent = content

	self.Sidebar = sidebar
	self.Content = content
	self.HideButton = hideButton
	self.ConfigButton = configButton

	self.Pages = create("Folder", {
		Name = "Pages",
		Parent = content,
	})

	self.ConfigPanel = self:_createConfigPanel()
	self.NotificationHolder = self:_createNotificationHolder()

	hideButton.MouseButton1Click:Connect(function()
		self:Toggle()
	end)

	configButton.MouseButton1Click:Connect(function()
		self:SetConfigMenuVisible(not self.ConfigPanel.Visible)
	end)

	draggable(topbar, self.Root)
end

function Window:_createNotificationHolder()
	local holder = create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -16, 0, 16),
		Size = UDim2.fromOffset(260, 300),
		Parent = self.Gui,
	})

	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = holder,
	})

	return holder
end

function Window:_createConfigPanel()
	local theme = self.Theme

	local panel = create("Frame", {
		AnchorPoint = Vector2.new(0, 0),
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(216, 66),
		Size = UDim2.fromOffset(326, 392),
		Visible = false,
		ZIndex = 30,
		Parent = self.Root,
	})
	self:_track("SurfaceObjects", panel, "BackgroundColor3")
	corner(12).Parent = panel
	self:_track("StrokeObjects", stroke(theme.Stroke, 1, 0), "Color").Parent = panel
	padding(12, 12, 12, 12).Parent = panel

	local title = createLabel(theme, self.SettingsTitle, theme.Text, UDim2.new(1, -36, 0, 18))
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.ZIndex = 31
	title.Parent = panel
	self.SettingsTitleLabel = title
	self:_track("TextObjects", title, "TextColor3")

	local close = makeButton(theme, "X", UDim2.fromOffset(24, 24))
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, 0, 0, 0)
	close.ZIndex = 31
	close.Parent = panel
	table.insert(self.ButtonObjects, close)

	local sub = createLabel(theme, self.SettingsSubtitle, theme.Muted, UDim2.new(1, 0, 0, 16))
	sub.Position = UDim2.fromOffset(0, 18)
	sub.TextSize = 11
	sub.ZIndex = 31
	sub.Parent = panel
	self.SettingsSubtitleLabel = sub
	self:_track("MutedTextObjects", sub, "TextColor3")

	local appearanceLabel = createLabel(theme, "Accent", theme.Muted, UDim2.new(1, 0, 0, 16))
	appearanceLabel.Position = UDim2.fromOffset(0, 42)
	appearanceLabel.TextSize = 11
	appearanceLabel.ZIndex = 31
	appearanceLabel.Parent = panel
	self:_track("MutedTextObjects", appearanceLabel, "TextColor3")

	local accentRow = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 62),
		Size = UDim2.new(1, 0, 0, 68),
		ZIndex = 31,
		Parent = panel,
	})

	create("UIGridLayout", {
		CellPadding = UDim2.fromOffset(8, 8),
		CellSize = UDim2.fromOffset(94, 30),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = accentRow,
	})

	for name, color in pairs(ACCENT_PRESETS) do
		local accentButton = makeButton(theme, name, UDim2.fromOffset(94, 30))
		accentButton.Parent = accentRow
		table.insert(self.ButtonObjects, accentButton)
		accentButton.MouseButton1Click:Connect(function()
			self:SetAccentColor(color)
		end)
	end

	local input = create("TextBox", {
		BackgroundColor3 = theme.SurfaceAlt,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Font = Enum.Font.Gotham,
		PlaceholderColor3 = theme.Muted,
		PlaceholderText = "config name",
		Position = UDim2.fromOffset(0, 132),
		Size = UDim2.new(1, 0, 0, 36),
		Text = self.ConfigName,
		TextColor3 = theme.Text,
		TextSize = 13,
		ZIndex = 31,
		Parent = panel,
	})
	self:_track("SurfaceAltObjects", input, "BackgroundColor3")
	self:_track("TextObjects", input, "TextColor3")
	self:_track("MutedTextObjects", input, "PlaceholderColor3")
	corner(8).Parent = input
	self:_track("StrokeObjects", stroke(theme.Stroke, 1, 0.15), "Color").Parent = input
	padding(0, 12, 0, 12).Parent = input

	local buttonRow = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 178),
		Size = UDim2.new(1, 0, 0, 34),
		ZIndex = 31,
		Parent = panel,
	})

	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = buttonRow,
	})

	local save = makeButton(theme, "Kaydet", UDim2.fromOffset(102, 34))
	local load = makeButton(theme, "Yukle", UDim2.fromOffset(102, 34))
	local refresh = makeButton(theme, "Yenile", UDim2.fromOffset(102, 34))
	save.Parent = buttonRow
	load.Parent = buttonRow
	refresh.Parent = buttonRow
	table.insert(self.ButtonObjects, save)
	table.insert(self.ButtonObjects, load)
	table.insert(self.ButtonObjects, refresh)

	local autoRow = create("Frame", {
		BackgroundColor3 = theme.SurfaceAlt,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 222),
		Size = UDim2.new(1, 0, 0, 42),
		ZIndex = 31,
		Parent = panel,
	})
	self:_track("SurfaceAltObjects", autoRow, "BackgroundColor3")
	corner(8).Parent = autoRow
	self:_track("StrokeObjects", stroke(theme.Stroke, 1, 0.15), "Color").Parent = autoRow

	local autoLabel = createLabel(theme, "Autoload this config", theme.Text, UDim2.new(1, -60, 1, 0))
	autoLabel.Position = UDim2.fromOffset(12, 0)
	autoLabel.ZIndex = 31
	autoLabel.Parent = autoRow
	self:_track("TextObjects", autoLabel, "TextColor3")

	local autoToggle = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		AutoButtonColor = false,
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(34, 20),
		Text = "",
		ZIndex = 31,
		Parent = autoRow,
	})
	self:_track("BackgroundObjects", autoToggle, "BackgroundColor3")
	corner(10).Parent = autoToggle

	local autoKnob = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = theme.Text,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(2, 10),
		Size = UDim2.fromOffset(16, 16),
		ZIndex = 32,
		Parent = autoToggle,
	})
	self:_track("TextObjects", autoKnob, "BackgroundColor3")
	corner(8).Parent = autoKnob

	local listFrame = create("ScrollingFrame", {
		Active = true,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		Position = UDim2.fromOffset(0, 274),
		ScrollBarImageColor3 = theme.Accent,
		ScrollBarThickness = 3,
		Size = UDim2.new(1, 0, 0, 70),
		ZIndex = 31,
		Parent = panel,
	})
	self:_track("BackgroundObjects", listFrame, "BackgroundColor3")
	self:_track("AccentObjects", listFrame, "ScrollBarImageColor3")
	corner(8).Parent = listFrame
	padding(8, 8, 8, 8).Parent = listFrame
	create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = listFrame,
	})

	local unload = makeButton(theme, "Unload", UDim2.new(1, 0, 0, 34))
	unload.Position = UDim2.fromOffset(0, 352)
	unload.ZIndex = 31
	unload.Parent = panel
	table.insert(self.ButtonObjects, unload)

	local function syncAutoToggle()
		local meta = self.ConfigStore:getMeta()
		local active = meta.autoload == self.ConfigName
		self._lastAutoloadState = active
		autoToggle.BackgroundColor3 = active and theme.Accent or theme.Background
		TweenService:Create(autoKnob, TweenInfo.new(0.15), {
			Position = active and UDim2.new(1, -18, 0.5, 0) or UDim2.fromOffset(2, 10),
		}):Play()
	end

	local function refreshConfigList()
		for _, child in ipairs(listFrame:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		self.ConfigName = input.Text ~= "" and input.Text or self.ConfigName
		syncAutoToggle()

		for _, name in ipairs(self.ConfigStore:list()) do
			local item = create("Frame", {
				BackgroundColor3 = theme.SurfaceAlt,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 34),
				ZIndex = 31,
				Parent = listFrame,
			})
			self:_track("SurfaceAltObjects", item, "BackgroundColor3")
			corner(8).Parent = item
			self:_track("StrokeObjects", stroke(theme.Stroke, 1, 0.15), "Color").Parent = item

			local label = createLabel(theme, name, theme.Text, UDim2.new(1, -82, 1, 0))
			label.Position = UDim2.fromOffset(12, 0)
			label.ZIndex = 32
			label.Parent = item
			self:_track("TextObjects", label, "TextColor3")

			local useButton = makeButton(theme, "Use", UDim2.fromOffset(56, 24))
			useButton.AnchorPoint = Vector2.new(1, 0.5)
			useButton.Position = UDim2.new(1, -8, 0.5, 0)
			useButton.ZIndex = 32
			useButton.Parent = item
			table.insert(self.ButtonObjects, useButton)

			useButton.MouseButton1Click:Connect(function()
				input.Text = name
				self.ConfigName = name
				syncAutoToggle()
			end)
		end
	end

	close.MouseButton1Click:Connect(function()
		self:SetConfigMenuVisible(false)
	end)

	input.FocusLost:Connect(function()
		if input.Text ~= "" then
			self.ConfigName = input.Text
			syncAutoToggle()
		end
	end)

	save.MouseButton1Click:Connect(function()
		self.ConfigName = input.Text ~= "" and input.Text or self.ConfigName
		self:SaveConfig(self.ConfigName)
		refreshConfigList()
	end)

	load.MouseButton1Click:Connect(function()
		self.ConfigName = input.Text ~= "" and input.Text or self.ConfigName
		self:LoadConfig(self.ConfigName)
		refreshConfigList()
	end)

	refresh.MouseButton1Click:Connect(refreshConfigList)
	unload.MouseButton1Click:Connect(function()
		self:Destroy()
	end)

	autoToggle.MouseButton1Click:Connect(function()
		self.ConfigName = input.Text ~= "" and input.Text or self.ConfigName
		local meta = self.ConfigStore:getMeta()
		local shouldEnable = meta.autoload ~= self.ConfigName
		meta.autoload = shouldEnable and self.ConfigName or nil
		self.ConfigStore:setMeta(meta)
		syncAutoToggle()
	end)

	self._refreshConfigs = refreshConfigList
	refreshConfigList()
	return panel
end

function Window:_wireToggleKey()
	table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == self.ToggleKey then
			self:Toggle()
		end
	end))
end

function Window:SetConfigMenuVisible(visible)
	self.ConfigPanel.Visible = visible
	if visible and self._refreshConfigs then
		self._refreshConfigs()
	end
end

function Window:Toggle()
	self.Root.Visible = not self.Root.Visible
	if not self.Root.Visible then
		self.ConfigPanel.Visible = false
	end
end

function Window:SetValue(id, value, skipCallback)
	local control = self.Controls[id]
	if not control then
		return
	end

	self.Flags[id] = value

	if control.SetVisual then
		control.SetVisual(value)
	end

	if not skipCallback and control.Callback then
		task.spawn(control.Callback, value)
	end
end

function Window:GetValue(id)
	return self.Flags[id]
end

function Window:CollectConfig()
	local payload = {}
	for id in pairs(self.Controls) do
		payload[id] = self.Flags[id]
	end
	return payload
end

function Window:ApplyConfig(payload)
	for id, value in pairs(payload or {}) do
		if self.Controls[id] then
			self:SetValue(id, value)
		end
	end
end

function Window:SaveConfig(name)
	name = name or self.ConfigName
	self.ConfigStore:save(name, self:CollectConfig())
end

function Window:LoadConfig(name)
	name = name or self.ConfigName
	local payload = self.ConfigStore:load(name)
	if not payload then
		return
	end

	self:ApplyConfig(payload)
end

function Window:TryAutoload()
	local meta = self.ConfigStore:getMeta()
	if meta.autoload then
		task.defer(function()
			self:LoadConfig(meta.autoload)
		end)
	end
end

function Window:Notify(options)
	options = options or {}
	local theme = self.Theme

	local item = create("Frame", {
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(250, 60),
		Parent = self.NotificationHolder,
	})
	self:_track("SurfaceObjects", item, "BackgroundColor3")
	corner(10).Parent = item
	self:_track("StrokeObjects", stroke(theme.Stroke, 1, 0.1), "Color").Parent = item
	padding(10, 12, 10, 12).Parent = item

	local title = createLabel(theme, options.Title or "Notification", theme.Text, UDim2.new(1, 0, 0, 18))
	title.Font = Enum.Font.GothamBold
	title.Parent = item
	self:_track("TextObjects", title, "TextColor3")

	local message = createLabel(theme, options.Content or "", theme.Muted, UDim2.new(1, 0, 0, 16))
	message.Position = UDim2.fromOffset(0, 20)
	message.TextSize = 11
	message.Parent = item
	self:_track("MutedTextObjects", message, "TextColor3")

	item.BackgroundTransparency = 1
	TweenService:Create(item, TweenInfo.new(0.18), {BackgroundTransparency = 0}):Play()

	task.delay(options.Duration or 3.2, function()
		if item.Parent then
			local tween = TweenService:Create(item, TweenInfo.new(0.2), {
				BackgroundTransparency = 1,
			})
			tween:Play()
			tween.Completed:Wait()
			item:Destroy()
		end
	end)
end

function Window:AddTab(options)
	options = options or {}
	local theme = self.Theme

	local button = create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamMedium,
		Size = UDim2.new(1, 0, 0, 36),
		Text = options.Title or "Tab",
		TextColor3 = theme.Muted,
		TextSize = 13,
		Parent = self.Sidebar,
	})
	self:_track("BackgroundObjects", button, "BackgroundColor3")
	self:_track("MutedTextObjects", button, "TextColor3")
	corner(8).Parent = button

	local page = create("ScrollingFrame", {
		Active = true,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		ScrollBarImageColor3 = theme.Accent,
		ScrollBarThickness = 4,
		Size = UDim2.new(1, 0, 1, 0),
		Visible = false,
		Parent = self.Content,
	})
	padding(14, 14, 14, 14).Parent = page
	create("UIListLayout", {
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = page,
	})

	local tab = setmetatable({
		Window = self,
		Button = button,
		Page = page,
		Sections = {},
	}, Tab)

	local function selectTab()
		self.SelectedTab = tab
		for _, other in ipairs(self.Tabs) do
			other.Page.Visible = false
			other.Button.BackgroundColor3 = theme.Background
			other.Button.TextColor3 = theme.Muted
		end

		page.Visible = true
		button.BackgroundColor3 = theme.Accent
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
	end

	button.MouseButton1Click:Connect(selectTab)

	table.insert(self.Tabs, tab)
	if #self.Tabs == 1 then
		selectTab()
	end

	return tab
end

function Tab:AddSection(title)
	local theme = self.Window.Theme
	local frame = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = theme.SurfaceAlt,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = self.Page,
	})
	self.Window:_track("SurfaceAltObjects", frame, "BackgroundColor3")
	corner(10).Parent = frame
	self.Window:_track("StrokeObjects", stroke(theme.Stroke, 1, 0.1), "Color").Parent = frame
	padding(12, 12, 12, 12).Parent = frame

	local heading = createLabel(theme, title or "Section", theme.Text, UDim2.new(1, 0, 0, 18))
	heading.Font = Enum.Font.GothamBold
	heading.Parent = frame
	self.Window:_track("TextObjects", heading, "TextColor3")

	local list = create("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = frame,
	})

	heading.LayoutOrder = 0

	local section = setmetatable({
		Window = self.Window,
		Frame = frame,
		List = list,
	}, Section)

	table.insert(self.Sections, section)
	return section
end

function Section:_registerControl(options)
	self.Window.Controls[options.Id] = options
	self.Window.Flags[options.Id] = options.Default
	if options.SetVisual then
		options.SetVisual(options.Default)
	end
	if options.Callback then
		task.spawn(options.Callback, options.Default)
	end
end

function Section:AddLabel(text)
	local label = createLabel(self.Window.Theme, text, self.Window.Theme.Muted, UDim2.new(1, 0, 0, 18))
	label.Parent = self.Frame
	self.Window:_track("MutedTextObjects", label, "TextColor3")
	return label
end

function Section:AddButton(options)
	options = options or {}
	local button = makeButton(self.Window.Theme, options.Title or "Button")
	button.Parent = self.Frame
	table.insert(self.Window.ButtonObjects, button)
	button.MouseButton1Click:Connect(function()
		if options.Callback then
			task.spawn(options.Callback)
		end
	end)
	return button
end

function Section:AddToggle(options)
	options = options or {}
	local theme = self.Window.Theme
	local frame = create("Frame", {
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 44),
		Parent = self.Frame,
	})
	self.Window:_track("BackgroundObjects", frame, "BackgroundColor3")
	corner(8).Parent = frame

	local label = createLabel(theme, options.Title or options.Id or "Toggle", theme.Text, UDim2.new(1, -64, 1, 0))
	label.Position = UDim2.fromOffset(12, 0)
	label.Parent = frame
	self.Window:_track("TextObjects", label, "TextColor3")

	local switch = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		AutoButtonColor = false,
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(38, 22),
		Text = "",
		Parent = frame,
	})
	self.Window:_track("BackgroundObjects", switch, "BackgroundColor3")
	corner(11).Parent = switch
	self.Window:_track("StrokeObjects", stroke(theme.Stroke, 1, 0.15), "Color").Parent = switch

	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = theme.Text,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(3, 11),
		Size = UDim2.fromOffset(16, 16),
		Parent = switch,
	})
	self.Window:_track("TextObjects", knob, "BackgroundColor3")
	corner(8).Parent = knob

	local id = options.Id or options.Title

	local function setVisual(value)
		TweenService:Create(switch, TweenInfo.new(0.15), {
			BackgroundColor3 = value and theme.Accent or theme.Background,
		}):Play()
		TweenService:Create(knob, TweenInfo.new(0.15), {
			Position = value and UDim2.new(1, -19, 0.5, 0) or UDim2.fromOffset(3, 11),
		}):Play()
	end

	switch.MouseButton1Click:Connect(function()
		self.Window:SetValue(id, not self.Window.Flags[id])
	end)

	self:_registerControl({
		Id = id,
		Default = options.Default or false,
		Callback = options.Callback,
		SetVisual = setVisual,
	})

	return frame
end

function Section:AddSlider(options)
	options = options or {}
	local theme = self.Window.Theme
	local min = options.Min or 0
	local max = options.Max or 100
	local decimals = options.Decimals or 0

	local frame = create("Frame", {
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 58),
		Parent = self.Frame,
	})
	self.Window:_track("BackgroundObjects", frame, "BackgroundColor3")
	corner(8).Parent = frame
	padding(10, 12, 10, 12).Parent = frame

	local label = createLabel(theme, options.Title or options.Id or "Slider", theme.Text, UDim2.new(1, -60, 0, 16))
	label.Parent = frame
	self.Window:_track("TextObjects", label, "TextColor3")

	local valueLabel = createLabel(theme, "", theme.Muted, UDim2.fromOffset(48, 16))
	valueLabel.AnchorPoint = Vector2.new(1, 0)
	valueLabel.Position = UDim2.new(1, 0, 0, 0)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = frame
	self.Window:_track("MutedTextObjects", valueLabel, "TextColor3")

	local bar = create("Frame", {
		BackgroundColor3 = theme.SurfaceAlt,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(12, 30),
		Size = UDim2.new(1, -24, 0, 8),
		Parent = frame,
	})
	self.Window:_track("SurfaceAltObjects", bar, "BackgroundColor3")
	corner(4).Parent = bar

	local fill = create("Frame", {
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0, 1),
		Parent = bar,
	})
	self.Window:_track("AccentObjects", fill, "BackgroundColor3")
	corner(4).Parent = fill

	local hitbox = create("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 8),
		Text = "",
		Parent = bar,
	})

	local id = options.Id or options.Title

	local function applyFromPosition(x)
		local alpha = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		local raw = min + ((max - min) * alpha)
		local snap = decimals > 0 and tonumber(string.format("%." .. decimals .. "f", raw)) or math.floor(raw + 0.5)
		self.Window:SetValue(id, snap)
	end

	local dragging = false

	hitbox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			applyFromPosition(input.Position.X)
		end
	end)

	hitbox.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			applyFromPosition(input.Position.X)
		end
	end)

	local function setVisual(value)
		local alpha = (value - min) / (max - min)
		fill.Size = UDim2.fromScale(math.clamp(alpha, 0, 1), 1)
		valueLabel.Text = formatValue(value, decimals)
	end

	self:_registerControl({
		Id = id,
		Default = options.Default or min,
		Callback = options.Callback,
		SetVisual = setVisual,
	})

	return frame
end

function Section:AddInput(options)
	options = options or {}
	local theme = self.Window.Theme
	local frame = create("Frame", {
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 72),
		Parent = self.Frame,
	})
	self.Window:_track("BackgroundObjects", frame, "BackgroundColor3")
	corner(8).Parent = frame
	padding(10, 12, 10, 12).Parent = frame

	local id = options.Id or options.Title
	local label = createLabel(theme, options.Title or id or "Input", theme.Text, UDim2.new(1, 0, 0, 16))
	label.Parent = frame
	self.Window:_track("TextObjects", label, "TextColor3")

	local box = create("TextBox", {
		BackgroundColor3 = theme.SurfaceAlt,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Font = Enum.Font.Gotham,
		PlaceholderColor3 = theme.Muted,
		PlaceholderText = options.Placeholder or "",
		Position = UDim2.fromOffset(12, 30),
		Size = UDim2.new(1, -24, 0, 30),
		Text = "",
		TextColor3 = theme.Text,
		TextSize = 13,
		Parent = frame,
	})
	self.Window:_track("SurfaceAltObjects", box, "BackgroundColor3")
	self.Window:_track("TextObjects", box, "TextColor3")
	self.Window:_track("MutedTextObjects", box, "PlaceholderColor3")
	corner(8).Parent = box
	self.Window:_track("StrokeObjects", stroke(theme.Stroke, 1, 0.15), "Color").Parent = box
	padding(0, 10, 0, 10).Parent = box

	box.FocusLost:Connect(function()
		self.Window:SetValue(id, box.Text)
	end)

	local function setVisual(value)
		box.Text = tostring(value or "")
	end

	self:_registerControl({
		Id = id,
		Default = options.Default or "",
		Callback = options.Callback,
		SetVisual = setVisual,
	})

	return frame
end

function Section:AddDropdown(options)
	options = options or {}
	local theme = self.Window.Theme
	local values = options.Values or {}
	local id = options.Id or options.Title

	local frame = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = self.Frame,
	})
	self.Window:_track("BackgroundObjects", frame, "BackgroundColor3")
	corner(8).Parent = frame
	padding(10, 12, 10, 12).Parent = frame

	local label = createLabel(theme, options.Title or id or "Dropdown", theme.Text, UDim2.new(1, 0, 0, 16))
	label.Parent = frame
	self.Window:_track("TextObjects", label, "TextColor3")

	local current = create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = theme.SurfaceAlt,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(12, 30),
		Size = UDim2.new(1, -24, 0, 30),
		Text = "",
		TextColor3 = theme.Text,
		TextSize = 13,
		Font = Enum.Font.Gotham,
		Parent = frame,
	})
	self.Window:_track("SurfaceAltObjects", current, "BackgroundColor3")
	self.Window:_track("TextObjects", current, "TextColor3")
	corner(8).Parent = current
	self.Window:_track("StrokeObjects", stroke(theme.Stroke, 1, 0.15), "Color").Parent = current

	local list = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 66),
		Size = UDim2.new(1, -24, 0, 0),
		Visible = false,
		Parent = frame,
	})
	create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = list,
	})

	local opened = false

	for _, value in ipairs(values) do
		local item = makeButton(theme, tostring(value), UDim2.new(1, 0, 0, 28))
		item.Parent = list
		table.insert(self.Window.ButtonObjects, item)
		item.MouseButton1Click:Connect(function()
			self.Window:SetValue(id, value)
			opened = false
			list.Visible = false
		end)
	end

	current.MouseButton1Click:Connect(function()
		opened = not opened
		list.Visible = opened
	end)

	local function setVisual(value)
		current.Text = tostring(value)
	end

	self:_registerControl({
		Id = id,
		Default = options.Default or values[1] or "",
		Callback = options.Callback,
		SetVisual = setVisual,
	})

	return frame
end

function Window:Destroy()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	if self.Gui and self.Gui.Parent then
		self.Gui:Destroy()
	end
end

return ZenithUI
