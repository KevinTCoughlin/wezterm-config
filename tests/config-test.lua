local events = {}

local action = setmetatable({}, {
  __index = function(_, name)
    return function(value)
      return { name = name, value = value }
    end
  end,
})

package.preload.wezterm = function()
  return {
    action = action,
    config_builder = function()
      return {}
    end,
    font_with_fallback = function(fonts)
      return fonts
    end,
    format = function(elements)
      return elements
    end,
    on = function(name, callback)
      events[name] = callback
    end,
  }
end

package.preload["plugins.material-you.init"] = function()
  return {
    apply_to_config = function()
      return { separator = "#565f89" }
    end,
  }
end

package.preload["plugins.wezterm-ollama/plugin/init"] = function()
  return {
    apply_to_config = function()
      return {}
    end,
    get_status_elements = function()
      return {}
    end,
  }
end

package.preload["plugins.wezterm-battery/plugin/init"] = function()
  return {
    apply_to_config = function()
      return {}
    end,
    get_status_with_separator = function()
      return {}
    end,
  }
end

local config = dofile("wezterm.lua")
assert(type(config) == "table")

local format_tab_title = assert(events["format-tab-title"])
assert(format_tab_title({
  tab_index = 0,
  active_pane = {
    current_working_dir = { file_path = "C:\\Users\\Kevin\\Development" },
    foreground_process_name = "C:\\Windows\\System32\\pwsh.exe",
  },
}) == " 1:Development ")

assert(format_tab_title({
  tab_index = 1,
  active_pane = {},
}) == " 2:term ")
