-- vim-workout: Operator skills
-- Defines operator skills (Tier 6): d, c, y

local M = {}

M.skills = {
  -- Tier 6: Basic Operators (requires Tier 3 line motions)
  {
    id = "operator_d",
    name = "Delete",
    key = "d",
    type = "operator",
    tier = 6,
    description = "Delete text with a motion (d{motion})",
    prerequisites = { "motion_0", "motion_dollar" },
  },
  {
    id = "operator_c",
    name = "Change",
    key = "c",
    type = "operator",
    tier = 6,
    description = "Change text (delete and enter insert mode) with a motion (c{motion})",
    prerequisites = { "operator_d" },
  },
  {
    id = "operator_y",
    name = "Yank",
    key = "y",
    type = "operator",
    tier = 6,
    description = "Yank (copy) text with a motion (y{motion})",
    prerequisites = { "motion_0", "motion_dollar" },
  },

  -- Line-wise shortcuts
  {
    id = "operator_dd",
    name = "Delete Line",
    key = "dd",
    type = "operator",
    tier = 6,
    description = "Delete the entire current line",
    prerequisites = { "operator_d" },
  },
  {
    id = "operator_cc",
    name = "Change Line",
    key = "cc",
    type = "operator",
    tier = 6,
    description = "Change the entire current line",
    prerequisites = { "operator_c" },
  },
  {
    id = "operator_yy",
    name = "Yank Line",
    key = "yy",
    type = "operator",
    tier = 6,
    description = "Yank (copy) the entire current line",
    prerequisites = { "operator_y" },
  },

  -- Delete to end/start shortcuts
  {
    id = "operator_D",
    name = "Delete to End",
    key = "D",
    type = "operator",
    tier = 6,
    description = "Delete from cursor to end of line (same as d$)",
    prerequisites = { "operator_d", "motion_dollar" },
  },
  {
    id = "operator_C",
    name = "Change to End",
    key = "C",
    type = "operator",
    tier = 6,
    description = "Change from cursor to end of line (same as c$)",
    prerequisites = { "operator_c", "motion_dollar" },
  },

  -- Tier 8: Advanced Operators
  -- Indent operators
  {
    id = "operator_gt",
    name = "Indent",
    key = ">",
    type = "operator",
    tier = 8,
    description = "Indent text with a motion (>{motion})",
    prerequisites = { "operator_d" },
  },
  {
    id = "operator_gtgt",
    name = "Indent Line",
    key = ">>",
    type = "operator",
    tier = 8,
    description = "Indent the current line",
    prerequisites = { "operator_gt" },
  },
  {
    id = "operator_lt",
    name = "Outdent",
    key = "<",
    type = "operator",
    tier = 8,
    description = "Outdent (unindent) text with a motion (<{motion})",
    prerequisites = { "operator_gt" },
  },
  {
    id = "operator_ltlt",
    name = "Outdent Line",
    key = "<<",
    type = "operator",
    tier = 8,
    description = "Outdent (unindent) the current line",
    prerequisites = { "operator_lt" },
  },

  -- Case operators
  {
    id = "operator_gu",
    name = "Lowercase",
    key = "gu",
    type = "operator",
    tier = 8,
    description = "Make text lowercase with a motion (gu{motion})",
    prerequisites = { "operator_c" },
  },
  {
    id = "operator_gU",
    name = "Uppercase",
    key = "gU",
    type = "operator",
    tier = 8,
    description = "Make text uppercase with a motion (gU{motion})",
    prerequisites = { "operator_gu" },
  },
  {
    id = "operator_gtilde",
    name = "Toggle Case",
    key = "g~",
    type = "operator",
    tier = 8,
    description = "Toggle case of text with a motion (g~{motion})",
    prerequisites = { "operator_gU" },
  },

  -- Format operators
  {
    id = "operator_gq",
    name = "Format Text",
    key = "gq",
    type = "operator",
    tier = 8,
    description = "Format/wrap text with a motion (gq{motion})",
    prerequisites = { "operator_c" },
  },
  {
    id = "operator_eq",
    name = "Auto-indent",
    key = "=",
    type = "operator",
    tier = 8,
    description = "Auto-indent code with a motion (={motion})",
    prerequisites = { "operator_gtgt" },
  },
}

return M
