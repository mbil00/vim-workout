-- vim-workout: Core module
-- Entry point that coordinates all plugin functionality

local M = {}

local ui = require("vim-workout.ui")
local session = require("vim-workout.session")
local skills = require("vim-workout.skills")
local progress = require("vim-workout.progress")

--- Start a new workout session
function M.start()
  -- Load progress data
  local prog = progress.load()

  -- Get unlocked skills
  local unlocked = skills.get_unlocked(prog)

  if #unlocked == 0 then
    -- First time user - unlock Tier 1 (basic motions)
    progress.unlock_skill(prog, "motion_hjkl")
    unlocked = skills.get_unlocked(prog)
  end

  -- Start the session
  session.start(unlocked, prog)
end

--- Show skill tree and progress
function M.show_skills()
  local prog = progress.load()
  ui.show_skill_tree(prog)
end

--- Show detailed statistics
function M.show_stats()
  local prog = progress.load()
  ui.show_stats(prog)
end

--- Reset all progress with confirmation
function M.reset_progress()
  ui.confirm("Reset all vim-workout progress? This cannot be undone.", function(confirmed)
    if confirmed then
      progress.reset()
      vim.notify("vim-workout: Progress reset!", vim.log.levels.INFO)
    end
  end)
end

--- Focus practice on a specific skill
---@param skill_id string The skill ID to practice
function M.focus_skill(skill_id)
  local skill = skills.get_by_id(skill_id)
  if not skill then
    vim.notify("vim-workout: Unknown skill '" .. skill_id .. "'", vim.log.levels.ERROR)
    return
  end

  local prog = progress.load()
  session.start_focused(skill, prog)
end

--- Show settings editor
function M.show_settings()
  ui.show_settings()
end

return M
