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
config.initial_cols = 120
config.initial_rows = 20

-- Position window in bottom-right quarter on launch (disabled on Windows - causes off-screen issues)
-- wezterm.on("gui-startup", function(cmd)
--   local screen = wezterm.gui.screens().active
--   local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
--   local gui = window:gui_window()
--
--   -- Get actual window dimensions after spawn
--   local dims = gui:get_dimensions()
--   local win_width = dims.pixel_width
--   local win_height = dims.pixel_height
--
--   -- Position: right-aligned, bottom of screen (with small margin)
--   local margin = 10
--   local x = screen.x + screen.width - win_width - margin
--   local y = screen.y + screen.height - win_height - margin
--   gui:set_position(x, y)
-- end)
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

config.front_end = "Software"  -- Fallback if GPU rendering fails
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
    wezterm.run_child_process({ "osascript", "-e", [[
      tell application "System Events"
        if exists process "Music" then
          tell application "Music" to if player state is playing or player state is paused then playpause
        end if
        if exists process "Podcasts" then
          tell application "Podcasts" to if player state is playing or player state is paused then playpause
        end if
        if exists process "TV" then
          tell application "TV" to if player state is playing or player state is paused then playpause
        end if
      end tell
    ]] })
  end) },
  { key = ".", mods = "CTRL|SHIFT", action = wezterm.action_callback(function()
    wezterm.run_child_process({ "osascript", "-e", [[
      tell application "System Events"
        if exists process "Music" then
          tell application "Music" to if player state is playing or player state is paused then next track
        end if
        if exists process "Podcasts" then
          tell application "Podcasts" to if player state is playing or player state is paused then next track
        end if
        if exists process "TV" then
          tell application "TV" to if player state is playing or player state is paused then next track
        end if
      end tell
    ]] })
  end) },
  { key = ",", mods = "CTRL|SHIFT", action = wezterm.action_callback(function()
    wezterm.run_child_process({ "osascript", "-e", [[
      tell application "System Events"
        if exists process "Music" then
          tell application "Music" to if player state is playing or player state is paused then previous track
        end if
        if exists process "Podcasts" then
          tell application "Podcasts" to if player state is playing or player state is paused then previous track
        end if
        if exists process "TV" then
          tell application "TV" to if player state is playing or player state is paused then previous track
        end if
      end tell
    ]] })
  end) },
  { key = "=", mods = "CTRL|SHIFT", action = wezterm.action_callback(function()
    wezterm.run_child_process({ "osascript", "-e", [[
      tell application "System Events"
        if exists process "Music" then
          tell application "Music" to if player state is playing or player state is paused then set sound volume to (sound volume + 10)
        end if
        if exists process "Podcasts" then
          tell application "Podcasts" to if player state is playing or player state is paused then set sound volume to (sound volume + 10)
        end if
        if exists process "TV" then
          tell application "TV" to if player state is playing or player state is paused then set sound volume to (sound volume + 10)
        end if
      end tell
    ]] })
  end) },
  { key = "-", mods = "CTRL|SHIFT", action = wezterm.action_callback(function()
    wezterm.run_child_process({ "osascript", "-e", [[
      tell application "System Events"
        if exists process "Music" then
          tell application "Music" to if player state is playing or player state is paused then set sound volume to (sound volume - 10)
        end if
        if exists process "Podcasts" then
          tell application "Podcasts" to if player state is playing or player state is paused then set sound volume to (sound volume - 10)
        end if
        if exists process "TV" then
          tell application "TV" to if player state is playing or player state is paused then set sound volume to (sound volume - 10)
        end if
      end tell
    ]] })
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

-- Marquee configuration
local media_config = {
  scroll_width = 40,       -- visible characters for track display
  update_interval = 1000,  -- 1Hz - sufficient for 1 char/sec scroll
  poll_every_n = 2,        -- poll media every N updates (~2 sec)
}

config.status_update_interval = media_config.update_interval

local media_state = {
  position = 0,
  cached_track = "",
  cached_playing = false,
  update_count = 0,
}

wezterm.on("update-status", function(window, pane)
  window:set_left_status("")

  -- Succinct datetime based on window width
  local dims = window:get_dimensions()
  local cols = dims.cols or 120
  local time_fmt
  if cols < 80 then
    time_fmt = "%-I:%M%p"
  elseif cols < 100 then
    time_fmt = "%-m/%-d %-I:%M%p"
  else
    time_fmt = "%a %-m/%-d %-I:%M%p"
  end
  local datetime = wezterm.strftime(time_fmt):gsub("AM", "a"):gsub("PM", "p")

  -- Poll media only every N updates
  media_state.update_count = media_state.update_count + 1
  local should_poll = media_state.update_count >= media_config.poll_every_n
  if should_poll then
    media_state.update_count = 0

    local ok, output, stderr = wezterm.run_child_process({
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
      return (name of current track) & " — " & (artist of current track) & "|" & (ps is playing)
    end if
  end tell
end if
if tvRunning then
  tell application "TV"
    set ps to player state
    if ps is playing or ps is paused then
      return (name of current track) & " — " & (album of current track) & "|" & (ps is playing)
    end if
  end tell
end if
return ""
      ]],
    })

    local result = output and output:gsub("^%s*(.-)%s*$", "%1") or ""
    if result ~= "" then
      local track, playing = result:match("^(.+)|(%a+)")
      if track then
        if track ~= media_state.cached_track then
          media_state.cached_track = track
          media_state.position = 0
        end
        media_state.cached_playing = (playing == "true")
      end
    else
      media_state.cached_track = ""
      media_state.cached_playing = false
    end
  end

  -- No media? Just show time
  if media_state.cached_track == "" then
    window:set_right_status(wezterm.format({
      { Foreground = { Color = "#565f89" } },
      { Text = datetime .. "  " },
    }))
    return
  end

  local track = media_state.cached_track
  local is_playing = media_state.cached_playing

  -- Dynamic scroll width based on window size
  local scroll_width = media_config.scroll_width
  if cols < 80 then
    scroll_width = 20
  elseif cols < 100 then
    scroll_width = 30
  end

  -- Scrolling marquee (always scroll if track is long)
  local display = track
  if #track > scroll_width then
    local padding = "     "
    local scroll = track .. padding .. track
    display = scroll:sub(media_state.position + 1, media_state.position + scroll_width)
    media_state.position = (media_state.position + 1) % (#track + #padding)
  end

  window:set_right_status(wezterm.format({
    { Foreground = { Color = "#c0caf5" } },
    { Text = display },
    { Foreground = { Color = "#565f89" } },
    { Text = " | " .. datetime .. "  " },
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
