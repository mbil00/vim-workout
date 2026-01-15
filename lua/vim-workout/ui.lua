-- vim-workout: UI module
-- Handles floating windows, prompts, and visual feedback

local M = {}

--- Create a centered floating window
---@param content string[] Lines to display
---@param opts? table Optional settings (width, height, title, on_close)
---@return number buf Buffer handle
---@return number win Window handle
function M.create_float(content, opts)
  opts = opts or {}

  -- Calculate dimensions
  local width = opts.width or 50
  local height = opts.height or #content + 2

  -- Ensure minimum size
  for _, line in ipairs(content) do
    width = math.max(width, #line + 4)
  end

  -- Cap at screen size
  local screen_width = vim.o.columns
  local screen_height = vim.o.lines
  width = math.min(width, screen_width - 4)
  height = math.min(height, screen_height - 4)

  -- Center position
  local row = math.floor((screen_height - height) / 2)
  local col = math.floor((screen_width - width) / 2)

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

  -- Create window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = opts.title and (" " .. opts.title .. " ") or nil,
    title_pos = opts.title and "center" or nil,
  })

  -- Set window options
  vim.api.nvim_win_set_option(win, "winblend", 0)
  vim.api.nvim_win_set_option(win, "cursorline", false)

  -- Close on q or Escape
  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if opts.on_close then
      opts.on_close()
    end
  end

  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })

  return buf, win
end

--- Show exercise prompt window
---@param exercise table Exercise data
---@param exercise_num number Current exercise number
---@param on_start function Callback when user starts
---@param on_quit function Callback when user quits
function M.show_exercise_prompt(exercise, exercise_num, on_start, on_quit)
  local content = {
    "",
    "  Exercise #" .. exercise_num,
    "",
    "  " .. exercise.instruction,
    "",
  }

  if exercise.skills and #exercise.skills > 0 then
    local skill_names = {}
    for _, skill in ipairs(exercise.skills) do
      table.insert(skill_names, skill.name .. " (" .. skill.key .. ")")
    end
    table.insert(content, "  Skills: " .. table.concat(skill_names, " + "))
    table.insert(content, "")
  end

  table.insert(content, "  Press ENTER to start, q to quit")
  table.insert(content, "")

  local buf, win = M.create_float(content, { title = "vim-workout" })

  -- Handle Enter to start
  vim.keymap.set("n", "<CR>", function()
    vim.api.nvim_win_close(win, true)
    on_start()
  end, { buffer = buf, nowait = true })

  -- Override q to call quit callback
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
    on_quit()
  end, { buffer = buf, nowait = true })
end

--- Show feedback window after exercise completion
---@param result table Exercise result data
---@param on_next function Callback for next exercise
---@param on_quit function Callback when user quits
function M.show_feedback(result, on_next, on_quit)
  local content = {}

  -- Result status
  if result.success then
    table.insert(content, "")
    table.insert(content, "  [OK] Completed!")
  else
    table.insert(content, "")
    table.insert(content, "  [X] Not quite right")
  end
  table.insert(content, "")

  -- Keystroke comparison
  if result.user_keys then
    local user_display = table.concat(result.user_keys, " ")
    local optimal_display = table.concat(result.optimal_keys or {}, " ")

    table.insert(content, "  Your keystrokes:  " .. user_display .. "  (" .. #result.user_keys .. " keys)")
    table.insert(content, "  Optimal:          " .. optimal_display .. "  (" .. #(result.optimal_keys or {}) .. " keys)")
    table.insert(content, "")
  end

  -- Educational tip
  if result.tip then
    table.insert(content, "  Tip: " .. result.tip)
    table.insert(content, "")
  end

  -- Mastery progress
  if result.skill_mastery then
    for skill_id, mastery in pairs(result.skill_mastery) do
      local bar = M.progress_bar(mastery, 10)
      table.insert(content, "  " .. skill_id .. " " .. bar .. " " .. math.floor(mastery * 100) .. "%")
    end
    table.insert(content, "")
  end

  table.insert(content, "  Press ENTER for next, q to quit")
  table.insert(content, "")

  local buf, win = M.create_float(content, { title = "Result" })

  vim.keymap.set("n", "<CR>", function()
    vim.api.nvim_win_close(win, true)
    on_next()
  end, { buffer = buf, nowait = true })

  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
    on_quit()
  end, { buffer = buf, nowait = true })
end

--- Generate a text progress bar
---@param value number Value between 0 and 1
---@param width number Width in characters
---@return string
function M.progress_bar(value, width)
  local filled = math.floor(value * width)
  local empty = width - filled
  return string.rep("█", filled) .. string.rep("░", empty)
end

--- Show skill tree with progress
---@param prog table Progress data
function M.show_skill_tree(prog)
  local skills = require("vim-workout.skills")
  local all_skills = skills.get_all()

  local content = { "", "  Skill Tree", "", "" }

  local tiers = {}
  for _, skill in ipairs(all_skills) do
    local tier = skill.tier or 1
    tiers[tier] = tiers[tier] or {}
    table.insert(tiers[tier], skill)
  end

  for tier_num = 1, 10 do
    if tiers[tier_num] then
      table.insert(content, "  Tier " .. tier_num)
      for _, skill in ipairs(tiers[tier_num]) do
        local skill_prog = prog.skills[skill.id] or { unlocked = false, successes = 0, attempts = 0, optimal = 0 }
        local status = skill_prog.unlocked and "[x]" or "[ ]"
        local mastery = ""
        if skill_prog.attempts > 0 then
          -- Show optimal rate - how often you use the best keystrokes
          local pct = math.floor((skill_prog.optimal / skill_prog.attempts) * 100)
          mastery = " (" .. pct .. "% optimal)"
        end
        table.insert(content, "    " .. status .. " " .. skill.name .. " (" .. skill.key .. ")" .. mastery)
      end
      table.insert(content, "")
    end
  end

  table.insert(content, "  Press q to close")
  table.insert(content, "")

  M.create_float(content, { title = "Skills" })
end

--- Show statistics
---@param prog table Progress data
function M.show_stats(prog)
  local content = {
    "",
    "  Statistics",
    "",
    "  Total exercises: " .. (prog.total_exercises or 0),
    "  Current streak: " .. (prog.current_streak or 0),
    "",
  }

  -- Count unlocked skills
  local unlocked = 0
  local total = 0
  for _, data in pairs(prog.skills or {}) do
    total = total + 1
    if data.unlocked then
      unlocked = unlocked + 1
    end
  end

  table.insert(content, "  Skills unlocked: " .. unlocked)
  table.insert(content, "")
  table.insert(content, "  Press q to close")
  table.insert(content, "")

  M.create_float(content, { title = "Stats" })
end

--- Show confirmation dialog
---@param message string Confirmation message
---@param callback function Called with true/false
function M.confirm(message, callback)
  local content = {
    "",
    "  " .. message,
    "",
    "  [y] Yes    [n] No",
    "",
  }

  local buf, win = M.create_float(content, { title = "Confirm" })

  vim.keymap.set("n", "y", function()
    vim.api.nvim_win_close(win, true)
    callback(true)
  end, { buffer = buf, nowait = true })

  vim.keymap.set("n", "n", function()
    vim.api.nvim_win_close(win, true)
    callback(false)
  end, { buffer = buf, nowait = true })

  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
    callback(false)
  end, { buffer = buf, nowait = true })
end

return M
