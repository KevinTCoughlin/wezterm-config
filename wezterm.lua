-- Wezterm Configuration
local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Plugins
local smart_splits = wezterm.plugin.require("https://github.com/mrjones2014/smart-splits.nvim")
-- local apple_media = require("plugins.apple-media")  -- using inline implementation

-- ============================================
-- Appearance
-- ============================================

config.color_scheme = "Tokyo Night"
config.font = wezterm.font("JetBrains Mono", { weight = "Regular" })
config.font_size = 14.0
config.line_height = 1.1

-- Window
config.window_decorations = "RESIZE"
config.initial_cols = 140
config.initial_rows = 45

-- Position window at top-left on launch
wezterm.on("gui-startup", function(cmd)
  local screen = wezterm.gui.screens().active
  local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
  window:gui_window():set_position(screen.x, screen.y)
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

config.default_prog = { "/bin/zsh", "-l" }

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

  -- Media controls (Apple Music/Podcasts/TV) - using CTRL|SHIFT to avoid tmux conflict
  { key = "m", mods = "CTRL|SHIFT", action = wezterm.action_callback(function()
    wezterm.run_child_process({ "osascript", "-e", 'tell application "Music" to playpause' })
  end) },
  { key = ".", mods = "CTRL|SHIFT", action = wezterm.action_callback(function()
    wezterm.run_child_process({ "osascript", "-e", 'tell application "Music" to next track' })
  end) },
  { key = ",", mods = "CTRL|SHIFT", action = wezterm.action_callback(function()
    wezterm.run_child_process({ "osascript", "-e", 'tell application "Music" to previous track' })
  end) },
  { key = "=", mods = "CTRL|SHIFT", action = wezterm.action_callback(function()
    wezterm.run_child_process({ "osascript", "-e", 'tell application "Music" to set sound volume to (sound volume + 10)' })
  end) },
  { key = "-", mods = "CTRL|SHIFT", action = wezterm.action_callback(function()
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

wezterm.on("update-status", function(window, pane)
  local ok, output = wezterm.run_child_process({
    "osascript", "-e", [[
      tell application "System Events"
        if exists process "Music" then
          tell application "Music"
            if player state is playing or player state is paused then
              return (name of current track) & " — " & (artist of current track) & "|" & (player state is playing)
            end if
          end tell
        end if
      end tell
      return ""
    ]]
  })

  local result = output and output:gsub("^%s*(.-)%s*$", "%1") or ""
  if result == "" then
    window:set_right_status(wezterm.format({
      { Foreground = { Color = "#565f89" } },
      { Text = wezterm.strftime("%a %b %-d %H:%M") .. "  " },
    }))
    return
  end

  local track, playing = result:match("^(.+)|(.+)$")
  local is_playing = playing == "true"

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

  window:set_right_status(wezterm.format({
    { Foreground = { Color = "#7aa2f7" } },
    { Text = "󰎆 " },
    { Foreground = { Color = "#7aa2f7" } },
    { Text = eq .. "  " },
    { Foreground = { Color = "#c0caf5" } },
    { Text = display },
    { Foreground = { Color = "#565f89" } },
    { Text = "  │  " .. wezterm.strftime("%a %b %-d %H:%M") .. "  " },
  }))
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

return config
