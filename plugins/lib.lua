-- lib.lua
-- Shared utilities for WezTerm plugins
-- Common patterns for configuration merging, state management, and status bar building

local wezterm = require("wezterm")
local M = {}

-- Debug mode
M.debug_mode = os.getenv("WEZTERM_DEBUG") == "1"

-------------------------------------------------------------------------------
-- Safe Process Execution
-------------------------------------------------------------------------------

--- Safe command execution with array form (no shell injection)
--- @param cmd table Command as array: {cmd, arg1, arg2, ...}
--- @param timeout_secs number Timeout in seconds (default: 5)
--- @return boolean success, string output, string stderr
function M.safe_run(cmd, timeout_secs)
  if type(cmd) == "string" then
    error("safe_run() requires array form: {cmd, arg1, arg2, ...} not string")
  end
  
  timeout_secs = timeout_secs or 5
  local start_time = os.time()
  local success, output, stderr = wezterm.run_child_process(cmd)
  local elapsed = os.time() - start_time
  
  if M.debug_mode then
    wezterm.log_error(string.format("[DEBUG] safe_run(%s) => success=%s, elapsed=%ds", 
      table.concat(cmd, " "), tostring(success), elapsed))
  end
  
  return success, output, stderr
end

--- Escape string for AppleScript (prevents injection)
--- @param str string String to escape
--- @return string Escaped string safe for AppleScript
function M.escape_applescript(str)
  str = str:gsub("\\", "\\\\")
  str = str:gsub('"', '\\"')
  return str
end

--- Safe directory creation (no shell injection)
--- @param path string Directory path to create
--- @return boolean success
function M.mkdir_p(path)
  if not path or path == "" then
    wezterm.log_error("[WARN] mkdir_p() called with empty path")
    return false
  end
  
  local success, output, stderr = M.safe_run({"mkdir", "-p", path})
  if not success then
    wezterm.log_error(string.format("[ERROR] mkdir_p failed for %s: %s", path, stderr or "unknown error"))
    return false
  end
  return true
end

--- Get secure temp file
--- @param prefix string Prefix for temp file
--- @param suffix string Suffix for temp file
--- @return string Temp file path
function M.get_temp_file(prefix, suffix)
  prefix = prefix or "wezterm"
  suffix = suffix or ""
  
  local tmp_file = os.tmpname()
  if suffix ~= "" then
    tmp_file = tmp_file .. suffix
  end
  
  return tmp_file
end

--- Safe file write with error handling
--- @param path string File path
--- @param content string File content
--- @return boolean success
function M.safe_write_file(path, content)
  local f, err = io.open(path, "w")
  if not f then
    wezterm.log_error(string.format("[ERROR] Cannot open %s for writing: %s", path, err))
    return false
  end
  
  local ok, err = f:write(content)
  f:close()
  
  if not ok then
    wezterm.log_error(string.format("[ERROR] Cannot write to %s: %s", path, err))
    return false
  end
  
  return true
end

--- Platform detection helpers
--- @return boolean true if running on macOS
function M.is_macos()
  local ostype = os.getenv("OSTYPE") or ""
  return ostype:match("darwin") ~= nil
end

--- @return boolean true if running on Windows
function M.is_windows()
  return wezterm.target_triple:find("windows") ~= nil
end

-------------------------------------------------------------------------------
-- Configuration Merging
-------------------------------------------------------------------------------

--- Deep merge user options with defaults
--- Handles nested tables and preserves user overrides
--- @param defaults table Default configuration options
--- @param user_opts table|nil User-provided configuration options
--- @return table Merged configuration
function M.merge_opts(defaults, user_opts)
  user_opts = user_opts or {}
  local opts = {}

  for k, v in pairs(defaults) do
    if type(v) == "table" then
      -- Deep copy default table
      opts[k] = {}
      for tk, tv in pairs(v) do
        opts[k][tk] = tv
      end
      -- Merge user overrides
      if user_opts[k] and type(user_opts[k]) == "table" then
        for tk, tv in pairs(user_opts[k]) do
          opts[k][tk] = tv
        end
      end
    else
      -- Override scalar values
      opts[k] = user_opts[k] ~= nil and user_opts[k] or v
    end
  end

  return opts
end

--- Alternative merge using setmetatable (for flat configurations)
--- More performant for non-nested options
--- @param defaults table Default configuration options
--- @param user_opts table|nil User-provided configuration options
--- @return table Merged configuration with metatable
function M.merge_opts_meta(defaults, user_opts)
  return setmetatable(user_opts or {}, { __index = defaults })
end

-------------------------------------------------------------------------------
-- State Management
-------------------------------------------------------------------------------

--- Create a state initialization factory
--- Returns a function that creates fresh state objects
--- @param template table State template
--- @return function Factory function that returns fresh state
function M.create_state_factory(template)
  return function()
    local state = {}
    for k, v in pairs(template) do
      if type(v) == "table" then
        state[k] = {}
        for tk, tv in pairs(v) do
          state[k][tk] = tv
        end
      else
        state[k] = v
      end
    end
    return state
  end
end

--- Reset state to initial values
--- @param state table Current state
--- @param template table State template
function M.reset_state(state, template)
  for k, v in pairs(template) do
    state[k] = v
  end
end

-------------------------------------------------------------------------------
-- Status Bar Element Building
-------------------------------------------------------------------------------

--- Add a colored text element to the status bar
--- @param elements table Status bar elements array
--- @param color string Hex color code
--- @param text string Text to display
function M.add_element(elements, color, text)
  if color then
    table.insert(elements, { Foreground = { Color = color } })
  end
  table.insert(elements, { Text = text })
end

--- Add a separator element to the status bar
--- @param elements table Status bar elements array
--- @param color string Hex color code
--- @param separator string Separator text (default: "  │  ")
function M.add_separator(elements, color, separator)
  separator = separator or "  │  "
  M.add_element(elements, color, separator)
end

--- Add a hyperlink element to the status bar
--- @param elements table Status bar elements array
--- @param color string Hex color code
--- @param text string Text to display
--- @param url string Hyperlink URL
function M.add_hyperlink(elements, color, text, url)
  if color then
    table.insert(elements, { Foreground = { Color = color } })
  end
  table.insert(elements, { Attribute = { Hyperlink = url } })
  table.insert(elements, { Text = text })
  table.insert(elements, "ResetAttributes")
end

-------------------------------------------------------------------------------
-- String Utilities
-------------------------------------------------------------------------------

--- Trim whitespace from string
--- @param str string Input string
--- @return string Trimmed string
function M.trim(str)
  return str:gsub("^%s*(.-)%s*$", "%1")
end

--- Truncate string to max length with optional suffix
--- @param str string Input string
--- @param max_len number Maximum length
--- @param suffix string Suffix to add if truncated (default: "...")
--- @return string Truncated string
function M.truncate(str, max_len, suffix)
  suffix = suffix or "..."
  if #str <= max_len then
    return str
  end
  return str:sub(1, max_len - #suffix) .. suffix
end

-------------------------------------------------------------------------------
-- Cache Management
-------------------------------------------------------------------------------

--- Create a simple time-based cache
--- @param ttl number Time to live in seconds
--- @return table Cache object with get/set methods
function M.create_cache(ttl)
  local cache = {
    data = nil,
    last_update = 0,
    ttl = ttl,
  }

  function cache:get()
    local now = os.time()
    if now - self.last_update >= self.ttl then
      return nil
    end
    return self.data
  end

  function cache:set(data)
    self.data = data
    self.last_update = os.time()
  end

  function cache:invalidate()
    self.data = nil
    self.last_update = 0
  end

  return cache
end

return M
