# vim-workout: Neovim Plugin Implementation Plan

## Overview
A Neovim plugin that teaches vim through interactive, progressively unlocking exercises with educational feedback. Skills are randomly mixed into exercises once unlocked, creating natural spaced repetition.

## Core Concepts

### Skill System
- **Skills**: Individual vim capabilities (e.g., `w` motion, `d` operator, `iw` text object)
- **Skill Trees**: Grouped progressions (Motions → Operators → Text Objects → Combinations)
- **Unlock conditions**: Master prerequisite skills before unlocking new ones
- **Mastery**: Tracked per-skill based on success rate and optimal usage

### Exercise Generation
- Exercises are **generated dynamically** from the pool of unlocked skills
- Each exercise combines 1-3 skills (e.g., "delete inner word" = `d` + `iw`)
- Weighted randomness: struggling skills appear more often
- Difficulty scales with skill count and complexity

### Feedback System
- **Result verification**: Did the buffer reach the expected state?
- **Optimal comparison**: What keystrokes did you use vs. optimal?
- **Educational tips**: Explain why the optimal solution is better

---

## Architecture

```
vim-workout/
├── lua/
│   └── vim-workout/
│       ├── init.lua           -- Entry point, user commands
│       ├── skills/            -- Skill definitions by category
│       │   ├── init.lua       -- Skill registry & loader
│       │   ├── motions.lua    -- h,j,k,l,w,b,e,0,$,gg,G,f,t...
│       │   ├── operators.lua  -- d,c,y,>,<,=...
│       │   ├── text_objects.lua -- iw,aw,i",a",ip,ap...
│       │   └── combined.lua   -- Operator + motion/text-object combos
│       ├── exercises/         -- Exercise generators by category
│       │   ├── init.lua       -- Core: generate, weights, routing
│       │   ├── motions.lua    -- Motion exercise generators (Tier 1-3)
│       │   ├── operators.lua  -- Operator exercise generators (Tier 6)
│       │   └── text_objects.lua -- Text object generators (Tier 7, stub)
│       ├── session.lua        -- Practice session management
│       ├── verifier.lua       -- Result & keystroke verification
│       ├── progress.lua       -- Mastery tracking, persistence
│       └── ui.lua             -- Floating windows, prompts, feedback
├── data/
│   └── word_lists.lua         -- Random words/sentences for exercises
└── plugin/
    └── vim-workout.lua        -- Auto-registers :VimWorkout commands
```

---

## Skill Definition Schema

```lua
-- Example skill definition
{
  id = "motion_w",
  name = "Word Forward",
  key = "w",
  type = "motion",
  description = "Move forward to the start of the next word",
  prerequisites = { "motion_hjkl" },  -- Must master basic motions first
  exercises = {
    {
      instruction = "Move to the word '{target}'",
      generator = function(ctx) ... end,  -- Generates buffer content
      verifier = function(ctx) ... end,   -- Checks cursor position
      optimal = function(ctx) ... end,    -- Returns optimal keystrokes
    }
  }
}
```

---

## Skill Progression Tree

### Tier 1: Foundations
- `motion_hjkl` - Basic movement (h, j, k, l)

### Tier 2: Word Motions
- `motion_w` - Word forward (w)
- `motion_b` - Word backward (b)
- `motion_e` - End of word (e)
- `motion_W_B_E` - WORD variants (W, B, E)

### Tier 3: Line Motions
- `motion_0` - Line start (0)
- `motion_caret` - First non-blank (^)
- `motion_dollar` - Line end ($)

### Tier 4: Character Search
- `motion_f` - Find character (f{char})
- `motion_t` - Till character (t{char})
- `motion_F_T` - Reverse find/till (F, T)
- `motion_semicolon_comma` - Repeat search (;, ,)

### Tier 5: File Navigation
- `motion_gg_G` - File start/end/line (gg, G, {n}G)
- `motion_percent` - Matching bracket (%)
- `motion_braces` - Paragraph motion ({, })

### Tier 6: Basic Operators (unlocks after Tier 3)
- `operator_d` - Delete (d)
- `operator_c` - Change (c)
- `operator_y` - Yank (y)

### Tier 7: Text Objects (unlocks after Tier 6)
- `textobj_word` - Inner/around word (iw, aw)
- `textobj_quotes` - Inner/around quotes (i", a", i', a')
- `textobj_brackets` - Inner/around brackets (i), a), i], a}, etc.)
- `textobj_paragraph` - Inner/around paragraph (ip, ap)

### Tier 8: Advanced Operators
- `operator_indent` - Indent/dedent (>, <)
- `operator_case` - Case toggle (gu, gU, g~)
- `operator_format` - Format (gq, =)

### Tier 9: Visual Mode
- `visual_v` - Character-wise (v)
- `visual_V` - Line-wise (V)
- `visual_block` - Block-wise (Ctrl-v)

### Tier 10: Registers & Macros
- `registers` - Named registers ("a, "b, "+, etc.)
- `macros` - Record/playback (q{reg}, @{reg})

---

## Exercise Generation Algorithm

```lua
function generate_exercise(unlocked_skills, mastery_scores)
  -- 1. Weight skills by inverse mastery (struggling = higher weight)
  local weights = calculate_weights(unlocked_skills, mastery_scores)

  -- 2. Select 1-3 skills based on complexity level
  local selected = weighted_random_select(weights, num_skills)

  -- 3. Determine exercise type based on selected skills
  --    e.g., motion-only, operator+motion, operator+text-object
  local exercise_type = determine_type(selected)

  -- 4. Generate buffer content and target state
  local content = generate_content(exercise_type, selected)

  -- 5. Calculate optimal solution
  local optimal = calculate_optimal(selected, content)

  return {
    skills = selected,
    instruction = generate_instruction(selected, content),
    buffer_content = content.initial,
    expected_state = content.expected,
    cursor_start = content.cursor_start,
    optimal_keys = optimal,
  }
end
```

---

## Verification System

### Result Verification
```lua
function verify_result(expected, actual)
  -- Compare buffer content
  local content_match = expected.lines == actual.lines

  -- Compare cursor position (if relevant)
  local cursor_match = expected.cursor == actual.cursor

  return content_match and cursor_match
end
```

### Optimal Keystroke Comparison
```lua
function compare_keystrokes(user_keys, optimal_keys)
  local user_count = #user_keys
  local optimal_count = #optimal_keys

  return {
    completed = true,
    user_keystrokes = user_keys,
    optimal_keystrokes = optimal_keys,
    efficiency = optimal_count / user_count,  -- 1.0 = perfect
    extra_keys = user_count - optimal_count,
    is_optimal = user_keys == optimal_keys,
  }
end
```

---

## Session Flow

1. **:VimWorkout** - Start a workout session
2. Plugin shows floating window with current skill progress
3. User presses Enter to start exercise
4. Practice buffer opens with:
   - Header comment showing instruction
   - Generated content
   - Cursor at starting position
5. User performs the action
6. On completion (or timeout), plugin verifies:
   - Did buffer reach expected state?
   - What keystrokes were used?
7. Feedback window shows:
   - ✓/✗ Result
   - Your keystrokes vs optimal
   - Educational explanation
8. Mastery scores update
9. Next exercise generates (or session ends)

---

## User Commands

- `:VimWorkout` - Start random exercise session
- `:VimWorkoutSkills` - View skill tree and progress
- `:VimWorkoutStats` - View detailed statistics
- `:VimWorkoutReset` - Reset progress (with confirmation)
- `:VimWorkoutFocus {skill}` - Practice specific skill

---

## Progress Persistence

Store in `~/.local/share/nvim/vim-workout/progress.json`:

```json
{
  "skills": {
    "motion_hjkl": { "unlocked": true, "attempts": 50, "successes": 48, "optimal": 35 },
    "motion_w": { "unlocked": true, "attempts": 30, "successes": 28, "optimal": 20 },
    "operator_d": { "unlocked": false, "attempts": 0, "successes": 0, "optimal": 0 }
  },
  "total_exercises": 150,
  "total_time_seconds": 3600,
  "current_streak": 5,
  "last_session": "2026-01-15T10:30:00Z"
}
```

---

## UI Components

### Exercise Window (Floating)
```
┌─ vim-workout ─────────────────────────────┐
│ Exercise #42                              │
│                                           │
│ Delete the word "function"                │
│                                           │
│ Skills: d (delete) + w (word motion)      │
│ Press ENTER to start, q to quit           │
└───────────────────────────────────────────┘
```

### Feedback Window (Floating)
```
┌─ Result ──────────────────────────────────┐
│ ✓ Completed!                              │
│                                           │
│ Your keystrokes:  d w w w    (4 keys)     │
│ Optimal:          d 3 w      (3 keys)     │
│                                           │
│ Tip: Use {count} prefix to repeat motions │
│      d3w = delete 3 words in one command  │
│                                           │
│ Mastery: motion_w ████████░░ 80%          │
│                                           │
│ Press ENTER for next, q to quit           │
└───────────────────────────────────────────┘
```

---

## Implementation Phases

### Phase 1: Foundation ✅ COMPLETE
- [x] Project structure setup
- [x] Basic plugin loading & commands
- [x] Simple UI (floating windows)
- [x] Practice buffer creation

### Phase 2: Core Mechanics ✅ COMPLETE
- [x] Skill definition system
- [x] Tier 1-3 skills (basic motions)
- [x] Basic exercise generator (motion-only)
- [x] Result verification (cursor position)

### Phase 3: Operators & Verification
- [x] Operator skills (d, c, y) - Implemented: d, c, y, dd, cc, yy, D, C
- [x] Keystroke capture system
- [x] Buffer state verification - Uses expected_lines comparison
- [x] Optimal solution comparison

### Phase 4: Text Objects & Combinations
- [ ] Text object skills
- [ ] Combined exercise generation (operator + text object)
- [x] Educational feedback system

### Phase 5: Progress & Polish
- [x] Progress persistence
- [x] Mastery-weighted exercise selection
- [x] Skill unlock system
- [x] Statistics display

### Phase 6: Advanced Features
- [ ] Visual mode exercises
- [ ] Registers & macros
- [ ] Custom skill focus mode
- [ ] Session configuration

---

## Configuration

- **Content Types**: Both code snippets AND prose/text for versatile skill building
- **Unlock Threshold**: 80% success rate to advance to next tier
- **Minimum Attempts**: 5 attempts required before unlocking next tier
- **Mastery Display**: Shows optimal rate (optimal / attempts), not just success rate

---

## Key Technical Challenges

1. **Keystroke Capture**: Use `vim.on_key()` to capture all keystrokes during exercise
2. **Buffer State Comparison**: Compare line content and cursor position
3. **Optimal Solution Calculation**: Pre-calculate or use pattern matching
4. **Random Content Generation**: Word lists, sentence templates, code snippets (functions, variables, brackets)

---

## Testing Strategy

1. **Manual testing**: Run exercises, verify UI, check persistence
2. **Unit tests**: Skill definitions, exercise generation, verification logic
3. **Use plenary.nvim** for test framework (standard for Neovim plugins)

---

## Files Created

1. `plugin/vim-workout.lua` - Entry point
2. `lua/vim-workout/init.lua` - Core module
3. `lua/vim-workout/ui.lua` - Floating windows
4. `lua/vim-workout/session.lua` - Practice session
5. `lua/vim-workout/exercise.lua` - Exercise generator
6. `lua/vim-workout/verifier.lua` - Completion checking
7. `lua/vim-workout/progress.lua` - Persistence & unlocking
8. `lua/vim-workout/data.lua` - Word lists
9. `lua/vim-workout/skills/init.lua` - Skill registry
10. `lua/vim-workout/skills/motions.lua` - Motion skills (Tier 1-5)
11. `lua/vim-workout/skills/operators.lua` - Operator skills (Tier 6)
