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
local state = { position = 0, last_track = "", eq_frame = 1, is_playing = false }

local function get_volume_icon(vol)
  if vol == 0 then return ICONS.vol_mute
  elseif vol <= 33 then return ICONS.vol_low
  elseif vol <= 66 then return ICONS.vol_med
  else return ICONS.vol_high end
end

local function music_command(cmd)
  return wezterm.action_callback(function()
    wezterm.run_child_process({ "osascript", "-e", 'tell application "Music" to ' .. cmd })
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
  return ok and out:gsub("^%s*(.-)%s*$", "%1") or "OFF"
end

local function build_status(opts)
  local info = get_music_info()
  if info == "OFF" then
    state = { position = 0, last_track = "", eq_frame = 1, is_playing = false }
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
  local opts = setmetatable(user_opts or {}, { __index = defaults })
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
      table.insert(e, { Foreground = { Color = opts.color_eq } })
      table.insert(e, { Text = m.eq .. "  " })

      -- Controls
      if opts.show_controls then
        -- Prev
        table.insert(e, { Foreground = { Color = opts.color_prev_next } })
        table.insert(e, { Attribute = { Hyperlink = prev_url } })
        table.insert(e, { Text = ICONS.prev })
        table.insert(e, "ResetAttributes")

        table.insert(e, { Text = " " })

        -- Play/Pause
        if m.playing then
          table.insert(e, { Foreground = { Color = opts.color_pause } })
        else
          table.insert(e, { Foreground = { Color = opts.color_play } })
        end
        table.insert(e, { Attribute = { Hyperlink = play_url } })
        table.insert(e, { Text = m.playing and ICONS.pause or ICONS.play })
        table.insert(e, "ResetAttributes")

        table.insert(e, { Text = " " })

        -- Next
        table.insert(e, { Foreground = { Color = opts.color_prev_next } })
        table.insert(e, { Attribute = { Hyperlink = next_url } })
        table.insert(e, { Text = ICONS.next })
        table.insert(e, "ResetAttributes")

        table.insert(e, { Text = "  " })
      end

      -- Track
      table.insert(e, { Foreground = { Color = opts.color_track } })
      table.insert(e, { Text = m.track })

      -- Volume
      if opts.show_volume then
        table.insert(e, { Foreground = { Color = opts.color_volume } })
        table.insert(e, { Text = "  " .. get_volume_icon(m.volume) })
      end

      table.insert(e, { Foreground = { Color = opts.color_date } })
      table.insert(e, { Text = "  │  " })
    end

    -- Date
    if opts.show_date then
      table.insert(e, { Foreground = { Color = opts.color_date } })
      table.insert(e, { Text = wezterm.strftime(opts.date_format) .. "  " })
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
  os.execute("mkdir -p " .. path)
  for _, app in ipairs({
    { "PlayPause", "playpause" },
    { "NextTrack", "next track" },
    { "PrevTrack", "previous track" },
  }) do
    local f = io.open("/tmp/" .. app[1] .. ".applescript", "w")
    if f then
      f:write('tell application "Music" to ' .. app[2])
      f:close()
      os.execute("osacompile -o " .. path .. "/" .. app[1] .. ".app /tmp/" .. app[1] .. ".applescript 2>/dev/null")
    end
  end
end

return M
