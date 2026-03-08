local AlmondGUI = {}
AlmondGUI.__index = AlmondGUI
AlmondGUI.Version = "1.1.0"

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui       = game:GetService("StarterGui")
local LocalPlayer      = Players.LocalPlayer

local DefaultTheme = {
    Background       = Color3.fromRGB(18, 18, 26),
    TitleBar         = Color3.fromRGB(22, 22, 32),
    Surface          = Color3.fromRGB(28, 28, 40),
    SurfaceHover     = Color3.fromRGB(38, 38, 52),
    SurfaceActive    = Color3.fromRGB(48, 48, 64),
    Accent           = Color3.fromRGB(108, 92, 231),
    AccentHover      = Color3.fromRGB(128, 112, 248),
    AccentDark       = Color3.fromRGB(78, 65, 180),
    TabActive        = Color3.fromRGB(108, 92, 231),
    TabInactive      = Color3.fromRGB(28, 28, 40),
    TabHover         = Color3.fromRGB(38, 38, 52),
    Text             = Color3.fromRGB(225, 225, 240),
    TextSecondary    = Color3.fromRGB(155, 155, 175),
    TextMuted        = Color3.fromRGB(100, 100, 120),
    Border           = Color3.fromRGB(45, 45, 62),
    SliderTrack      = Color3.fromRGB(40, 40, 55),
    SliderFill       = Color3.fromRGB(108, 92, 231),
    ToggleOff        = Color3.fromRGB(55, 55, 72),
    ToggleOn         = Color3.fromRGB(108, 92, 231),
    ToggleKnob       = Color3.fromRGB(240, 240, 250),
    InputBackground  = Color3.fromRGB(14, 14, 20),
    DropdownBg       = Color3.fromRGB(22, 22, 32),
    Success          = Color3.fromRGB(46, 213, 115),
    Warning          = Color3.fromRGB(255, 177, 66),
    Error            = Color3.fromRGB(252, 92, 101),
    Info             = Color3.fromRGB(69, 170, 242),
    MiniIconBg       = Color3.fromRGB(28, 28, 40),
    Font             = Enum.Font.GothamMedium,
    FontBold         = Enum.Font.GothamBold,
    FontSemibold     = Enum.Font.GothamSemibold,
    FontLight        = Enum.Font.Gotham,
    TitleSize        = 16,
    TabSize          = 13,
    ControlSize      = 14,
    ValueSize        = 13,
    SectionSize      = 15,
    LabelSize        = 13,
    CornerRadius     = UDim.new(0, 8),
    CornerSmall      = UDim.new(0, 6),
    CornerLarge      = UDim.new(0, 12),
    CornerPill       = UDim.new(0, 999),
    TitleBarHeight   = 42,
    TabWidth         = 130,
    TabWidthMobile   = 44,
    ControlHeight    = 38,
    SliderHeight     = 52,
    ToggleSwitchW    = 44,
    ToggleSwitchH    = 24,
    ToggleKnobSize   = 18,
    Padding          = 12,
    ControlPadding   = 8,
    TweenSpeed       = 0.25,
    TweenSpeedFast   = 0.12,
    TweenSpeedSlow   = 0.4,
    EasingStyle      = Enum.EasingStyle.Quart,
    EasingDirection  = Enum.EasingDirection.Out,
}

local function Create(className, properties, children)
    local inst = Instance.new(className)
    local assignParent
    if properties then
        for key, value in pairs(properties) do
            if key == "Parent" then
                assignParent = value
            else
                inst[key] = value
            end
        end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = inst
        end
    end
    if assignParent then
        inst.Parent = assignParent
    end
    return inst
end

local function Tween(obj, props, speed, style, dir)
    local info = TweenInfo.new(
        speed or DefaultTheme.TweenSpeed,
        style or DefaultTheme.EasingStyle,
        dir   or DefaultTheme.EasingDirection
    )
    local tw = TweenService:Create(obj, info, props)
    tw:Play()
    return tw
end

local function Corner(parent, radius)
    return Create("UICorner", {
        CornerRadius = radius or DefaultTheme.CornerRadius,
        Parent = parent,
    })
end

local function Pad(parent, top, right, bottom, left)
    top    = top    or DefaultTheme.Padding
    right  = right  or top
    bottom = bottom or top
    left   = left   or right
    return Create("UIPadding", {
        PaddingTop    = UDim.new(0, top),
        PaddingRight  = UDim.new(0, right),
        PaddingBottom = UDim.new(0, bottom),
        PaddingLeft   = UDim.new(0, left),
        Parent = parent,
    })
end

local function ListLayout(parent, padding, dir, hAlign, vAlign)
    return Create("UIListLayout", {
        Padding             = UDim.new(0, padding or DefaultTheme.ControlPadding),
        FillDirection       = dir    or Enum.FillDirection.Vertical,
        HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Center,
        VerticalAlignment   = vAlign or Enum.VerticalAlignment.Top,
        SortOrder           = Enum.SortOrder.LayoutOrder,
        Parent = parent,
    })
end

local function Stroke(parent, color, thickness)
    return Create("UIStroke", {
        Color           = color     or DefaultTheme.Border,
        Thickness       = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function GetViewportSize()
    local cam = workspace.CurrentCamera
    return cam and cam.ViewportSize or Vector2.new(1920, 1080)
end

local function IsMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function IsTablet()
    if not UserInputService.TouchEnabled then return false end
    local vp = GetViewportSize()
    return math.min(vp.X, vp.Y) > 600
end

local function GetDeviceType()
    if IsMobile() and not IsTablet() then return "Phone"
    elseif IsTablet()                 then return "Tablet"
    else                                   return "Desktop"
    end
end

local function GetResponsiveSize(baseW, baseH)
    local vp     = GetViewportSize()
    local device = GetDeviceType()
    if device == "Phone" then
        return UDim2.new(0.94, 0, 0.82, 0)
    elseif device == "Tablet" then
        return UDim2.new(0.72, 0, 0.76, 0)
    end
    local w = math.min(baseW, vp.X * 0.85)
    local h = math.min(baseH, vp.Y * 0.85)
    return UDim2.fromOffset(w, h)
end

local function GetTabWidth()
    return GetDeviceType() == "Phone" and DefaultTheme.TabWidthMobile or DefaultTheme.TabWidth
end

local function MakeDraggable(dragTarget, dragHandle)
    local dragging      = false
    local dragStartPos  = nil
    local frameStartPos = nil

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging      = true
            dragStartPos  = input.Position
            frameStartPos = dragTarget.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    local conn = UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStartPos
            Tween(dragTarget, {
                Position = UDim2.new(
                    frameStartPos.X.Scale, frameStartPos.X.Offset + delta.X,
                    frameStartPos.Y.Scale, frameStartPos.Y.Offset + delta.Y
                )
            }, 0.06, Enum.EasingStyle.Quad)
        end
    end)
    return conn
end

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

function AlmondGUI:CreateWindow(config)
    config = config or {}
    local title      = config.Title or "AlmondGUI"
    local icon       = config.Icon  or "🌰"
    local baseWidth  = (config.Size and config.Size.Width)  or 560
    local baseHeight = (config.Size and config.Size.Height) or 400
    local theme = setmetatable(config.Theme or {}, { __index = DefaultTheme })

    local self = setmetatable({}, Window)
    self._theme       = theme
    self._tabs        = {}
    self._activeTab   = nil
    self._minimized   = false
    self._visible     = true
    self._title       = title
    self._icon        = icon
    self._connections = {}

    local playerGui = LocalPlayer:WaitForChild("PlayerGui")

    self._screenGui = Create("ScreenGui", {
        Name              = "AlmondGUI",
        Parent            = playerGui,
        ResetOnSpawn      = false,
        ZIndexBehavior    = Enum.ZIndexBehavior.Sibling,
        DisplayOrder      = 100,
    })

    local windowSize = GetResponsiveSize(baseWidth, baseHeight)
    self._mainFrame = Create("CanvasGroup", {
        Name                = "MainWindow",
        Size                = windowSize,
        Position            = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint         = Vector2.new(0.5, 0.5),
        BackgroundColor3    = theme.Background,
        BorderSizePixel     = 0,
        GroupTransparency   = 0,
        Parent              = self._screenGui,
    })
    Corner(self._mainFrame, theme.CornerLarge)
    Stroke(self._mainFrame, theme.Border, 1)
    self._windowSize = windowSize

    self._titleBar = Create("Frame", {
        Name             = "TitleBar",
        Size             = UDim2.new(1, 0, 0, theme.TitleBarHeight),
        BackgroundColor3 = theme.TitleBar,
        BorderSizePixel  = 0,
        Parent           = self._mainFrame,
    })
    Corner(self._titleBar, theme.CornerLarge)

    Create("Frame", {
        Name             = "BottomCover",
        Size             = UDim2.new(1, 0, 0, 14),
        Position         = UDim2.new(0, 0, 1, -14),
        BackgroundColor3 = theme.TitleBar,
        BorderSizePixel  = 0,
        Parent           = self._titleBar,
    })

    Create("Frame", {
        Name             = "TitleBorder",
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = theme.Border,
        BorderSizePixel  = 0,
        Parent           = self._titleBar,
    })

    Create("TextLabel", {
        Name                 = "TitleIcon",
        Size                 = UDim2.new(0, 28, 1, 0),
        Position             = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text                 = icon,
        TextSize             = 18,
        Font                 = Enum.Font.SourceSans,
        TextColor3           = theme.Text,
        Parent               = self._titleBar,
    })

    self._titleLabel = Create("TextLabel", {
        Name                 = "TitleLabel",
        Size                 = UDim2.new(1, -100, 1, 0),
        Position             = UDim2.new(0, 42, 0, 0),
        BackgroundTransparency = 1,
        Text                 = title,
        TextSize             = theme.TitleSize,
        Font                 = theme.FontBold,
        TextColor3           = theme.Text,
        TextXAlignment       = Enum.TextXAlignment.Left,
        TextTruncate         = Enum.TextTruncate.AtEnd,
        Parent               = self._titleBar,
    })

    local minimizeBtn = Create("TextButton", {
        Name                   = "MinimizeBtn",
        Size                   = UDim2.new(0, 30, 0, 30),
        Position               = UDim2.new(1, -38, 0.5, 0),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        BackgroundColor3       = theme.Surface,
        BackgroundTransparency = 0.5,
        Text                   = "─",
        TextSize               = 16,
        Font                   = theme.Font,
        TextColor3             = theme.TextSecondary,
        BorderSizePixel        = 0,
        AutoButtonColor        = false,
        Parent                 = self._titleBar,
    })
    Corner(minimizeBtn, theme.CornerSmall)

    minimizeBtn.MouseEnter:Connect(function()
        Tween(minimizeBtn, { BackgroundTransparency = 0, BackgroundColor3 = theme.SurfaceHover }, theme.TweenSpeedFast)
    end)
    minimizeBtn.MouseLeave:Connect(function()
        Tween(minimizeBtn, { BackgroundTransparency = 0.5, BackgroundColor3 = theme.Surface }, theme.TweenSpeedFast)
    end)

    table.insert(self._connections, MakeDraggable(self._mainFrame, self._titleBar))

    local body = Create("Frame", {
        Name                   = "Body",
        Size                   = UDim2.new(1, 0, 1, -theme.TitleBarHeight),
        Position               = UDim2.new(0, 0, 0, theme.TitleBarHeight),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Parent                 = self._mainFrame,
    })

    local tabWidth = GetTabWidth()

    self._tabSidebar = Create("Frame", {
        Name             = "TabSidebar",
        Size             = UDim2.new(0, tabWidth, 1, 0),
        BackgroundColor3 = theme.TitleBar,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        Parent           = body,
    })

    Create("Frame", {
        Name             = "SidebarBorder",
        Size             = UDim2.new(0, 1, 1, 0),
        Position         = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = theme.Border,
        BorderSizePixel  = 0,
        Parent           = self._tabSidebar,
    })

    self._tabContainer = Create("ScrollingFrame", {
        Name                     = "TabButtons",
        Size                     = UDim2.new(1, -1, 1, -8),
        Position                 = UDim2.new(0, 0, 0, 4),
        BackgroundTransparency   = 1,
        BorderSizePixel          = 0,
        ScrollBarThickness       = 2,
        ScrollBarImageColor3     = theme.Accent,
        ScrollBarImageTransparency = 0.6,
        CanvasSize               = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize      = Enum.AutomaticSize.Y,
        Parent                   = self._tabSidebar,
    })
    Pad(self._tabContainer, 4, 6, 4, 6)
    ListLayout(self._tabContainer, 4)

    self._contentArea = Create("Frame", {
        Name                   = "ContentArea",
        Size                   = UDim2.new(1, -tabWidth, 1, 0),
        Position               = UDim2.new(0, tabWidth, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ClipsDescendants       = true,
        Parent                 = body,
    })

    local MINI_SIZE    = 26
    local MINI_HOVER   = 30

    self._miniIcon = Create("TextButton", {
        Name                   = "MiniIcon",
        Size                   = UDim2.fromOffset(MINI_SIZE, MINI_SIZE),
        Position               = UDim2.new(0.5, 0, 0.92, 0),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        BackgroundColor3       = theme.MiniIconBg,
        BackgroundTransparency = 0.15,
        Text                   = icon,
        TextSize               = 14,
        Font                   = Enum.Font.SourceSans,
        TextColor3             = theme.Text,
        BorderSizePixel        = 0,
        AutoButtonColor        = false,
        Visible                = false,
        Parent                 = self._screenGui,
    })
    Corner(self._miniIcon, theme.CornerPill)
    Stroke(self._miniIcon, theme.Accent, 1.5)

    self._miniIcon.MouseEnter:Connect(function()
        Tween(self._miniIcon, {
            BackgroundTransparency = 0,
            Size = UDim2.fromOffset(MINI_HOVER, MINI_HOVER),
        }, theme.TweenSpeedFast)
    end)
    self._miniIcon.MouseLeave:Connect(function()
        Tween(self._miniIcon, {
            BackgroundTransparency = 0.15,
            Size = UDim2.fromOffset(MINI_SIZE, MINI_SIZE),
        }, theme.TweenSpeedFast)
    end)

    table.insert(self._connections, MakeDraggable(self._miniIcon, self._miniIcon))

    self._miniIcon.MouseButton1Click:Connect(function()
        self:Restore()
    end)

    self._notifContainer = Create("Frame", {
        Name                   = "Notifications",
        Size                   = UDim2.new(0, 300, 1, -20),
        Position               = UDim2.new(1, -10, 0, 10),
        AnchorPoint            = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Parent                 = self._screenGui,
    })
    ListLayout(
        self._notifContainer, 8,
        Enum.FillDirection.Vertical,
        Enum.HorizontalAlignment.Right,
        Enum.VerticalAlignment.Bottom
    )

    minimizeBtn.MouseButton1Click:Connect(function()
        self:Minimize()
    end)

    local targetSize = windowSize
    self._mainFrame.GroupTransparency = 1
    self._mainFrame.Size = UDim2.new(
        targetSize.X.Scale * 0.92, targetSize.X.Offset * 0.92,
        targetSize.Y.Scale * 0.92, targetSize.Y.Offset * 0.92
    )
    task.defer(function()
        Tween(self._mainFrame, {
            GroupTransparency = 0,
            Size = targetSize,
        }, theme.TweenSpeedSlow, Enum.EasingStyle.Back)
    end)

    self._MINI_SIZE  = MINI_SIZE
    self._MINI_HOVER = MINI_HOVER

    return self
end

function Window:SelectTab(tab)
    local theme = self._theme
    if self._activeTab and self._activeTab ~= tab then
        local prev = self._activeTab
        prev._content.Visible = false
        Tween(prev._button, {
            BackgroundColor3       = theme.TabInactive,
            BackgroundTransparency = 0.5,
        }, theme.TweenSpeed)
        Tween(prev._indicator, { BackgroundTransparency = 1 }, theme.TweenSpeed)
    end
    self._activeTab = tab
    tab._content.Visible = true
    tab._content.CanvasPosition = Vector2.new(0, 0)
    Tween(tab._button, {
        BackgroundColor3       = theme.Accent,
        BackgroundTransparency = 0.15,
    }, theme.TweenSpeed)
    Tween(tab._indicator, { BackgroundTransparency = 0 }, theme.TweenSpeed)
end

function Window:AddTab(config)
    config = config or {}
    local name  = config.Name or "Tab"
    local icon  = config.Icon or ""
    local theme = self._theme

    local tab = setmetatable({}, Tab)
    tab._window      = self
    tab._name        = name
    tab._layoutOrder = 0

    local isMobileLayout = GetDeviceType() == "Phone"
    local tabBtnHeight   = 36
    local tabOrder       = #self._tabs + 1

    local tabBtn = Create("TextButton", {
        Name                   = "TabBtn_" .. name,
        Size                   = UDim2.new(1, 0, 0, tabBtnHeight),
        BackgroundColor3       = theme.TabInactive,
        BackgroundTransparency = 0.5,
        BorderSizePixel        = 0,
        Text                   = "",
        AutoButtonColor        = false,
        LayoutOrder            = tabOrder,
        Parent                 = self._tabContainer,
    })
    Corner(tabBtn, theme.CornerSmall)

    local indicator = Create("Frame", {
        Name                   = "Indicator",
        Size                   = UDim2.new(0, 3, 0.55, 0),
        Position               = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint            = Vector2.new(0, 0.5),
        BackgroundColor3       = theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Parent                 = tabBtn,
    })
    Corner(indicator, theme.CornerPill)

    if isMobileLayout then
        Create("TextLabel", {
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                   = icon,
            TextSize               = 18,
            Font                   = Enum.Font.SourceSans,
            TextColor3             = theme.Text,
            Parent                 = tabBtn,
        })
    else
        if icon ~= "" then
            Create("TextLabel", {
                Name                   = "Icon",
                Size                   = UDim2.new(0, 24, 1, 0),
                Position               = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                Text                   = icon,
                TextSize               = 16,
                Font                   = Enum.Font.SourceSans,
                TextColor3             = theme.Text,
                TextXAlignment         = Enum.TextXAlignment.Left,
                Parent                 = tabBtn,
            })
        end
        Create("TextLabel", {
            Name                   = "Label",
            Size                   = UDim2.new(1, icon ~= "" and -40 or -16, 1, 0),
            Position               = UDim2.new(0, icon ~= "" and 34 or 8, 0, 0),
            BackgroundTransparency = 1,
            Text                   = name,
            TextSize               = theme.TabSize,
            Font                   = theme.Font,
            TextColor3             = theme.Text,
            TextXAlignment         = Enum.TextXAlignment.Left,
            TextTruncate           = Enum.TextTruncate.AtEnd,
            Parent                 = tabBtn,
        })
    end

    tab._button    = tabBtn
    tab._indicator = indicator

    local contentFrame = Create("ScrollingFrame", {
        Name                       = "TabContent_" .. name,
        Size                       = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency     = 1,
        BorderSizePixel            = 0,
        ScrollBarThickness         = 3,
        ScrollBarImageColor3       = theme.Accent,
        ScrollBarImageTransparency = 0.5,
        CanvasSize                 = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize        = Enum.AutomaticSize.Y,
        Visible                    = false,
        Parent                     = self._contentArea,
    })
    Pad(contentFrame, 12, 16, 12, 16)
    ListLayout(contentFrame, 8)

    tab._content = contentFrame

    tabBtn.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)

    tabBtn.MouseEnter:Connect(function()
        if self._activeTab ~= tab then
            Tween(tabBtn, { BackgroundColor3 = theme.TabHover, BackgroundTransparency = 0 }, theme.TweenSpeedFast)
        end
    end)
    tabBtn.MouseLeave:Connect(function()
        if self._activeTab ~= tab then
            Tween(tabBtn, { BackgroundColor3 = theme.TabInactive, BackgroundTransparency = 0.5 }, theme.TweenSpeedFast)
        end
    end)

    table.insert(self._tabs, tab)

    if #self._tabs == 1 then
        self:SelectTab(tab)
    end

    return tab
end

function Window:SetTitle(text)
    self._title = text
    self._titleLabel.Text = text
end

function Window:Minimize()
    if self._minimized then return end
    self._minimized = true
    local theme = self._theme
    local ws = self._windowSize

    Tween(self._mainFrame, {
        GroupTransparency = 1,
        Size = UDim2.new(
            ws.X.Scale * 0.92, ws.X.Offset * 0.92,
            ws.Y.Scale * 0.92, ws.Y.Offset * 0.92
        ),
    }, theme.TweenSpeed)

    task.delay(theme.TweenSpeed + 0.02, function()
        self._mainFrame.Visible = false
        self._miniIcon.Visible = true
        self._miniIcon.Size = UDim2.fromOffset(0, 0)
        Tween(self._miniIcon, {
            Size = UDim2.fromOffset(self._MINI_SIZE, self._MINI_SIZE),
        }, 0.3, Enum.EasingStyle.Back)
    end)
end

function Window:Restore()
    if not self._minimized then return end
    self._minimized = false
    local theme = self._theme
    local ws = self._windowSize

    Tween(self._miniIcon, {
        Size = UDim2.fromOffset(0, 0),
    }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)

    task.delay(0.22, function()
        self._miniIcon.Visible = false
        self._mainFrame.Visible = true
        self._mainFrame.GroupTransparency = 1
        self._mainFrame.Size = UDim2.new(
            ws.X.Scale * 0.92, ws.X.Offset * 0.92,
            ws.Y.Scale * 0.92, ws.Y.Offset * 0.92
        )
        Tween(self._mainFrame, {
            GroupTransparency = 0,
            Size = ws,
        }, theme.TweenSpeed, Enum.EasingStyle.Back)
    end)
end

function Window:Close()
    if not self._visible then return end
    self._visible = false
    local theme = self._theme
    Tween(self._mainFrame, { GroupTransparency = 1 }, theme.TweenSpeed)
    task.delay(theme.TweenSpeed + 0.02, function()
        self._mainFrame.Visible = false
        self._miniIcon.Visible  = false
    end)
end

function Window:Show()
    if self._visible then return end
    self._visible   = true
    self._minimized = false
    local theme = self._theme
    local ws    = self._windowSize
    self._mainFrame.Visible        = true
    self._mainFrame.GroupTransparency = 1
    self._miniIcon.Visible         = false
    self._mainFrame.Size = UDim2.new(
        ws.X.Scale * 0.92, ws.X.Offset * 0.92,
        ws.Y.Scale * 0.92, ws.Y.Offset * 0.92
    )
    Tween(self._mainFrame, {
        GroupTransparency = 0,
        Size = ws,
    }, theme.TweenSpeedSlow, Enum.EasingStyle.Back)
end

function Window:Toggle()
    if self._visible then self:Close() else self:Show() end
end

function Window:IsMinimized()
    return self._minimized
end

function Window:IsVisible()
    return self._visible
end

function Window:Destroy()
    for _, conn in ipairs(self._connections) do
        if conn.Connected then
            conn:Disconnect()
        end
    end
    self._connections = {}
    self._screenGui:Destroy()
    self._tabs = {}
    self._activeTab = nil
end

function Window:Notify(config)
    config = config or {}
    local nTitle     = config.Title       or "Notification"
    local nDesc      = config.Description or ""
    local duration   = config.Duration    or 5
    local notifType  = config.Type        or "info"
    local theme      = self._theme

    local typeColors = {
        success = theme.Success,
        warning = theme.Warning,
        error   = theme.Error,
        info    = theme.Info,
    }
    local accentColor = typeColors[notifType] or theme.Info

    local notif = Create("CanvasGroup", {
        Name                = "Notification",
        Size                = UDim2.new(1, 0, 0, 72),
        BackgroundColor3    = theme.Surface,
        BorderSizePixel     = 0,
        GroupTransparency   = 1,
        Parent              = self._notifContainer,
    })
    Corner(notif, theme.CornerSmall)
    Stroke(notif, accentColor, 1)

    local accentBar = Create("Frame", {
        Name             = "AccentBar",
        Size             = UDim2.new(0, 3, 1, -16),
        Position         = UDim2.new(0, 8, 0.5, 0),
        AnchorPoint      = Vector2.new(0, 0.5),
        BackgroundColor3 = accentColor,
        BorderSizePixel  = 0,
        Parent           = notif,
    })
    Corner(accentBar, DefaultTheme.CornerPill)

    Create("TextLabel", {
        Size                   = UDim2.new(1, -30, 0, 20),
        Position               = UDim2.new(0, 22, 0, 12),
        BackgroundTransparency = 1,
        Text                   = nTitle,
        TextSize               = 14,
        Font                   = theme.FontBold,
        TextColor3             = theme.Text,
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextTruncate           = Enum.TextTruncate.AtEnd,
        Parent                 = notif,
    })

    Create("TextLabel", {
        Size                   = UDim2.new(1, -30, 0, 30),
        Position               = UDim2.new(0, 22, 0, 32),
        BackgroundTransparency = 1,
        Text                   = nDesc,
        TextSize               = 12,
        Font                   = theme.FontLight,
        TextColor3             = theme.TextSecondary,
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextWrapped            = true,
        Parent                 = notif,
    })

    Tween(notif, { GroupTransparency = 0 }, 0.35)

    task.delay(duration, function()
        if notif and notif.Parent then
            Tween(notif, { GroupTransparency = 1 }, 0.35)
            task.wait(0.38)
            if notif and notif.Parent then
                notif:Destroy()
            end
        end
    end)
end

function Tab:AddButton(config)
    config = config or {}
    local name        = config.Name        or "Button"
    local description = config.Description
    local callback    = config.Callback    or function() end
    local theme       = self._window._theme

    self._layoutOrder = self._layoutOrder + 1
    local height = description and 54 or theme.ControlHeight

    local button = Create("TextButton", {
        Name                   = "Btn_" .. name,
        Size                   = UDim2.new(1, 0, 0, height),
        BackgroundColor3       = theme.Surface,
        BorderSizePixel        = 0,
        Text                   = "",
        AutoButtonColor        = false,
        LayoutOrder            = self._layoutOrder,
        Parent                 = self._content,
    })
    Corner(button, theme.CornerSmall)

    local label = Create("TextLabel", {
        Name                   = "Label",
        Size                   = UDim2.new(1, -24, 0, description and 20 or height),
        Position               = UDim2.new(0, 12, 0, description and 9 or 0),
        BackgroundTransparency = 1,
        Text                   = name,
        TextSize               = theme.ControlSize,
        Font                   = theme.Font,
        TextColor3             = theme.Text,
        TextXAlignment         = Enum.TextXAlignment.Left,
        Parent                 = button,
    })

    if description then
        Create("TextLabel", {
            Name                   = "Description",
            Size                   = UDim2.new(1, -24, 0, 16),
            Position               = UDim2.new(0, 12, 0, 30),
            BackgroundTransparency = 1,
            Text                   = description,
            TextSize               = 12,
            Font                   = theme.FontLight,
            TextColor3             = theme.TextMuted,
            TextXAlignment         = Enum.TextXAlignment.Left,
            Parent                 = button,
        })
    end

    button.MouseEnter:Connect(function()
        Tween(button, { BackgroundColor3 = theme.SurfaceHover }, theme.TweenSpeedFast)
    end)
    button.MouseLeave:Connect(function()
        Tween(button, { BackgroundColor3 = theme.Surface }, theme.TweenSpeedFast)
    end)

    button.MouseButton1Click:Connect(function()
        Tween(button, { BackgroundColor3 = theme.SurfaceActive }, 0.05)
        task.delay(0.06, function()
            Tween(button, { BackgroundColor3 = theme.SurfaceHover }, 0.15)
        end)
        callback()
    end)

    local ref = {}
    function ref:SetText(text) label.Text = text end
    function ref:SetCallback(fn) callback = fn end
    return ref
end

function Tab:AddToggle(config)
    config = config or {}
    local name     = config.Name     or "Toggle"
    local default  = config.Default  or false
    local callback = config.Callback or function() end
    local theme    = self._window._theme

    self._layoutOrder = self._layoutOrder + 1
    local value = default

    local container = Create("Frame", {
        Name             = "Toggle_" .. name,
        Size             = UDim2.new(1, 0, 0, theme.ControlHeight),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel  = 0,
        LayoutOrder      = self._layoutOrder,
        Parent           = self._content,
    })
    Corner(container, theme.CornerSmall)

    Create("TextLabel", {
        Size                   = UDim2.new(1, -68, 1, 0),
        Position               = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text                   = name,
        TextSize               = theme.ControlSize,
        Font                   = theme.Font,
        TextColor3             = theme.Text,
        TextXAlignment         = Enum.TextXAlignment.Left,
        Parent                 = container,
    })

    local track = Create("Frame", {
        Name             = "Track",
        Size             = UDim2.fromOffset(theme.ToggleSwitchW, theme.ToggleSwitchH),
        Position         = UDim2.new(1, -56, 0.5, 0),
        AnchorPoint      = Vector2.new(0, 0.5),
        BackgroundColor3 = value and theme.ToggleOn or theme.ToggleOff,
        BorderSizePixel  = 0,
        Parent           = container,
    })
    Corner(track, theme.CornerPill)

    local knobX_on  = UDim2.new(1, -theme.ToggleKnobSize - 3, 0.5, 0)
    local knobX_off = UDim2.new(0, 3, 0.5, 0)

    local knob = Create("Frame", {
        Name             = "Knob",
        Size             = UDim2.fromOffset(theme.ToggleKnobSize, theme.ToggleKnobSize),
        Position         = value and knobX_on or knobX_off,
        AnchorPoint      = Vector2.new(0, 0.5),
        BackgroundColor3 = theme.ToggleKnob,
        BorderSizePixel  = 0,
        Parent           = track,
    })
    Corner(knob, theme.CornerPill)

    local function updateVisual()
        Tween(track, { BackgroundColor3 = value and theme.ToggleOn or theme.ToggleOff }, 0.2)
        Tween(knob, { Position = value and knobX_on or knobX_off }, 0.2, Enum.EasingStyle.Back)
    end

    local toggleBtn = Create("TextButton", {
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text                   = "",
        Parent                 = container,
    })

    toggleBtn.MouseButton1Click:Connect(function()
        value = not value
        updateVisual()
        callback(value)
    end)

    toggleBtn.MouseEnter:Connect(function()
        Tween(container, { BackgroundColor3 = theme.SurfaceHover }, theme.TweenSpeedFast)
    end)
    toggleBtn.MouseLeave:Connect(function()
        Tween(container, { BackgroundColor3 = theme.Surface }, theme.TweenSpeedFast)
    end)

    local ref = {}
    function ref:SetValue(val) value = val; updateVisual() end
    function ref:GetValue() return value end
    function ref:SetCallback(fn) callback = fn end
    return ref
end

function Tab:AddSlider(config)
    config = config or {}
    local name      = config.Name      or "Slider"
    local min       = config.Min       or 0
    local max       = config.Max       or 100
    local default   = config.Default   or min
    local increment = config.Increment or 1
    local suffix    = config.Suffix    or ""
    local callback  = config.Callback  or function() end
    local theme     = self._window._theme

    self._layoutOrder = self._layoutOrder + 1
    local currentValue = default

    local container = Create("Frame", {
        Name             = "Slider_" .. name,
        Size             = UDim2.new(1, 0, 0, theme.SliderHeight),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel  = 0,
        LayoutOrder      = self._layoutOrder,
        Parent           = self._content,
    })
    Corner(container, theme.CornerSmall)

    Create("TextLabel", {
        Size                   = UDim2.new(0.65, -12, 0, 20),
        Position               = UDim2.new(0, 12, 0, 6),
        BackgroundTransparency = 1,
        Text                   = name,
        TextSize               = theme.ControlSize,
        Font                   = theme.Font,
        TextColor3             = theme.Text,
        TextXAlignment         = Enum.TextXAlignment.Left,
        Parent                 = container,
    })

    local valueLabel = Create("TextLabel", {
        Size                   = UDim2.new(0.35, -12, 0, 20),
        Position               = UDim2.new(0.65, 0, 0, 6),
        BackgroundTransparency = 1,
        Text                   = tostring(default) .. suffix,
        TextSize               = theme.ValueSize,
        Font                   = theme.Font,
        TextColor3             = theme.Accent,
        TextXAlignment         = Enum.TextXAlignment.Right,
        Parent                 = container,
    })

    local trackFrame = Create("Frame", {
        Name             = "Track",
        Size             = UDim2.new(1, -24, 0, 6),
        Position         = UDim2.new(0, 12, 0, 34),
        BackgroundColor3 = theme.SliderTrack,
        BorderSizePixel  = 0,
        Parent           = container,
    })
    Corner(trackFrame, theme.CornerPill)

    local pct = math.clamp((default - min) / math.max(max - min, 0.001), 0, 1)
    local fill = Create("Frame", {
        Name             = "Fill",
        Size             = UDim2.new(pct, 0, 1, 0),
        BackgroundColor3 = theme.SliderFill,
        BorderSizePixel  = 0,
        Parent           = trackFrame,
    })
    Corner(fill, theme.CornerPill)

    local sliderKnob = Create("Frame", {
        Name             = "Knob",
        Size             = UDim2.fromOffset(16, 16),
        Position         = UDim2.new(pct, 0, 0.5, 0),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.ToggleKnob,
        BorderSizePixel  = 0,
        ZIndex           = 2,
        Parent           = trackFrame,
    })
    Corner(sliderKnob, theme.CornerPill)

    local dragging = false

    local function formatValue(val)
        if increment >= 1 then return tostring(math.floor(val)) end
        local decimals = math.max(0, math.ceil(-math.log10(increment)))
        return string.format("%." .. decimals .. "f", val)
    end

    valueLabel.Text = formatValue(default) .. suffix

    local function setValue(val)
        val = math.clamp(val, min, max)
        if increment > 0 then
            val = math.floor(val / increment + 0.5) * increment
            val = math.clamp(val, min, max)
        end
        currentValue = val
        local p = (val - min) / math.max(max - min, 0.001)
        Tween(fill, { Size = UDim2.new(p, 0, 1, 0) }, 0.05, Enum.EasingStyle.Quad)
        Tween(sliderKnob, { Position = UDim2.new(p, 0, 0.5, 0) }, 0.05, Enum.EasingStyle.Quad)
        valueLabel.Text = formatValue(val) .. suffix
        callback(val)
    end

    local trackOverlay = Create("TextButton", {
        Size                   = UDim2.new(1, -24, 0, 22),
        Position               = UDim2.new(0, 12, 0, 24),
        BackgroundTransparency = 1,
        Text                   = "",
        Parent                 = container,
    })

    trackOverlay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            local p = math.clamp(
                (input.Position.X - trackFrame.AbsolutePosition.X) / math.max(trackFrame.AbsoluteSize.X, 1),
                0, 1
            )
            setValue(min + p * (max - min))
        end
    end)

    trackOverlay.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local sliderConn = UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local p = math.clamp(
                (input.Position.X - trackFrame.AbsolutePosition.X) / math.max(trackFrame.AbsoluteSize.X, 1),
                0, 1
            )
            setValue(min + p * (max - min))
        end
    end)
    table.insert(self._window._connections, sliderConn)

    container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            Tween(container, { BackgroundColor3 = theme.SurfaceHover }, theme.TweenSpeedFast)
        end
    end)
    container.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            Tween(container, { BackgroundColor3 = theme.Surface }, theme.TweenSpeedFast)
        end
    end)

    local ref = {}
    function ref:SetValue(val) setValue(val) end
    function ref:GetValue() return currentValue end
    function ref:SetCallback(fn) callback = fn end
    return ref
end

function Tab:AddLabel(text)
    local theme = self._window._theme
    self._layoutOrder = self._layoutOrder + 1

    local label = Create("TextLabel", {
        Name                   = "Label",
        Size                   = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text                   = text or "",
        TextSize               = theme.LabelSize,
        Font                   = theme.FontLight,
        TextColor3             = theme.TextSecondary,
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextWrapped            = true,
        AutomaticSize          = Enum.AutomaticSize.Y,
        LayoutOrder            = self._layoutOrder,
        Parent                 = self._content,
    })

    local ref = {}
    function ref:SetText(t) label.Text = t end
    return ref
end

function Tab:AddSection(text)
    local theme = self._window._theme
    self._layoutOrder = self._layoutOrder + 1

    local section = Create("Frame", {
        Name                   = "Section_" .. (text or ""),
        Size                   = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        LayoutOrder            = self._layoutOrder,
        Parent                 = self._content,
    })

    local heading = Create("TextLabel", {
        Size                   = UDim2.new(1, 0, 0, 22),
        Position               = UDim2.new(0, 0, 0, 6),
        BackgroundTransparency = 1,
        Text                   = text or "Section",
        TextSize               = theme.SectionSize,
        Font                   = theme.FontBold,
        TextColor3             = theme.Text,
        TextXAlignment         = Enum.TextXAlignment.Left,
        Parent                 = section,
    })

    Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = theme.Border,
        BorderSizePixel  = 0,
        Parent           = section,
    })

    local ref = {}
    function ref:SetText(t) heading.Text = t end
    return ref
end

function Tab:AddSeparator()
    self._layoutOrder = self._layoutOrder + 1
    Create("Frame", {
        Name                   = "Separator",
        Size                   = UDim2.new(1, 0, 0, 1),
        BackgroundColor3       = self._window._theme.Border,
        BackgroundTransparency = 0.5,
        BorderSizePixel        = 0,
        LayoutOrder            = self._layoutOrder,
        Parent                 = self._content,
    })
end

function Tab:AddTextInput(config)
    config = config or {}
    local name        = config.Name        or "Input"
    local placeholder = config.Placeholder or "Enter text..."
    local default     = config.Default     or ""
    local callback    = config.Callback    or function() end
    local theme       = self._window._theme

    self._layoutOrder = self._layoutOrder + 1

    local container = Create("Frame", {
        Name             = "Input_" .. name,
        Size             = UDim2.new(1, 0, 0, 60),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel  = 0,
        LayoutOrder      = self._layoutOrder,
        Parent           = self._content,
    })
    Corner(container, theme.CornerSmall)

    Create("TextLabel", {
        Size                   = UDim2.new(1, -24, 0, 18),
        Position               = UDim2.new(0, 12, 0, 8),
        BackgroundTransparency = 1,
        Text                   = name,
        TextSize               = theme.ControlSize,
        Font                   = theme.Font,
        TextColor3             = theme.Text,
        TextXAlignment         = Enum.TextXAlignment.Left,
        Parent                 = container,
    })

    local textBox = Create("TextBox", {
        Size                   = UDim2.new(1, -24, 0, 26),
        Position               = UDim2.new(0, 12, 0, 28),
        BackgroundColor3       = theme.InputBackground,
        BorderSizePixel        = 0,
        Text                   = default,
        PlaceholderText        = placeholder,
        PlaceholderColor3      = theme.TextMuted,
        TextSize               = theme.ValueSize,
        Font                   = theme.FontLight,
        TextColor3             = theme.Text,
        TextXAlignment         = Enum.TextXAlignment.Left,
        ClearTextOnFocus       = false,
        Parent                 = container,
    })
    Corner(textBox, theme.CornerSmall)
    Pad(textBox, 4, 8, 4, 8)

    textBox.FocusLost:Connect(function(enterPressed)
        callback(textBox.Text, enterPressed)
    end)

    container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            Tween(container, { BackgroundColor3 = theme.SurfaceHover }, theme.TweenSpeedFast)
        end
    end)
    container.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            Tween(container, { BackgroundColor3 = theme.Surface }, theme.TweenSpeedFast)
        end
    end)

    local ref = {}
    function ref:GetText() return textBox.Text end
    function ref:SetText(t) textBox.Text = t end
    function ref:SetCallback(fn) callback = fn end
    return ref
end

function Tab:AddDropdown(config)
    config = config or {}
    local name     = config.Name     or "Dropdown"
    local options  = config.Options  or {}
    local default  = config.Default  or (options[1] or "")
    local callback = config.Callback or function() end
    local theme    = self._window._theme

    self._layoutOrder = self._layoutOrder + 1
    local selected = default
    local isOpen   = false

    local container = Create("Frame", {
        Name             = "Dropdown_" .. name,
        Size             = UDim2.new(1, 0, 0, theme.ControlHeight),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel  = 0,
        LayoutOrder      = self._layoutOrder,
        ClipsDescendants = true,
        Parent           = self._content,
    })
    Corner(container, theme.CornerSmall)

    Create("TextLabel", {
        Size                   = UDim2.new(0.5, -12, 0, theme.ControlHeight),
        Position               = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text                   = name,
        TextSize               = theme.ControlSize,
        Font                   = theme.Font,
        TextColor3             = theme.Text,
        TextXAlignment         = Enum.TextXAlignment.Left,
        Parent                 = container,
    })

    local selectedLabel = Create("TextLabel", {
        Size                   = UDim2.new(0.5, -36, 0, theme.ControlHeight),
        Position               = UDim2.new(0.5, 0, 0, 0),
        BackgroundTransparency = 1,
        Text                   = selected,
        TextSize               = theme.ValueSize,
        Font                   = theme.Font,
        TextColor3             = theme.Accent,
        TextXAlignment         = Enum.TextXAlignment.Right,
        TextTruncate           = Enum.TextTruncate.AtEnd,
        Parent                 = container,
    })

    local arrow = Create("TextLabel", {
        Size                   = UDim2.new(0, 20, 0, theme.ControlHeight),
        Position               = UDim2.new(1, -24, 0, 0),
        BackgroundTransparency = 1,
        Text                   = "▾",
        TextSize               = 14,
        Font                   = theme.Font,
        TextColor3             = theme.TextSecondary,
        Parent                 = container,
    })

    local dropdownList = Create("Frame", {
        Name                   = "DropdownList",
        Size                   = UDim2.new(1, 0, 0, 0),
        Position               = UDim2.fromOffset(0, theme.ControlHeight + 4),
        BackgroundColor3       = theme.DropdownBg,
        BorderSizePixel        = 0,
        ClipsDescendants       = true,
        Visible                = false,
        ZIndex                 = 50,
        Parent                 = container,
    })
    Corner(dropdownList, theme.CornerSmall)
    Stroke(dropdownList, theme.Border, 1)

    local listContent = Create("Frame", {
        Name                   = "ListContent",
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent                 = dropdownList,
    })
    Pad(listContent, 4, 4, 4, 4)
    ListLayout(listContent, 2)

    local optionButtons = {}

    local function closeDropdown()
        if not isOpen then return end
        isOpen = false
        Tween(dropdownList, { Size = UDim2.new(1, 0, 0, 0) }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        Tween(container, { Size = UDim2.new(1, 0, 0, theme.ControlHeight) }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        task.delay(0.2, function()
            if not isOpen then
                dropdownList.Visible = false
            end
        end)
    end

    local function openDropdown()
        if isOpen then return end
        isOpen = true
        dropdownList.Visible = true
        dropdownList.Size = UDim2.new(1, 0, 0, 0)
        local targetH = math.min(#options * 30 + 8, 200)
        Tween(dropdownList, { Size = UDim2.new(1, 0, 0, targetH) }, 0.2, Enum.EasingStyle.Quad)
        Tween(container, { Size = UDim2.new(1, 0, 0, theme.ControlHeight + 4 + targetH) }, 0.2, Enum.EasingStyle.Quad)
    end

    local function buildOptions()
        for _, btn in ipairs(optionButtons) do
            btn:Destroy()
        end
        optionButtons = {}

        for i, option in ipairs(options) do
            local optBtn = Create("TextButton", {
                Name                   = "Opt_" .. option,
                Size                   = UDim2.new(1, 0, 0, 28),
                BackgroundColor3       = option == selected and theme.Accent or theme.DropdownBg,
                BackgroundTransparency = option == selected and 0.15 or 0.5,
                BorderSizePixel        = 0,
                Text                   = option,
                TextSize               = theme.ValueSize,
                Font                   = theme.Font,
                TextColor3             = theme.Text,
                AutoButtonColor        = false,
                LayoutOrder            = i,
                ZIndex                 = 51,
                Parent                 = listContent,
            })
            Corner(optBtn, theme.CornerSmall)

            optBtn.MouseEnter:Connect(function()
                if option ~= selected then
                    Tween(optBtn, { BackgroundTransparency = 0, BackgroundColor3 = theme.SurfaceHover }, 0.08)
                end
            end)
            optBtn.MouseLeave:Connect(function()
                if option ~= selected then
                    Tween(optBtn, { BackgroundTransparency = 0.5, BackgroundColor3 = theme.DropdownBg }, 0.08)
                end
            end)

            optBtn.MouseButton1Click:Connect(function()
                selected = option
                selectedLabel.Text = option
                closeDropdown()
                buildOptions()
                callback(option)
            end)

            table.insert(optionButtons, optBtn)
        end
    end

    buildOptions()

    local toggleBtn = Create("TextButton", {
        Size                   = UDim2.new(1, 0, 0, theme.ControlHeight),
        BackgroundTransparency = 1,
        Text                   = "",
        ZIndex                 = 2,
        Parent                 = container,
    })

    toggleBtn.MouseButton1Click:Connect(function()
        if isOpen then closeDropdown() else openDropdown() end
    end)

    toggleBtn.MouseEnter:Connect(function()
        Tween(container, { BackgroundColor3 = theme.SurfaceHover }, theme.TweenSpeedFast)
    end)
    toggleBtn.MouseLeave:Connect(function()
        Tween(container, { BackgroundColor3 = theme.Surface }, theme.TweenSpeedFast)
    end)

    local ref = {}
    function ref:GetValue() return selected end
    function ref:SetValue(val)
        selected = val
        selectedLabel.Text = val
        buildOptions()
    end
    function ref:SetOptions(newOpts)
        options = newOpts
        if not table.find(options, selected) then
            selected = options[1] or ""
            selectedLabel.Text = selected
        end
        buildOptions()
    end
    function ref:SetCallback(fn) callback = fn end
    return ref
end

function Tab:AddKeybind(config)
    config = config or {}
    local name     = config.Name     or "Keybind"
    local default  = config.Default  or Enum.KeyCode.E
    local callback = config.Callback or function() end
    local theme    = self._window._theme

    self._layoutOrder = self._layoutOrder + 1
    local currentKey = default
    local listening  = false

    local container = Create("Frame", {
        Name             = "Keybind_" .. name,
        Size             = UDim2.new(1, 0, 0, theme.ControlHeight),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel  = 0,
        LayoutOrder      = self._layoutOrder,
        Parent           = self._content,
    })
    Corner(container, theme.CornerSmall)

    Create("TextLabel", {
        Size                   = UDim2.new(1, -100, 1, 0),
        Position               = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text                   = name,
        TextSize               = theme.ControlSize,
        Font                   = theme.Font,
        TextColor3             = theme.Text,
        TextXAlignment         = Enum.TextXAlignment.Left,
        Parent                 = container,
    })

    local keyBtn = Create("TextButton", {
        Size                   = UDim2.new(0, 70, 0, 26),
        Position               = UDim2.new(1, -82, 0.5, 0),
        AnchorPoint            = Vector2.new(0, 0.5),
        BackgroundColor3       = theme.InputBackground,
        BorderSizePixel        = 0,
        Text                   = default.Name,
        TextSize               = theme.ValueSize,
        Font                   = theme.Font,
        TextColor3             = theme.Accent,
        AutoButtonColor        = false,
        Parent                 = container,
    })
    Corner(keyBtn, theme.CornerSmall)
    Stroke(keyBtn, theme.Border, 1)

    keyBtn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        keyBtn.Text = "..."
        Tween(keyBtn, { BackgroundColor3 = theme.Accent }, 0.15)
        Tween(keyBtn, { TextColor3 = theme.Text }, 0.15)

        local conn
        conn = UserInputService.InputBegan:Connect(function(input, processed)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == Enum.KeyCode.Escape then
                    keyBtn.Text = currentKey.Name
                    Tween(keyBtn, { BackgroundColor3 = theme.InputBackground }, 0.15)
                    Tween(keyBtn, { TextColor3 = theme.Accent }, 0.15)
                    listening = false
                    conn:Disconnect()
                    return
                end
                currentKey = input.KeyCode
                keyBtn.Text = input.KeyCode.Name
                Tween(keyBtn, { BackgroundColor3 = theme.InputBackground }, 0.15)
                Tween(keyBtn, { TextColor3 = theme.Accent }, 0.15)
                listening = false
                conn:Disconnect()
            end
        end)
    end)

    local keybindConn = UserInputService.InputBegan:Connect(function(input, processed)
        if processed or listening then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == currentKey then
            callback(currentKey)
        end
    end)
    table.insert(self._window._connections, keybindConn)

    keyBtn.MouseEnter:Connect(function()
        if not listening then
            Tween(keyBtn, { BackgroundColor3 = theme.SurfaceHover }, theme.TweenSpeedFast)
        end
    end)
    keyBtn.MouseLeave:Connect(function()
        if not listening then
            Tween(keyBtn, { BackgroundColor3 = theme.InputBackground }, theme.TweenSpeedFast)
        end
    end)

    container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            Tween(container, { BackgroundColor3 = theme.SurfaceHover }, theme.TweenSpeedFast)
        end
    end)
    container.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            Tween(container, { BackgroundColor3 = theme.Surface }, theme.TweenSpeedFast)
        end
    end)

    local ref = {}
    function ref:GetValue() return currentKey end
    function ref:SetValue(key)
        currentKey = key
        keyBtn.Text = key.Name
    end
    function ref:SetCallback(fn) callback = fn end
    return ref
end

function Tab:AddProgressBar(config)
    config = config or {}
    local name    = config.Name    or "Progress"
    local default = config.Default or 0
    local suffix  = config.Suffix  or "%"
    local theme   = self._window._theme

    self._layoutOrder = self._layoutOrder + 1
    local currentValue = math.clamp(default, 0, 100)

    local container = Create("Frame", {
        Name             = "Progress_" .. name,
        Size             = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel  = 0,
        LayoutOrder      = self._layoutOrder,
        Parent           = self._content,
    })
    Corner(container, theme.CornerSmall)

    Create("TextLabel", {
        Size                   = UDim2.new(0.65, -12, 0, 20),
        Position               = UDim2.new(0, 12, 0, 4),
        BackgroundTransparency = 1,
        Text                   = name,
        TextSize               = theme.ControlSize,
        Font                   = theme.Font,
        TextColor3             = theme.Text,
        TextXAlignment         = Enum.TextXAlignment.Left,
        Parent                 = container,
    })

    local valueLabel = Create("TextLabel", {
        Size                   = UDim2.new(0.35, -12, 0, 20),
        Position               = UDim2.new(0.65, 0, 0, 4),
        BackgroundTransparency = 1,
        Text                   = tostring(math.floor(currentValue)) .. suffix,
        TextSize               = theme.ValueSize,
        Font                   = theme.Font,
        TextColor3             = theme.Accent,
        TextXAlignment         = Enum.TextXAlignment.Right,
        Parent                 = container,
    })

    local trackFrame = Create("Frame", {
        Size             = UDim2.new(1, -24, 0, 8),
        Position         = UDim2.new(0, 12, 0, 28),
        BackgroundColor3 = theme.SliderTrack,
        BorderSizePixel  = 0,
        Parent           = container,
    })
    Corner(trackFrame, theme.CornerPill)

    local pct = currentValue / 100
    local fill = Create("Frame", {
        Name             = "Fill",
        Size             = UDim2.new(pct, 0, 1, 0),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel  = 0,
        Parent           = trackFrame,
    })
    Corner(fill, theme.CornerPill)

    local ref = {}
    function ref:SetValue(val)
        currentValue = math.clamp(val, 0, 100)
        local p = currentValue / 100
        Tween(fill, { Size = UDim2.new(p, 0, 1, 0) }, 0.25, Enum.EasingStyle.Quad)
        valueLabel.Text = tostring(math.floor(currentValue)) .. suffix
    end
    function ref:GetValue() return currentValue end
    function ref:SetColor(color)
        Tween(fill, { BackgroundColor3 = color }, 0.15)
    end
    return ref
end

function Tab:AddInventoryGrid(config)
    config = config or {}
    local columns  = config.Columns  or 4
    local itemSize = config.ItemSize or 80
    local items    = config.Items    or {}
    local theme    = self._window._theme

    self._layoutOrder = self._layoutOrder + 1

    local device = GetDeviceType()
    if device == "Phone" then
        columns  = math.min(columns, 3)
        itemSize = math.min(itemSize, 68)
    end

    local grid = Create("Frame", {
        Name                   = "InventoryGrid",
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder            = self._layoutOrder,
        Parent                 = self._content,
    })

    Create("UIGridLayout", {
        CellSize              = UDim2.fromOffset(itemSize, itemSize + 22),
        CellPadding           = UDim2.fromOffset(8, 8),
        FillDirection         = Enum.FillDirection.Horizontal,
        HorizontalAlignment   = Enum.HorizontalAlignment.Left,
        SortOrder             = Enum.SortOrder.LayoutOrder,
        FillDirectionMaxCells = columns,
        Parent                = grid,
    })

    local itemOrder = 0

    local function CreateItem(itemConfig, order)
        local cell = Create("TextButton", {
            Name                   = "Item_" .. (itemConfig.Name or "Item"),
            BackgroundColor3       = theme.Surface,
            BorderSizePixel        = 0,
            Text                   = "",
            AutoButtonColor        = false,
            LayoutOrder            = order,
            Parent                 = grid,
        })
        Corner(cell, theme.CornerSmall)

        if itemConfig.Image then
            Create("ImageLabel", {
                Size                   = UDim2.new(1, -16, 1, -38),
                Position               = UDim2.new(0.5, 0, 0, 8),
                AnchorPoint            = Vector2.new(0.5, 0),
                BackgroundTransparency = 1,
                Image                  = itemConfig.Image,
                ScaleType              = Enum.ScaleType.Fit,
                Parent                 = cell,
            })
        elseif itemConfig.Icon then
            Create("TextLabel", {
                Size                   = UDim2.new(1, 0, 1, -28),
                Position               = UDim2.new(0, 0, 0, 2),
                BackgroundTransparency = 1,
                Text                   = itemConfig.Icon,
                TextSize               = 32,
                Font                   = Enum.Font.SourceSans,
                TextColor3             = theme.Text,
                Parent                 = cell,
            })
        end

        Create("TextLabel", {
            Size                   = UDim2.new(1, -6, 0, 18),
            Position               = UDim2.new(0.5, 0, 1, -20),
            AnchorPoint            = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Text                   = itemConfig.Name or "Item",
            TextSize               = 11,
            Font                   = theme.Font,
            TextColor3             = theme.TextSecondary,
            TextTruncate           = Enum.TextTruncate.AtEnd,
            Parent                 = cell,
        })

        cell.MouseEnter:Connect(function()
            Tween(cell, { BackgroundColor3 = theme.SurfaceHover }, theme.TweenSpeedFast)
        end)
        cell.MouseLeave:Connect(function()
            Tween(cell, { BackgroundColor3 = theme.Surface }, theme.TweenSpeedFast)
        end)

        if itemConfig.Callback then
            cell.MouseButton1Click:Connect(function()
                Tween(cell, { BackgroundColor3 = theme.Accent }, 0.06)
                task.delay(0.1, function()
                    Tween(cell, { BackgroundColor3 = theme.SurfaceHover }, 0.15)
                end)
                itemConfig.Callback(itemConfig)
            end)
        end

        return cell
    end

    for _, item in ipairs(items) do
        itemOrder = itemOrder + 1
        CreateItem(item, itemOrder)
    end

    local ref = {}
    function ref:AddItem(itemConfig)
        itemOrder = itemOrder + 1
        return CreateItem(itemConfig, itemOrder)
    end
    function ref:ClearItems()
        for _, child in ipairs(grid:GetChildren()) do
            if child:IsA("GuiButton") then
                child:Destroy()
            end
        end
        itemOrder = 0
    end
    function ref:SetItems(newItems)
        ref:ClearItems()
        for _, item in ipairs(newItems) do
            ref:AddItem(item)
        end
    end
    return ref
end

function AlmondGUI:DisableDefaultBackpack()
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    end)
end

function AlmondGUI:EnableDefaultBackpack()
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
    end)
end

return AlmondGUI
