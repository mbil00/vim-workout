-- vim-workout: Progress tracking module
-- Persists skill mastery and session statistics

local M = {}

local settings = require("vim-workout.settings")

-- Default data directory
local data_dir = vim.fn.stdpath("data") .. "/vim-workout"
local progress_file = data_dir .. "/progress.json"

--- Load progress from disk
---@return table progress
function M.load()
  -- Ensure data directory exists
  vim.fn.mkdir(data_dir, "p")

  -- Try to read existing progress
  local file = io.open(progress_file, "r")
  if not file then
    return M.default_progress()
  end

  local content = file:read("*a")
  file:close()

  local ok, data = pcall(vim.json.decode, content)
  if not ok or type(data) ~= "table" then
    return M.default_progress()
  end

  -- Merge with defaults to ensure all fields exist
  return vim.tbl_deep_extend("keep", data, M.default_progress())
end

--- Save progress to disk
---@param prog table Progress data
function M.save(prog)
  vim.fn.mkdir(data_dir, "p")

  prog.last_session = os.date("!%Y-%m-%dT%H:%M:%SZ")

  local ok, json = pcall(vim.json.encode, prog)
  if not ok then
    vim.notify("vim-workout: Failed to encode progress", vim.log.levels.ERROR)
    return
  end

  local file = io.open(progress_file, "w")
  if not file then
    vim.notify("vim-workout: Failed to save progress", vim.log.levels.ERROR)
    return
  end

  file:write(json)
  file:close()
end

--- Create default progress structure
---@return table progress
function M.default_progress()
  return {
    skills = {
      motion_hjkl = { unlocked = true, attempts = 0, successes = 0, optimal = 0 },
    },
    total_exercises = 0,
    total_time_seconds = 0,
    current_streak = 0,
    last_session = nil,
  }
end

--- Reset all progress
function M.reset()
  local file = io.open(progress_file, "w")
  if file then
    file:write("{}")
    file:close()
  end
end

--- Unlock a skill
---@param prog table Progress data
---@param skill_id string Skill ID to unlock
function M.unlock_skill(prog, skill_id)
  prog.skills = prog.skills or {}
  prog.skills[skill_id] = prog.skills[skill_id] or {
    unlocked = false,
    attempts = 0,
    successes = 0,
    optimal = 0,
  }
  prog.skills[skill_id].unlocked = true
end

--- Record an exercise attempt
---@param prog table Progress data
---@param skill_id string Skill ID
---@param success boolean Whether the exercise was completed successfully
---@param optimal boolean Whether the solution was optimal
function M.record_attempt(prog, skill_id, success, optimal)
  prog.skills = prog.skills or {}
  prog.skills[skill_id] = prog.skills[skill_id] or {
    unlocked = true,
    attempts = 0,
    successes = 0,
    optimal = 0,
  }

  local skill = prog.skills[skill_id]
  skill.attempts = skill.attempts + 1

  if success then
    skill.successes = skill.successes + 1
  end

  if optimal then
    skill.optimal = skill.optimal + 1
  end

  -- Update totals
  prog.total_exercises = (prog.total_exercises or 0) + 1

  -- Update streak
  if success then
    prog.current_streak = (prog.current_streak or 0) + 1
  else
    prog.current_streak = 0
  end

  -- Check for skill unlocks
  M.check_unlocks(prog, skill_id)
end

--- Check if completing a skill should unlock new ones
---@param prog table Progress data
---@param completed_skill_id string The skill that was just practiced
function M.check_unlocks(prog, completed_skill_id)
  local skills_module = require("vim-workout.skills")
  local all_skills = skills_module.get_all()

  -- Get threshold settings
  local unlock_threshold = settings.get("unlock_threshold") or 0.80
  local min_attempts = settings.get("min_attempts_for_unlock") or 5

  for _, skill in ipairs(all_skills) do
    -- Skip already unlocked skills
    local skill_prog = prog.skills[skill.id]
    if skill_prog and skill_prog.unlocked then
      goto continue
    end

    -- Check prerequisites
    local prereqs_met = true
    for _, prereq_id in ipairs(skill.prerequisites or {}) do
      local prereq_prog = prog.skills[prereq_id]
      if not prereq_prog or not prereq_prog.unlocked then
        prereqs_met = false
        break
      end

      -- Check minimum attempts and mastery threshold
      if prereq_prog.attempts < min_attempts then
        prereqs_met = false
        break
      end

      local mastery = prereq_prog.successes / prereq_prog.attempts
      if mastery < unlock_threshold then
        prereqs_met = false
        break
      end
    end

    if prereqs_met and #(skill.prerequisites or {}) > 0 then
      M.unlock_skill(prog, skill.id)
      vim.notify("vim-workout: Unlocked skill '" .. skill.name .. "'!", vim.log.levels.INFO)
    end

    ::continue::
  end
end

--- Get mastery percentage for a skill
---@param prog table Progress data
---@param skill_id string Skill ID
---@return number mastery Between 0 and 1
function M.get_mastery(prog, skill_id)
  local skill = prog.skills and prog.skills[skill_id]
  if not skill or skill.attempts == 0 then
    return 0
  end
  return skill.successes / skill.attempts
end

return M
