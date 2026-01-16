-- vim-workout: Skills registry
-- Central registry for all skills

local M = {}

local motions = require("vim-workout.skills.motions")
local operators = require("vim-workout.skills.operators")
local text_objects = require("vim-workout.skills.text_objects")

-- All skills combined
local all_skills = {}

-- Build skill registry
local function init()
  all_skills = {}

  -- Add motion skills
  for _, skill in ipairs(motions.skills) do
    table.insert(all_skills, skill)
  end

  -- Add operator skills
  for _, skill in ipairs(operators.skills) do
    table.insert(all_skills, skill)
  end

  -- Add text object skills
  for _, skill in ipairs(text_objects.skills) do
    table.insert(all_skills, skill)
  end
end

--- Get all registered skills
---@return table skills
function M.get_all()
  if #all_skills == 0 then
    init()
  end
  return all_skills
end

--- Get a skill by ID
---@param skill_id string
---@return table|nil skill
function M.get_by_id(skill_id)
  for _, skill in ipairs(M.get_all()) do
    if skill.id == skill_id then
      return skill
    end
  end
  return nil
end

--- Get all unlocked skills for a user
---@param prog table Progress data
---@return table skills List of unlocked skill definitions
function M.get_unlocked(prog)
  local unlocked = {}

  for _, skill in ipairs(M.get_all()) do
    local skill_prog = prog.skills and prog.skills[skill.id]
    if skill_prog and skill_prog.unlocked then
      table.insert(unlocked, skill)
    end
  end

  return unlocked
end

--- Get skills by tier
---@param tier number Tier number
---@return table skills
function M.get_by_tier(tier)
  local result = {}
  for _, skill in ipairs(M.get_all()) do
    if skill.tier == tier then
      table.insert(result, skill)
    end
  end
  return result
end

return M
