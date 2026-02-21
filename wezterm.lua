-- WezTerm config — native multiplexer, no tmux needed
-- Ollama and Battery plugins for status bar

local wezterm = require("wezterm")
local ollama = require("plugins.wezterm-ollama/plugin/init")
local battery = require("plugins.wezterm-battery/plugin/init")
local config = wezterm.config_builder()

-- ─────────────────────────────────────────────────────────────────────────────
-- Appearance
-- ─────────────────────────────────────────────────────────────────────────────
config.color_scheme = "Tokyo Night"
config.font = wezterm.font_with_fallback({
  { family = "JetBrains Mono", weight = "Regular" },
  "Symbols Nerd Font Mono",
})
config.font_size = 14.0
config.line_height = 1.1

config.window_decorations = "RESIZE"
config.window_padding = { left = 10, right = 10, top = 10, bottom = 10 }
config.window_background_opacity = 0.95

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
  local title = pane.current_working_dir and pane.current_working_dir.file_path:match("([^/]+)/?$")
    or pane.foreground_process_name:match("([^/]+)$")
    or "term"
  return string.format(" %d:%s ", tab.tab_index + 1, title:sub(1, 18))
end)

-- Status bar plugins
local ollama_opts = ollama.apply_to_config(config)
local battery_opts = battery.apply_to_config(config)

wezterm.on("update-status", function(window, pane)
  local e = { { Text = "  " } }

  -- Battery
  local batt = battery.get_status_with_separator(battery_opts)
  for _, elem in ipairs(batt) do
    table.insert(e, elem)
  end

  -- Ollama
  local ollama_elems = ollama.get_status_elements(ollama_opts)
  if #ollama_elems > 0 then
    table.insert(e, { Foreground = { Color = "#565f89" } })
    table.insert(e, { Text = "  │  " })
    for _, elem in ipairs(ollama_elems) do
      table.insert(e, elem)
    end
  end

  table.insert(e, { Text = "  " })
  window:set_right_status(wezterm.format(e))
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
config.enable_kitty_keyboard = false
config.unicode_version = 16
config.custom_block_glyphs = true
-- Platform-aware font rendering
config.freetype_load_target = "Light"
config.freetype_load_flags = "NO_HINTING"
-- ─────────────────────────────────────────────────────────────────────────────
-- Shell
-- ─────────────────────────────────────────────────────────────────────────────

-- ─────────────────────────────────────────────────────────────────────────────
-- Shell integration (semantic zones, clickable prompts, CWD tracking)
-- ─────────────────────────────────────────────────────────────────────────────
config.term = "xterm-256color"

-- ─────────────────────────────────────────────────────────────────────────────
-- Keys (native multiplexer, vim-style)
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

  -- Resize panes
  { key = "H", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Left", 5 }) },
  { key = "J", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Down", 5 }) },
  { key = "K", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Up", 5 }) },
  { key = "L", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Right", 5 }) },

  -- Tabs
  { key = "c", mods = "LEADER", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
  { key = "n", mods = "LEADER", action = wezterm.action.ActivateTabRelative(1) },
  { key = "p", mods = "LEADER", action = wezterm.action.ActivateTabRelative(-1) },

  -- Tab by number
  { key = "1", mods = "LEADER", action = wezterm.action.ActivateTab(0) },
  { key = "2", mods = "LEADER", action = wezterm.action.ActivateTab(1) },
  { key = "3", mods = "LEADER", action = wezterm.action.ActivateTab(2) },
  { key = "4", mods = "LEADER", action = wezterm.action.ActivateTab(3) },
  { key = "5", mods = "LEADER", action = wezterm.action.ActivateTab(4) },

  -- Command palette
  { key = ":", mods = "LEADER|SHIFT", action = wezterm.action.ActivateCommandPalette },

  -- Reload
  { key = "r", mods = "LEADER", action = wezterm.action.ReloadConfiguration },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Misc
-- ─────────────────────────────────────────────────────────────────────────────
config.scrollback_lines = 50000
config.enable_scroll_bar = false
config.audible_bell = "Disabled"
config.check_for_updates = false
config.detect_password_input = true
config.normalize_output_to_unicode_nfc = true
config.adjust_window_size_when_changing_font_size = false
config.hide_mouse_cursor_when_typing = true
config.swallow_mouse_click_on_pane_focus = true
config.canonicalize_pasted_newlines = "LineFeed"
config.inactive_pane_hsb = { saturation = 0.9, brightness = 0.8 }
config.skip_close_confirmation_for_processes_named = {
  "bash",
  "sh",
  "zsh",
  "fish",
  "nu",
}

-- Quick select patterns (Ctrl+Shift+Space)
config.quick_select_patterns = {
  "[0-9a-f]{7,40}", -- git hashes
  "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}", -- UUIDs
  "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}", -- IPv4
  "[\\w.-]+\\.[a-z]{2,}(?:/[\\w.-]*)*", -- URLs/domains
  "/[\\w.-/]+", -- file paths
}

return config
