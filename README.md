# WezTerm Config

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![CI](https://github.com/KevinTCoughlin/wezterm-config/actions/workflows/ci.yml/badge.svg)](https://github.com/KevinTCoughlin/wezterm-config/actions/workflows/ci.yml)

Personal, cross-platform WezTerm configuration with a native multiplexer workflow and local status plugins.

## Features

- Tokyo Night fallback theme with optional KDE Material You colors
- Battery and Ollama status indicators
- JetBrains Mono and Nerd Font fallback
- tmux-like pane and tab keybindings with a `Ctrl+a` leader
- Windows- and Unix-style path handling in tab titles

Material You colors are loaded from
`$XDG_RUNTIME_DIR/kde-material-you-colors-$USER.json`, or from
`$HOME/.cache` when `XDG_RUNTIME_DIR` is unavailable. Missing color data falls
back to Tokyo Night.

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

## Requirements

- [WezTerm](https://wezfurlong.org/wezterm/)
- JetBrains Mono and Symbols Nerd Font Mono (recommended)
- `curl` for Ollama status checks
- Ollama is optional; the status indicator shows `off` when unavailable
- KDE Material You color generation is optional and Linux-specific

## Installation

```bash
git clone --recurse-submodules \
  https://github.com/KevinTCoughlin/wezterm-config.git ~/.config/wezterm
```

For an existing checkout:

```bash
git submodule update --init --recursive
```

The Ollama plugin is pinned as a Git submodule so configuration updates remain reproducible.

## Validation

```bash
./scripts/check.sh
```

The check validates all Lua syntax, verifies the required submodule is initialized,
and loads the configuration through WezTerm when the executable is available.
CI installs and verifies the pinned stable WezTerm release
`20240203-110809-5046fc22`; a missing WezTerm executable is an error in CI.
Set `REQUIRE_WEZTERM=1` to require the same API validation locally.

## License

MIT
