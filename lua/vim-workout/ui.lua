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
  table.insert(content, "  During exercise: Ctrl-R to restart, Ctrl-C to abort")
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
---@return number win Window handle
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

  return win
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

--- Show brief completion indicator overlay
--- Displays a small floating indicator while keeping the practice buffer visible
---@return number win Window handle (caller should close it after delay)
function M.show_completion_indicator()
  local content = { "  ✓ Success!  " }

  -- Small floating window at top-right of screen
  local width = #content[1]
  local screen_width = vim.o.columns

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

  local win = vim.api.nvim_open_win(buf, false, {  -- false = don't focus
    relative = "editor",
    width = width,
    height = 1,
    row = 1,
    col = screen_width - width - 2,
    style = "minimal",
    border = "rounded",
    focusable = false,
  })

  -- Green highlight for success
  vim.api.nvim_win_set_option(win, "winhighlight", "Normal:DiagnosticOk,FloatBorder:DiagnosticOk")

  return win
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

--- Show interactive settings editor
function M.show_settings()
  local settings = require("vim-workout.settings")
  local defs = settings.SETTING_DEFS
  local current_settings = settings.load()
  local original_settings = vim.deepcopy(current_settings)
  local selected = 1

  -- State for tracking changes
  local has_changes = false

  -- Helper to render a boolean value
  local function render_bool(val)
    return val and "[x]" or "[ ]"
  end

  -- Helper to render a setting value
  local function render_value(def, val)
    if def.type == "boolean" then
      return render_bool(val)
    elseif def.format then
      return def.format(val)
    else
      return tostring(val)
    end
  end

  -- Build content lines
  local function build_content()
    local content = { "" }

    for i, def in ipairs(defs) do
      local val = current_settings[def.id]
      local display = render_value(def, val)
      local prefix = i == selected and "  > " or "    "
      local line = prefix .. def.label .. ": "

      -- Pad label to align values
      local pad_len = 25 - #def.label
      line = line .. string.rep(" ", pad_len) .. display

      -- Mark changed values
      if current_settings[def.id] ~= original_settings[def.id] then
        line = line .. " *"
        has_changes = true
      end

      table.insert(content, line)
    end

    table.insert(content, "")
    table.insert(content, "  j/k: Navigate   +/-/h/l: Adjust   Space: Toggle")
    table.insert(content, "  r: Reset defaults   q/Esc: Save & close")
    table.insert(content, "")

    return content
  end

  -- Create the initial window
  local content = build_content()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

  local width = 55
  local height = #content + 2
  local screen_width = vim.o.columns
  local screen_height = vim.o.lines
  local row = math.floor((screen_height - height) / 2)
  local col = math.floor((screen_width - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " vim-workout Settings ",
    title_pos = "center",
  })

  vim.api.nvim_win_set_option(win, "cursorline", false)

  -- Refresh the display
  local function refresh()
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    local new_content = build_content()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_content)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
  end

  -- Close and save
  local function close_and_save()
    settings.save(current_settings)
    vim.api.nvim_win_close(win, true)
    if has_changes then
      vim.notify("vim-workout: Settings saved!", vim.log.levels.INFO)
    end
  end

  -- Adjust a numeric setting
  local function adjust(delta)
    local def = defs[selected]
    if def.type ~= "number" then
      return
    end

    local val = current_settings[def.id]
    local step = def.step or 1
    val = val + (step * delta)

    -- Clamp to min/max
    if def.min and val < def.min then
      val = def.min
    end
    if def.max and val > def.max then
      val = def.max
    end

    current_settings[def.id] = val
    refresh()
  end

  -- Toggle a boolean setting
  local function toggle()
    local def = defs[selected]
    if def.type ~= "boolean" then
      return
    end

    current_settings[def.id] = not current_settings[def.id]
    refresh()
  end

  -- Navigation
  vim.keymap.set("n", "j", function()
    selected = math.min(selected + 1, #defs)
    refresh()
  end, { buffer = buf, nowait = true })

  vim.keymap.set("n", "k", function()
    selected = math.max(selected - 1, 1)
    refresh()
  end, { buffer = buf, nowait = true })

  -- Adjustments
  vim.keymap.set("n", "+", function()
    adjust(1)
  end, { buffer = buf, nowait = true })

  vim.keymap.set("n", "-", function()
    adjust(-1)
  end, { buffer = buf, nowait = true })

  vim.keymap.set("n", "l", function()
    adjust(1)
  end, { buffer = buf, nowait = true })

  vim.keymap.set("n", "h", function()
    adjust(-1)
  end, { buffer = buf, nowait = true })

  -- Toggle
  vim.keymap.set("n", "<Space>", function()
    toggle()
  end, { buffer = buf, nowait = true })

  vim.keymap.set("n", "<CR>", function()
    toggle()
  end, { buffer = buf, nowait = true })

  -- Reset to defaults
  vim.keymap.set("n", "r", function()
    current_settings = settings.get_defaults()
    refresh()
  end, { buffer = buf, nowait = true })

  -- Close
  vim.keymap.set("n", "q", close_and_save, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close_and_save, { buffer = buf, nowait = true })

  -- Set buffer as non-modifiable initially
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

return M
