-- apple-media.lua
-- Apple Media status bar plugin for Wezterm
-- Supports: Apple Music, Apple Podcasts, Apple TV
-- https://github.com/KevinTCoughlin/wezterm-apple-music
--
-- Usage:
--   local apple_media = require("plugins.apple-media")
--   apple_media.apply_to_config(config)
--   apple_media.setup_keys(config)

local wezterm = require("wezterm")
local lib = require("plugins.lib")
local M = {}

-------------------------------------------------------------------------------
-- Configuration
-------------------------------------------------------------------------------

local defaults = {
  update_interval = 500,
  scroll_width = 30,
  scroll_padding = "  ·  ",

  colors = {
    eq = "#7aa2f7",
    track = "#c0caf5",
    controls = "#7dcfff",
    play = "#9ece6a",
    pause = "#f7768e",
    volume = "#bb9af7",
    music = "#7aa2f7",
    podcast = "#e0af68",
    tv = "#f7768e",
    date = "#565f89",
  },

  eq_style = "thin",
  show_volume = true,
  show_controls = true,
  show_app_icon = true,
  show_date = true,
  date_format = "%a %b %-d %H:%M",
}

-------------------------------------------------------------------------------
-- Equalizer Styles
-------------------------------------------------------------------------------

local EQ_STYLES = {
  thin = { "▏▎▍", "▎▍▌", "▍▌▋", "▌▋▊", "▋▊▉", "▊▉▊", "▉▊▋", "▊▋▌", "▋▌▍", "▌▍▎", "▍▎▏", "▎▏▎" },
  classic = { "▁▃▅", "▂▅▃", "▃▂▅", "▅▃▂", "▃▅▃", "▂▃▅" },
  dots = { "●○●", "○●○", "●●○", "○●●", "●○○", "○○●" },
  mini = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
  wave = { "∿∿∿", "∾∿∿", "∿∾∿", "∿∿∾" },
}

-------------------------------------------------------------------------------
-- Icons (Nerd Font)
-------------------------------------------------------------------------------

local ICONS = {
  music = "󰎆",
  podcast = "󰦔",
  tv = "󰕼",
  prev = "󰒮",
  play = "󰐊",
  pause = "󰏤",
  next = "󰒭",
  vol_mute = "󰖁",
  vol_low = "󰕿",
  vol_med = "󰖀",
  vol_high = "󰕾",
}

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

local state_template = {
  position = 0,
  last_track = "",
  eq_frame = 1,
  is_playing = false,
  app = nil,
}

local state = lib.create_state_factory(state_template)()

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function get_volume_icon(vol)
  if vol == 0 then return ICONS.vol_mute
  elseif vol <= 33 then return ICONS.vol_low
  elseif vol <= 66 then return ICONS.vol_med
  else return ICONS.vol_high end
end


-------------------------------------------------------------------------------
-- Media Detection
-------------------------------------------------------------------------------

local function get_media_info()
  local ok, out = wezterm.run_child_process({
    "osascript", "-e", [[
      -- Check Music
      tell application "System Events"
        if exists process "Music" then
          tell application "Music"
            if player state is playing or player state is paused then
              set vol to sound volume
              set trackName to name of current track
              set artistName to artist of current track
              set isPlaying to (player state is playing)
              return "music|" & isPlaying & "|" & vol & "|" & trackName & "|" & artistName
            end if
          end tell
        end if
      end tell

      -- Check Podcasts
      tell application "System Events"
        if exists process "Podcasts" then
          tell application "Podcasts"
            if player state is playing or player state is paused then
              set vol to sound volume
              set epName to name of current episode
              set showName to name of (show of current episode)
              set isPlaying to (player state is playing)
              return "podcast|" & isPlaying & "|" & vol & "|" & epName & "|" & showName
            end if
          end tell
        end if
      end tell

      -- Check TV
      tell application "System Events"
        if exists process "TV" then
          tell application "TV"
            if player state is playing or player state is paused then
              set vol to sound volume
              set vidName to name of current track
              set showName to ""
              try
                set showName to show of current track
              end try
              if showName is "" then set showName to album of current track
              set isPlaying to (player state is playing)
              return "tv|" & isPlaying & "|" & vol & "|" & vidName & "|" & showName
            end if
          end tell
        end if
      end tell

      return "OFF"
    ]]
  })

  if not ok then return nil end
  local result = lib.trim(out)
  if result == "OFF" or result == "" then return nil end

  local app, playing, vol, title, subtitle = result:match("^([^|]+)|([^|]+)|([^|]+)|([^|]*)|(.*)$")
  if not app then return nil end

  return {
    app = app,
    playing = playing == "true",
    volume = tonumber(vol) or 0,
    title = title or "",
    subtitle = subtitle or "",
  }
end

local function media_command(cmd)
  return wezterm.action_callback(function()
    wezterm.run_child_process({ "osascript", "-e", [[
      tell application "System Events"
        if exists process "Music" then
          tell application "Music"
            if player state is playing or player state is paused then
              ]] .. cmd .. [[
              return
            end if
          end tell
        end if
        if exists process "Podcasts" then
          tell application "Podcasts"
            if player state is playing or player state is paused then
              ]] .. cmd .. [[
              return
            end if
          end tell
        end if
        if exists process "TV" then
          tell application "TV"
            if player state is playing or player state is paused then
              ]] .. cmd .. [[
              return
            end if
          end tell
        end if
      end tell
    ]] })
  end)
end

-------------------------------------------------------------------------------
-- Status Builder
-------------------------------------------------------------------------------

local function build_status(opts)
  local info = get_media_info()
  if not info then
    lib.reset_state(state, state_template)
    return nil
  end

  state.is_playing = info.playing
  state.app = info.app

  local display = info.title
  if info.subtitle and info.subtitle ~= "" then
    display = display .. " — " .. info.subtitle
  end

  if display ~= state.last_track then
    state.last_track = display
    state.position = 0
  end

  local eq_frames = EQ_STYLES[opts.eq_style] or EQ_STYLES.thin
  local eq = state.is_playing and eq_frames[state.eq_frame] or "⏸"
  if state.is_playing then
    state.eq_frame = (state.eq_frame % #eq_frames) + 1
  end

  local visible
  if #display <= opts.scroll_width then
    visible = display
  else
    local scroll = display .. opts.scroll_padding .. display
    visible = scroll:sub(state.position + 1, state.position + opts.scroll_width)
    state.position = (state.position + 1) % (#display + #opts.scroll_padding)
  end

  return {
    app = info.app,
    eq = eq,
    display = visible,
    volume = info.volume,
    playing = info.playing,
  }
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

function M.apply_to_config(config, user_opts)
  local opts = lib.merge_opts(defaults, user_opts)
  config.status_update_interval = opts.update_interval

  wezterm.on("update-status", function(window, pane)
    local m = build_status(opts)
    local e = {}
    local colors = opts.colors

    if m then
      -- App icon
      if opts.show_app_icon then
        local icon = ICONS.music
        local icon_color = colors.music
        if m.app == "podcast" then
          icon = ICONS.podcast
          icon_color = colors.podcast
        elseif m.app == "tv" then
          icon = ICONS.tv
          icon_color = colors.tv
        end
        lib.add_element(e, icon_color, icon .. " ")
      end

      -- Equalizer
      lib.add_element(e, colors.eq, m.eq .. "  ")

      -- Controls
      if opts.show_controls then
        lib.add_element(e, colors.controls, ICONS.prev .. " ")
        lib.add_element(e, m.playing and colors.pause or colors.play, (m.playing and ICONS.pause or ICONS.play) .. " ")
        lib.add_element(e, colors.controls, ICONS.next .. "  ")
      end

      -- Track/Episode/Video
      lib.add_element(e, colors.track, m.display)

      -- Volume
      if opts.show_volume then
        lib.add_element(e, colors.volume, "  " .. get_volume_icon(m.volume))
      end

      lib.add_separator(e, colors.date)
    end

    if opts.show_date then
      lib.add_element(e, colors.date, wezterm.strftime(opts.date_format) .. "  ")
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
      action = media_command(b.cmd),
    })
  end

  config.keys = keys
end

return M
