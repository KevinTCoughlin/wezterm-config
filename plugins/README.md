# Wezterm Apple Media Plugin

Status bar plugin for Apple Music and Apple Podcasts in Wezterm.

![Preview](https://github.com/KevinTCoughlin/wezterm-apple-music/raw/main/preview.png)

## Features

- **Auto-detection** - Automatically shows whichever app is playing
- **Smooth scrolling** - Marquee effect for long titles
- **Animated equalizer** - Multiple styles (thin, classic, dots, mini, wave)
- **App icons** - Shows 󰎆 for Music, 󰦔 for Podcasts
- **Playback controls** - Prev/Play-Pause/Next with keyboard shortcuts
- **Volume indicator** - Nerd Font icons showing current level
- **Tokyo Night colors** - Beautiful default palette (customizable)

## Requirements

- macOS with Apple Music and/or Apple Podcasts
- Wezterm
- Nerd Font (for icons)

## Installation

### Option 1: Copy to config

```bash
mkdir -p ~/.config/wezterm/plugins
curl -o ~/.config/wezterm/plugins/apple-media.lua \
  https://raw.githubusercontent.com/KevinTCoughlin/wezterm-apple-music/main/apple-media.lua
```

### Option 2: Clone

```bash
git clone https://github.com/KevinTCoughlin/wezterm-apple-music \
  ~/.config/wezterm/plugins/apple-media
```

## Usage

In your `wezterm.lua`:

```lua
local apple_media = require("plugins.apple-media")

-- Apply to config
apple_media.apply_to_config(config, {
  eq_style = "thin",
  show_controls = true,
  show_volume = true,
  show_app_icon = true,
})

-- Setup keyboard shortcuts
apple_media.setup_keys(config)
```

## Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `update_interval` | 500 | Refresh rate in ms |
| `scroll_width` | 30 | Max visible title characters |
| `scroll_padding` | `"  ·  "` | Separator in scroll loop |
| `eq_style` | `"thin"` | Equalizer style |
| `show_volume` | true | Show volume icon |
| `show_controls` | true | Show playback controls |
| `show_app_icon` | true | Show Music/Podcast icon |
| `show_date` | true | Show date/time |
| `date_format` | `"%a %b %-d %H:%M"` | strftime format |

### Colors

```lua
colors = {
  eq = "#7aa2f7",        -- equalizer
  track = "#c0caf5",     -- track/episode title
  controls = "#7dcfff",  -- prev/next icons
  play = "#9ece6a",      -- play icon
  pause = "#f7768e",     -- pause icon
  volume = "#bb9af7",    -- volume icon
  podcast = "#e0af68",   -- podcast accent
  date = "#565f89",      -- date/time
}
```

## Equalizer Styles

| Style | Preview |
|-------|---------|
| `thin` | `▏▎▍` `▎▍▌` `▍▌▋` |
| `classic` | `▁▃▅` `▂▅▃` `▃▂▅` |
| `dots` | `●○●` `○●○` `●●○` |
| `mini` | `⠋` `⠙` `⠹` `⠸` |
| `wave` | `∿∿∿` `∾∿∿` `∿∾∿` |

## Keyboard Shortcuts

After calling `setup_keys(config)`:

| Binding | Action |
|---------|--------|
| `C-a m` | Play/Pause |
| `C-a >` | Next track/episode |
| `C-a <` | Previous track/episode |
| `C-a +` | Volume up |
| `C-a _` | Volume down |

## Status Bar Preview

**Music playing:**
```
󰎆 ▎▍▌  󰒮 󰏤 󰒭  Song Title — Artist Name  󰕾  │  Fri Jan 16 22:30
```

**Podcast playing:**
```
󰦔 ▍▌▋  󰒮 󰏤 󰒭  Episode Title — Show Name  󰖀  │  Fri Jan 16 22:30
```

**Paused:**
```
󰎆 ⏸  󰒮 󰐊 󰒭  Song Title — Artist Name  󰕾  │  Fri Jan 16 22:30
```

## Related Files

- `apple-media.lua` - Combined Music + Podcasts plugin (recommended)
- `apple-music.lua` - Music-only plugin (legacy)

## License

MIT

## Author

Kevin T. Coughlin ([@kevintcoughlin](https://github.com/KevinTCoughlin))
