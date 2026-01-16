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

--- Generate find character forward (f) exercise
---@param skill table
---@return table
function M.gen_find_char(skill)
  local words = data.get_random_words(8)
  local line = table.concat(words, " ")

  -- Pick a target character that appears in the line
  -- Use a distinctive character (not space, prefer letters in middle of words)
  local target_word_idx = math.random(3, #words - 1)
  local target_word = words[target_word_idx]
  local char_pos_in_word = math.random(1, #target_word)
  local target_char = target_word:sub(char_pos_in_word, char_pos_in_word)

  -- Calculate the absolute position of target character
  local target_col = 0
  for i = 1, target_word_idx - 1 do
    target_col = target_col + #words[i] + 1 -- word + space
  end
  target_col = target_col + char_pos_in_word - 1

  return {
    instruction = "Jump to the character '" .. target_char .. "' using f" .. target_char,
    buffer_content = { line },
    cursor_start = { 1, 0 },
    expected_cursor = { 1, target_col },
    optimal_keys = { "f", target_char },
    skills = { skill },
  }
end

--- Generate till character forward (t) exercise
---@param skill table
---@return table
function M.gen_till_char(skill)
  local words = data.get_random_words(8)
  local line = table.concat(words, " ")

  -- Pick a target character (starting from word 3 to ensure space before)
  local target_word_idx = math.random(3, #words - 1)
  local target_word = words[target_word_idx]
  -- Pick character after first position (so there's a position before it)
  local char_pos_in_word = math.random(2, math.max(2, #target_word))
  local target_char = target_word:sub(char_pos_in_word, char_pos_in_word)

  -- Calculate the absolute position of target character
  local target_col = 0
  for i = 1, target_word_idx - 1 do
    target_col = target_col + #words[i] + 1
  end
  target_col = target_col + char_pos_in_word - 1

  -- t stops one position BEFORE the character
  local expected_col = target_col - 1

  return {
    instruction = "Jump to just BEFORE the character '" .. target_char .. "' using t" .. target_char,
    buffer_content = { line },
    cursor_start = { 1, 0 },
    expected_cursor = { 1, expected_col },
    optimal_keys = { "t", target_char },
    skills = { skill },
  }
end

--- Generate find character backward (F) exercise
---@param skill table
---@return table
function M.gen_find_char_backward(skill)
  local words = data.get_random_words(8)
  local line = table.concat(words, " ")

  -- Pick a target character in an early word
  local target_word_idx = math.random(2, 4)
  local target_word = words[target_word_idx]
  local char_pos_in_word = math.random(1, #target_word)
  local target_char = target_word:sub(char_pos_in_word, char_pos_in_word)

  -- Calculate the absolute position of target character
  local target_col = 0
  for i = 1, target_word_idx - 1 do
    target_col = target_col + #words[i] + 1
  end
  target_col = target_col + char_pos_in_word - 1

  -- Start cursor at end of line
  local start_col = #line - 1

  return {
    instruction = "Jump BACKWARD to the character '" .. target_char .. "' using F" .. target_char,
    buffer_content = { line },
    cursor_start = { 1, start_col },
    expected_cursor = { 1, target_col },
    optimal_keys = { "F", target_char },
    skills = { skill },
  }
end

--- Generate till character backward (T) exercise
---@param skill table
---@return table
function M.gen_till_char_backward(skill)
  local words = data.get_random_words(8)
  local line = table.concat(words, " ")

  -- Pick a target character in an early word
  local target_word_idx = math.random(2, 4)
  local target_word = words[target_word_idx]
  -- Pick character before last position (so there's a position after it)
  local char_pos_in_word = math.random(1, math.max(1, #target_word - 1))
  local target_char = target_word:sub(char_pos_in_word, char_pos_in_word)

  -- Calculate the absolute position of target character
  local target_col = 0
  for i = 1, target_word_idx - 1 do
    target_col = target_col + #words[i] + 1
  end
  target_col = target_col + char_pos_in_word - 1

  -- T stops one position AFTER the character
  local expected_col = target_col + 1

  -- Start cursor at end of line
  local start_col = #line - 1

  return {
    instruction = "Jump BACKWARD to just AFTER the character '" .. target_char .. "' using T" .. target_char,
    buffer_content = { line },
    cursor_start = { 1, start_col },
    expected_cursor = { 1, expected_col },
    optimal_keys = { "T", target_char },
    skills = { skill },
  }
end

--- Generate repeat find (;) exercise - uses f then ; to reach further occurrence
---@param skill table
---@return table
function M.gen_repeat_find(skill)
  -- Create line with repeated character
  local target_char = ({ "x", "z", "q", "k" })[math.random(4)]
  local words = { "start", target_char .. "one", "middle", target_char .. "two", "end", target_char .. "three" }
  local line = table.concat(words, " ")

  -- Target: the second occurrence (after first f, use ;)
  -- "start xone middle xtwo end xthree"
  -- First x at pos 6, second x at pos 19, third x at pos 28
  local first_pos = 6
  local second_pos = #"start " + #(target_char .. "one") + #" middle "

  return {
    instruction = "Jump to the SECOND '" .. target_char .. "' using f" .. target_char .. " then ;",
    buffer_content = { line },
    cursor_start = { 1, 0 },
    expected_cursor = { 1, second_pos },
    optimal_keys = { "f", target_char, ";" },
    skills = { skill },
  }
end

--- Generate repeat find reverse (,) exercise
---@param skill table
---@return table
function M.gen_repeat_find_reverse(skill)
  -- Create line with repeated character
  local target_char = ({ "x", "z", "q", "k" })[math.random(4)]
  local words = { target_char .. "first", "middle", target_char .. "second", "more", target_char .. "third" }
  local line = table.concat(words, " ")

  -- Start at the third occurrence, go back to second using F then , (or f from start, ;, then ,)
  -- Actually simpler: start at end, F to third, , to go back to second
  local third_pos = #(target_char .. "first") + #" middle " + #(target_char .. "second") + #" more "
  local second_pos = #(target_char .. "first") + #" middle "

  return {
    instruction = "From the end, jump to '" .. target_char .. "' using F" .. target_char .. ", then back to the next one using ,",
    buffer_content = { line },
    cursor_start = { 1, #line - 1 },
    expected_cursor = { 1, second_pos },
    optimal_keys = { "F", target_char, "," },
    skills = { skill },
  }
end

--- Generate go to top (gg) exercise
---@param skill table
---@return table
function M.gen_goto_top(skill)
  local lines = {}
  for i = 1, 10 do
    table.insert(lines, table.concat(data.get_random_words(6), " "))
  end

  local start_line = math.random(5, 9)

  return {
    instruction = "Jump to the TOP of the file using gg",
    buffer_content = lines,
    cursor_start = { start_line, 0 },
    expected_cursor = { 1, 0 },
    optimal_keys = { "g", "g" },
    skills = { skill },
  }
end

--- Generate go to bottom (G) exercise
---@param skill table
---@return table
function M.gen_goto_bottom(skill)
  local lines = {}
  for i = 1, 10 do
    table.insert(lines, table.concat(data.get_random_words(6), " "))
  end

  return {
    instruction = "Jump to the BOTTOM of the file using G",
    buffer_content = lines,
    cursor_start = { 1, 0 },
    expected_cursor = { 10, 0 },
    optimal_keys = { "G" },
    skills = { skill },
  }
end

--- Generate go to specific line (nG or ngg) exercise
---@param skill table
---@param use_gg boolean Use gg instead of G
---@return table
function M.gen_goto_line(skill, use_gg)
  local lines = {}
  for i = 1, 10 do
    table.insert(lines, "Line " .. i .. ": " .. table.concat(data.get_random_words(4), " "))
  end

  local target_line = math.random(3, 8)
  local key = use_gg and "gg" or "G"
  local optimal = use_gg and { tostring(target_line), "g", "g" } or { tostring(target_line), "G" }

  return {
    instruction = "Jump to LINE " .. target_line .. " using " .. target_line .. key,
    buffer_content = lines,
    cursor_start = { 1, 0 },
    expected_cursor = { target_line, 0 },
    optimal_keys = optimal,
    skills = { skill },
  }
end

--- Generate matching bracket (%) exercise
---@param skill table
---@return table
function M.gen_match_bracket(skill)
  local templates = {
    { line = "if (condition) { return true; }", start = 3, expected = 13 }, -- ( to )
    { line = "arr[index + 1] = value", start = 3, expected = 13 }, -- [ to ]
    { line = "function test() { return { key: val }; }", start = 17, expected = 39 }, -- { to }
    { line = "((nested) + (expr))", start = 0, expected = 18 }, -- outer ( to )
    { line = "data = {a: [1, 2], b: 3}", start = 7, expected = 23 }, -- { to }
  }

  local template = templates[math.random(#templates)]

  return {
    instruction = "Jump to the MATCHING BRACKET using %",
    buffer_content = { template.line },
    cursor_start = { 1, template.start },
    expected_cursor = { 1, template.expected },
    optimal_keys = { "%" },
    skills = { skill },
  }
end

--- Generate paragraph up ({) exercise
---@param skill table
---@return table
function M.gen_paragraph_up(skill)
  local lines = {
    "First paragraph line one.",
    "First paragraph line two.",
    "",
    "Second paragraph line one.",
    "Second paragraph line two.",
    "Second paragraph line three.",
    "",
    "Third paragraph line one.",
    "Third paragraph line two.",
  }

  -- Start in third paragraph, jump to blank line above second paragraph
  return {
    instruction = "Jump to the previous PARAGRAPH BOUNDARY using {",
    buffer_content = lines,
    cursor_start = { 8, 0 },
    expected_cursor = { 7, 0 },
    optimal_keys = { "{" },
    skills = { skill },
  }
end

--- Generate paragraph down (}) exercise
---@param skill table
---@return table
function M.gen_paragraph_down(skill)
  local lines = {
    "First paragraph line one.",
    "First paragraph line two.",
    "",
    "Second paragraph line one.",
    "Second paragraph line two.",
    "Second paragraph line three.",
    "",
    "Third paragraph line one.",
    "Third paragraph line two.",
  }

  -- Start in first paragraph, jump to blank line after first paragraph
  return {
    instruction = "Jump to the next PARAGRAPH BOUNDARY using }",
    buffer_content = lines,
    cursor_start = { 1, 0 },
    expected_cursor = { 3, 0 },
    optimal_keys = { "}" },
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
