-- material-you: Dynamic Material You colors for WezTerm tab bar
-- Reads M3 color scheme from kde-material-you-colors daemon JSON output
-- and maps it to WezTerm's tab_bar colors.

local wezterm = require("wezterm")

local M = {}

-- ============================================
-- Configuration Defaults (Tokyo Night fallback)
-- ============================================

local defaults = {
  json_path = "/tmp/kde-material-you-colors-" .. (os.getenv("USER") or "unknown") .. ".json",
  scheme = "dark",
}

local fallback_colors = {
  -- Pane
  pane_bg = "#1a1b26",
  pane_fg = "#c0caf5",
  -- Cursor
  cursor_bg = "#7aa2f7",
  cursor_fg = "#1a1b26",
  -- Selection
  selection_bg = "#283457",
  selection_fg = "#c0caf5",
  -- Split
  split = "#565f89",
  -- Tab bar
  background = "#1a1b26",
  active_tab_bg = "#7aa2f7",
  active_tab_fg = "#1a1b26",
  inactive_tab_bg = "#1a1b26",
  inactive_tab_fg = "#565f89",
  inactive_tab_hover_bg = "#24283b",
  inactive_tab_hover_fg = "#c0caf5",
  new_tab_fg = "#565f89",
  separator = "#565f89",
}

-- Resolved colors (available after apply_to_config)
local resolved_colors = nil

-- ============================================
-- JSON Reading
-- ============================================

local function read_colors(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local content = f:read("*a")
  f:close()
  if not content or content == "" then
    return nil
  end

  local parse_ok, data = pcall(wezterm.json_parse, content)
  if not parse_ok or not data then
    return nil
  end

  return data
end

-- ============================================
-- Color Mapping (M3 → tab_bar)
-- ============================================

local function map_colors(scheme)
  return {
    -- Pane
    pane_bg = scheme.surface,
    pane_fg = scheme.onSurface,
    -- Cursor
    cursor_bg = scheme.primary,
    cursor_fg = scheme.onPrimary,
    -- Selection
    selection_bg = scheme.primaryContainer,
    selection_fg = scheme.onPrimaryContainer,
    -- Split
    split = scheme.outlineVariant,
    -- Tab bar
    background = scheme.surfaceDim,
    active_tab_bg = scheme.primary,
    active_tab_fg = scheme.onPrimary,
    inactive_tab_bg = scheme.surfaceDim,
    inactive_tab_fg = scheme.onSurfaceVariant,
    inactive_tab_hover_bg = scheme.surfaceContainerHigh,
    inactive_tab_hover_fg = scheme.onSurface,
    new_tab_fg = scheme.outline,
    separator = scheme.outline,
  }
end

-- ============================================
-- Public API
-- ============================================

function M.apply_to_config(config, user_opts)
  user_opts = user_opts or {}
  local json_path = user_opts.json_path or defaults.json_path
  local scheme_key = user_opts.scheme or defaults.scheme

  local colors = fallback_colors

  local data = read_colors(json_path)
  if data and data.schemes and data.schemes[scheme_key] then
    colors = map_colors(data.schemes[scheme_key])
    wezterm.log_info("material-you: loaded colors from " .. json_path .. " primary=" .. colors.active_tab_bg)
  else
    wezterm.log_warn("material-you: FALLBACK — could not read " .. json_path)
  end

  resolved_colors = colors

  config.colors = config.colors or {}
  config.colors.background = colors.pane_bg
  config.colors.foreground = colors.pane_fg
  config.colors.cursor_bg = colors.cursor_bg
  config.colors.cursor_fg = colors.cursor_fg
  config.colors.cursor_border = colors.cursor_bg
  config.colors.selection_bg = colors.selection_bg
  config.colors.selection_fg = colors.selection_fg
  config.colors.split = colors.split
  config.colors.tab_bar = {
    background = colors.background,
    active_tab = { bg_color = colors.active_tab_bg, fg_color = colors.active_tab_fg },
    inactive_tab = { bg_color = colors.inactive_tab_bg, fg_color = colors.inactive_tab_fg },
    inactive_tab_hover = { bg_color = colors.inactive_tab_hover_bg, fg_color = colors.inactive_tab_hover_fg },
    new_tab = { bg_color = colors.background, fg_color = colors.new_tab_fg },
    new_tab_hover = { bg_color = colors.inactive_tab_hover_bg, fg_color = colors.inactive_tab_hover_fg },
  }

  return colors
end

function M.get_colors()
  return resolved_colors or fallback_colors
end

return M
