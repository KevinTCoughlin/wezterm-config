# WezTerm Config

Chezmoi-managed WezTerm configuration with custom status bar plugins.

## Lua API Gotchas

- **No `wezterm.read_file()`** — this function does not exist. Use `io.open(path, "r")` + `f:read("*a")` for file I/O.
- **`wezterm.json_parse()`** works fine for parsing JSON strings into Lua tables.
- **No `wezterm cli reload-config-for-all`** — use `touch ~/.config/wezterm/wezterm.lua` to trigger the file watcher instead.

## Plugin Pattern

Plugins live in `plugins/` and follow this pattern:

- `apply_to_config(config, user_opts)` — merges defaults with user options, mutates config, returns resolved opts
- `get_status_elements(opts)` — returns `FormatItem[]` for the status bar
- Deep merge via local `merge_opts()` function (no shared lib)
- Module-level `resolved_opts` for state between `apply_to_config` and status calls

## Material You Plugin (`plugins/material-you/`)

- Reads M3 color scheme from `/tmp/kde-material-you-colors-$USER.json`
- Maps dark scheme tokens to both pane and tab bar colors:
  - **Pane**: `surface` → background, `onSurface` → foreground
  - **Tab bar**: `surfaceDim` → bar bg, `primary`/`onPrimary` → active tab, `onSurfaceVariant` → inactive tab fg, `surfaceContainerHigh`/`onSurface` → hover, `outline` → separator/new tab
- Falls back to Tokyo Night when JSON is missing (macOS, Windows, daemon not running)
- `on_change_hook` in `~/.config/kde-material-you-colors/config.conf` touches the config to trigger reload
- `get_colors()` exposes resolved colors for use in status bar separators

## Template Guards

`wezterm.lua.tmpl` uses chezmoi `{{ if eq .chezmoi.os "linux" }}` guards for Linux-only features (Material You). macOS gets Apple Media plugin instead. Non-Linux platforms keep hardcoded Tokyo Night tab colors.
