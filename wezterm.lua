-- Wezterm Configuration
local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Plugins
local smart_splits = wezterm.plugin.require("https://github.com/mrjones2014/smart-splits.nvim")
local ollama = dofile(wezterm.config_dir .. "/plugins/wezterm-ollama/plugin/init.lua")
local battery = dofile(wezterm.config_dir .. "/plugins/wezterm-battery/plugin/init.lua")

-- Media keybindings (Option+Shift+key)
-- Customize keys/modifiers to your preference
local media_keys = {
  mods = "OPT|SHIFT",      -- modifier combo
  play_pause = "Space",    -- Opt+Shift+Space
  next_track = "n",        -- Opt+Shift+n
  prev_track = "p",        -- Opt+Shift+p
  vol_up = "=",            -- Opt+Shift+=
  vol_down = "-",          -- Opt+Shift+-
}

-- ============================================
-- Appearance
-- ============================================

config.color_scheme = "Tokyo Night"
config.font = wezterm.font("JetBrains Mono", { weight = "Regular" })
config.font_size = 14.0
config.line_height = 1.1

-- Window
config.window_decorations = "RESIZE"
config.initial_cols = 120
config.initial_rows = 20

-- Position window in bottom-right quarter on launch
wezterm.on("gui-startup", function(cmd)
  local screen = wezterm.gui.screens().active
  local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
  local gui = window:gui_window()

  -- Get actual window dimensions after spawn
  local dims = gui:get_dimensions()
  local win_width = dims.pixel_width
  local win_height = dims.pixel_height

  -- Position: right-aligned, bottom of screen (with small margin)
  local margin = 10
  local x = screen.x + screen.width - win_width - margin
  local y = screen.y + screen.height - win_height - margin
  gui:set_position(x, y)
end)
config.window_padding = {
  left = 10,
  right = 10,
  top = 10,
  bottom = 10,
}
config.window_background_opacity = 0.95
config.macos_window_background_blur = 20

-- Tab bar
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = false

-- Cursor
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 500

-- ============================================
-- Performance
-- ============================================

config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"
config.animation_fps = 60
config.max_fps = 120

-- ============================================
-- Shell
-- ============================================

-- Use platform-appropriate shell
if wezterm.target_triple:find("windows") then
  config.default_prog = { "pwsh.exe" }
else
  config.default_prog = { "/bin/zsh", "-l" }
end

-- ============================================
-- Key Bindings
-- ============================================

config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

config.keys = {
  -- Pane splitting (like tmux with C-a)
  { key = "|", mods = "LEADER|SHIFT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "-", mods = "LEADER", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },

  -- Pane navigation (vim-style)
  { key = "h", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Left") },
  { key = "j", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Down") },
  { key = "k", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Up") },
  { key = "l", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Right") },

  -- Pane resize
  { key = "H", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Left", 5 }) },
  { key = "J", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Down", 5 }) },
  { key = "K", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Up", 5 }) },
  { key = "L", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Right", 5 }) },

  -- Close pane
  { key = "x", mods = "LEADER", action = wezterm.action.CloseCurrentPane({ confirm = false }) },

  -- Tabs
  { key = "c", mods = "LEADER", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
  { key = "n", mods = "LEADER", action = wezterm.action.ActivateTabRelative(1) },
  { key = "p", mods = "LEADER", action = wezterm.action.ActivateTabRelative(-1) },

  -- Tab navigation by number
  { key = "1", mods = "LEADER", action = wezterm.action.ActivateTab(0) },
  { key = "2", mods = "LEADER", action = wezterm.action.ActivateTab(1) },
  { key = "3", mods = "LEADER", action = wezterm.action.ActivateTab(2) },
  { key = "4", mods = "LEADER", action = wezterm.action.ActivateTab(3) },
  { key = "5", mods = "LEADER", action = wezterm.action.ActivateTab(4) },

  -- Zoom pane (toggle fullscreen for current pane)
  { key = "z", mods = "LEADER", action = wezterm.action.TogglePaneZoomState },

  -- Copy mode (like tmux)
  { key = "v", mods = "LEADER", action = wezterm.action.ActivateCopyMode },

  -- Quick reload config
  { key = "r", mods = "LEADER", action = wezterm.action.ReloadConfiguration },

  -- Command palette
  { key = ":", mods = "LEADER|SHIFT", action = wezterm.action.ActivateCommandPalette },

  -- Media controls (Apple Music) - customize in media_keys table at top of file
  { key = media_keys.play_pause, mods = media_keys.mods, action = wezterm.action_callback(function()
    wezterm.run_child_process({ "osascript", "-e", 'tell application "Music" to playpause' })
  end) },
  { key = media_keys.next_track, mods = media_keys.mods, action = wezterm.action_callback(function()
    wezterm.run_child_process({ "osascript", "-e", 'tell application "Music" to next track' })
  end) },
  { key = media_keys.prev_track, mods = media_keys.mods, action = wezterm.action_callback(function()
    wezterm.run_child_process({ "osascript", "-e", 'tell application "Music" to previous track' })
  end) },
  { key = media_keys.vol_up, mods = media_keys.mods, action = wezterm.action_callback(function()
    wezterm.run_child_process({ "osascript", "-e", 'tell application "Music" to set sound volume to (sound volume + 10)' })
  end) },
  { key = media_keys.vol_down, mods = media_keys.mods, action = wezterm.action_callback(function()
    wezterm.run_child_process({ "osascript", "-e", 'tell application "Music" to set sound volume to (sound volume - 10)' })
  end) },

  -- macOS natural text editing
  { key = "LeftArrow", mods = "OPT", action = wezterm.action.SendKey({ key = "b", mods = "ALT" }) },
  { key = "RightArrow", mods = "OPT", action = wezterm.action.SendKey({ key = "f", mods = "ALT" }) },
  { key = "LeftArrow", mods = "CMD", action = wezterm.action.SendKey({ key = "Home" }) },
  { key = "RightArrow", mods = "CMD", action = wezterm.action.SendKey({ key = "End" }) },
  { key = "Backspace", mods = "CMD", action = wezterm.action.SendKey({ key = "u", mods = "CTRL" }) },

}

-- ============================================
-- Mouse
-- ============================================

config.mouse_bindings = {
  -- Cmd-click to open hyperlinks
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "CMD",
    action = wezterm.action.OpenLinkAtMouseCursor,
  },
}

-- ============================================
-- Apple Music Status Bar
-- ============================================

-- User configuration
local media_config = {
  scroll_speed = 3,        -- characters to scroll per tick (1 = slow, 5 = fast)
  scroll_width = 35,       -- visible characters for track display
  update_interval = 150,   -- ms between updates (lower = smoother)
  eq_style = "wave",       -- "wave", "thin", "classic", "dots", "mini"
}

-- Battery configuration
local battery_config = {
  show_percentage = true,     -- show numeric percentage
  show_time = false,          -- show time remaining
  use_granular_icons = true,  -- icons change based on level
  low_threshold = 20,         -- orange warning below this
  critical_threshold = 10,    -- red warning below this
  colors = {
    charging = "#9ece6a",     -- green
    discharging = "#7aa2f7",  -- blue
    full = "#9ece6a",         -- green
    low = "#e0af68",          -- orange
    critical = "#f7768e",     -- red
    percentage = "#c0caf5",   -- text
  },
}

config.status_update_interval = media_config.update_interval

local media_state = { position = 0, last_track = "", eq_frame = 1 }
local eq_styles = {
  wave = { "∿∿∿", "∾∿∿", "∿∾∿", "∿∿∾" },
  thin = { "▏▎▍", "▎▍▌", "▍▌▋", "▌▋▊", "▋▊▉", "▊▉▊", "▉▊▋", "▊▋▌", "▋▌▍", "▌▍▎", "▍▎▏", "▎▏▎" },
  classic = { "▁▃▅", "▂▅▃", "▃▂▅", "▅▃▂", "▃▅▃", "▂▃▅" },
  dots = { "●○●", "○●○", "●●○", "○●●", "●○○", "○○●" },
  mini = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
}
local eq_frames = eq_styles[media_config.eq_style] or eq_styles.wave

local media_icons = {
  music = { icon = "󰎆", color = "#7aa2f7" },
  podcast = { icon = "󰦔", color = "#e0af68" },
  tv = { icon = "󰕼", color = "#f7768e" },
}

-- Helper to build status elements with Ollama + Battery + datetime
local function build_status_suffix()
  local elements = {}

  -- Separator
  table.insert(elements, { Foreground = { Color = "#565f89" } })
  table.insert(elements, { Text = "  │  " })

  -- Ollama status
  for _, e in ipairs(ollama.get_status_elements()) do
    table.insert(elements, e)
  end

  -- Battery status (with separator)
  for _, e in ipairs(battery.get_status_with_separator()) do
    table.insert(elements, e)
  end

  -- Datetime
  for _, e in ipairs(ollama.get_datetime_elements()) do
    table.insert(elements, e)
  end

  return elements
end

wezterm.on("update-status", function(window, pane)
  local is_macos = wezterm.target_triple:find("darwin") ~= nil
  local result = ""

  -- Apple Music/TV status only works on macOS
  if is_macos then
    local _, output = wezterm.run_child_process({
      "osascript",
      "-e", [[
tell application "System Events"
  set musicRunning to exists process "Music"
  set tvRunning to exists process "TV"
end tell
if musicRunning then
  tell application "Music"
    set ps to player state
    if ps is playing or ps is paused then
      return "music|" & (name of current track) & " — " & (artist of current track) & "|" & (ps is playing)
    end if
  end tell
end if
if tvRunning then
  tell application "TV"
    set ps to player state
    if ps is playing or ps is paused then
      return "tv|" & (name of current track) & " — " & (album of current track) & "|" & (ps is playing)
    end if
  end tell
end if
return ""
      ]],
    })
    result = output and output:gsub("^%s*(.-)%s*$", "%1") or ""
  end

  -- No media playing (or not on macOS) - show Ollama + Battery + datetime only
  if result == "" then
    local elements = {}
    for _, e in ipairs(ollama.get_status_elements()) do
      table.insert(elements, e)
    end
    for _, e in ipairs(battery.get_status_with_separator()) do
      table.insert(elements, e)
    end
    for _, e in ipairs(ollama.get_datetime_elements()) do
      table.insert(elements, e)
    end
    window:set_right_status(wezterm.format(elements))
    return
  end

  local app, track, playing = result:match("^([^|]+)|(.+)|(%a+)$")
  if not app or not track then
    local elements = {}
    for _, e in ipairs(ollama.get_status_elements()) do
      table.insert(elements, e)
    end
    for _, e in ipairs(battery.get_status_with_separator()) do
      table.insert(elements, e)
    end
    for _, e in ipairs(ollama.get_datetime_elements()) do
      table.insert(elements, e)
    end
    window:set_right_status(wezterm.format(elements))
    return
  end
  local is_playing = playing == "true"
  local media = media_icons[app] or media_icons.music

  -- Reset scroll position on track change
  if track ~= media_state.last_track then
    media_state.last_track = track
    media_state.position = 0
  end

  -- Scrolling marquee
  local display = track
  if #track > media_config.scroll_width then
    local padding = "  ·  "
    local scroll = track .. padding .. track
    display = scroll:sub(media_state.position + 1, media_state.position + media_config.scroll_width)
    media_state.position = (media_state.position + media_config.scroll_speed) % (#track + #padding)
  end

  -- Animate equalizer
  local eq = is_playing and eq_frames[media_state.eq_frame] or "⏸"
  if is_playing then
    media_state.eq_frame = (media_state.eq_frame % #eq_frames) + 1
  end

  -- Build elements: media + Ollama + datetime
  local elements = {
    { Foreground = { Color = media.color } },
    { Text = media.icon .. " " },
    { Foreground = { Color = media.color } },
    { Text = eq .. "  " },
    { Foreground = { Color = "#c0caf5" } },
    { Text = display },
  }

  -- Add Ollama status + datetime suffix
  for _, e in ipairs(build_status_suffix()) do
    table.insert(elements, e)
  end

  window:set_right_status(wezterm.format(elements))
end)

-- ============================================
-- Misc
-- ============================================

config.scrollback_lines = 50000
config.enable_scroll_bar = false
config.adjust_window_size_when_changing_font_size = false
config.audible_bell = "Disabled"
config.check_for_updates = false

-- Disable ligatures if you prefer
-- config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }

-- ============================================
-- Smart Splits Integration
-- ============================================

-- Apply smart-splits for seamless Neovim <-> Wezterm navigation
smart_splits.apply_to_config(config, {
  direction_keys = { "h", "j", "k", "l" },
  modifiers = {
    move = "CTRL",
    resize = "ALT",
  },
})

-- ============================================
-- Ollama Integration
-- ============================================

-- Apply plugin config (disables default LEADER keybindings)
local ollama_opts = ollama.apply_to_config(config, {
  default_model = "deepseek-r1:7b",
  keys = {
    select_model = false,  -- We'll use OPT|SHIFT instead
    quick_chat = false,
  },
})

-- Custom keybindings (Option+Shift+key, same as media controls)
table.insert(config.keys, {
  key = "i",
  mods = "OPT|SHIFT",
  action = ollama.create_model_selector_action(ollama_opts),
})
table.insert(config.keys, {
  key = "o",
  mods = "OPT|SHIFT",
  action = ollama.create_quick_chat_action(ollama_opts),
})

-- ============================================
-- Battery Integration
-- ============================================

battery.apply_to_config(config, battery_config)

return config
