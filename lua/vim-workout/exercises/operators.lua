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

  -- Expected line is the substring up to cursor position
  -- When cursor is at start of word3, d$ leaves "word1 word2 " (with trailing space)
  local expected_line = line:sub(1, start_col)

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

  -- Expected line: text before cursor + new text
  -- c$ deletes from cursor to end, then we type new_text
  local expected_line = line:sub(1, start_col) .. new_text

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

-------------------------------------------------------------------------
-- Tier 8: Indent Generators
-------------------------------------------------------------------------

--- Generate "indent line" (>>) exercise
---@param skill table
---@return table
function M.gen_indent_line(skill)
  local lines = {
    "function example()",
    "local x = 1",
    "return x",
    "end",
  }

  -- Target line 2 or 3 (the unindented code lines)
  local target_line = math.random(2, 3)

  -- Build expected lines with indentation added
  local expected_lines = {}
  for i, line in ipairs(lines) do
    if i == target_line then
      table.insert(expected_lines, "  " .. line)  -- 2-space indent
    else
      table.insert(expected_lines, line)
    end
  end

  return {
    instruction = "Indent the current line using >>",
    buffer_content = lines,
    cursor_start = { target_line, 0 },
    expected_lines = expected_lines,
    optimal_keys = { ">", ">" },
    skills = { skill },
  }
end

--- Generate "indent with motion" (>j, >2j) exercise
---@param skill table
---@return table
function M.gen_indent_motion(skill)
  local lines = {
    "function example()",
    "local a = 1",
    "local b = 2",
    "local c = 3",
    "return a + b + c",
    "end",
  }

  -- Indent lines 2-4 (cursor on line 2, >2j indents 3 lines)
  local count = math.random(1, 2)

  -- Build expected lines
  local expected_lines = {}
  for i, line in ipairs(lines) do
    if i >= 2 and i <= 2 + count then
      table.insert(expected_lines, "  " .. line)
    else
      table.insert(expected_lines, line)
    end
  end

  local motion_desc = count == 1 and ">j" or ">" .. count .. "j"
  local optimal = count == 1 and { ">", "j" } or { ">", tostring(count), "j" }

  return {
    instruction = "Indent " .. (count + 1) .. " lines using " .. motion_desc,
    buffer_content = lines,
    cursor_start = { 2, 0 },
    expected_lines = expected_lines,
    optimal_keys = optimal,
    skills = { skill },
  }
end

--- Generate "outdent line" (<<) exercise
---@param skill table
---@return table
function M.gen_outdent_line(skill)
  local lines = {
    "function example()",
    "    local x = 1",  -- 4 spaces (will become 2)
    "  return x",       -- 2 spaces
    "end",
  }

  -- Target the over-indented line
  local target_line = 2

  -- Build expected lines with reduced indentation
  local expected_lines = {
    "function example()",
    "  local x = 1",  -- Reduced by one shiftwidth (2 spaces)
    "  return x",
    "end",
  }

  return {
    instruction = "Remove one level of indentation using <<",
    buffer_content = lines,
    cursor_start = { target_line, 0 },
    expected_lines = expected_lines,
    optimal_keys = { "<", "<" },
    skills = { skill },
  }
end

--- Generate "outdent with motion" (<j) exercise
---@param skill table
---@return table
function M.gen_outdent_motion(skill)
  local lines = {
    "function example()",
    "    local a = 1",  -- 4 spaces
    "    local b = 2",  -- 4 spaces
    "  return a + b",   -- 2 spaces
    "end",
  }

  -- Build expected lines
  local expected_lines = {
    "function example()",
    "  local a = 1",    -- Reduced to 2 spaces
    "  local b = 2",    -- Reduced to 2 spaces
    "  return a + b",
    "end",
  }

  return {
    instruction = "Outdent 2 lines using <j",
    buffer_content = lines,
    cursor_start = { 2, 0 },
    expected_lines = expected_lines,
    optimal_keys = { "<", "j" },
    skills = { skill },
  }
end

-------------------------------------------------------------------------
-- Tier 8: Case Generators
-------------------------------------------------------------------------

--- Generate "lowercase word" (guw) exercise
---@param skill table
---@return table
function M.gen_lowercase(skill)
  -- Create a line with mixed case words
  local words = { "Hello", "WORLD", "Test", "CODE", "Data", "VALUE" }
  local lowercase_words = { "hello", "world", "test", "code", "data", "value" }

  -- Pick a random word to target (index 2-5)
  local target_idx = math.random(2, 5)
  local line_words = {}
  for i = 1, 6 do
    table.insert(line_words, words[math.random(#words)])
  end

  -- Make target word uppercase
  local uppercase_words = { "HELLO", "WORLD", "TEST", "CODE", "DATA", "VALUE" }
  line_words[target_idx] = uppercase_words[math.random(#uppercase_words)]
  local target_word = line_words[target_idx]

  local line = table.concat(line_words, " ")

  -- Calculate cursor position
  local start_col = 0
  for i = 1, target_idx - 1 do
    start_col = start_col + #line_words[i] + 1
  end

  -- Build expected line
  local expected_words = {}
  for i, w in ipairs(line_words) do
    if i == target_idx then
      table.insert(expected_words, w:lower())
    else
      table.insert(expected_words, w)
    end
  end
  local expected_line = table.concat(expected_words, " ")

  return {
    instruction = "Make '" .. target_word .. "' lowercase using guw",
    buffer_content = { line },
    cursor_start = { 1, start_col },
    expected_lines = { expected_line },
    optimal_keys = { "g", "u", "w" },
    skills = { skill },
  }
end

--- Generate "uppercase word" (gUw) exercise
---@param skill table
---@return table
function M.gen_uppercase(skill)
  -- Create a line with mixed case words
  local words = { "hello", "world", "test", "code", "data", "value" }

  local line_words = {}
  for i = 1, 6 do
    table.insert(line_words, words[math.random(#words)])
  end

  -- Target word (index 2-5)
  local target_idx = math.random(2, 5)
  local target_word = line_words[target_idx]

  local line = table.concat(line_words, " ")

  -- Calculate cursor position
  local start_col = 0
  for i = 1, target_idx - 1 do
    start_col = start_col + #line_words[i] + 1
  end

  -- Build expected line
  local expected_words = {}
  for i, w in ipairs(line_words) do
    if i == target_idx then
      table.insert(expected_words, w:upper())
    else
      table.insert(expected_words, w)
    end
  end
  local expected_line = table.concat(expected_words, " ")

  return {
    instruction = "Make '" .. target_word .. "' uppercase using gUw",
    buffer_content = { line },
    cursor_start = { 1, start_col },
    expected_lines = { expected_line },
    optimal_keys = { "g", "U", "w" },
    skills = { skill },
  }
end

--- Generate "toggle case" (g~w) exercise
---@param skill table
---@return table
function M.gen_toggle_case(skill)
  -- Create mixed case words
  local mixed_words = { "HeLLo", "WoRLd", "TeST", "CoDe", "DaTa", "VaLuE" }

  local line_words = {}
  for i = 1, 6 do
    table.insert(line_words, mixed_words[math.random(#mixed_words)])
  end

  -- Target word (index 2-5)
  local target_idx = math.random(2, 5)
  local target_word = line_words[target_idx]

  local line = table.concat(line_words, " ")

  -- Calculate cursor position
  local start_col = 0
  for i = 1, target_idx - 1 do
    start_col = start_col + #line_words[i] + 1
  end

  -- Toggle case helper
  local function toggle_case(s)
    local result = ""
    for i = 1, #s do
      local c = s:sub(i, i)
      if c:match("%u") then
        result = result .. c:lower()
      else
        result = result .. c:upper()
      end
    end
    return result
  end

  -- Build expected line
  local expected_words = {}
  for i, w in ipairs(line_words) do
    if i == target_idx then
      table.insert(expected_words, toggle_case(w))
    else
      table.insert(expected_words, w)
    end
  end
  local expected_line = table.concat(expected_words, " ")

  return {
    instruction = "Toggle the case of '" .. target_word .. "' using g~w",
    buffer_content = { line },
    cursor_start = { 1, start_col },
    expected_lines = { expected_line },
    optimal_keys = { "g", "~", "w" },
    skills = { skill },
  }
end

-------------------------------------------------------------------------
-- Tier 8: Format Generators
-------------------------------------------------------------------------

--- Generate "format line" (gqq) exercise
--- Uses a short line that wraps predictably at textwidth
---@param skill table
---@return table
function M.gen_format_line(skill)
  -- Create a long line that should wrap
  -- Note: This exercise works best when textwidth is set
  -- For predictable testing, we use a line with natural break points
  local long_line = "This is a very long line of text that should be formatted and wrapped to fit within the standard text width of the editor."

  -- After gqq, the line should wrap (depends on textwidth setting)
  -- For exercise purposes, we verify any reformatting occurred
  -- Expected: line split at textwidth boundary (typically 80 chars)
  local expected_lines = {
    "This is a very long line of text that should be formatted and wrapped to fit",
    "within the standard text width of the editor.",
  }

  return {
    instruction = "Format the long line using gqq (wraps at textwidth)",
    buffer_content = { long_line },
    cursor_start = { 1, 0 },
    expected_lines = expected_lines,
    optimal_keys = { "g", "q", "q" },
    skills = { skill },
  }
end

--- Generate "auto-indent" (==) exercise
---@param skill table
---@return table
function M.gen_auto_indent(skill)
  -- Code with incorrect indentation
  local lines = {
    "function example()",
    "local x = 1",  -- Should be indented
    "  return x",
    "end",
  }

  -- Line 2 needs proper indentation
  local expected_lines = {
    "function example()",
    "  local x = 1",  -- Properly indented
    "  return x",
    "end",
  }

  return {
    instruction = "Auto-indent the current line using ==",
    buffer_content = lines,
    cursor_start = { 2, 0 },
    expected_lines = expected_lines,
    optimal_keys = { "=", "=" },
    skills = { skill },
  }
end

return M
