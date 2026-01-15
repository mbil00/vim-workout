-- vim-workout: Verification module
-- Checks exercise completion and compares with optimal solution

local M = {}

--- Check if an exercise is completed
---@param exercise table Exercise definition
---@param actual table Current state { lines, cursor }
---@param captured_keys table List of captured keystrokes
---@return table result { completed, success, is_optimal, tip }
function M.check(exercise, actual, captured_keys)
  local result = {
    completed = false,
    success = false,
    is_optimal = false,
    tip = nil,
  }

  -- Check based on exercise type
  if exercise.expected_cursor then
    result = M.check_cursor_position(exercise, actual, captured_keys)
  elseif exercise.expected_lines then
    result = M.check_buffer_content(exercise, actual, captured_keys)
  end

  return result
end

--- Check cursor position exercise
---@param exercise table Exercise with expected_cursor
---@param actual table Current state
---@param captured_keys table Captured keystrokes
---@return table result
function M.check_cursor_position(exercise, actual, captured_keys)
  local expected = exercise.expected_cursor
  local current = actual.cursor

  -- Check if cursor is at expected position
  local at_target = current[1] == expected[1] and current[2] == expected[2]

  if not at_target then
    return {
      completed = false,
      success = false,
      is_optimal = false,
      tip = nil,
    }
  end

  -- Cursor is at target - exercise completed
  local optimal_keys = exercise.optimal_keys or {}
  local is_optimal = M.compare_keystrokes(captured_keys, optimal_keys)

  -- Generate educational tip if not optimal
  local tip = nil
  if not is_optimal and #optimal_keys > 0 then
    tip = M.generate_tip(captured_keys, optimal_keys, exercise)
  end

  return {
    completed = true,
    success = true,
    is_optimal = is_optimal,
    tip = tip,
  }
end

--- Check buffer content exercise
---@param exercise table Exercise with expected_lines
---@param actual table Current state
---@param captured_keys table Captured keystrokes
---@return table result
function M.check_buffer_content(exercise, actual, captured_keys)
  local expected_lines = exercise.expected_lines
  local current_lines = actual.lines

  -- Compare line by line
  if #expected_lines ~= #current_lines then
    return {
      completed = false,
      success = false,
      is_optimal = false,
      tip = nil,
    }
  end

  for i, expected_line in ipairs(expected_lines) do
    if current_lines[i] ~= expected_line then
      return {
        completed = false,
        success = false,
        is_optimal = false,
        tip = nil,
      }
    end
  end

  -- Buffer matches - exercise completed
  local optimal_keys = exercise.optimal_keys or {}
  local is_optimal = M.compare_keystrokes(captured_keys, optimal_keys)

  local tip = nil
  if not is_optimal and #optimal_keys > 0 then
    tip = M.generate_tip(captured_keys, optimal_keys, exercise)
  end

  return {
    completed = true,
    success = true,
    is_optimal = is_optimal,
    tip = tip,
  }
end

--- Compare user keystrokes with optimal solution
---@param user_keys table User's keystrokes
---@param optimal_keys table Optimal keystrokes
---@return boolean is_optimal
function M.compare_keystrokes(user_keys, optimal_keys)
  if #user_keys ~= #optimal_keys then
    return false
  end

  for i, key in ipairs(user_keys) do
    if key ~= optimal_keys[i] then
      return false
    end
  end

  return true
end

--- Generate an educational tip based on the difference
---@param user_keys table User's keystrokes
---@param optimal_keys table Optimal keystrokes
---@param exercise table Exercise definition
---@return string tip
function M.generate_tip(user_keys, optimal_keys, exercise)
  local user_count = #user_keys
  local optimal_count = #optimal_keys
  local diff = user_count - optimal_count

  if diff > 0 then
    -- User used more keystrokes
    local optimal_str = table.concat(optimal_keys, "")

    -- Check for common patterns
    if M.has_repeated_motion(user_keys) then
      return "Use a count prefix to repeat motions: " .. optimal_str .. " does the same in fewer keys"
    end

    return "Optimal solution: " .. optimal_str .. " (" .. optimal_count .. " keys instead of " .. user_count .. ")"
  elseif diff < 0 then
    -- User used fewer keystrokes (rare but possible if exercise optimal isn't truly optimal)
    return "Nice! You found an efficient solution."
  else
    -- Same count but different keys
    return "Try: " .. table.concat(optimal_keys, "") .. " for the standard approach"
  end
end

--- Check if user repeated the same motion multiple times
---@param keys table Keystrokes
---@return boolean
function M.has_repeated_motion(keys)
  if #keys < 2 then
    return false
  end

  local motion_keys = { "h", "j", "k", "l", "w", "b", "e", "W", "B", "E" }
  local motion_set = {}
  for _, m in ipairs(motion_keys) do
    motion_set[m] = true
  end

  local last_key = nil
  local repeat_count = 0

  for _, key in ipairs(keys) do
    if motion_set[key] then
      if key == last_key then
        repeat_count = repeat_count + 1
        if repeat_count >= 2 then
          return true
        end
      else
        repeat_count = 1
        last_key = key
      end
    end
  end

  return false
end

return M
