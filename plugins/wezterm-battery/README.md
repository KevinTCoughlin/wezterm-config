# wezterm-battery

Battery status indicator for WezTerm status bar.

## Features

- Battery percentage display with state-based coloring
- Granular icons that change based on charge level
- Configurable thresholds for low/critical warnings
- Optional time remaining display
- macOS support via `pmset`

## Installation

Clone or copy this plugin to your WezTerm plugins directory:

```bash
# Clone
git clone https://github.com/KevinTCoughlin/wezterm-battery.git \
  ~/.config/wezterm/plugins/wezterm-battery

# Or copy manually
cp -r wezterm-battery ~/.config/wezterm/plugins/
```

## Usage

```lua
-- In your wezterm.lua
local battery = dofile(wezterm.config_dir .. "/plugins/wezterm-battery/plugin/init.lua")

-- Apply with defaults
battery.apply_to_config(config)

-- Or with custom options
battery.apply_to_config(config, {
  show_percentage = true,
  show_time = true,
  low_threshold = 25,
  critical_threshold = 10,
})
```

### Status Bar Integration

Add battery to your `update-status` event:

```lua
wezterm.on("update-status", function(window, pane)
  local elements = {}

  -- Add battery status
  for _, e in ipairs(battery.get_status_elements()) do
    table.insert(elements, e)
  end

  -- Or use the separator variant
  for _, e in ipairs(battery.get_status_with_separator()) do
    table.insert(elements, e)
  end

  window:set_right_status(wezterm.format(elements))
end)
```

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `show_percentage` | boolean | `true` | Show numeric percentage |
| `show_time` | boolean | `false` | Show remaining time |
| `low_threshold` | number | `20` | Percentage for "low" state |
| `critical_threshold` | number | `10` | Percentage for "critical" state |
| `use_granular_icons` | boolean | `true` | Use level-based icons |
| `cache_ttl` | number | `5` | Seconds between battery checks |

### Icons

Override individual state icons:

```lua
battery.apply_to_config(config, {
  icons = {
    charging = "⚡",
    discharging = "🔋",
    full = "✓",
    low = "⚠",
    critical = "!",
  },
})
```

Or provide custom granular icon sets (11 icons each, 0-100% in 10% increments):

```lua
battery.apply_to_config(config, {
  use_granular_icons = true,
  discharge_icons = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█", "█", "█", "█" },
  charge_icons = { "⚡▁", "⚡▂", "⚡▃", "⚡▄", "⚡▅", "⚡▆", "⚡▇", "⚡█", "⚡█", "⚡█", "⚡█" },
})
```

### Colors

Customize colors for each state:

```lua
battery.apply_to_config(config, {
  colors = {
    charging = "#9ece6a",     -- Green
    discharging = "#7aa2f7",  -- Blue
    full = "#9ece6a",         -- Green
    low = "#e0af68",          -- Orange
    critical = "#f7768e",     -- Red
    unknown = "#565f89",      -- Gray
    percentage = "#c0caf5",   -- Text color for percentage
    time = "#565f89",         -- Text color for time remaining
    separator = "#565f89",    -- Separator color
  },
})
```

## API

### `battery.apply_to_config(config, opts)`

Initialize the plugin with configuration options. Returns resolved options.

### `battery.get_status_elements(opts?)`

Returns an array of WezTerm format elements for the battery status.

### `battery.get_status_with_separator(opts?)`

Returns battery status elements prefixed with a separator (`│`).

### `battery.get_battery_info(opts?)`

Returns raw battery info:

```lua
{
  percentage = 85,           -- 0-100 or nil
  status = "discharging",    -- charging, discharging, full, unknown
  time_remaining = "5h 30m", -- string or nil
  is_present = true,         -- boolean
}
```

## Platform Support

Currently macOS only (uses `pmset -g batt`). Linux support can be added by parsing `/sys/class/power_supply/`.

## License

MIT
