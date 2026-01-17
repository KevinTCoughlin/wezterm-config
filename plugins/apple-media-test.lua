-- Simple test version
local wezterm = require("wezterm")
local M = {}

function M.apply_to_config(config, opts)
  config.status_update_interval = 1000

  wezterm.on("update-status", function(window, pane)
    local ok, out = wezterm.run_child_process({
      "osascript", "-e", [[
        tell application "System Events"
          if exists process "Music" then
            tell application "Music"
              if player state is playing then
                return "♫ " & name of current track & " - " & artist of current track
              else if player state is paused then
                return "⏸ " & name of current track & " - " & artist of current track
              end if
            end tell
          end if
        end tell
        return ""
      ]]
    })

    local music = ok and out:gsub("^%s*(.-)%s*$", "%1") or ""
    local date = wezterm.strftime("%a %b %-d %H:%M")

    local status = ""
    if music ~= "" then
      status = music .. "  │  "
    end
    status = status .. date

    window:set_right_status(wezterm.format({
      { Foreground = { Color = "#7aa2f7" } },
      { Text = status .. "  " },
    }))
  end)
end

function M.setup_keys(config, mods) end

return M
