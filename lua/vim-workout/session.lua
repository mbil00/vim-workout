-- vim-workout: Session module
-- Manages practice sessions, exercise flow, and keystroke capture

local M = {}

local ui = require("vim-workout.ui")
local exercise = require("vim-workout.exercises")
local verifier = require("vim-workout.verifier")
local progress = require("vim-workout.progress")
local settings = require("vim-workout.settings")

-- Session state
local state = {
  active = false,
  exercise_num = 0,
  current_exercise = nil,
  unlocked_skills = {},
  prog = nil,
  practice_buf = nil,
  original_win = nil,
  original_buf = nil,
  captured_keys = {},
  key_handler = nil,
  autocmd_id = nil,
  ready = false,  -- Prevent instant completion during setup
  completing = false,  -- Prevent actions during completion delay
  indicator_win = nil,  -- Track completion indicator window
  feedback_win = nil,  -- Track feedback window
}

--- Close any tracked floating windows
local function close_floating_windows()
  if state.indicator_win and vim.api.nvim_win_is_valid(state.indicator_win) then
    pcall(vim.api.nvim_win_close, state.indicator_win, true)
  end
  state.indicator_win = nil

  if state.feedback_win and vim.api.nvim_win_is_valid(state.feedback_win) then
    pcall(vim.api.nvim_win_close, state.feedback_win, true)
  end
  state.feedback_win = nil
end

--- Reset state for a new exercise
local function reset_exercise_state()
  close_floating_windows()
  state.practice_buf = nil
  state.captured_keys = {}
  state.autocmd_id = nil
  state.ready = false
  state.completing = false
end

--- Start a new workout session
---@param unlocked_skills table List of unlocked skill definitions
---@param prog table Progress data
function M.start(unlocked_skills, prog)
  state.active = true
  state.exercise_num = 0
  state.unlocked_skills = unlocked_skills
  state.prog = prog
  state.original_win = vim.api.nvim_get_current_win()
  state.original_buf = vim.api.nvim_get_current_buf()

  M.next_exercise()
end

--- Start a focused session on a specific skill
---@param skill table Skill definition
---@param prog table Progress data
function M.start_focused(skill, prog)
  state.active = true
  state.exercise_num = 0
  state.unlocked_skills = { skill }
  state.prog = prog
  state.original_win = vim.api.nvim_get_current_win()
  state.original_buf = vim.api.nvim_get_current_buf()

  M.next_exercise()
end

--- Generate and show the next exercise
function M.next_exercise()
  if not state.active then
    return
  end

  state.exercise_num = state.exercise_num + 1
  reset_exercise_state()

  -- Generate exercise from unlocked skills
  state.current_exercise = exercise.generate(state.unlocked_skills, state.prog)

  -- Show exercise prompt
  ui.show_exercise_prompt(
    state.current_exercise,
    state.exercise_num,
    M.begin_exercise,
    M.end_session
  )
end

--- Begin the current exercise (create practice buffer)
function M.begin_exercise()
  local ex = state.current_exercise
  if not ex then
    return
  end

  -- Make sure we're in a valid window
  if not state.original_win or not vim.api.nvim_win_is_valid(state.original_win) then
    state.original_win = vim.api.nvim_get_current_win()
  end

  -- Focus the original window
  vim.api.nvim_set_current_win(state.original_win)

  -- Create practice buffer with unique name
  state.practice_buf = vim.api.nvim_create_buf(false, true)
  local buf_name = "vim-workout-practice-" .. state.exercise_num
  pcall(vim.api.nvim_buf_set_name, state.practice_buf, buf_name)

  -- Buffer settings (set before content to avoid issues)
  vim.api.nvim_buf_set_option(state.practice_buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(state.practice_buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(state.practice_buf, "swapfile", false)

  -- Set buffer content
  vim.api.nvim_buf_set_lines(state.practice_buf, 0, -1, false, ex.buffer_content)

  -- Display buffer in the original window
  vim.api.nvim_win_set_buf(state.original_win, state.practice_buf)

  -- Set cursor to starting position
  if ex.cursor_start then
    vim.api.nvim_win_set_cursor(state.original_win, ex.cursor_start)
  end

  -- Clear captured keys
  state.captured_keys = {}

  -- Start keystroke capture
  M.start_key_capture()

  -- Set up completion check (after each cursor move, check if done)
  state.autocmd_id = vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "TextChanged", "TextChangedI" }, {
    buffer = state.practice_buf,
    callback = function()
      -- Use vim.schedule to avoid issues with autocmd nesting
      vim.schedule(function()
        if state.active and state.practice_buf then
          M.check_completion()
        end
      end)
    end,
  })

  -- Allow quitting with Ctrl-C
  vim.keymap.set("n", "<C-c>", function()
    M.abort_exercise()
  end, { buffer = state.practice_buf, nowait = true })

  -- Allow restarting with Ctrl-R
  vim.keymap.set("n", "<C-r>", function()
    M.restart_exercise()
  end, { buffer = state.practice_buf, nowait = true })

  -- Mark ready after a short delay to prevent instant completion
  vim.defer_fn(function()
    state.ready = true
  end, 100)
end

--- Restart the current exercise (reset buffer and captured keys)
function M.restart_exercise()
  local ex = state.current_exercise
  if not ex or not state.practice_buf then
    return
  end

  -- Don't restart if already completing
  if state.completing then
    return
  end

  -- Validate buffer is still valid
  if not vim.api.nvim_buf_is_valid(state.practice_buf) then
    return
  end

  -- Temporarily disable completion checking
  state.ready = false

  -- Reset buffer content to original
  vim.api.nvim_buf_set_option(state.practice_buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(state.practice_buf, 0, -1, false, ex.buffer_content)

  -- Reset cursor to starting position
  if ex.cursor_start then
    local cursor_win = vim.fn.bufwinid(state.practice_buf)
    if cursor_win ~= -1 then
      pcall(vim.api.nvim_win_set_cursor, cursor_win, ex.cursor_start)
    end
  end

  -- Clear captured keystrokes
  state.captured_keys = {}

  -- Notify user
  vim.notify("Exercise restarted", vim.log.levels.INFO)

  -- Re-enable completion checking after delay
  vim.defer_fn(function()
    state.ready = true
  end, 100)
end

--- Start capturing keystrokes
function M.start_key_capture()
  -- Stop any existing handler first
  M.stop_key_capture()

  state.key_handler = vim.on_key(function(key, typed)
    if not state.active or not state.practice_buf then
      return
    end

    -- Only capture if we're in the practice buffer
    local ok, current_buf = pcall(vim.api.nvim_get_current_buf)
    if not ok or current_buf ~= state.practice_buf then
      return
    end

    -- Convert key to readable format
    local readable = vim.fn.keytrans(typed or key)
    if readable and readable ~= "" then
      table.insert(state.captured_keys, readable)
    end
  end, nil)
end

--- Stop capturing keystrokes
function M.stop_key_capture()
  if state.key_handler then
    pcall(vim.on_key, nil, state.key_handler)
    state.key_handler = nil
  end
end

--- Check if the exercise is completed
function M.check_completion()
  local ex = state.current_exercise
  if not ex or not state.practice_buf then
    return
  end

  -- Don't check until setup is complete
  if not state.ready then
    return
  end

  -- Don't check if already completing (in delay period)
  if state.completing then
    return
  end

  -- Validate buffer is still valid
  if not vim.api.nvim_buf_is_valid(state.practice_buf) then
    return
  end

  -- Get current buffer state
  local ok, current_lines = pcall(vim.api.nvim_buf_get_lines, state.practice_buf, 0, -1, false)
  if not ok then
    return
  end

  -- Get cursor from the window displaying the practice buffer
  local cursor_win = vim.fn.bufwinid(state.practice_buf)
  if cursor_win == -1 then
    return
  end

  local ok2, current_cursor = pcall(vim.api.nvim_win_get_cursor, cursor_win)
  if not ok2 then
    return
  end

  -- Verify completion
  local result = verifier.check(ex, {
    lines = current_lines,
    cursor = current_cursor,
  }, state.captured_keys)

  if result.completed then
    M.complete_exercise(result)
  end
end

--- Complete the current exercise and show feedback
---@param result table Verification result
function M.complete_exercise(result)
  -- Prevent re-entry during completion
  if state.completing then
    return
  end
  state.completing = true

  M.stop_key_capture()

  -- Clear autocmd
  if state.autocmd_id then
    pcall(vim.api.nvim_del_autocmd, state.autocmd_id)
    state.autocmd_id = nil
  end

  -- Update progress
  local ex = state.current_exercise
  if ex and ex.skills then
    for _, skill in ipairs(ex.skills) do
      progress.record_attempt(state.prog, skill.id, result.success, result.is_optimal)
    end
    progress.save(state.prog)

    -- Build mastery info for feedback (show optimal rate, not just success rate)
    result.skill_mastery = {}
    for _, skill in ipairs(ex.skills) do
      local skill_prog = state.prog.skills[skill.id]
      if skill_prog and skill_prog.attempts > 0 then
        -- Show optimal rate - this is what matters for learning
        result.skill_mastery[skill.id] = skill_prog.optimal / skill_prog.attempts
      end
    end
  end

  -- Add user keys to result
  result.user_keys = state.captured_keys
  result.optimal_keys = ex.optimal_keys

  -- Show completion indicator so user can see their change
  state.indicator_win = ui.show_completion_indicator()

  -- Wait before showing feedback, so user can see the result of their action
  local delay_ms = settings.get("completion_delay_ms") or 2000
  vim.defer_fn(function()
    -- Session may have been ended during the delay
    if not state.active then
      close_floating_windows()
      return
    end

    -- Close the indicator
    if state.indicator_win and vim.api.nvim_win_is_valid(state.indicator_win) then
      pcall(vim.api.nvim_win_close, state.indicator_win, true)
    end
    state.indicator_win = nil

    -- Close practice buffer
    if state.practice_buf and vim.api.nvim_buf_is_valid(state.practice_buf) then
      pcall(vim.api.nvim_buf_delete, state.practice_buf, { force = true })
    end
    state.practice_buf = nil

    -- Restore original buffer in original window before showing feedback
    if state.original_win and vim.api.nvim_win_is_valid(state.original_win) then
      if state.original_buf and vim.api.nvim_buf_is_valid(state.original_buf) then
        pcall(vim.api.nvim_win_set_buf, state.original_win, state.original_buf)
      end
    end

    -- Show feedback and track window
    state.feedback_win = ui.show_feedback(result, M.next_exercise, M.end_session)
  end, delay_ms)
end

--- Abort the current exercise
function M.abort_exercise()
  M.stop_key_capture()
  close_floating_windows()

  if state.autocmd_id then
    pcall(vim.api.nvim_del_autocmd, state.autocmd_id)
    state.autocmd_id = nil
  end

  if state.practice_buf and vim.api.nvim_buf_is_valid(state.practice_buf) then
    pcall(vim.api.nvim_buf_delete, state.practice_buf, { force = true })
  end
  state.practice_buf = nil

  M.end_session()
end

--- End the workout session
function M.end_session()
  M.stop_key_capture()
  state.active = false
  state.completing = false
  close_floating_windows()

  if state.autocmd_id then
    pcall(vim.api.nvim_del_autocmd, state.autocmd_id)
    state.autocmd_id = nil
  end

  -- Clean up practice buffer if it exists
  if state.practice_buf and vim.api.nvim_buf_is_valid(state.practice_buf) then
    pcall(vim.api.nvim_buf_delete, state.practice_buf, { force = true })
  end

  -- Return to original buffer in original window
  if state.original_win and vim.api.nvim_win_is_valid(state.original_win) then
    vim.api.nvim_set_current_win(state.original_win)
    if state.original_buf and vim.api.nvim_buf_is_valid(state.original_buf) then
      pcall(vim.api.nvim_win_set_buf, state.original_win, state.original_buf)
    end
  end

  local completed = state.exercise_num - 1 -- Don't count the aborted one
  if completed < 0 then
    completed = 0
  end
  vim.notify("vim-workout: Session ended. " .. completed .. " exercises completed.", vim.log.levels.INFO)
end

return M
