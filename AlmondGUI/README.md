# 🌰 AlmondGUI

**A modern, premium, dark-mode Roblox UI framework.**

AlmondGUI is a reusable, developer-friendly GUI library for Roblox that lets you create beautiful, responsive interfaces with minimal code. It works on desktop, mobile, and tablet out of the box.


## ✨ Features

- **Dark mode by default** — sleek, polished, premium look
- **Responsive** — auto-adapts to phone, tablet, and desktop
- **Smooth animations** — TweenService-powered transitions everywhere
- **Minimize system** — 🌰 draggable floating icon to restore the window
- **Tab-based layout** — sidebar navigation with icon support
- **Rich controls** — buttons, sliders, toggles, dropdowns, keybinds, progress bars, labels, sections, text inputs, inventory grids
- **Toast notifications** — success, warning, error, info notifications with auto-dismiss
- **Draggable** — window and mini icon draggable on mouse and touch
- **Easy API** — clean, readable, extensible developer interface
- **CoreGui-safe** — handles Roblox backpack conflicts gracefully

## 🚀 Installation & Setup

```lua
local AlmondGUI = loadstring(game:HttpGet("YOUR_RAW_URL_HERE"))()
```
---

## ⚡ Quick Start

```lua
-- Create a window
local Window = AlmondGUI:CreateWindow({
    Title = "My App",
    Icon  = "🌰",
})

-- Add a tab
local Tab = Window:AddTab({ Name = "Main", Icon = "🏠" })

-- Add a button
Tab:AddButton({
    Name     = "Click Me",
    Callback = function()
        print("Button clicked!")
    end,
})

-- Add a toggle
Tab:AddToggle({
    Name     = "Dark Mode",
    Default  = true,
    Callback = function(value)
        print("Toggle:", value)
    end,
})

-- Add a slider
Tab:AddSlider({
    Name      = "Volume",
    Min       = 0,
    Max       = 100,
    Default   = 50,
    Increment = 5,
    Suffix    = "%",
    Callback  = function(value)
        print("Volume:", value)
    end,
})
```

---

## 📖 API Reference

### `AlmondGUI:CreateWindow(config)`

Creates and returns a new GUI window.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `config.Title` | string | `"AlmondGUI"` | Window title text |
| `config.Icon` | string | `"🌰"` | Title bar icon (emoji or text) |
| `config.Size` | table | `{Width=560, Height=400}` | Base window dimensions (auto-scales on mobile) |
| `config.Theme` | table | `{}` | Theme color/property overrides |

**Returns:** `Window` object

```lua
local Window = AlmondGUI:CreateWindow({
    Title = "My Application",
    Icon  = "🌰",
    Size  = { Width = 600, Height = 450 },
})
```

---

### `Window:AddTab(config)`

Adds a new tab to the window sidebar.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `config.Name` | string | `"Tab"` | Tab display name |
| `config.Icon` | string | `""` | Tab icon (emoji, shown in sidebar) |

**Returns:** `Tab` object

```lua
local HomeTab = Window:AddTab({ Name = "Home", Icon = "🏠" })
```

---

### `Window:SelectTab(tab)`

Programmatically switch to a specific tab.

```lua
Window:SelectTab(HomeTab)
```

---

### `Window:Minimize()` / `Window:Restore()`

Minimize the window to the 🌰 floating icon, or restore it.

```lua
Window:Minimize()  -- hides window, shows draggable 🌰 icon
Window:Restore()   -- hides 🌰 icon, shows window
```

The user can also click/tap the 🌰 icon to restore, or click the minimize button (`─`) in the title bar to minimize.

---

### `Window:Close()` / `Window:Show()` / `Window:Toggle()`

Hide, show, or toggle the entire window. There is no built-in close button — use `Window:Destroy()` from your own UI (e.g. a "Destroy GUI" button in Settings).

```lua
Window:Close()   -- fade out and hide
Window:Show()    -- fade in and show
Window:Toggle()  -- toggle visibility
```

---

### `Window:Destroy()`

Permanently destroys the window and all its UI elements. Add a button for this in your Settings tab:

```lua
SettingsTab:AddButton({
    Name        = "Destroy GUI",
    Description = "Permanently removes this GUI.",
    Callback    = function()
        Window:Destroy()
    end,
})
```

---

### `Window:SetTitle(text)`

Change the window title at runtime.

```lua
Window:SetTitle("New Title")
```

---

### `Window:IsMinimized()` / `Window:IsVisible()`

Check current window state.

```lua
if Window:IsMinimized() then ... end
if Window:IsVisible() then ... end
```

---

### `Window:Notify(config)`

Show a toast notification.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `config.Title` | string | `"Notification"` | Heading text |
| `config.Description` | string | `""` | Body text |
| `config.Duration` | number | `5` | Seconds before auto-dismiss |
| `config.Type` | string | `"info"` | `"success"`, `"warning"`, `"error"`, or `"info"` |

```lua
Window:Notify({
    Title       = "Saved!",
    Description = "Your settings have been saved.",
    Type        = "success",
    Duration    = 4,
})
```

---

### `Tab:AddButton(config)`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `config.Name` | string | `"Button"` | Button label |
| `config.Description` | string | `nil` | Optional subtext below the label |
| `config.Callback` | function | `noop` | Called on click/tap |

**Returns:** `{ SetText(text), SetCallback(fn) }`

```lua
local btn = Tab:AddButton({
    Name        = "Execute",
    Description = "Runs the main function.",
    Callback    = function() print("Executed!") end,
})

-- Update later:
btn:SetText("Run Again")
```

---

### `Tab:AddToggle(config)`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `config.Name` | string | `"Toggle"` | Toggle label |
| `config.Default` | boolean | `false` | Initial state |
| `config.Callback` | function | `noop` | Called with `true`/`false` |

**Returns:** `{ SetValue(bool), GetValue(), SetCallback(fn) }`

```lua
local toggle = Tab:AddToggle({
    Name     = "God Mode",
    Default  = false,
    Callback = function(enabled)
        print("God Mode:", enabled)
    end,
})

-- Programmatic control:
toggle:SetValue(true)
print(toggle:GetValue()) -- true
```

---

### `Tab:AddSlider(config)`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `config.Name` | string | `"Slider"` | Slider label |
| `config.Min` | number | `0` | Minimum value |
| `config.Max` | number | `100` | Maximum value |
| `config.Default` | number | `Min` | Starting value |
| `config.Increment` | number | `1` | Step size |
| `config.Suffix` | string | `""` | Suffix for value display (e.g. `"%"`) |
| `config.Callback` | function | `noop` | Called with current value |

**Returns:** `{ SetValue(num), GetValue(), SetCallback(fn) }`

```lua
local slider = Tab:AddSlider({
    Name      = "Opacity",
    Min       = 0,
    Max       = 1,
    Default   = 0.5,
    Increment = 0.05,
    Callback  = function(val) print("Opacity:", val) end,
})

slider:SetValue(0.75)
```

---

### `Tab:AddLabel(text)`

Adds a read-only text label.

**Returns:** `{ SetText(text) }`

```lua
local lbl = Tab:AddLabel("Version 1.0.0")
lbl:SetText("Version 1.0.1")
```

---

### `Tab:AddSection(text)`

Adds a bold heading with an underline divider.

**Returns:** `{ SetText(text) }`

```lua
Tab:AddSection("General Settings")
```

---

### `Tab:AddSeparator()`

Adds a thin horizontal divider line.

```lua
Tab:AddSeparator()
```

---

### `Tab:AddTextInput(config)`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `config.Name` | string | `"Input"` | Label above the text box |
| `config.Placeholder` | string | `"Enter text..."` | Placeholder text |
| `config.Default` | string | `""` | Default value |
| `config.Callback` | function | `noop` | Called with `(text, enterPressed)` on focus lost |

**Returns:** `{ GetText(), SetText(text), SetCallback(fn) }`

```lua
local input = Tab:AddTextInput({
    Name        = "Username",
    Placeholder = "Enter your name...",
    Callback    = function(text, enterPressed)
        if enterPressed then print("Name:", text) end
    end,
})
```

---

### `Tab:AddDropdown(config)`

Creates a dropdown selector with animated expand/collapse.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `config.Name` | string | `"Dropdown"` | Label text |
| `config.Options` | table | `{}` | Array of string options |
| `config.Default` | string | first option | Initially selected value |
| `config.Callback` | function | `noop` | Called with the selected option string |

**Returns:** `{ GetValue(), SetValue(str), SetOptions(table), SetCallback(fn) }`

```lua
local dropdown = Tab:AddDropdown({
    Name     = "Region",
    Options  = { "NA", "EU", "Asia", "OCE" },
    Default  = "NA",
    Callback = function(option)
        print("Region:", option)
    end,
})

-- Programmatic control:
dropdown:SetValue("EU")
dropdown:SetOptions({ "NA", "EU", "SA" })
```

---

### `Tab:AddKeybind(config)`

Creates a keybind picker. Click the key button, then press any key to rebind.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `config.Name` | string | `"Keybind"` | Label text |
| `config.Default` | Enum.KeyCode | `Enum.KeyCode.E` | Initial key |
| `config.Callback` | function | `noop` | Called when the bound key is pressed during gameplay |

**Returns:** `{ GetValue(), SetValue(keyCode), SetCallback(fn) }`

```lua
Tab:AddKeybind({
    Name     = "Toggle GUI",
    Default  = Enum.KeyCode.RightShift,
    Callback = function()
        Window:Toggle()
    end,
})
```

---

### `Tab:AddProgressBar(config)`

Creates a read-only progress bar. Update it programmatically.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `config.Name` | string | `"Progress"` | Label text |
| `config.Default` | number | `0` | Initial value (0–100) |
| `config.Suffix` | string | `"%"` | Suffix for the value display |

**Returns:** `{ GetValue(), SetValue(num), SetColor(Color3) }`

```lua
local bar = Tab:AddProgressBar({
    Name    = "XP Progress",
    Default = 35,
    Suffix  = "%",
})

-- Update later:
bar:SetValue(75)
bar:SetColor(Color3.fromRGB(46, 213, 115))  -- green when near complete
```

---

### `Tab:AddInventoryGrid(config)`

Creates a grid layout for inventory items.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `config.Columns` | number | `4` | Number of columns |
| `config.ItemSize` | number | `80` | Cell size in pixels |
| `config.Items` | table | `{}` | Array of item configs |

Each item in `config.Items`:

| Field | Type | Description |
|---|---|---|
| `Name` | string | Item display name |
| `Icon` | string | Emoji icon (used if no Image) |
| `Image` | string | Roblox asset ID (e.g. `"rbxassetid://123"`) |
| `Callback` | function | Called with the item table on click |

**Returns:** `{ AddItem(config), ClearItems(), SetItems(items) }`

```lua
local grid = Tab:AddInventoryGrid({
    Columns  = 4,
    ItemSize = 80,
    Items    = {
        { Name = "Sword",  Icon = "🗡️", Callback = function(i) print("Equip:", i.Name) end },
        { Name = "Shield", Icon = "🛡️", Callback = function(i) print("Equip:", i.Name) end },
    },
})

-- Add items dynamically:
grid:AddItem({ Name = "Potion", Icon = "🧪", Callback = function() end })

-- Replace all items:
grid:SetItems({ ... })

-- Clear grid:
grid:ClearItems()
```

---

### `AlmondGUI:DisableDefaultBackpack()`

Disables the default Roblox backpack/inventory CoreGui.

```lua
AlmondGUI:DisableDefaultBackpack()
```

### `AlmondGUI:EnableDefaultBackpack()`

Re-enables the default Roblox backpack/inventory CoreGui.

```lua
AlmondGUI:EnableDefaultBackpack()
```

## 📱 Responsive Behavior

AlmondGUI automatically detects the device type and adapts:

| | Phone | Tablet | Desktop |
|---|---|---|---|
| **Window Size** | 94% × 82% of screen | 72% × 76% of screen | Fixed pixels (max 85% of screen) |
| **Tab Sidebar** | 44px (icons only) | 130px (icon + text) | 130px (icon + text) |
| **Inventory Grid** | max 3 columns, smaller cells | 4 columns | 4 columns |
| **Touch Controls** | Full touch support | Full touch support | Mouse + keyboard |
| **Dragging** | Touch drag | Touch drag | Mouse drag |

**Detection logic:**
- **Phone:** `TouchEnabled = true` AND `KeyboardEnabled = false` AND screen short edge ≤ 600px
- **Tablet:** `TouchEnabled = true` AND screen short edge > 600px
- **Desktop:** Everything else

All controls are touch-friendly with appropriately sized hit areas (minimum 36px height).

---

## 🎨 Customization

### Theme Overrides

Pass a `Theme` table in `CreateWindow` to override any default color or setting:

```lua
local Window = AlmondGUI:CreateWindow({
    Title = "Custom Theme",
    Theme = {
        Background = Color3.fromRGB(10, 10, 15),
        Accent     = Color3.fromRGB(255, 107, 107),  -- Red accent
        Surface    = Color3.fromRGB(25, 25, 35),
        Text       = Color3.fromRGB(255, 255, 255),
    },
})
```

### Available Theme Properties

**Colors:** `Background`, `TitleBar`, `Surface`, `SurfaceHover`, `SurfaceActive`, `Accent`, `AccentHover`, `AccentDark`, `TabActive`, `TabInactive`, `TabHover`, `Text`, `TextSecondary`, `TextMuted`, `Border`, `SliderTrack`, `SliderFill`, `ToggleOff`, `ToggleOn`, `ToggleKnob`, `InputBackground`, `Success`, `Warning`, `Error`, `Info`, `MiniIconBg`

**Typography:** `Font`, `FontBold`, `FontSemibold`, `FontLight`, `TitleSize`, `TabSize`, `ControlSize`, `ValueSize`, `SectionSize`, `LabelSize`

**Dimensions:** `CornerRadius`, `CornerSmall`, `CornerLarge`, `CornerPill`, `TitleBarHeight`, `TabWidth`, `TabWidthMobile`, `ControlHeight`, `SliderHeight`, `ToggleSwitchW`, `ToggleSwitchH`, `ToggleKnobSize`, `Padding`, `ControlPadding`

**Animation:** `TweenSpeed`, `TweenSpeedFast`, `TweenSpeedSlow`, `EasingStyle`, `EasingDirection`

### Adding New Controls / Pages

To extend AlmondGUI with your own control types, add methods to the Tab prototype:

```lua
-- After requiring AlmondGUI, before creating windows:
-- Example: A custom "Paragraph" control
local AlmondGUI = require(game.ReplicatedStorage.AlmondGUI)

-- Access Tab internals (Tab is internal, but you can add to any tab instance):
-- Each tab has: tab._content (the ScrollingFrame), tab._layoutOrder, tab._window._theme

-- Add a method to your tab after creation:
local function AddParagraph(tab, title, body)
    tab._layoutOrder = tab._layoutOrder + 1
    local theme = tab._window._theme

    local frame = Instance.new("Frame")
    frame.Name = "Paragraph"
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.BackgroundColor3 = theme.Surface
    frame.BorderSizePixel = 0
    frame.LayoutOrder = tab._layoutOrder
    frame.Parent = tab._content

    local corner = Instance.new("UICorner")
    corner.CornerRadius = theme.CornerSmall
    corner.Parent = frame

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 12)
    pad.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.Parent = frame

    local heading = Instance.new("TextLabel")
    heading.Size = UDim2.new(1, 0, 0, 20)
    heading.BackgroundTransparency = 1
    heading.Text = title
    heading.TextSize = 14
    heading.Font = theme.FontBold
    heading.TextColor3 = theme.Text
    heading.TextXAlignment = Enum.TextXAlignment.Left
    heading.Parent = frame

    local bodyLabel = Instance.new("TextLabel")
    bodyLabel.Size = UDim2.new(1, 0, 0, 0)
    bodyLabel.AutomaticSize = Enum.AutomaticSize.Y
    bodyLabel.BackgroundTransparency = 1
    bodyLabel.Text = body
    bodyLabel.TextSize = 12
    bodyLabel.Font = theme.FontLight
    bodyLabel.TextColor3 = theme.TextSecondary
    bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
    bodyLabel.TextWrapped = true
    bodyLabel.Parent = frame
end

-- Usage:
local Tab = Window:AddTab({ Name = "Info", Icon = "📝" })
AddParagraph(Tab, "About", "This is a custom paragraph control added to AlmondGUI.")
```

---

## 🧪 Examples

### Minimal Window

```lua
local AlmondGUI = require(game.ReplicatedStorage.AlmondGUI)
local Window = AlmondGUI:CreateWindow({ Title = "Minimal" })
local Tab = Window:AddTab({ Name = "Main", Icon = "⭐" })
Tab:AddLabel("Hello, World!")
```

### Button with Notification

```lua
local Tab = Window:AddTab({ Name = "Actions", Icon = "⚡" })
Tab:AddButton({
    Name     = "Heal",
    Callback = function()
        -- your healing logic here
        Window:Notify({ Title = "Healed!", Type = "success", Duration = 3 })
    end,
})
```

### Toggle Example

```lua
Tab:AddToggle({
    Name     = "ESP",
    Default  = false,
    Callback = function(enabled)
        -- toggle ESP logic here
        print("ESP:", enabled)
    end,
})
```

### Slider Example

```lua
Tab:AddSlider({
    Name      = "FOV",
    Min       = 30,
    Max       = 120,
    Default   = 70,
    Increment = 1,
    Callback  = function(val)
        workspace.CurrentCamera.FieldOfView = val
    end,
})
```

### About Tab

```lua
local AboutTab = Window:AddTab({ Name = "About", Icon = "ℹ️" })
AboutTab:AddSection("My Game")
AboutTab:AddLabel("Version 2.1.0")
AboutTab:AddLabel("Created by YourName")
AboutTab:AddSeparator()
AboutTab:AddButton({
    Name     = "Discord Server",
    Callback = function() print("discord.gg/yourserver") end,
})
```

### Settings Tab with Text Input

```lua
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "⚙️" })
SettingsTab:AddSection("Profile")

SettingsTab:AddTextInput({
    Name        = "Display Name",
    Placeholder = "Type here...",
    Callback    = function(text, enterPressed)
        if enterPressed then
            print("Name set to:", text)
        end
    end,
})

SettingsTab:AddSlider({
    Name      = "Volume",
    Min       = 0,
    Max       = 100,
    Default   = 75,
    Suffix    = "%",
    Callback  = function(v) print("Volume:", v) end,
})
```

### Custom Close Behavior

```lua
local Window = AlmondGUI:CreateWindow({
    Title = "Confirm Close",
    CloseCallback = function()
        -- Instead of closing immediately, show a notification
        Window:Notify({
            Title       = "Are you sure?",
            Description = "The window is still open. Minimize instead!",
            Type        = "warning",
            Duration    = 3,
        })
    end,
})
```

---

## 🔧 Troubleshooting

| Issue | Solution |
|---|---|
| GUI doesn't appear | Make sure the script is a **LocalScript**, not a Script. ModuleScripts must be required from a LocalScript. |
| Inventory tab is blank | Ensure you're adding controls to the correct tab variable. Check that `AddInventoryGrid` is called with items. |
| Default backpack overlaps | Call `AlmondGUI:DisableDefaultBackpack()` before creating the window. |
| Backpack re-appears on respawn | Add the disable call inside `player.CharacterAdded:Connect(...)` |
| Window not draggable on mobile | Drag from the **title bar** area. The mini 🌰 icon is also draggable. |
| Controls cut off at bottom | Content scrolls — swipe up/down inside the content area. |
| Slider not responding to touch | Make sure you're dragging horizontally on the slider track area. |
| Font doesn't look right | AlmondGUI uses `GothamMedium`/`GothamBold`/`Gotham` — these are built-in Roblox fonts. |

---

## 📄 License

MIT License. Free to use, modify, and distribute.

---

**Made with 🌰 by Almond**
