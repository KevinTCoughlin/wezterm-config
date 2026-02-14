-- Minimal wezterm config (~60 lines)
-- Terminal renders text. That's it.

local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- ─────────────────────────────────────────────────────────────────────────────
-- Appearance
-- ─────────────────────────────────────────────────────────────────────────────
config.color_scheme = "Tokyo Night"
config.font = wezterm.font("JetBrains Mono", { weight = "Regular" })
config.font_size = 14.0
config.line_height = 1.1

config.window_decorations = "RESIZE"
config.window_padding = { left = 10, right = 10, top = 10, bottom = 10 }
config.window_background_opacity = 0.95
config.macos_window_background_blur = 20

-- Tab bar colors (Tokyo Night aligned)
config.colors = {
  tab_bar = {
    background = "#1a1b26",
    active_tab = { bg_color = "#7aa2f7", fg_color = "#1a1b26" },
    inactive_tab = { bg_color = "#1a1b26", fg_color = "#565f89" },
    inactive_tab_hover = { bg_color = "#24283b", fg_color = "#c0caf5" },
    new_tab = { bg_color = "#1a1b26", fg_color = "#565f89" },
    new_tab_hover = { bg_color = "#24283b", fg_color = "#c0caf5" },
  },
}

-- Tab bar (minimal)
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 24

-- Clean tab titles: "1:dirname" or "1:process"
wezterm.on("format-tab-title", function(tab)
  local pane = tab.active_pane
  local title = pane.current_working_dir
    and pane.current_working_dir.file_path:match("([^/]+)/?$")
    or pane.foreground_process_name:match("([^/]+)$")
    or "term"
  return string.format(" %d:%s ", tab.tab_index + 1, title:sub(1, 18))
end)

-- Status bar: calls external script (Unix-y, reusable)
config.status_update_interval = 5000  -- 5 sec, not 150ms
wezterm.on("update-status", function(window)
  local success, stdout = wezterm.run_child_process({ os.getenv("HOME") .. "/.local/bin/wezterm-status" })
  local status = success and stdout:gsub("%s+$", "") or ""
  window:set_right_status(wezterm.format({
    { Foreground = { Color = "#7aa2f7" } },
    { Text = status .. "  " },
  }))
end)

config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 500

-- ─────────────────────────────────────────────────────────────────────────────
-- Performance
-- ─────────────────────────────────────────────────────────────────────────────
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"
config.max_fps = 120
config.animation_fps = 60
config.mux_output_parser_coalesce_delay_ms = 0

-- ─────────────────────────────────────────────────────────────────────────────
-- Modern protocols & rendering
-- ─────────────────────────────────────────────────────────────────────────────
config.enable_kitty_keyboard = true
config.unicode_version = 16
config.custom_block_glyphs = true

-- Platform-aware font rendering
if wezterm.target_triple:find("windows") then
  config.freetype_load_target = "Normal"
else
  config.freetype_load_target = "Light"
  config.freetype_load_flags = "NO_HINTING"
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Shell
-- ─────────────────────────────────────────────────────────────────────────────
config.default_prog = { "/bin/zsh", "-l" }

-- ─────────────────────────────────────────────────────────────────────────────
-- Keys (minimal, tmux-like)
-- ─────────────────────────────────────────────────────────────────────────────
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

config.keys = {
  -- Splits
  { key = "|", mods = "LEADER|SHIFT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "-", mods = "LEADER", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },

  -- Navigate panes (vim-style)
  { key = "h", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Left") },
  { key = "j", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Down") },
  { key = "k", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Up") },
  { key = "l", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Right") },

  -- Close pane
  { key = "x", mods = "LEADER", action = wezterm.action.CloseCurrentPane({ confirm = false }) },

  -- Zoom
  { key = "z", mods = "LEADER", action = wezterm.action.TogglePaneZoomState },

  -- Copy mode
  { key = "v", mods = "LEADER", action = wezterm.action.ActivateCopyMode },

  -- Tabs
  { key = "c", mods = "LEADER", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
  { key = "n", mods = "LEADER", action = wezterm.action.ActivateTabRelative(1) },
  { key = "p", mods = "LEADER", action = wezterm.action.ActivateTabRelative(-1) },

  -- Reload
  { key = "r", mods = "LEADER", action = wezterm.action.ReloadConfiguration },
}

-- Cmd-click opens links (macOS)
config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "CMD",
    action = wezterm.action.OpenLinkAtMouseCursor,
  },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Misc
-- ─────────────────────────────────────────────────────────────────────────────
config.scrollback_lines = 10000
config.enable_scroll_bar = false
config.audible_bell = "Disabled"
config.check_for_updates = false
config.detect_password_input = true
config.normalize_output_to_unicode_nfc = true

-- Quick select patterns (Ctrl+Shift+Space)
config.quick_select_patterns = {
  "[0-9a-f]{7,40}",  -- git hashes
  "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}",  -- UUIDs
}

return config
