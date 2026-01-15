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
}

return M
