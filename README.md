# Zenith UI

Zenith UI is a standalone Roblox Lua UI library built for script hubs and personal tooling. It aims for a clean, low-noise look while still giving you the features people actually expect when they load a modern exploit UI:

- Minimal window with draggable shell
- Tabs and sections
- Toggles, sliders, dropdowns, inputs and buttons
- Config save and load
- Autoload support
- Closable config menu
- Built-in notifications
- Single-file import flow

## Design direction

Instead of copying the louder "cheat panel" look that many public libraries use, Zenith UI leans into a darker graphite surface, restrained accent usage and tighter spacing. The goal is a library that looks custom when you ship it inside your own script.

## Usage

```lua
local ZenithUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/oxp7331-web/zenith-ui/main/src/ZenithUI.lua"))()

local Window = ZenithUI.new({
    Title = "Zenith UI",
    Subtitle = "minimalist runtime panel",
    ConfigFolder = "ZenithUI",
    DefaultTheme = "default",
    ToggleKey = Enum.KeyCode.RightShift,
})

local MainTab = Window:AddTab({ Title = "Main" })
local MainSection = MainTab:AddSection("Main")

MainSection:AddToggle({
    Id = "farm_enabled",
    Title = "Auto Farm",
    Default = false,
    Callback = function(value)
        print("Auto Farm:", value)
    end,
})
```

Full example: [examples/demo.lua](/C:/Users/soact/Documents/itadoriyuji/uilibrary/examples/demo.lua)

## Loader notes

For exploit usage, call the loader with `:`:

```lua
local ZenithUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/oxp7331-web/zenith-ui/main/src/ZenithUI.lua"))()
```

Not this:

```lua
local ZenithUI = loadstring(game.HttpGet("https://raw.githubusercontent.com/oxp7331-web/zenith-ui/main/src/ZenithUI.lua"))()
```

If you are testing in Roblox Studio instead of an executor, `game:HttpGet()` may still be unavailable. In that case use `HttpService:GetAsync()` with HTTP enabled:

```lua
local HttpService = game:GetService("HttpService")
local ZenithUI = loadstring(HttpService:GetAsync("https://raw.githubusercontent.com/oxp7331-web/zenith-ui/main/src/ZenithUI.lua"))()
```

## API

### `ZenithUI.new(options)`

Options:

- `Title`
- `Subtitle`
- `Theme`
- `ConfigFolder`
- `DefaultConfig`
- `DefaultTheme`
- `ToggleKey`

### Window methods

- `Window:AddTab({ Title = "Main" })`
- `Window:SetConfigMenuVisible(boolean)`
- `Window:SaveConfig(name)`
- `Window:LoadConfig(name)`
- `Window:TryAutoload()`
- `Window:Notify({ Title = "...", Content = "..." })`
- `Window:GetTheme()`
- `Window:SetTheme(themeTable)`
- `Window:SetThemeColor(key, color)`
- `Window:SetAccentColor(color)`
- `Window:SaveTheme(name)`
- `Window:LoadTheme(name)`
- `Window:GetValue(id)`
- `Window:SetValue(id, value)`
- `Window:Toggle()`
- `Window:Destroy()`

### Section methods

- `Section:AddLabel(text)`
- `Section:AddButton({ Title, Callback })`
- `Section:AddToggle({ Id, Title, Default, Callback })`
- `Section:AddSlider({ Id, Title, Min, Max, Default, Decimals, Callback })`
- `Section:AddInput({ Id, Title, Placeholder, Default, Callback })`
- `Section:AddDropdown({ Id, Title, Values, Default, Callback })`

## Config behavior

If the executor supports `isfolder`, `makefolder`, `isfile`, `writefile` and `readfile`, configs are stored on disk under:

```text
ZenithUI/
  configs/
  themes/
  meta.json
```

If those APIs are missing, the library still works, but config data only lives for the current session.

Config payloads now store:

- `flags`
- `themeName`
- `themeOverrides`

Older flat config JSON files are still accepted and loaded as flag-only payloads.

## Shipping notes

- Replace the raw GitHub URL in your loader before publishing.
- Rename `ZenithUI.lua` if you want your own brand on it.
- Extend the built-in theme table if you want a different visual identity.
