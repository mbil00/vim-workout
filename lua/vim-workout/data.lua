-- vim-workout: Data module
-- Provides word lists and content for exercise generation

local M = {}

-- Common programming-related words
M.code_words = {
  "function", "return", "const", "let", "var", "class", "import", "export",
  "async", "await", "if", "else", "for", "while", "switch", "case", "break",
  "continue", "try", "catch", "throw", "new", "this", "super", "extends",
  "implements", "interface", "type", "enum", "public", "private", "protected",
  "static", "final", "abstract", "void", "int", "string", "boolean", "null",
  "undefined", "true", "false", "print", "console", "log", "error", "debug",
  "require", "module", "package", "struct", "def", "self", "None", "True",
  "False", "lambda", "yield", "from", "as", "with", "pass", "raise", "assert",
}

-- Common English words for prose
M.prose_words = {
  "the", "quick", "brown", "fox", "jumps", "over", "lazy", "dog", "and",
  "then", "runs", "away", "into", "forest", "where", "finds", "hidden",
  "treasure", "beneath", "ancient", "oak", "tree", "with", "golden",
  "leaves", "falling", "gently", "ground", "while", "wind", "whispers",
  "through", "branches", "above", "creating", "symphony", "nature",
  "sounds", "that", "echo", "valley", "below", "mountains", "rise",
  "majestically", "distance", "their", "peaks", "covered", "snow",
  "sparkling", "morning", "sunlight", "birds", "sing", "cheerful",
  "songs", "welcoming", "new", "day", "begins", "fresh", "start",
}

-- Variable names for code exercises
M.variable_names = {
  "count", "index", "value", "result", "data", "items", "list", "array",
  "map", "set", "key", "name", "user", "config", "options", "settings",
  "handler", "callback", "promise", "response", "request", "error",
  "message", "status", "state", "props", "context", "ref", "hook",
  "effect", "memo", "reducer", "action", "store", "dispatch", "selector",
  "component", "element", "node", "child", "parent", "root", "path",
  "url", "query", "params", "body", "headers", "method", "endpoint",
}

-- Function names for code exercises
M.function_names = {
  "init", "setup", "start", "stop", "run", "execute", "process",
  "handle", "create", "update", "delete", "get", "set", "fetch",
  "load", "save", "read", "write", "parse", "format", "validate",
  "transform", "convert", "encode", "decode", "encrypt", "decrypt",
  "connect", "disconnect", "send", "receive", "emit", "listen",
  "subscribe", "unsubscribe", "register", "unregister", "mount",
  "unmount", "render", "compile", "build", "test", "debug", "log",
}

--- Get random words from combined lists
---@param count number Number of words to get
---@return table words
function M.get_random_words(count)
  -- Combine code and prose words
  local all_words = {}
  for _, w in ipairs(M.code_words) do
    table.insert(all_words, w)
  end
  for _, w in ipairs(M.prose_words) do
    table.insert(all_words, w)
  end

  local result = {}
  for _ = 1, count do
    local idx = math.random(#all_words)
    table.insert(result, all_words[idx])
  end

  return result
end

--- Get a random code line
---@return string line
function M.get_random_code_line()
  local templates = {
    function()
      return "const " .. M.variable_names[math.random(#M.variable_names)] ..
        " = " .. M.function_names[math.random(#M.function_names)] .. "();"
    end,
    function()
      return "function " .. M.function_names[math.random(#M.function_names)] ..
        "(" .. M.variable_names[math.random(#M.variable_names)] .. ") {"
    end,
    function()
      return "if (" .. M.variable_names[math.random(#M.variable_names)] ..
        " === " .. M.variable_names[math.random(#M.variable_names)] .. ") {"
    end,
    function()
      return "return " .. M.variable_names[math.random(#M.variable_names)] ..
        "." .. M.function_names[math.random(#M.function_names)] .. "();"
    end,
    function()
      return "let " .. M.variable_names[math.random(#M.variable_names)] ..
        " = [" .. table.concat(M.get_random_words(3), ", ") .. "];"
    end,
  }

  return templates[math.random(#templates)]()
end

--- Get a random prose sentence
---@return string sentence
function M.get_random_prose_sentence()
  local words = M.get_random_words(math.random(6, 12))
  words[1] = words[1]:sub(1, 1):upper() .. words[1]:sub(2)
  return table.concat(words, " ") .. "."
end

--- Get random content (mixed code and prose)
---@param lines number Number of lines
---@return table lines
function M.get_random_content(lines)
  local result = {}
  for _ = 1, lines do
    if math.random() > 0.5 then
      table.insert(result, M.get_random_code_line())
    else
      table.insert(result, M.get_random_prose_sentence())
    end
  end
  return result
end

return M
