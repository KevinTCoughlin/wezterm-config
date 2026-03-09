-- lib.lua
-- Shared utilities for WezTerm plugins
-- Common patterns for configuration merging, state management, and status bar building

local M = {}

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
