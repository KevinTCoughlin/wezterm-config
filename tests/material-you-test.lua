local parse_result
local warnings = {}

package.preload.wezterm = function()
  return {
    json_parse = function()
      return parse_result
    end,
    log_error = function() end,
    log_info = function() end,
    log_warn = function(message)
      table.insert(warnings, message)
    end,
    target_triple = "x86_64-unknown-linux-gnu",
  }
end

local material_you = require("plugins.material-you.init")
local fixture = "tests/material-you-test.lua"

parse_result = {
  schemes = {
    dark = {
      surface = "#000000",
    },
  },
}
local config = {}
local colors = material_you.apply_to_config(config, { json_path = fixture })
assert(colors.pane_bg == "#1a1b26")
assert(warnings[1]:match("missing token onSurface"))

parse_result = {
  schemes = {
    dark = {
      surface = "#000001",
      onSurface = "#000002",
      primary = "#000003",
      onPrimary = "#000004",
      primaryContainer = "#000005",
      onPrimaryContainer = "#000006",
      outlineVariant = "#000007",
      surfaceDim = "#000008",
      onSurfaceVariant = "#000009",
      surfaceContainerHigh = "#00000a",
      outline = "#00000b",
    },
  },
}
config = {}
colors = material_you.apply_to_config(config, { json_path = fixture })
assert(colors.pane_bg == "#000001")
assert(config.colors.tab_bar.active_tab.bg_color == "#000003")
