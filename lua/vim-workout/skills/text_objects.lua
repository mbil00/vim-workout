-- vim-workout: Text object skills
-- Defines text object skills (Tier 7): iw, aw, i", a", i), a), etc.

local M = {}

M.skills = {
  -- Tier 7: Text Objects (requires Tier 6 operators)

  -- Word text objects
  {
    id = "textobj_iw",
    name = "Inner Word",
    key = "iw",
    type = "text_object",
    tier = 7,
    description = "Select the inner word (word without surrounding spaces)",
    prerequisites = { "operator_d", "operator_c" },
  },
  {
    id = "textobj_aw",
    name = "Around Word",
    key = "aw",
    type = "text_object",
    tier = 7,
    description = "Select around word (word including surrounding space)",
    prerequisites = { "textobj_iw" },
  },

  -- Quote text objects
  {
    id = "textobj_i_dquote",
    name = "Inner Double Quote",
    key = 'i"',
    type = "text_object",
    tier = 7,
    description = "Select text inside double quotes",
    prerequisites = { "textobj_iw" },
  },
  {
    id = "textobj_a_dquote",
    name = "Around Double Quote",
    key = 'a"',
    type = "text_object",
    tier = 7,
    description = "Select text including double quotes",
    prerequisites = { "textobj_i_dquote" },
  },
  {
    id = "textobj_i_squote",
    name = "Inner Single Quote",
    key = "i'",
    type = "text_object",
    tier = 7,
    description = "Select text inside single quotes",
    prerequisites = { "textobj_i_dquote" },
  },
  {
    id = "textobj_a_squote",
    name = "Around Single Quote",
    key = "a'",
    type = "text_object",
    tier = 7,
    description = "Select text including single quotes",
    prerequisites = { "textobj_i_squote" },
  },

  -- Bracket text objects
  {
    id = "textobj_i_paren",
    name = "Inner Parentheses",
    key = "i)",
    type = "text_object",
    tier = 7,
    description = "Select text inside parentheses (also i( or ib)",
    prerequisites = { "textobj_aw" },
  },
  {
    id = "textobj_a_paren",
    name = "Around Parentheses",
    key = "a)",
    type = "text_object",
    tier = 7,
    description = "Select text including parentheses (also a( or ab)",
    prerequisites = { "textobj_i_paren" },
  },
  {
    id = "textobj_i_bracket",
    name = "Inner Brackets",
    key = "i]",
    type = "text_object",
    tier = 7,
    description = "Select text inside square brackets (also i[)",
    prerequisites = { "textobj_i_paren" },
  },
  {
    id = "textobj_a_bracket",
    name = "Around Brackets",
    key = "a]",
    type = "text_object",
    tier = 7,
    description = "Select text including square brackets (also a[)",
    prerequisites = { "textobj_i_bracket" },
  },
  {
    id = "textobj_i_brace",
    name = "Inner Braces",
    key = "i}",
    type = "text_object",
    tier = 7,
    description = "Select text inside curly braces (also i{ or iB)",
    prerequisites = { "textobj_i_paren" },
  },
  {
    id = "textobj_a_brace",
    name = "Around Braces",
    key = "a}",
    type = "text_object",
    tier = 7,
    description = "Select text including curly braces (also a{ or aB)",
    prerequisites = { "textobj_i_brace" },
  },

  -- Angle bracket text objects
  {
    id = "textobj_i_angle",
    name = "Inner Angle Brackets",
    key = "i>",
    type = "text_object",
    tier = 7,
    description = "Select text inside angle brackets (also i<)",
    prerequisites = { "textobj_i_bracket" },
  },
  {
    id = "textobj_a_angle",
    name = "Around Angle Brackets",
    key = "a>",
    type = "text_object",
    tier = 7,
    description = "Select text including angle brackets (also a<)",
    prerequisites = { "textobj_i_angle" },
  },

  -- Paragraph text objects
  {
    id = "textobj_ip",
    name = "Inner Paragraph",
    key = "ip",
    type = "text_object",
    tier = 7,
    description = "Select the inner paragraph (text block without surrounding blank lines)",
    prerequisites = { "textobj_aw" },
  },
  {
    id = "textobj_ap",
    name = "Around Paragraph",
    key = "ap",
    type = "text_object",
    tier = 7,
    description = "Select around paragraph (including trailing blank lines)",
    prerequisites = { "textobj_ip" },
  },

  -- Tag text objects (for HTML/XML)
  {
    id = "textobj_it",
    name = "Inner Tag",
    key = "it",
    type = "text_object",
    tier = 7,
    description = "Select text inside matching XML/HTML tags",
    prerequisites = { "textobj_i_angle" },
  },
  {
    id = "textobj_at",
    name = "Around Tag",
    key = "at",
    type = "text_object",
    tier = 7,
    description = "Select text including matching XML/HTML tags",
    prerequisites = { "textobj_it" },
  },
}

return M
