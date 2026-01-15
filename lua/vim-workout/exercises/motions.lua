-- vim-workout: Motion exercise generators
-- Generators for Tier 1-5 motion skills

local M = {}

local data = require("vim-workout.data")

--- Generate hjkl exercise
---@param skill table
---@return table
function M.gen_hjkl(skill)
  local direction = ({ "h", "j", "k", "l" })[math.random(4)]
  local count = math.random(2, 4)

  local lines = {}
  for i = 1, 7 do
    table.insert(lines, table.concat(data.get_random_words(8), " "))
  end

  local instruction, cursor_start, expected_cursor, optimal_keys

  if direction == "j" then
    instruction = "Move DOWN " .. count .. " lines using j"
    cursor_start = { 2, 5 }
    expected_cursor = { 2 + count, 5 }
    optimal_keys = count == 1 and { "j" } or { tostring(count), "j" }

  elseif direction == "k" then
    instruction = "Move UP " .. count .. " lines using k"
    cursor_start = { 2 + count, 5 }
    expected_cursor = { 2, 5 }
    optimal_keys = count == 1 and { "k" } or { tostring(count), "k" }

  elseif direction == "l" then
    instruction = "Move RIGHT " .. count .. " characters using l"
    cursor_start = { 1, 5 }
    expected_cursor = { 1, 5 + count }
    optimal_keys = count == 1 and { "l" } or { tostring(count), "l" }

  else -- h
    instruction = "Move LEFT " .. count .. " characters using h"
    cursor_start = { 1, 10 }
    expected_cursor = { 1, 10 - count }
    optimal_keys = count == 1 and { "h" } or { tostring(count), "h" }
  end

  return {
    instruction = instruction,
    buffer_content = lines,
    cursor_start = cursor_start,
    expected_cursor = expected_cursor,
    optimal_keys = optimal_keys,
    skills = { skill },
  }
end

--- Generate word forward (w/W) exercise
---@param skill table
---@return table
function M.gen_word_forward(skill)
  local words = data.get_random_words(10)
  local line = table.concat(words, " ")

  local jump_count = math.random(2, 5)
  local target_word = words[jump_count + 1]

  -- Calculate target column
  local target_col = 0
  for i = 1, jump_count do
    target_col = target_col + #words[i] + 1
  end

  local key = skill.key:gsub("{.*}", "") -- Remove {char} if present
  local optimal_keys = jump_count == 1 and { key } or { tostring(jump_count), key }

  return {
    instruction = "Move forward to '" .. target_word .. "' using " .. key,
    buffer_content = { line },
    cursor_start = { 1, 0 },
    expected_cursor = { 1, target_col },
    optimal_keys = optimal_keys,
    skills = { skill },
  }
end

--- Generate word backward (b/B) exercise
---@param skill table
---@return table
function M.gen_word_backward(skill)
  local words = data.get_random_words(10)
  local line = table.concat(words, " ")

  local start_word_idx = math.random(5, 8)
  local jump_count = math.random(2, 4)
  local target_word_idx = start_word_idx - jump_count

  -- Calculate start column
  local start_col = 0
  for i = 1, start_word_idx - 1 do
    start_col = start_col + #words[i] + 1
  end

  -- Calculate target column
  local target_col = 0
  for i = 1, target_word_idx - 1 do
    target_col = target_col + #words[i] + 1
  end

  local key = skill.key:gsub("{.*}", "")
  local optimal_keys = jump_count == 1 and { key } or { tostring(jump_count), key }

  return {
    instruction = "Move backward to '" .. words[target_word_idx] .. "' using " .. key,
    buffer_content = { line },
    cursor_start = { 1, start_col },
    expected_cursor = { 1, target_col },
    optimal_keys = optimal_keys,
    skills = { skill },
  }
end

--- Generate end of word (e/E) exercise
---@param skill table
---@return table
function M.gen_word_end(skill)
  local words = data.get_random_words(10)
  local line = table.concat(words, " ")

  local jump_count = math.random(2, 4)
  local target_word = words[jump_count]

  -- End of word position (end of jump_count-th word)
  -- For "the quick brown": end of "the"=2, end of "quick"=8
  -- Formula: sum of word lengths + spaces between words - 1
  local target_col = -1
  for i = 1, jump_count do
    target_col = target_col + #words[i]
    if i < jump_count then
      target_col = target_col + 1  -- space between words
    end
  end

  local key = skill.key:gsub("{.*}", "")
  local optimal_keys = jump_count == 1 and { key } or { tostring(jump_count), key }

  return {
    instruction = "Move to END of word '" .. target_word .. "' using " .. key,
    buffer_content = { line },
    cursor_start = { 1, 0 },
    expected_cursor = { 1, target_col },
    optimal_keys = optimal_keys,
    skills = { skill },
  }
end

--- Generate line start (0) exercise
---@param skill table
---@return table
function M.gen_line_start(skill)
  local words = data.get_random_words(10)
  local line = table.concat(words, " ")

  local start_col = math.random(15, 30)
  start_col = math.min(start_col, #line - 1)

  return {
    instruction = "Move to the BEGINNING of the line using 0",
    buffer_content = { line },
    cursor_start = { 1, start_col },
    expected_cursor = { 1, 0 },
    optimal_keys = { "0" },
    skills = { skill },
  }
end

--- Generate first non-blank (^) exercise
---@param skill table
---@return table
function M.gen_first_nonblank(skill)
  local words = data.get_random_words(8)
  local indent = string.rep(" ", math.random(2, 6))
  local line = indent .. table.concat(words, " ")

  return {
    instruction = "Move to the FIRST NON-BLANK character using ^",
    buffer_content = { line },
    cursor_start = { 1, 0 },
    expected_cursor = { 1, #indent },
    optimal_keys = { "^" },
    skills = { skill },
  }
end

--- Generate line end ($) exercise
---@param skill table
---@return table
function M.gen_line_end(skill)
  local words = data.get_random_words(10)
  local line = table.concat(words, " ")

  return {
    instruction = "Move to the END of the line using $",
    buffer_content = { line },
    cursor_start = { 1, 0 },
    expected_cursor = { 1, #line - 1 },
    optimal_keys = { "$" },
    skills = { skill },
  }
end

--- Fallback generator for skills without specific implementation
---@param skill table
---@return table
function M.gen_basic_motion(skill)
  -- Create a multi-line buffer with clear targets
  local lines = {}
  for i = 1, 5 do
    table.insert(lines, table.concat(data.get_random_words(8), " "))
  end

  -- For unimplemented motions, create a simple "move down" exercise
  -- This ensures the exercise is always completable
  local count = math.random(2, 3)

  return {
    instruction = "Practice: Move down " .. count .. " lines (skill: " .. skill.key .. " - use j for now)",
    buffer_content = lines,
    cursor_start = { 1, 0 },
    expected_cursor = { 1 + count, 0 },
    optimal_keys = { tostring(count), "j" },
    skills = { skill },
  }
end

return M
