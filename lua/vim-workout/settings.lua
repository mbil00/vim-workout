-- vim-workout: Settings module
-- Handles user-configurable settings with persistence

local M = {}

-- Data directory
local data_dir = vim.fn.stdpath("data") .. "/vim-workout"
local settings_file = data_dir .. "/settings.json"

-- Default settings
local DEFAULTS = {
  completion_delay_ms = 2000,      -- Delay before showing feedback
  unlock_threshold = 0.80,         -- Success rate to unlock next tier
  min_attempts_for_unlock = 5,     -- Minimum attempts before unlock
  show_tips = true,                -- Show educational tips
  accept_better_solutions = true,  -- Accept shorter keystrokes as optimal
}

-- Setting definitions for UI
M.SETTING_DEFS = {
  {
    id = "completion_delay_ms",
    label = "Completion delay",
    type = "number",
    min = 500,
    max = 5000,
    step = 500,
    format = function(v) return string.format("%.1f seconds", v / 1000) end,
  },
  {
    id = "unlock_threshold",
    label = "Unlock threshold",
    type = "number",
    min = 0.50,
    max = 1.00,
    step = 0.05,
    format = function(v) return string.format("%d%%", v * 100) end,
  },
  {
    id = "min_attempts_for_unlock",
    label = "Min attempts to unlock",
    type = "number",
    min = 1,
    max = 20,
    step = 1,
    format = function(v) return tostring(v) end,
  },
  {
    id = "show_tips",
    label = "Show tips",
    type = "boolean",
  },
  {
    id = "accept_better_solutions",
    label = "Accept better solutions",
    type = "boolean",
  },
}

-- Cached settings
local cached_settings = nil

--- Load settings from disk
---@return table settings
function M.load()
  if cached_settings then
    return cached_settings
  end

  -- Ensure data directory exists
  vim.fn.mkdir(data_dir, "p")

  -- Try to read existing settings
  local file = io.open(settings_file, "r")
  if not file then
    cached_settings = vim.deepcopy(DEFAULTS)
    return cached_settings
  end

  local content = file:read("*a")
  file:close()

  local ok, data = pcall(vim.json.decode, content)
  if not ok or type(data) ~= "table" then
    cached_settings = vim.deepcopy(DEFAULTS)
    return cached_settings
  end

  -- Merge with defaults to ensure all fields exist
  cached_settings = vim.tbl_deep_extend("keep", data, DEFAULTS)
  return cached_settings
end

--- Save settings to disk
---@param settings table Settings data
function M.save(settings)
  vim.fn.mkdir(data_dir, "p")

  local ok, json = pcall(vim.json.encode, settings)
  if not ok then
    vim.notify("vim-workout: Failed to encode settings", vim.log.levels.ERROR)
    return
  end

  local file = io.open(settings_file, "w")
  if not file then
    vim.notify("vim-workout: Failed to save settings", vim.log.levels.ERROR)
    return
  end

  file:write(json)
  file:close()

  -- Update cache
  cached_settings = settings
end

--- Get a specific setting value
---@param key string Setting key
---@return any value
function M.get(key)
  local settings = M.load()
  return settings[key]
end

--- Set a specific setting value
---@param key string Setting key
---@param value any Setting value
function M.set(key, value)
  local settings = M.load()
  settings[key] = value
  M.save(settings)
end

--- Reset all settings to defaults
function M.reset()
  cached_settings = vim.deepcopy(DEFAULTS)
  M.save(cached_settings)
end

--- Clear settings cache (useful for testing)
function M.clear_cache()
  cached_settings = nil
end

--- Get default settings
---@return table defaults
function M.get_defaults()
  return vim.deepcopy(DEFAULTS)
end

return M
