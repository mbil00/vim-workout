-- vim-workout: Operator exercise generators
-- Generators for Tier 6 operator skills (d, c, y)

local M = {}

local data = require("vim-workout.data")

-------------------------------------------------------------------------
-- Delete Generators
-------------------------------------------------------------------------

--- Generate delete with motion (dw, d2w, d$, etc.) exercise
---@param skill table
---@return table
function M.gen_delete_motion(skill)
  -- Pick a random motion type for the delete operation
  local motion_types = { "word", "words", "to_end" }
  local motion_type = motion_types[math.random(#motion_types)]

  if motion_type == "word" then
    return M.gen_delete_word(skill)
  elseif motion_type == "words" then
    return M.gen_delete_words(skill)
  else
    return M.gen_delete_to_end(skill)
  end
end

--- Generate "delete word" (dw) exercise
---@param skill table
---@return table
function M.gen_delete_word(skill)
  local words = data.get_random_words(8)
  local line = table.concat(words, " ")

  -- Target word to delete (not the first or last)
  local target_idx = math.random(2, 5)
  local target_word = words[target_idx]

  -- Calculate cursor start position (beginning of target word)
  local start_col = 0
  for i = 1, target_idx - 1 do
    start_col = start_col + #words[i] + 1
  end

  -- Build expected line after deletion
  local expected_words = {}
  for i, w in ipairs(words) do
    if i ~= target_idx then
      table.insert(expected_words, w)
    end
  end
  local expected_line = table.concat(expected_words, " ")

  return {
    instruction = "Delete the word '" .. target_word .. "' using dw",
    buffer_content = { line },
    cursor_start = { 1, start_col },
    expected_lines = { expected_line },
    optimal_keys = { "d", "w" },
    skills = { skill },
  }
end

--- Generate "delete multiple words" (d2w, d3w) exercise
---@param skill table
---@return table
function M.gen_delete_words(skill)
  local words = data.get_random_words(10)
  local line = table.concat(words, " ")

  local count = math.random(2, 3)
  local target_idx = 2  -- Start from second word

  -- Calculate cursor start position
  local start_col = 0
  for i = 1, target_idx - 1 do
    start_col = start_col + #words[i] + 1
  end

  -- Build expected line after deletion
  local expected_words = {}
  for i, w in ipairs(words) do
    if i < target_idx or i >= target_idx + count then
      table.insert(expected_words, w)
    end
  end
  local expected_line = table.concat(expected_words, " ")

  -- Words being deleted for instruction
  local deleted_words = {}
  for i = target_idx, target_idx + count - 1 do
    if words[i] then
      table.insert(deleted_words, words[i])
    end
  end

  return {
    instruction = "Delete " .. count .. " words ('" .. table.concat(deleted_words, " ") .. "') using d" .. count .. "w",
    buffer_content = { line },
    cursor_start = { 1, start_col },
    expected_lines = { expected_line },
    optimal_keys = { "d", tostring(count), "w" },
    skills = { skill },
  }
end

--- Generate "delete to end of line" (d$ or D) exercise
---@param skill table
---@return table
function M.gen_delete_to_end(skill)
  local words = data.get_random_words(8)
  local line = table.concat(words, " ")

  -- Start somewhere in the middle
  local start_word_idx = math.random(3, 5)
  local start_col = 0
  for i = 1, start_word_idx - 1 do
    start_col = start_col + #words[i] + 1
  end

  -- Expected line is just the words before cursor
  local expected_words = {}
  for i = 1, start_word_idx - 1 do
    table.insert(expected_words, words[i])
  end
  local expected_line = table.concat(expected_words, " ")

  local use_D = skill.id == "operator_D"
  local key_display = use_D and "D" or "d$"
  local optimal = use_D and { "D" } or { "d", "$" }

  return {
    instruction = "Delete from cursor to END of line using " .. key_display,
    buffer_content = { line },
    cursor_start = { 1, start_col },
    expected_lines = { expected_line },
    optimal_keys = optimal,
    skills = { skill },
  }
end

--- Generate "delete entire line" (dd) exercise
---@param skill table
---@return table
function M.gen_delete_line(skill)
  local lines = {}
  for i = 1, 5 do
    table.insert(lines, table.concat(data.get_random_words(6), " "))
  end

  -- Target line to delete (not first or last)
  local target_line = math.random(2, 4)

  -- Build expected lines after deletion
  local expected_lines = {}
  for i, line in ipairs(lines) do
    if i ~= target_line then
      table.insert(expected_lines, line)
    end
  end

  return {
    instruction = "Delete the entire line using dd",
    buffer_content = lines,
    cursor_start = { target_line, 0 },
    expected_lines = expected_lines,
    optimal_keys = { "d", "d" },
    skills = { skill },
  }
end

-------------------------------------------------------------------------
-- Change Generators
-------------------------------------------------------------------------

--- Generate change with motion (cw) exercise
---@param skill table
---@return table
function M.gen_change_motion(skill)
  local words = data.get_random_words(8)
  local line = table.concat(words, " ")

  -- Target word to change
  local target_idx = math.random(2, 5)
  local target_word = words[target_idx]
  local new_word = data.get_random_words(1)[1]

  -- Make sure new word is different
  while new_word == target_word do
    new_word = data.get_random_words(1)[1]
  end

  -- Calculate cursor start position
  local start_col = 0
  for i = 1, target_idx - 1 do
    start_col = start_col + #words[i] + 1
  end

  -- Build expected line after change
  local expected_words = {}
  for i, w in ipairs(words) do
    if i == target_idx then
      table.insert(expected_words, new_word)
    else
      table.insert(expected_words, w)
    end
  end
  local expected_line = table.concat(expected_words, " ")

  -- Build optimal keys: cw + new_word + <Esc>
  local optimal = { "c", "w" }
  for i = 1, #new_word do
    table.insert(optimal, new_word:sub(i, i))
  end
  table.insert(optimal, "<Esc>")

  return {
    instruction = "Change '" .. target_word .. "' to '" .. new_word .. "' using cw",
    buffer_content = { line },
    cursor_start = { 1, start_col },
    expected_lines = { expected_line },
    optimal_keys = optimal,
    skills = { skill },
  }
end

--- Generate "change to end of line" (c$ or C) exercise
---@param skill table
---@return table
function M.gen_change_to_end(skill)
  local words = data.get_random_words(8)
  local line = table.concat(words, " ")

  -- Start somewhere in the middle
  local start_word_idx = math.random(3, 5)
  local start_col = 0
  for i = 1, start_word_idx - 1 do
    start_col = start_col + #words[i] + 1
  end

  -- New text to replace rest of line
  local new_text = table.concat(data.get_random_words(2), " ")

  -- Expected line
  local expected_words = {}
  for i = 1, start_word_idx - 1 do
    table.insert(expected_words, words[i])
  end
  local expected_line = table.concat(expected_words, " ") .. " " .. new_text

  local use_C = skill.id == "operator_C"
  local key_display = use_C and "C" or "c$"
  local optimal = use_C and { "C" } or { "c", "$" }

  -- Add the new text characters to optimal
  for i = 1, #new_text do
    table.insert(optimal, new_text:sub(i, i))
  end
  table.insert(optimal, "<Esc>")

  return {
    instruction = "Change from cursor to end of line to '" .. new_text .. "' using " .. key_display,
    buffer_content = { line },
    cursor_start = { 1, start_col },
    expected_lines = { expected_line },
    optimal_keys = optimal,
    skills = { skill },
  }
end

--- Generate "change entire line" (cc) exercise
---@param skill table
---@return table
function M.gen_change_line(skill)
  local lines = {}
  for i = 1, 5 do
    table.insert(lines, table.concat(data.get_random_words(6), " "))
  end

  local target_line = math.random(2, 4)
  local new_content = table.concat(data.get_random_words(4), " ")

  -- Build expected lines after change
  local expected_lines = {}
  for i, line in ipairs(lines) do
    if i == target_line then
      table.insert(expected_lines, new_content)
    else
      table.insert(expected_lines, line)
    end
  end

  -- Optimal keys: cc + new content + <Esc>
  local optimal = { "c", "c" }
  for i = 1, #new_content do
    table.insert(optimal, new_content:sub(i, i))
  end
  table.insert(optimal, "<Esc>")

  return {
    instruction = "Replace the entire line with '" .. new_content .. "' using cc",
    buffer_content = lines,
    cursor_start = { target_line, 0 },
    expected_lines = expected_lines,
    optimal_keys = optimal,
    skills = { skill },
  }
end

-------------------------------------------------------------------------
-- Yank Generators
-------------------------------------------------------------------------

--- Generate yank with motion exercise
--- Uses yy + p (duplicate line) as it's the most straightforward yank exercise
---@param skill table
---@return table
function M.gen_yank_motion(skill)
  -- For basic yank, use yy + p (duplicate line)
  -- This is cleaner than yw + p which has complex paste behavior
  return M.gen_yank_line(skill)
end

--- Generate "yank entire line" (yy) exercise
---@param skill table
---@return table
function M.gen_yank_line(skill)
  local lines = {}
  for i = 1, 4 do
    table.insert(lines, table.concat(data.get_random_words(5), " "))
  end

  local target_line = math.random(2, 3)

  -- After yy and p, line should be duplicated below
  local expected_lines = {}
  for i, line in ipairs(lines) do
    table.insert(expected_lines, line)
    if i == target_line then
      table.insert(expected_lines, line)  -- Duplicated line
    end
  end

  return {
    instruction = "Yank the entire line and paste it below (yy then p)",
    buffer_content = lines,
    cursor_start = { target_line, 0 },
    expected_lines = expected_lines,
    optimal_keys = { "y", "y", "p" },
    skills = { skill },
  }
end

return M
