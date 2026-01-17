# WezTerm Config

Personal WezTerm configuration with Apple Media status bar integration.

## Features

- **Apple Media Status Bar** - Shows currently playing content from Music, Podcasts, and TV
- **Smart Splits** - Seamless navigation between WezTerm and Neovim panes
- **Tokyo Night** theme with JetBrains Mono font
- **tmux-like keybindings** with `Ctrl+a` leader key

## Apple Media Status Bar

Displays currently playing content in the bottom right of the tab bar with auto-detection for:

| App | Icon | Color |
|-----|------|-------|
| Music | 󰎆 | Blue |
| Podcasts | 󰦔 | Orange |
| TV | 󰕼 | Red |

Features:
- Animated equalizer (5 styles: wave, thin, classic, dots, mini)
- Scrolling marquee for long titles
- Track/episode name and artist/show

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
  scroll_speed = 3,        -- 1 = slow, 5 = fast
  scroll_width = 35,       -- visible characters for track display
  update_interval = 150,   -- ms between updates (lower = smoother)
  eq_style = "wave",       -- wave, thin, classic, dots, mini
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
- [JetBrains Mono Nerd Font](https://www.nerdfonts.com/)
- macOS (for Apple Music integration)

## Installation

```bash
git clone https://github.com/KevinTCoughlin/wezterm-config.git ~/.config/wezterm
```

## License

MIT
