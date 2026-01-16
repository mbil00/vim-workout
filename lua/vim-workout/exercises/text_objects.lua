-- vim-workout: Text object exercise generators
-- Generators for Tier 7 text object skills (iw, aw, i", a", etc.)
-- Text objects are always used with operators (d, c, y)

local M = {}

local data = require("vim-workout.data")

-------------------------------------------------------------------------
-- Helper functions
-------------------------------------------------------------------------

--- Pick a random operator for text object exercises
---@return string op The operator key
---@return string op_name The operator name for instructions
local function random_operator()
  local ops = {
    { key = "d", name = "Delete" },
    { key = "c", name = "Change" },
  }
  local op = ops[math.random(#ops)]
  return op.key, op.name
end

--- Build expected line after deleting a range
---@param line string Original line
---@param start_col number Start column (0-indexed)
---@param end_col number End column (0-indexed, exclusive)
---@return string
local function delete_range(line, start_col, end_col)
  local before = line:sub(1, start_col)
  local after = line:sub(end_col + 1)
  return before .. after
end

--- Build expected line after changing a range
---@param line string Original line
---@param start_col number Start column (0-indexed)
---@param end_col number End column (0-indexed, exclusive)
---@param new_text string Replacement text
---@return string
local function change_range(line, start_col, end_col, new_text)
  local before = line:sub(1, start_col)
  local after = line:sub(end_col + 1)
  return before .. new_text .. after
end

-------------------------------------------------------------------------
-- Word Text Object Generators (iw, aw)
-------------------------------------------------------------------------

--- Generate inner word (diw) exercise
---@param skill table
---@return table
function M.gen_inner_word(skill)
  local words = data.get_random_words(7)
  local line = table.concat(words, " ")

  -- Target word (not first or last for better exercise)
  local target_idx = math.random(2, 5)
  local target_word = words[target_idx]

  -- Calculate cursor position (somewhere in the middle of target word)
  local cursor_col = 0
  for i = 1, target_idx - 1 do
    cursor_col = cursor_col + #words[i] + 1
  end
  -- Put cursor in middle of word
  cursor_col = cursor_col + math.floor(#target_word / 2)

  local op, op_name = random_operator()

  -- Build expected result
  local expected_line
  local optimal_keys
  local instruction

  if op == "d" then
    -- diw deletes word but leaves space
    local expected_words = {}
    for i, w in ipairs(words) do
      if i ~= target_idx then
        table.insert(expected_words, w)
      else
        table.insert(expected_words, "")  -- Leave the space
      end
    end
    expected_line = table.concat(expected_words, " "):gsub("  ", " ")
    optimal_keys = { "d", "i", "w" }
    instruction = op_name .. " the word '" .. target_word .. "' using diw"
  else
    -- ciw changes the word
    local new_word = data.get_random_words(1)[1]
    while new_word == target_word do
      new_word = data.get_random_words(1)[1]
    end

    local expected_words = {}
    for i, w in ipairs(words) do
      if i == target_idx then
        table.insert(expected_words, new_word)
      else
        table.insert(expected_words, w)
      end
    end
    expected_line = table.concat(expected_words, " ")
    optimal_keys = { "c", "i", "w" }
    for i = 1, #new_word do
      table.insert(optimal_keys, new_word:sub(i, i))
    end
    table.insert(optimal_keys, "<Esc>")
    instruction = "Change '" .. target_word .. "' to '" .. new_word .. "' using ciw"
  end

  return {
    instruction = instruction,
    buffer_content = { line },
    cursor_start = { 1, cursor_col },
    expected_lines = { expected_line },
    optimal_keys = optimal_keys,
    skills = { skill },
  }
end

--- Generate around word (daw) exercise
---@param skill table
---@return table
function M.gen_around_word(skill)
  local words = data.get_random_words(7)
  local line = table.concat(words, " ")

  -- Target word (not first or last)
  local target_idx = math.random(2, 5)
  local target_word = words[target_idx]

  -- Calculate cursor position (middle of target word)
  local cursor_col = 0
  for i = 1, target_idx - 1 do
    cursor_col = cursor_col + #words[i] + 1
  end
  cursor_col = cursor_col + math.floor(#target_word / 2)

  -- daw deletes word AND surrounding space
  local expected_words = {}
  for i, w in ipairs(words) do
    if i ~= target_idx then
      table.insert(expected_words, w)
    end
  end
  local expected_line = table.concat(expected_words, " ")

  return {
    instruction = "Delete '" .. target_word .. "' including space using daw",
    buffer_content = { line },
    cursor_start = { 1, cursor_col },
    expected_lines = { expected_line },
    optimal_keys = { "d", "a", "w" },
    skills = { skill },
  }
end

-------------------------------------------------------------------------
-- Quote Text Object Generators (i", a", i', a')
-------------------------------------------------------------------------

--- Generate inner double quote (di") exercise
---@param skill table
---@return table
function M.gen_inner_dquote(skill)
  local before_words = data.get_random_words(2)
  local quoted_words = data.get_random_words(math.random(2, 3))
  local after_words = data.get_random_words(2)

  local quoted_text = table.concat(quoted_words, " ")
  local line = table.concat(before_words, " ") .. ' "' .. quoted_text .. '" ' .. table.concat(after_words, " ")

  -- Find quote positions
  local quote_start = #table.concat(before_words, " ") + 2  -- after first quote
  local cursor_col = quote_start + math.floor(#quoted_text / 2)

  local op, op_name = random_operator()

  local expected_line
  local optimal_keys
  local instruction

  if op == "d" then
    expected_line = table.concat(before_words, " ") .. ' "" ' .. table.concat(after_words, " ")
    optimal_keys = { "d", "i", '"' }
    instruction = op_name .. " the text inside quotes using di\""
  else
    local new_text = data.get_random_words(1)[1]
    expected_line = table.concat(before_words, " ") .. ' "' .. new_text .. '" ' .. table.concat(after_words, " ")
    optimal_keys = { "c", "i", '"' }
    for i = 1, #new_text do
      table.insert(optimal_keys, new_text:sub(i, i))
    end
    table.insert(optimal_keys, "<Esc>")
    instruction = "Change quoted text to '" .. new_text .. "' using ci\""
  end

  return {
    instruction = instruction,
    buffer_content = { line },
    cursor_start = { 1, cursor_col },
    expected_lines = { expected_line },
    optimal_keys = optimal_keys,
    skills = { skill },
  }
end

--- Generate around double quote (da") exercise
---@param skill table
---@return table
function M.gen_around_dquote(skill)
  local before_words = data.get_random_words(2)
  local quoted_words = data.get_random_words(2)
  local after_words = data.get_random_words(2)

  local quoted_text = table.concat(quoted_words, " ")
  local line = table.concat(before_words, " ") .. ' "' .. quoted_text .. '" ' .. table.concat(after_words, " ")

  local quote_start = #table.concat(before_words, " ") + 2
  local cursor_col = quote_start + 1

  -- da" deletes quotes and content
  local expected_line = table.concat(before_words, " ") .. "  " .. table.concat(after_words, " ")

  return {
    instruction = "Delete the quoted text INCLUDING quotes using da\"",
    buffer_content = { line },
    cursor_start = { 1, cursor_col },
    expected_lines = { expected_line },
    optimal_keys = { "d", "a", '"' },
    skills = { skill },
  }
end

--- Generate inner single quote (di') exercise
---@param skill table
---@return table
function M.gen_inner_squote(skill)
  local before_words = data.get_random_words(2)
  local quoted_word = data.get_random_words(1)[1]
  local after_words = data.get_random_words(2)

  local line = table.concat(before_words, " ") .. " '" .. quoted_word .. "' " .. table.concat(after_words, " ")

  local quote_start = #table.concat(before_words, " ") + 2
  local cursor_col = quote_start + 1

  local op, op_name = random_operator()

  local expected_line
  local optimal_keys
  local instruction

  if op == "d" then
    expected_line = table.concat(before_words, " ") .. " '' " .. table.concat(after_words, " ")
    optimal_keys = { "d", "i", "'" }
    instruction = op_name .. " text inside single quotes using di'"
  else
    local new_text = data.get_random_words(1)[1]
    expected_line = table.concat(before_words, " ") .. " '" .. new_text .. "' " .. table.concat(after_words, " ")
    optimal_keys = { "c", "i", "'" }
    for i = 1, #new_text do
      table.insert(optimal_keys, new_text:sub(i, i))
    end
    table.insert(optimal_keys, "<Esc>")
    instruction = "Change to '" .. new_text .. "' using ci'"
  end

  return {
    instruction = instruction,
    buffer_content = { line },
    cursor_start = { 1, cursor_col },
    expected_lines = { expected_line },
    optimal_keys = optimal_keys,
    skills = { skill },
  }
end

--- Generate around single quote (da') exercise
---@param skill table
---@return table
function M.gen_around_squote(skill)
  local before_words = data.get_random_words(2)
  local quoted_word = data.get_random_words(1)[1]
  local after_words = data.get_random_words(2)

  local line = table.concat(before_words, " ") .. " '" .. quoted_word .. "' " .. table.concat(after_words, " ")

  local quote_start = #table.concat(before_words, " ") + 2
  local cursor_col = quote_start + 1

  local expected_line = table.concat(before_words, " ") .. "  " .. table.concat(after_words, " ")

  return {
    instruction = "Delete quoted text INCLUDING quotes using da'",
    buffer_content = { line },
    cursor_start = { 1, cursor_col },
    expected_lines = { expected_line },
    optimal_keys = { "d", "a", "'" },
    skills = { skill },
  }
end

-------------------------------------------------------------------------
-- Parentheses Text Object Generators (i), a))
-------------------------------------------------------------------------

--- Generate inner parentheses (di)) exercise
---@param skill table
---@return table
function M.gen_inner_paren(skill)
  local func_name = data.function_names[math.random(#data.function_names)]
  local args = data.get_random_words(math.random(2, 3))
  local args_text = table.concat(args, ", ")

  local line = func_name .. "(" .. args_text .. ");"

  -- Cursor inside parentheses
  local cursor_col = #func_name + 1 + math.floor(#args_text / 2)

  local op, op_name = random_operator()

  local expected_line
  local optimal_keys
  local instruction

  if op == "d" then
    expected_line = func_name .. "();"
    optimal_keys = { "d", "i", ")" }
    instruction = op_name .. " arguments inside parentheses using di)"
  else
    local new_arg = data.variable_names[math.random(#data.variable_names)]
    expected_line = func_name .. "(" .. new_arg .. ");"
    optimal_keys = { "c", "i", ")" }
    for i = 1, #new_arg do
      table.insert(optimal_keys, new_arg:sub(i, i))
    end
    table.insert(optimal_keys, "<Esc>")
    instruction = "Change arguments to '" .. new_arg .. "' using ci)"
  end

  return {
    instruction = instruction,
    buffer_content = { line },
    cursor_start = { 1, cursor_col },
    expected_lines = { expected_line },
    optimal_keys = optimal_keys,
    skills = { skill },
  }
end

--- Generate around parentheses (da)) exercise
---@param skill table
---@return table
function M.gen_around_paren(skill)
  local before = data.variable_names[math.random(#data.variable_names)]
  local args = data.get_random_words(2)
  local after = data.variable_names[math.random(#data.variable_names)]

  local line = before .. " (" .. table.concat(args, ", ") .. ") " .. after

  local cursor_col = #before + 2 + 2  -- Inside parens

  local expected_line = before .. "  " .. after

  return {
    instruction = "Delete the parentheses AND content using da)",
    buffer_content = { line },
    cursor_start = { 1, cursor_col },
    expected_lines = { expected_line },
    optimal_keys = { "d", "a", ")" },
    skills = { skill },
  }
end

-------------------------------------------------------------------------
-- Bracket Text Object Generators (i], a])
-------------------------------------------------------------------------

--- Generate inner bracket (di]) exercise
---@param skill table
---@return table
function M.gen_inner_bracket(skill)
  local var_name = data.variable_names[math.random(#data.variable_names)]
  local elements = data.get_random_words(3)
  local elements_text = table.concat(elements, ", ")

  local line = "const " .. var_name .. " = [" .. elements_text .. "];"

  local bracket_start = #("const " .. var_name .. " = [")
  local cursor_col = bracket_start + math.floor(#elements_text / 2)

  local op, op_name = random_operator()

  local expected_line
  local optimal_keys
  local instruction

  if op == "d" then
    expected_line = "const " .. var_name .. " = [];"
    optimal_keys = { "d", "i", "]" }
    instruction = op_name .. " array elements using di]"
  else
    local new_elem = data.variable_names[math.random(#data.variable_names)]
    expected_line = "const " .. var_name .. " = [" .. new_elem .. "];"
    optimal_keys = { "c", "i", "]" }
    for i = 1, #new_elem do
      table.insert(optimal_keys, new_elem:sub(i, i))
    end
    table.insert(optimal_keys, "<Esc>")
    instruction = "Change array to '[" .. new_elem .. "]' using ci]"
  end

  return {
    instruction = instruction,
    buffer_content = { line },
    cursor_start = { 1, cursor_col },
    expected_lines = { expected_line },
    optimal_keys = optimal_keys,
    skills = { skill },
  }
end

--- Generate around bracket (da]) exercise
---@param skill table
---@return table
function M.gen_around_bracket(skill)
  local before = data.variable_names[math.random(#data.variable_names)]
  local elements = data.get_random_words(2)
  local after = "end"

  local line = before .. " [" .. table.concat(elements, ", ") .. "] " .. after

  local cursor_col = #before + 3

  local expected_line = before .. "  " .. after

  return {
    instruction = "Delete brackets AND content using da]",
    buffer_content = { line },
    cursor_start = { 1, cursor_col },
    expected_lines = { expected_line },
    optimal_keys = { "d", "a", "]" },
    skills = { skill },
  }
end

-------------------------------------------------------------------------
-- Brace Text Object Generators (i}, a})
-------------------------------------------------------------------------

--- Generate inner brace (di}) exercise
---@param skill table
---@return table
function M.gen_inner_brace(skill)
  local var_name = data.variable_names[math.random(#data.variable_names)]
  local key = data.variable_names[math.random(#data.variable_names)]
  local value = data.variable_names[math.random(#data.variable_names)]
  local content = key .. ": " .. value

  local line = "const " .. var_name .. " = { " .. content .. " };"

  local brace_start = #("const " .. var_name .. " = { ")
  local cursor_col = brace_start + 2

  local op, op_name = random_operator()

  local expected_line
  local optimal_keys
  local instruction

  if op == "d" then
    expected_line = "const " .. var_name .. " = {  };"
    optimal_keys = { "d", "i", "}" }
    instruction = op_name .. " object content using di}"
  else
    local new_key = data.variable_names[math.random(#data.variable_names)]
    local new_content = new_key .. ": true"
    expected_line = "const " .. var_name .. " = { " .. new_content .. " };"
    optimal_keys = { "c", "i", "}" }
    for i = 1, #new_content do
      table.insert(optimal_keys, new_content:sub(i, i))
    end
    table.insert(optimal_keys, "<Esc>")
    instruction = "Change to '{ " .. new_content .. " }' using ci}"
  end

  return {
    instruction = instruction,
    buffer_content = { line },
    cursor_start = { 1, cursor_col },
    expected_lines = { expected_line },
    optimal_keys = optimal_keys,
    skills = { skill },
  }
end

--- Generate around brace (da}) exercise
---@param skill table
---@return table
function M.gen_around_brace(skill)
  local before = "config ="
  local content = data.variable_names[math.random(#data.variable_names)] .. ": true"
  local after = "end"

  local line = before .. " { " .. content .. " } " .. after

  local cursor_col = #before + 4

  local expected_line = before .. "  " .. after

  return {
    instruction = "Delete braces AND content using da}",
    buffer_content = { line },
    cursor_start = { 1, cursor_col },
    expected_lines = { expected_line },
    optimal_keys = { "d", "a", "}" },
    skills = { skill },
  }
end

-------------------------------------------------------------------------
-- Angle Bracket Text Object Generators (i>, a>)
-------------------------------------------------------------------------

--- Generate inner angle bracket (di>) exercise
---@param skill table
---@return table
function M.gen_inner_angle(skill)
  local tag_name = "div"
  local content = data.get_random_words(2)
  local content_text = table.concat(content, " ")

  local line = "<" .. tag_name .. " class=\"" .. content_text .. "\">"

  local cursor_col = #tag_name + 3  -- Inside the tag

  local op, op_name = random_operator()

  local expected_line
  local optimal_keys
  local instruction

  if op == "d" then
    expected_line = "<>"
    optimal_keys = { "d", "i", ">" }
    instruction = op_name .. " inside angle brackets using di>"
  else
    local new_content = "span"
    expected_line = "<" .. new_content .. ">"
    optimal_keys = { "c", "i", ">" }
    for i = 1, #new_content do
      table.insert(optimal_keys, new_content:sub(i, i))
    end
    table.insert(optimal_keys, "<Esc>")
    instruction = "Change to '<" .. new_content .. ">' using ci>"
  end

  return {
    instruction = instruction,
    buffer_content = { line },
    cursor_start = { 1, cursor_col },
    expected_lines = { expected_line },
    optimal_keys = optimal_keys,
    skills = { skill },
  }
end

--- Generate around angle bracket (da>) exercise
---@param skill table
---@return table
function M.gen_around_angle(skill)
  local before = "text"
  local tag = "span"
  local after = "more"

  local line = before .. " <" .. tag .. "> " .. after

  local cursor_col = #before + 3

  local expected_line = before .. "  " .. after

  return {
    instruction = "Delete angle brackets AND content using da>",
    buffer_content = { line },
    cursor_start = { 1, cursor_col },
    expected_lines = { expected_line },
    optimal_keys = { "d", "a", ">" },
    skills = { skill },
  }
end

-------------------------------------------------------------------------
-- Paragraph Text Object Generators (ip, ap)
-------------------------------------------------------------------------

--- Generate inner paragraph (dip) exercise
---@param skill table
---@return table
function M.gen_inner_paragraph(skill)
  local lines = {
    "",
    table.concat(data.get_random_words(6), " "),
    table.concat(data.get_random_words(5), " "),
    table.concat(data.get_random_words(6), " "),
    "",
    table.concat(data.get_random_words(4), " "),
  }

  -- Cursor on line 2 (middle of first paragraph)
  local cursor_line = 2

  -- dip deletes the paragraph content but leaves blank lines
  local expected_lines = {
    "",
    "",
    lines[5],
    lines[6],
  }

  return {
    instruction = "Delete the current paragraph using dip",
    buffer_content = lines,
    cursor_start = { cursor_line, 0 },
    expected_lines = expected_lines,
    optimal_keys = { "d", "i", "p" },
    skills = { skill },
  }
end

--- Generate around paragraph (dap) exercise
---@param skill table
---@return table
function M.gen_around_paragraph(skill)
  local lines = {
    table.concat(data.get_random_words(6), " "),
    table.concat(data.get_random_words(5), " "),
    "",
    table.concat(data.get_random_words(4), " "),
    table.concat(data.get_random_words(5), " "),
  }

  -- Cursor on line 1
  local cursor_line = 1

  -- dap deletes paragraph AND trailing blank line
  local expected_lines = {
    lines[4],
    lines[5],
  }

  return {
    instruction = "Delete the paragraph INCLUDING blank line using dap",
    buffer_content = lines,
    cursor_start = { cursor_line, 0 },
    expected_lines = expected_lines,
    optimal_keys = { "d", "a", "p" },
    skills = { skill },
  }
end

-------------------------------------------------------------------------
-- Tag Text Object Generators (it, at)
-------------------------------------------------------------------------

--- Generate inner tag (dit) exercise
---@param skill table
---@return table
function M.gen_inner_tag(skill)
  local tag = "div"
  local content = data.get_random_words(3)
  local content_text = table.concat(content, " ")

  local line = "<" .. tag .. ">" .. content_text .. "</" .. tag .. ">"

  -- Cursor in the content
  local cursor_col = #tag + 2 + math.floor(#content_text / 2)

  local op, op_name = random_operator()

  local expected_line
  local optimal_keys
  local instruction

  if op == "d" then
    expected_line = "<" .. tag .. "></" .. tag .. ">"
    optimal_keys = { "d", "i", "t" }
    instruction = op_name .. " content between tags using dit"
  else
    local new_content = data.get_random_words(1)[1]
    expected_line = "<" .. tag .. ">" .. new_content .. "</" .. tag .. ">"
    optimal_keys = { "c", "i", "t" }
    for i = 1, #new_content do
      table.insert(optimal_keys, new_content:sub(i, i))
    end
    table.insert(optimal_keys, "<Esc>")
    instruction = "Change tag content to '" .. new_content .. "' using cit"
  end

  return {
    instruction = instruction,
    buffer_content = { line },
    cursor_start = { 1, cursor_col },
    expected_lines = { expected_line },
    optimal_keys = optimal_keys,
    skills = { skill },
  }
end

--- Generate around tag (dat) exercise
---@param skill table
---@return table
function M.gen_around_tag(skill)
  local before = "text"
  local tag = "span"
  local content = data.get_random_words(2)
  local after = "more"

  local tagged = "<" .. tag .. ">" .. table.concat(content, " ") .. "</" .. tag .. ">"
  local line = before .. " " .. tagged .. " " .. after

  -- Cursor in the tagged content
  local cursor_col = #before + 1 + #tag + 2 + 2

  local expected_line = before .. "  " .. after

  return {
    instruction = "Delete the entire tag element using dat",
    buffer_content = { line },
    cursor_start = { 1, cursor_col },
    expected_lines = { expected_line },
    optimal_keys = { "d", "a", "t" },
    skills = { skill },
  }
end

return M
