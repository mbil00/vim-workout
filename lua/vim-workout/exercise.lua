-- vim-workout: Exercise generator
-- Dynamically generates exercises from unlocked skills

local M = {}

local data = require("vim-workout.data")

--- Generate a random exercise from available skills
---@param unlocked_skills table List of unlocked skill definitions
---@param prog table Progress data
---@return table exercise Exercise definition
function M.generate(unlocked_skills, prog)
  -- Weight skills by inverse mastery (struggling skills appear more often)
  local weights = M.calculate_weights(unlocked_skills, prog)

  -- Select a skill based on weights
  local skill = M.weighted_select(unlocked_skills, weights)

  -- Generate exercise based on skill type
  return M.generate_for_skill(skill)
end

--- Calculate weights for skill selection (inverse mastery)
---@param skills table List of skills
---@param prog table Progress data
---@return table weights Weights indexed by skill id
function M.calculate_weights(skills, prog)
  local weights = {}

  for _, skill in ipairs(skills) do
    local skill_prog = prog.skills[skill.id]
    if skill_prog and skill_prog.attempts > 0 then
      local mastery = skill_prog.successes / skill_prog.attempts
      -- Inverse weight: lower mastery = higher weight
      weights[skill.id] = 2.0 - (mastery * 1.5)
    else
      -- New skill gets high weight
      weights[skill.id] = 1.5
    end
  end

  return weights
end

--- Select a skill based on weights
---@param skills table List of skills
---@param weights table Weights indexed by skill id
---@return table skill Selected skill
function M.weighted_select(skills, weights)
  local total_weight = 0
  for _, skill in ipairs(skills) do
    total_weight = total_weight + (weights[skill.id] or 1.0)
  end

  local rand = math.random() * total_weight
  local cumulative = 0

  for _, skill in ipairs(skills) do
    cumulative = cumulative + (weights[skill.id] or 1.0)
    if rand <= cumulative then
      return skill
    end
  end

  return skills[1]
end

--- Generate an exercise for a specific skill
---@param skill table Skill definition
---@return table exercise
function M.generate_for_skill(skill)
  -- Route to appropriate generator based on skill ID
  local generators = {
    -- Tier 1
    motion_hjkl = M.gen_hjkl,
    -- Tier 2
    motion_w = M.gen_word_forward,
    motion_b = M.gen_word_backward,
    motion_e = M.gen_word_end,
    motion_W = M.gen_word_forward,  -- Same logic, different key
    motion_B = M.gen_word_backward,
    motion_E = M.gen_word_end,
    -- Tier 3
    motion_0 = M.gen_line_start,
    motion_caret = M.gen_first_nonblank,
    motion_dollar = M.gen_line_end,
    -- Tier 6: Operators
    operator_d = M.gen_delete_motion,
    operator_c = M.gen_change_motion,
    operator_y = M.gen_yank_motion,
    operator_dd = M.gen_delete_line,
    operator_cc = M.gen_change_line,
    operator_yy = M.gen_yank_line,
    operator_D = M.gen_delete_to_end,
    operator_C = M.gen_change_to_end,
  }

  local generator = generators[skill.id]
  if generator then
    return generator(skill)
  end

  -- Fallback: generate a basic motion exercise
  return M.gen_basic_motion(skill)
end

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

-------------------------------------------------------------------------
-- Operator Generators (Tier 6)
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
