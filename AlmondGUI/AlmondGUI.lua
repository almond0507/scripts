--[[
    ╔═══════════════════════════════════════════════════════╗
    ║            AlmondGUI Framework  v1.0.0                ║
    ║      A Modern, Premium Roblox UI Framework            ║
    ╚═══════════════════════════════════════════════════════╝

    A dark-mode, responsive, mobile-friendly GUI framework
    for Roblox with smooth animations and a clean developer API.

    Usage (ModuleScript):
        local AlmondGUI = require(path.to.AlmondGUI)
        local Window = AlmondGUI:CreateWindow({ Title = "My App" })
        local Tab = Window:AddTab({ Name = "Home", Icon = "🏠" })
        Tab:AddButton({ Name = "Click Me", Callback = function() print("Hi!") end })

    License: MIT
]]

local AlmondGUI = {}
AlmondGUI.__index = AlmondGUI
AlmondGUI.Version = "1.0.0"

-- ═══════════════════════════════════════════════════════
--  SERVICES
-- ═══════════════════════════════════════════════════════

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui       = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════
--  DEFAULT THEME
-- ═══════════════════════════════════════════════════════

local DefaultTheme = {
    -- Core colors
    Background       = Color3.fromRGB(18, 18, 26),
    TitleBar         = Color3.fromRGB(22, 22, 32),
    Surface          = Color3.fromRGB(28, 28, 40),
    SurfaceHover     = Color3.fromRGB(38, 38, 52),
    SurfaceActive    = Color3.fromRGB(48, 48, 64),
    Accent           = Color3.fromRGB(108, 92, 231),
    AccentHover      = Color3.fromRGB(128, 112, 248),
    AccentDark       = Color3.fromRGB(78, 65, 180),

    -- Tab colors
    TabActive        = Color3.fromRGB(108, 92, 231),
    TabInactive      = Color3.fromRGB(28, 28, 40),
    TabHover         = Color3.fromRGB(38, 38, 52),

    -- Text colors
    Text             = Color3.fromRGB(225, 225, 240),
    TextSecondary    = Color3.fromRGB(155, 155, 175),
    TextMuted        = Color3.fromRGB(100, 100, 120),

    -- Component colors
    Border           = Color3.fromRGB(45, 45, 62),
    SliderTrack      = Color3.fromRGB(40, 40, 55),
    SliderFill       = Color3.fromRGB(108, 92, 231),
    ToggleOff        = Color3.fromRGB(55, 55, 72),
    ToggleOn         = Color3.fromRGB(108, 92, 231),
    ToggleKnob       = Color3.fromRGB(240, 240, 250),
    InputBackground  = Color3.fromRGB(14, 14, 20),

    -- Status colors
    Success          = Color3.fromRGB(46, 213, 115),
    Warning          = Color3.fromRGB(255, 177, 66),
    Error            = Color3.fromRGB(252, 92, 101),
    Info             = Color3.fromRGB(69, 170, 242),

    -- Mini icon
    MiniIconBg       = Color3.fromRGB(28, 28, 40),

    -- Typography
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

    -- Dimensions
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

    -- Animation
    TweenSpeed       = 0.25,
    TweenSpeedFast   = 0.12,
    TweenSpeedSlow   = 0.4,
    EasingStyle      = Enum.EasingStyle.Quart,
    EasingDirection  = Enum.EasingDirection.Out,
}

-- ═══════════════════════════════════════════════════════
--  UTILITY: INSTANCE CREATION
-- ═══════════════════════════════════════════════════════

local function Create(className, properties, children)
    local inst = Instance.new(className)
    if properties then
        for key, value in pairs(properties) do
            inst[key] = value
        end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = inst
        end
    end
    return inst
end

-- ═══════════════════════════════════════════════════════
--  UTILITY: TWEENING
-- ═══════════════════════════════════════════════════════

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

-- ═══════════════════════════════════════════════════════
--  UTILITY: UI DECORATORS
-- ═══════════════════════════════════════════════════════

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

-- ═══════════════════════════════════════════════════════
--  DEVICE DETECTION
-- ═══════════════════════════════════════════════════════

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

-- ═══════════════════════════════════════════════════════
--  DRAG SYSTEM (Mouse + Touch)
-- ═══════════════════════════════════════════════════════

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

    UserInputService.InputChanged:Connect(function(input)
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
end

-- ═══════════════════════════════════════════════════════
--  FORWARD DECLARATIONS
-- ═══════════════════════════════════════════════════════

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

-- ═══════════════════════════════════════════════════════
--  AlmondGUI:CreateWindow(config)
-- ═══════════════════════════════════════════════════════

function AlmondGUI:CreateWindow(config)
    config = config or {}
    local title      = config.Title or "AlmondGUI"
    local icon       = config.Icon  or "🌰"
    local baseWidth  = (config.Size and config.Size.Width)  or 560
    local baseHeight = (config.Size and config.Size.Height) or 400
    local closeCallback = config.CloseCallback

    -- Merge custom theme with defaults
    local theme = setmetatable(config.Theme or {}, { __index = DefaultTheme })

    -- Window object
    local self = setmetatable({}, Window)
    self._theme       = theme
    self._tabs        = {}
    self._activeTab   = nil
    self._minimized   = false
    self._visible     = true
    self._title       = title
    self._icon        = icon
    self._closeCallback = closeCallback

    local playerGui = LocalPlayer:WaitForChild("PlayerGui")

    -- ── ScreenGui ──────────────────────────────────────
    self._screenGui = Create("ScreenGui", {
        Name              = "AlmondGUI",
        Parent            = playerGui,
        ResetOnSpawn      = false,
        ZIndexBehavior    = Enum.ZIndexBehavior.Sibling,
        DisplayOrder      = 100,
    })

    -- ── Main Window (CanvasGroup for GroupTransparency + rounded clipping) ──
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

    -- ── Title Bar ──────────────────────────────────────
    self._titleBar = Create("Frame", {
        Name             = "TitleBar",
        Size             = UDim2.new(1, 0, 0, theme.TitleBarHeight),
        BackgroundColor3 = theme.TitleBar,
        BorderSizePixel  = 0,
        Parent           = self._mainFrame,
    })
    Corner(self._titleBar, theme.CornerLarge)
    -- Cover bottom rounded corners so only the top is rounded
    Create("Frame", {
        Name             = "BottomCover",
        Size             = UDim2.new(1, 0, 0, 14),
        Position         = UDim2.new(0, 0, 1, -14),
        BackgroundColor3 = theme.TitleBar,
        BorderSizePixel  = 0,
        Parent           = self._titleBar,
    })
    -- Bottom border line
    Create("Frame", {
        Name             = "TitleBorder",
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = theme.Border,
        BorderSizePixel  = 0,
        Parent           = self._titleBar,
    })

    -- Title icon
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

    -- Title text
    self._titleLabel = Create("TextLabel", {
        Name                 = "TitleLabel",
        Size                 = UDim2.new(1, -140, 1, 0),
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

    -- ── Title-bar control buttons ──────────────────────
    local function MakeControlBtn(name, text, color, xOffset)
        local btn = Create("TextButton", {
            Name                   = name,
            Size                   = UDim2.new(0, 30, 0, 30),
            Position               = UDim2.new(1, xOffset, 0.5, 0),
            AnchorPoint            = Vector2.new(0.5, 0.5),
            BackgroundColor3       = theme.Surface,
            BackgroundTransparency = 0.5,
            Text                   = text,
            TextSize               = 16,
            Font                   = theme.Font,
            TextColor3             = color,
            BorderSizePixel        = 0,
            AutoButtonColor        = false,
            Parent                 = self._titleBar,
        })
        Corner(btn, theme.CornerSmall)
        btn.MouseEnter:Connect(function()
            Tween(btn, { BackgroundTransparency = 0, BackgroundColor3 = theme.SurfaceHover }, theme.TweenSpeedFast)
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, { BackgroundTransparency = 0.5, BackgroundColor3 = theme.Surface }, theme.TweenSpeedFast)
        end)
        return btn
    end

    local closeBtn    = MakeControlBtn("CloseBtn",    "✕", theme.Error,         -22)
    local minimizeBtn = MakeControlBtn("MinimizeBtn", "─", theme.TextSecondary, -58)

    -- Make window draggable by title bar
    MakeDraggable(self._mainFrame, self._titleBar)

    -- ── Body (sidebar + content) ───────────────────────
    local body = Create("Frame", {
        Name                   = "Body",
        Size                   = UDim2.new(1, 0, 1, -theme.TitleBarHeight),
        Position               = UDim2.new(0, 0, 0, theme.TitleBarHeight),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Parent                 = self._mainFrame,
    })

    -- Tab sidebar
    local tabWidth = GetTabWidth()

    self._tabSidebar = Create("Frame", {
        Name             = "TabSidebar",
        Size             = UDim2.new(0, tabWidth, 1, 0),
        BackgroundColor3 = theme.TitleBar,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        Parent           = body,
    })
    -- Sidebar right border
    Create("Frame", {
        Name             = "SidebarBorder",
        Size             = UDim2.new(0, 1, 1, 0),
        Position         = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = theme.Border,
        BorderSizePixel  = 0,
        Parent           = self._tabSidebar,
    })

    -- Scrollable tab button list
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

    -- Content area
    self._contentArea = Create("Frame", {
        Name                   = "ContentArea",
        Size                   = UDim2.new(1, -tabWidth, 1, 0),
        Position               = UDim2.new(0, tabWidth, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ClipsDescendants       = true,
        Parent                 = body,
    })

    -- ── Mini Icon  🌰  (shown when minimized) ─────────
    self._miniIcon = Create("TextButton", {
        Name                   = "MiniIcon",
        Size                   = UDim2.fromOffset(52, 52),
        Position               = UDim2.new(0.5, 0, 0.92, 0),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        BackgroundColor3       = theme.MiniIconBg,
        BackgroundTransparency = 0.15,
        Text                   = "🌰",
        TextSize               = 26,
        Font                   = Enum.Font.SourceSans,
        TextColor3             = theme.Text,
        BorderSizePixel        = 0,
        AutoButtonColor        = false,
        Visible                = false,
        Parent                 = self._screenGui,
    })
    Corner(self._miniIcon, theme.CornerPill)
    Stroke(self._miniIcon, theme.Accent, 2)

    self._miniIcon.MouseEnter:Connect(function()
        Tween(self._miniIcon, {
            BackgroundTransparency = 0,
            Size = UDim2.fromOffset(58, 58),
        }, theme.TweenSpeedFast)
    end)
    self._miniIcon.MouseLeave:Connect(function()
        Tween(self._miniIcon, {
            BackgroundTransparency = 0.15,
            Size = UDim2.fromOffset(52, 52),
        }, theme.TweenSpeedFast)
    end)

    -- Make the mini icon draggable
    MakeDraggable(self._miniIcon, self._miniIcon)

    -- Click mini icon → restore
    self._miniIcon.MouseButton1Click:Connect(function()
        self:Restore()
    end)

    -- ── Notification container ─────────────────────────
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

    -- ── Button handlers ────────────────────────────────
    closeBtn.MouseButton1Click:Connect(function()
        if self._closeCallback then
            self._closeCallback()
        else
            self:Close()
        end
    end)

    minimizeBtn.MouseButton1Click:Connect(function()
        self:Minimize()
    end)

    -- ── Intro animation ────────────────────────────────
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

    return self
end

-- ═══════════════════════════════════════════════════════
--  WINDOW METHODS
-- ═══════════════════════════════════════════════════════

--- Switch to a specific tab
function Window:SelectTab(tab)
    local theme = self._theme

    -- Deselect previous tab
    if self._activeTab and self._activeTab ~= tab then
        local prev = self._activeTab
        prev._content.Visible = false
        Tween(prev._button, {
            BackgroundColor3       = theme.TabInactive,
            BackgroundTransparency = 0.5,
        }, theme.TweenSpeed)
        Tween(prev._indicator, { BackgroundTransparency = 1 }, theme.TweenSpeed)
    end

    -- Select new tab
    self._activeTab = tab
    tab._content.Visible = true
    -- Reset scroll position to top
    tab._content.CanvasPosition = Vector2.new(0, 0)

    Tween(tab._button, {
        BackgroundColor3       = theme.Accent,
        BackgroundTransparency = 0.15,
    }, theme.TweenSpeed)
    Tween(tab._indicator, { BackgroundTransparency = 0 }, theme.TweenSpeed)
end

--- Add a new tab to the window
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

    -- ── Tab button ─────────────────────────────────────
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

    -- Active indicator bar (left edge)
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
        -- Phone: icon only, centered
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
        -- Desktop/Tablet: icon + label
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

    -- ── Tab content (scrollable) ───────────────────────
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

    -- Tab button click
    tabBtn.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)

    -- Tab button hover
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

    -- Auto-select the first tab
    if #self._tabs == 1 then
        self:SelectTab(tab)
    end

    return tab
end

--- Set the window title
function Window:SetTitle(text)
    self._title = text
    self._titleLabel.Text = text
end

--- Minimize the window (shows the 🌰 mini icon)
function Window:Minimize()
    if self._minimized then return end
    self._minimized = true

    local theme = self._theme
    local ws = self._windowSize

    -- Animate window out
    Tween(self._mainFrame, {
        GroupTransparency = 1,
        Size = UDim2.new(
            ws.X.Scale * 0.92, ws.X.Offset * 0.92,
            ws.Y.Scale * 0.92, ws.Y.Offset * 0.92
        ),
    }, theme.TweenSpeed)

    task.delay(theme.TweenSpeed + 0.02, function()
        self._mainFrame.Visible = false

        -- Show mini icon with pop-in
        self._miniIcon.Visible = true
        self._miniIcon.Size = UDim2.fromOffset(0, 0)
        Tween(self._miniIcon, {
            Size = UDim2.fromOffset(52, 52),
        }, 0.3, Enum.EasingStyle.Back)
    end)
end

--- Restore the window from minimized state
function Window:Restore()
    if not self._minimized then return end
    self._minimized = false

    local theme = self._theme
    local ws = self._windowSize

    -- Hide mini icon
    Tween(self._miniIcon, {
        Size = UDim2.fromOffset(0, 0),
    }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)

    task.delay(0.22, function()
        self._miniIcon.Visible = false

        -- Show window with animation
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

--- Close (hide) the window
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

--- Show the window after it has been closed
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

--- Toggle window visibility
function Window:Toggle()
    if self._visible then
        self:Close()
    else
        self:Show()
    end
end

--- Check if window is minimized
function Window:IsMinimized()
    return self._minimized
end

--- Check if window is visible
function Window:IsVisible()
    return self._visible
end

--- Permanently destroy the window and clean up
function Window:Destroy()
    self._screenGui:Destroy()
    self._tabs = {}
    self._activeTab = nil
end

-- ═══════════════════════════════════════════════════════
--  NOTIFICATION SYSTEM
-- ═══════════════════════════════════════════════════════

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

    -- Use CanvasGroup for smooth fade of all children at once
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

    -- Accent stripe on the left
    local stripe = Create("Frame", {
        Size             = UDim2.new(0, 3, 1, -16),
        Position         = UDim2.new(0, 8, 0.5, 0),
        AnchorPoint      = Vector2.new(0, 0.5),
        BackgroundColor3 = accentColor,
        BorderSizePixel  = 0,
        Parent           = notif,
    })
    Corner(stripe, theme.CornerPill)

    -- Title
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

    -- Description
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

    -- Fade in
    Tween(notif, { GroupTransparency = 0 }, 0.35)

    -- Auto dismiss
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

-- ═══════════════════════════════════════════════════════
--  TAB CONTROLS
-- ═══════════════════════════════════════════════════════

-- ─────────────────────────────────────
-- Tab:AddButton(config)
-- config: { Name, Description, Callback }
-- returns: { SetText, SetCallback }
-- ─────────────────────────────────────
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

    -- Hover
    button.MouseEnter:Connect(function()
        Tween(button, { BackgroundColor3 = theme.SurfaceHover }, theme.TweenSpeedFast)
    end)
    button.MouseLeave:Connect(function()
        Tween(button, { BackgroundColor3 = theme.Surface }, theme.TweenSpeedFast)
    end)

    -- Click
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

-- ─────────────────────────────────────
-- Tab:AddToggle(config)
-- config: { Name, Default, Callback }
-- returns: { SetValue, GetValue, SetCallback }
-- ─────────────────────────────────────
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

    -- Label
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

    -- Switch track
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

    -- Switch knob
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
        Tween(track, {
            BackgroundColor3 = value and theme.ToggleOn or theme.ToggleOff,
        }, 0.2)
        Tween(knob, {
            Position = value and knobX_on or knobX_off,
        }, 0.2, Enum.EasingStyle.Back)
    end

    -- Click handler (full container area)
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

    -- Hover
    toggleBtn.MouseEnter:Connect(function()
        Tween(container, { BackgroundColor3 = theme.SurfaceHover }, theme.TweenSpeedFast)
    end)
    toggleBtn.MouseLeave:Connect(function()
        Tween(container, { BackgroundColor3 = theme.Surface }, theme.TweenSpeedFast)
    end)

    local ref = {}
    function ref:SetValue(val)
        value = val
        updateVisual()
    end
    function ref:GetValue()
        return value
    end
    function ref:SetCallback(fn)
        callback = fn
    end
    return ref
end

-- ─────────────────────────────────────
-- Tab:AddSlider(config)
-- config: { Name, Min, Max, Default, Increment, Suffix, Callback }
-- returns: { SetValue, GetValue, SetCallback }
-- ─────────────────────────────────────
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

    -- Name label
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

    -- Value label
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

    -- Slider track
    local trackFrame = Create("Frame", {
        Name             = "Track",
        Size             = UDim2.new(1, -24, 0, 6),
        Position         = UDim2.new(0, 12, 0, 34),
        BackgroundColor3 = theme.SliderTrack,
        BorderSizePixel  = 0,
        Parent           = container,
    })
    Corner(trackFrame, theme.CornerPill)

    -- Fill
    local pct = math.clamp((default - min) / math.max(max - min, 0.001), 0, 1)
    local fill = Create("Frame", {
        Name             = "Fill",
        Size             = UDim2.new(pct, 0, 1, 0),
        BackgroundColor3 = theme.SliderFill,
        BorderSizePixel  = 0,
        Parent           = trackFrame,
    })
    Corner(fill, theme.CornerPill)

    -- Knob
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

    -- Slider logic
    local dragging = false

    local function formatValue(val)
        if increment >= 1 then
            return tostring(math.floor(val))
        end
        local decimals = math.max(0, math.ceil(-math.log10(increment)))
        return string.format("%." .. decimals .. "f", val)
    end

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

    -- Interactive overlay
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

    UserInputService.InputChanged:Connect(function(input)
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

    -- Hover
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

    -- Set initial value (no animation)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    sliderKnob.Position = UDim2.new(pct, 0, 0.5, 0)

    local ref = {}
    function ref:SetValue(val) setValue(val) end
    function ref:GetValue() return currentValue end
    function ref:SetCallback(fn) callback = fn end
    return ref
end

-- ─────────────────────────────────────
-- Tab:AddLabel(text)
-- returns: { SetText }
-- ─────────────────────────────────────
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

-- ─────────────────────────────────────
-- Tab:AddSection(text)
-- returns: { SetText }
-- ─────────────────────────────────────
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

    -- Underline
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

-- ─────────────────────────────────────
-- Tab:AddSeparator()
-- ─────────────────────────────────────
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

-- ─────────────────────────────────────
-- Tab:AddTextInput(config)
-- config: { Name, Placeholder, Default, Callback }
-- returns: { GetText, SetText, SetCallback }
-- ─────────────────────────────────────
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

    -- Label
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

    -- TextBox
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

    -- Hover
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

-- ─────────────────────────────────────
-- Tab:AddInventoryGrid(config)
-- config: { Columns, ItemSize, Items }
--   Items = { { Name, Icon, Image, Callback }, ... }
-- returns: { AddItem, ClearItems, SetItems }
-- ─────────────────────────────────────
function Tab:AddInventoryGrid(config)
    config = config or {}
    local columns  = config.Columns  or 4
    local itemSize = config.ItemSize or 80
    local items    = config.Items    or {}
    local theme    = self._window._theme

    self._layoutOrder = self._layoutOrder + 1

    -- Adjust for mobile
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

        -- Image or icon/emoji
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

        -- Item name
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

        -- Hover
        cell.MouseEnter:Connect(function()
            Tween(cell, { BackgroundColor3 = theme.SurfaceHover }, theme.TweenSpeedFast)
        end)
        cell.MouseLeave:Connect(function()
            Tween(cell, { BackgroundColor3 = theme.Surface }, theme.TweenSpeedFast)
        end)

        -- Click
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

    -- Create initial items
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

-- ═══════════════════════════════════════════════════════
--  CONVENIENCE: Disable default Roblox CoreGui Backpack
-- ═══════════════════════════════════════════════════════

--- Call this to disable the default Roblox backpack/inventory UI.
--- Useful when using a custom Inventory tab to avoid conflicts.
--- Usage: AlmondGUI:DisableDefaultBackpack()
function AlmondGUI:DisableDefaultBackpack()
    local ok, err = pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    end)
    if not ok then
        warn("[AlmondGUI] Could not disable default backpack: " .. tostring(err))
    end
end

--- Re-enable the default Roblox backpack/inventory UI.
function AlmondGUI:EnableDefaultBackpack()
    local ok, err = pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
    end)
    if not ok then
        warn("[AlmondGUI] Could not enable default backpack: " .. tostring(err))
    end
end

-- ═══════════════════════════════════════════════════════
--  RETURN MODULE
-- ═══════════════════════════════════════════════════════

return AlmondGUI
