-- vim-workout: Exercise generator (core module)
-- Routes exercise generation to skill-specific generators

local M = {}

local data = require("vim-workout.data")

-- Lazy-load generators to avoid circular dependencies
local generators = {}

local function get_generators()
  if not generators.motions then
    generators.motions = require("vim-workout.exercises.motions")
    generators.operators = require("vim-workout.exercises.operators")
    generators.text_objects = require("vim-workout.exercises.text_objects")
  end
  return generators
end

--- Generate a random exercise from available skills
---@param unlocked_skills table List of unlocked skill definitions
---@param prog table Progress data
---@return table exercise Exercise definition
function M.generate(unlocked_skills, prog)
  -- Weight skills by inverse mastery (struggling skills appear more often)
  local weights = M.calculate_weights(unlocked_skills, prog)

  -- Select a skill based on weights
  local skill = M.weighted_select(unlocked_skills, weights)

  -- Generate exercise based on skill type
  return M.generate_for_skill(skill)
end

--- Calculate weights for skill selection (inverse mastery)
---@param skills table List of skills
---@param prog table Progress data
---@return table weights Weights indexed by skill id
function M.calculate_weights(skills, prog)
  local weights = {}

  for _, skill in ipairs(skills) do
    local skill_prog = prog.skills[skill.id]
    if skill_prog and skill_prog.attempts > 0 then
      local mastery = skill_prog.successes / skill_prog.attempts
      -- Inverse weight: lower mastery = higher weight
      weights[skill.id] = 2.0 - (mastery * 1.5)
    else
      -- New skill gets high weight
      weights[skill.id] = 1.5
    end
  end

  return weights
end

--- Select a skill based on weights
---@param skills table List of skills
---@param weights table Weights indexed by skill id
---@return table skill Selected skill
function M.weighted_select(skills, weights)
  local total_weight = 0
  for _, skill in ipairs(skills) do
    total_weight = total_weight + (weights[skill.id] or 1.0)
  end

  local rand = math.random() * total_weight
  local cumulative = 0

  for _, skill in ipairs(skills) do
    cumulative = cumulative + (weights[skill.id] or 1.0)
    if rand <= cumulative then
      return skill
    end
  end

  return skills[1]
end

--- Generate an exercise for a specific skill
---@param skill table Skill definition
---@return table exercise
function M.generate_for_skill(skill)
  local gens = get_generators()

  -- Route to appropriate generator based on skill ID
  local routing = {
    -- Tier 1: Basic motions
    motion_hjkl = gens.motions.gen_hjkl,
    -- Tier 2: Word motions
    motion_w = gens.motions.gen_word_forward,
    motion_b = gens.motions.gen_word_backward,
    motion_e = gens.motions.gen_word_end,
    motion_W = gens.motions.gen_word_forward,
    motion_B = gens.motions.gen_word_backward,
    motion_E = gens.motions.gen_word_end,
    -- Tier 3: Line motions
    motion_0 = gens.motions.gen_line_start,
    motion_caret = gens.motions.gen_first_nonblank,
    motion_dollar = gens.motions.gen_line_end,
    -- Tier 4: Character search
    motion_f = gens.motions.gen_find_char,
    motion_t = gens.motions.gen_till_char,
    motion_F = gens.motions.gen_find_char_backward,
    motion_T = gens.motions.gen_till_char_backward,
    motion_semicolon = gens.motions.gen_repeat_find,
    motion_comma = gens.motions.gen_repeat_find_reverse,
    -- Tier 5: File navigation
    motion_gg = gens.motions.gen_goto_top,
    motion_G = gens.motions.gen_goto_bottom,
    motion_percent = gens.motions.gen_match_bracket,
    motion_brace_open = gens.motions.gen_paragraph_up,
    motion_brace_close = gens.motions.gen_paragraph_down,
    -- Tier 6: Operators
    operator_d = gens.operators.gen_delete_motion,
    operator_c = gens.operators.gen_change_motion,
    operator_y = gens.operators.gen_yank_motion,
    operator_dd = gens.operators.gen_delete_line,
    operator_cc = gens.operators.gen_change_line,
    operator_yy = gens.operators.gen_yank_line,
    operator_D = gens.operators.gen_delete_to_end,
    operator_C = gens.operators.gen_change_to_end,
    -- Tier 7: Text Objects
    textobj_iw = gens.text_objects.gen_inner_word,
    textobj_aw = gens.text_objects.gen_around_word,
    textobj_i_dquote = gens.text_objects.gen_inner_dquote,
    textobj_a_dquote = gens.text_objects.gen_around_dquote,
    textobj_i_squote = gens.text_objects.gen_inner_squote,
    textobj_a_squote = gens.text_objects.gen_around_squote,
    textobj_i_paren = gens.text_objects.gen_inner_paren,
    textobj_a_paren = gens.text_objects.gen_around_paren,
    textobj_i_bracket = gens.text_objects.gen_inner_bracket,
    textobj_a_bracket = gens.text_objects.gen_around_bracket,
    textobj_i_brace = gens.text_objects.gen_inner_brace,
    textobj_a_brace = gens.text_objects.gen_around_brace,
    textobj_i_angle = gens.text_objects.gen_inner_angle,
    textobj_a_angle = gens.text_objects.gen_around_angle,
    textobj_ip = gens.text_objects.gen_inner_paragraph,
    textobj_ap = gens.text_objects.gen_around_paragraph,
    textobj_it = gens.text_objects.gen_inner_tag,
    textobj_at = gens.text_objects.gen_around_tag,
  }

  local generator = routing[skill.id]
  if generator then
    return generator(skill)
  end

  -- Fallback: generate a basic motion exercise
  return gens.motions.gen_basic_motion(skill)
end

return M
