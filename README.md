# WezTerm Config

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![GitHub Sponsors](https://img.shields.io/github/sponsors/KevinTCoughlin)](https://github.com/sponsors/KevinTCoughlin)

Minimal WezTerm configuration with Apple Media status bar.

## Features

- **Apple Media Status Bar** - Shows currently playing track with scrolling marquee
- **Smart Splits** - Seamless navigation between WezTerm and Neovim panes
- **Tokyo Night** theme with JetBrains Mono font
- **tmux-like keybindings** with `Ctrl+a` leader key

## Apple Media Status Bar

Displays currently playing content in the right status bar:

```
Song — Artist | Thu 1/23 3:45p
```

- Scrolling marquee for long titles (~1 char/sec)
- Polls media every 2 seconds (minimal resource usage)
- Responsive datetime based on window width

### Media Keybindings

| Binding | Action |
|---------|--------|
| `Ctrl+Shift+m` | play/pause |
| `Ctrl+Shift+.` | next track |
| `Ctrl+Shift+,` | previous track |
| `Ctrl+Shift+=` | volume up |
| `Ctrl+Shift+-` | volume down |

### Configuration

Edit the `media_config` table in `wezterm.lua`:

```lua
local media_config = {
  scroll_width = 40,       -- visible characters for track display
  update_interval = 1000,  -- 1Hz (1 char/sec scroll)
  poll_every_n = 2,        -- poll media every N updates (~2 sec)
  color = "#565f89",       -- status bar text color
}
```

## General Keybindings

Leader key: `Ctrl+a`

| Binding | Action |
|---------|--------|
| `C-a \|` | split horizontal |
| `C-a -` | split vertical |
| `C-a h/j/k/l` | navigate panes |
| `C-a H/J/K/L` | resize panes |
| `C-a x` | close pane |
| `C-a z` | zoom pane |
| `C-a c` | new tab |
| `C-a n/p` | next/prev tab |
| `C-a 1-5` | jump to tab |
| `C-a v` | copy mode |
| `C-a r` | reload config |

### Smart Splits (Neovim Integration)

| Binding | Action |
|---------|--------|
| `Ctrl+h/j/k/l` | navigate panes (works across Neovim) |
| `Alt+h/j/k/l` | resize panes |

## Requirements

- [WezTerm](https://wezfurlong.org/wezterm/)
- macOS (for Apple Music integration)

## Installation

```bash
git clone https://github.com/KevinTCoughlin/wezterm-config.git ~/.config/wezterm
```

## Support

If you find this useful, consider [sponsoring](https://github.com/sponsors/KevinTCoughlin).

## License

MIT
