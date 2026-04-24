-- apple-music.lua
-- Apple Music status bar plugin for Wezterm
-- https://github.com/KevinTCoughlin/wezterm-apple-music
--
-- Features:
--   - Smooth scrolling track title (marquee)
--   - Animated equalizer visualization
--   - Clickable playback controls (Cmd+Click)
--   - Volume indicator with Nerd Font icons
--
-- Usage:
--   local apple_music = require("plugins.apple-music")
--   apple_music.apply_to_config(config, { eq_style = "thin" })
--   apple_music.setup_keys(config)

local wezterm = require("wezterm")
local lib = require("plugins.lib")
local M = {}

-- Default configuration
local defaults = {
  update_interval = 500,
  scroll_width = 30,
  scroll_padding = "  ·  ",

  -- Colors (Tokyo Night palette)
  color_track = "#c0caf5",      -- track name
  color_eq = "#7aa2f7",         -- equalizer
  color_controls = "#565f89",    -- control icons default
  color_prev_next = "#7dcfff",   -- prev/next icons
  color_play = "#9ece6a",        -- play icon
  color_pause = "#f7768e",       -- pause icon
  color_volume = "#bb9af7",      -- volume icon
  color_date = "#565f89",        -- date/time

  eq_style = "thin",
  show_volume = true,
  show_controls = true,
  show_date = true,
  date_format = "%a %b %-d %H:%M",
  controls_path = os.getenv("HOME") .. "/.local/share/music-controls",
}

-- Equalizer styles
local EQ_STYLES = {
  thin = { "▏▎▍", "▎▍▌", "▍▌▋", "▌▋▊", "▋▊▉", "▊▉▊", "▉▊▋", "▊▋▌", "▋▌▍", "▌▍▎", "▍▎▏", "▎▏▎" },
  classic = { "▁▃▅", "▂▅▃", "▃▂▅", "▅▃▂", "▃▅▃", "▂▃▅" },
  dots = { "●○●", "○●○", "●●○", "○●●", "●○○", "○○●" },
  mini = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
}

-- Icons
local ICONS = {
  prev = "󰒮",
  play = "󰐊",
  pause = "󰏤",
  next = "󰒭",
  vol_mute = "󰖁",
  vol_low = "󰕿",
  vol_med = "󰖀",
  vol_high = "󰕾",
}

-- State
local state_template = { position = 0, last_track = "", eq_frame = 1, is_playing = false }
local state = lib.create_state_factory(state_template)()

local function get_volume_icon(vol)
  if vol == 0 then return ICONS.vol_mute
  elseif vol <= 33 then return ICONS.vol_low
  elseif vol <= 66 then return ICONS.vol_med
  else return ICONS.vol_high end
end

local function music_command(cmd)
  return wezterm.action_callback(function()
    local escaped_cmd = lib.escape_applescript(cmd)
    wezterm.run_child_process({ "osascript", "-e", 'tell application "Music" to ' .. escaped_cmd })
  end)
end

local function get_music_info()
  local ok, out = wezterm.run_child_process({
    "osascript", "-e", [[
      tell application "System Events"
        if not (exists process "Music") then return "OFF"
      end tell
      tell application "Music"
        set vol to sound volume
        if player state is playing then
          return "PLAYING|" & vol & "|" & name of current track & " — " & artist of current track
        else if player state is paused then
          return "PAUSED|" & vol & "|" & name of current track & " — " & artist of current track
        else
          return "STOPPED|" & vol & "|"
        end if
      end tell
    ]]
  })
  return ok and lib.trim(out) or "OFF"
end

local function build_status(opts)
  local info = get_music_info()
  if info == "OFF" then
    lib.reset_state(state, state_template)
    return nil
  end

  local pstate, vol, track = info:match("^(%w+)|(%d+)|(.*)$")
  if not pstate or track == "" then return nil end

  vol = tonumber(vol) or 0
  state.is_playing = (pstate == "PLAYING")

  if track ~= state.last_track then
    state.last_track = track
    state.position = 0
  end

  local eq_frames = EQ_STYLES[opts.eq_style] or EQ_STYLES.thin
  local eq = state.is_playing and eq_frames[state.eq_frame] or "⏸"
  if state.is_playing then
    state.eq_frame = (state.eq_frame % #eq_frames) + 1
  end

  local visible
  if #track <= opts.scroll_width then
    visible = track
  else
    local scroll = track .. opts.scroll_padding .. track
    visible = scroll:sub(state.position + 1, state.position + opts.scroll_width)
    state.position = (state.position + 1) % (#track + #opts.scroll_padding)
  end

  return { eq = eq, track = visible, volume = vol, playing = state.is_playing }
end

function M.apply_to_config(config, user_opts)
  local opts = lib.merge_opts_meta(defaults, user_opts)
  config.status_update_interval = opts.update_interval

  local ctrl_path = opts.controls_path
  local prev_url = "file://" .. ctrl_path .. "/PrevTrack.app"
  local play_url = "file://" .. ctrl_path .. "/PlayPause.app"
  local next_url = "file://" .. ctrl_path .. "/NextTrack.app"

  wezterm.on("update-status", function(window, pane)
    local m = build_status(opts)
    local e = {}

    if m then
      -- Equalizer
      lib.add_element(e, opts.color_eq, m.eq .. "  ")

      -- Controls
      if opts.show_controls then
        -- Prev
        lib.add_hyperlink(e, opts.color_prev_next, ICONS.prev, prev_url)
        lib.add_element(e, nil, " ")

        -- Play/Pause
        local play_pause_color = m.playing and opts.color_pause or opts.color_play
        lib.add_hyperlink(e, play_pause_color, m.playing and ICONS.pause or ICONS.play, play_url)
        lib.add_element(e, nil, " ")

        -- Next
        lib.add_hyperlink(e, opts.color_prev_next, ICONS.next, next_url)
        lib.add_element(e, nil, "  ")
      end

      -- Track
      lib.add_element(e, opts.color_track, m.track)

      -- Volume
      if opts.show_volume then
        lib.add_element(e, opts.color_volume, "  " .. get_volume_icon(m.volume))
      end

      lib.add_separator(e, opts.color_date)
    end

    -- Date
    if opts.show_date then
      lib.add_element(e, opts.color_date, wezterm.strftime(opts.date_format) .. "  ")
    end

    window:set_right_status(wezterm.format(e))
  end)
end

function M.setup_keys(config, mods)
  mods = mods or "LEADER"
  local keys = config.keys or {}
  local bindings = {
    { key = "m", cmd = "playpause" },
    { key = ">", shift = true, cmd = "next track" },
    { key = "<", shift = true, cmd = "previous track" },
    { key = "+", shift = true, cmd = "set sound volume to (sound volume + 10)" },
    { key = "_", shift = true, cmd = "set sound volume to (sound volume - 10)" },
  }
  for _, b in ipairs(bindings) do
    table.insert(keys, {
      key = b.key,
      mods = b.shift and (mods .. "|SHIFT") or mods,
      action = music_command(b.cmd),
    })
  end
  config.keys = keys
end

function M.create_control_apps()
  local path = defaults.controls_path
  
  -- Use safe mkdir instead of os.execute
  if not lib.mkdir_p(path) then
    wezterm.log_error("Failed to create control apps directory: " .. path)
    return
  end
  
  for _, app in ipairs({
    { "PlayPause", "playpause" },
    { "NextTrack", "next track" },
    { "PrevTrack", "previous track" },
  }) do
    -- Use os.tmpname() for secure temp file instead of /tmp/ path
    local tmp_file = lib.get_temp_file("wezterm-music", ".applescript")
    
    -- Write AppleScript to temp file
    if not lib.safe_write_file(tmp_file, 'tell application "Music" to ' .. app[2]) then
      wezterm.log_error("Failed to write AppleScript to " .. tmp_file)
      goto continue_app
    end
    
    -- Compile to app bundle using safe_run
    local success, output, stderr = lib.safe_run({
      "osacompile", "-o", path .. "/" .. app[1] .. ".app", tmp_file
    })
    
    if not success then
      wezterm.log_error("Failed to compile " .. app[1] .. ".app: " .. (stderr or "unknown error"))
    end
    
    -- Clean up temp file
    os.remove(tmp_file)
    
    ::continue_app::
  end
end

return M
