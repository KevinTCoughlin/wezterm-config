-- wezterm-battery: Battery status for Wezterm status bar
-- https://github.com/KevinTCoughlin/wezterm-battery
--
-- Features:
--   - Battery percentage display
--   - State-based colors (charging, discharging, full, low)
--   - Configurable icons and thresholds
--   - Cross-platform support via wezterm.battery_info()

local wezterm = require("wezterm")

local M = {}

-- ============================================
-- Plugin Metadata
-- ============================================

M._VERSION = "1.0.0"
M._LICENSE = "MIT"
M._URL = "https://github.com/KevinTCoughlin/wezterm-battery"

-- ============================================
-- Configuration Defaults
-- ============================================

local defaults = {
  -- Display options
  show_percentage = false, -- Show numeric percentage
  show_time = false, -- Show remaining time (if available)

  -- Color mode: "level" colors by charge level (green/yellow/red),
  --             "state" colors by charge state (charging/discharging/etc),
  --             "monochrome" uses a single color for everything
  color_mode = "level", -- "level", "state", or "monochrome"
  monochrome_color = "#565f89", -- Color used in monochrome mode

  -- Append charging indicator (⚡) to icon when charging
  show_charging_indicator = true,

  -- Battery thresholds
  low_threshold = 20, -- Percentage to trigger "low" state
  critical_threshold = 10, -- Percentage to trigger "critical" state

  -- Icons by state
  icons = {
    charging = "󰂄", -- nf-md-battery_charging
    discharging = "󰁹", -- nf-md-battery
    full = "󰁹", -- nf-md-battery
    low = "󰂃", -- nf-md-battery_alert
    critical = "󰂃", -- nf-md-battery_alert
    unknown = "󰂑", -- nf-md-battery_unknown
  },

  -- Granular discharge icons (by level)
  discharge_icons = {
    "󰂎", -- 0-10%   nf-md-battery_outline
    "󰁺", -- 10-20%  nf-md-battery_10
    "󰁻", -- 20-30%  nf-md-battery_20
    "󰁼", -- 30-40%  nf-md-battery_30
    "󰁽", -- 40-50%  nf-md-battery_40
    "󰁾", -- 50-60%  nf-md-battery_50
    "󰁿", -- 60-70%  nf-md-battery_60
    "󰂀", -- 70-80%  nf-md-battery_70
    "󰂁", -- 80-90%  nf-md-battery_80
    "󰂂", -- 90-100% nf-md-battery_90
    "󰁹", -- 100%    nf-md-battery
  },

  -- Granular charge icons (by level)
  charge_icons = {
    "󰢟", -- 0-10%   nf-md-battery_charging_outline
    "󰢜", -- 10-20%  nf-md-battery_charging_10
    "󰂆", -- 20-30%  nf-md-battery_charging_20
    "󰂇", -- 30-40%  nf-md-battery_charging_30
    "󰂈", -- 40-50%  nf-md-battery_charging_40
    "󰢝", -- 50-60%  nf-md-battery_charging_50
    "󰂉", -- 60-70%  nf-md-battery_charging_60
    "󰢞", -- 70-80%  nf-md-battery_charging_70
    "󰂊", -- 80-90%  nf-md-battery_charging_80
    "󰂋", -- 90-100% nf-md-battery_charging_90
    "󰂅", -- 100%    nf-md-battery_charging_100
  },

  -- Use granular icons instead of single state icon
  use_granular_icons = true,

  -- Colors by state (Tokyo Night defaults)
  colors = {
    charging = "#9ece6a", -- Green
    discharging = "#7aa2f7", -- Blue
    full = "#9ece6a", -- Green
    low = "#e0af68", -- Orange/Yellow
    critical = "#f7768e", -- Red
    unknown = "#565f89", -- Gray
    percentage = "#c0caf5", -- Light text
    time = "#565f89", -- Gray
    separator = "#565f89", -- Gray

    -- Level-based colors (used when color_mode = "level")
    level_high = "#9ece6a", -- Green (above low_threshold)
    level_mid = "#e0af68", -- Yellow (low_threshold..critical_threshold)
    level_low = "#f7768e", -- Red (below critical_threshold)
  },

  -- Update interval (handled by wezterm status_update_interval)
  cache_ttl = 5, -- Seconds to cache battery info
}

-- ============================================
-- State Management
-- ============================================

local state = {
  percentage = nil,
  status = "unknown", -- charging, discharging, full, unknown
  time_remaining = nil,
  last_check = 0,
  is_present = false,
}

-- Deep merge user options with defaults
local function merge_opts(user_opts)
  user_opts = user_opts or {}
  local opts = {}

  for k, v in pairs(defaults) do
    if type(v) == "table" then
      opts[k] = {}
      for tk, tv in pairs(v) do
        opts[k][tk] = tv
      end
      if user_opts[k] and type(user_opts[k]) == "table" then
        for tk, tv in pairs(user_opts[k]) do
          opts[k][tk] = tv
        end
      end
    else
      opts[k] = user_opts[k] ~= nil and user_opts[k] or v
    end
  end

  return opts
end

-- Resolved options (set after apply_to_config)
local resolved_opts = nil

-- ============================================
-- Battery Info Fetching (Cross-platform)
-- ============================================

local function fetch_battery_info(opts)
  local now = os.time()
  if now - state.last_check < opts.cache_ttl then
    return state
  end

  -- Use WezTerm's built-in cross-platform battery API
  local batteries = wezterm.battery_info()

  if batteries and #batteries > 0 then
    local battery = batteries[1] -- Use first battery

    state.is_present = true
    state.percentage = math.floor(battery.state_of_charge * 100 + 0.5)

    -- Map WezTerm states to our states
    local state_map = {
      ["Charging"] = "charging",
      ["Discharging"] = "discharging",
      ["Empty"] = "discharging",
      ["Full"] = "full",
      ["Unknown"] = "unknown",
    }
    state.status = state_map[battery.state] or "unknown"

    -- Calculate time remaining
    local seconds = nil
    if battery.state == "Charging" and battery.time_to_full then
      seconds = battery.time_to_full
    elseif battery.state == "Discharging" and battery.time_to_empty then
      seconds = battery.time_to_empty
    end

    if seconds and seconds > 0 then
      local hours = math.floor(seconds / 3600)
      local mins = math.floor((seconds % 3600) / 60)
      state.time_remaining = string.format("%dh %dm", hours, mins)
    else
      state.time_remaining = nil
    end
  else
    state.percentage = nil
    state.status = "unknown"
    state.time_remaining = nil
    state.is_present = false
  end

  state.last_check = now
  return state
end

-- ============================================
-- Icon Selection
-- ============================================

local function get_icon(opts, percentage, status)
  if not percentage then
    return opts.icons.unknown
  end

  -- Use granular icons if enabled
  if opts.use_granular_icons then
    local icon_set = status == "charging" and opts.charge_icons or opts.discharge_icons
    local index = math.floor(percentage / 10) + 1
    index = math.max(1, math.min(index, #icon_set))
    local icon = icon_set[index]
    if opts.show_charging_indicator and status == "charging" then
      icon = icon .. "⚡"
    end
    return icon
  end

  -- Fall back to state-based icons
  local icon
  if status == "charging" then
    icon = opts.icons.charging
  elseif status == "full" then
    icon = opts.icons.full
  elseif percentage <= opts.critical_threshold then
    icon = opts.icons.critical
  elseif percentage <= opts.low_threshold then
    icon = opts.icons.low
  elseif status == "discharging" then
    icon = opts.icons.discharging
  else
    icon = opts.icons.unknown
  end

  if opts.show_charging_indicator and status == "charging" then
    icon = icon .. "⚡"
  end
  return icon
end

-- ============================================
-- Color Selection
-- ============================================

local function get_color(opts, percentage, status)
  if not percentage then
    return opts.colors.unknown
  end

  -- Monochrome: single color for everything
  if opts.color_mode == "monochrome" then
    return opts.monochrome_color
  end

  -- Level-based: green/yellow/red by charge percentage
  if opts.color_mode == "level" then
    if percentage <= opts.critical_threshold then
      return opts.colors.level_low
    elseif percentage <= opts.low_threshold then
      return opts.colors.level_mid
    else
      return opts.colors.level_high
    end
  end

  -- State-based (default fallback)
  if status == "charging" then
    return opts.colors.charging
  elseif status == "full" then
    return opts.colors.full
  elseif percentage <= opts.critical_threshold then
    return opts.colors.critical
  elseif percentage <= opts.low_threshold then
    return opts.colors.low
  elseif status == "discharging" then
    return opts.colors.discharging
  end

  return opts.colors.unknown
end

-- ============================================
-- Status Bar Elements
-- ============================================

function M.get_status_elements(opts)
  opts = opts or resolved_opts or defaults
  local info = fetch_battery_info(opts)
  local elements = {}

  -- No battery present
  if not info.is_present then
    return elements
  end

  local icon = get_icon(opts, info.percentage, info.status)
  local color = get_color(opts, info.percentage, info.status)

  -- Icon
  table.insert(elements, { Foreground = { Color = color } })
  table.insert(elements, { Text = icon })

  -- Percentage
  if opts.show_percentage and info.percentage then
    table.insert(elements, { Text = " " })
    local pct_color = opts.color_mode == "state" and opts.colors.percentage or color
    table.insert(elements, { Foreground = { Color = pct_color } })
    table.insert(elements, { Text = tostring(info.percentage) .. "%" })
  end

  -- Time remaining
  if opts.show_time and info.time_remaining then
    table.insert(elements, { Text = " " })
    table.insert(elements, { Foreground = { Color = opts.colors.time } })
    table.insert(elements, { Text = "(" .. info.time_remaining .. ")" })
  end

  return elements
end

-- Convenience function to get elements with separator prefix
function M.get_status_with_separator(opts)
  opts = opts or resolved_opts or defaults
  local battery_elements = M.get_status_elements(opts)

  if #battery_elements == 0 then
    return {}
  end

  local elements = {
    { Foreground = { Color = opts.colors.separator } },
    { Text = "  │  " },
  }

  for _, e in ipairs(battery_elements) do
    table.insert(elements, e)
  end

  return elements
end

-- ============================================
-- Main Entry Point
-- ============================================

function M.apply_to_config(config, user_opts)
  local opts = merge_opts(user_opts)
  resolved_opts = opts
  return opts
end

-- ============================================
-- Utility Exports
-- ============================================

M.get_battery_info = function(opts)
  return fetch_battery_info(opts or resolved_opts or defaults)
end

M.defaults = defaults

return M
