# vim-workout Development Log

## Project Overview
A Neovim plugin to learn vim through interactive, progressively unlocking exercises with educational feedback. Skills are randomly mixed into exercises once unlocked, creating natural spaced repetition.

## Current Status: Phase 4 Complete (Text Objects Added)

### What's Implemented
- Plugin structure with Lua modules
- Floating window UI for prompts and feedback
- Session management with keystroke capture
- Exercise generation for Tier 1-3 motions
- Progress persistence to `~/.local/share/nvim/vim-workout/`
- Skill unlock system (80% success rate + 5 minimum attempts)
- Optimal keystroke comparison with educational tips
- Development reload command (`:VimWorkoutReload`)

### Skills Implemented
- **Tier 1**: h/j/k/l (basic movement)
- **Tier 2**: w, b, e, W, B, E (word motions)
- **Tier 3**: 0, ^, $ (line motions)
- **Tier 4-5**: Defined but using fallback generator (f, t, F, T, gg, G, %, {, })
- **Tier 6**: d, c, y, dd, cc, yy, D, C (operators)
- **Tier 7**: iw, aw, i", a", i', a', i), a), i], a], i}, a}, i>, a>, ip, ap, it, at (text objects)

---

## Issues Encountered & Fixes

### Issue 1: Exercises after first one never completed
**Symptom**: First exercise worked, subsequent exercises showed buffer but never registered completion.

**Root Cause**:
- `state.practice_win` was captured from `nvim_get_current_win()` which could return floating window after prompts closed
- Buffer/window state became inconsistent between exercises

**Fix** (session.lua):
- Save `original_win` at session start, not just `original_buf`
- Use `vim.fn.bufwinid(state.practice_buf)` to find correct window for cursor checks
- Explicitly focus `original_win` before creating practice buffer
- Add `pcall` wrappers for safer error handling
- Properly restore original buffer in original window between exercises

---

### Issue 2: Unimplemented skills (W, B, E) completed instantly
**Symptom**: Exercises for W, B, E showed "success" immediately with 0 keystrokes.

**Root Cause**:
- Fallback generator set `cursor_start == expected_cursor` (both `{1, 0}`)
- Exercise completed before user could do anything

**Fix** (exercise.lua):
- Rewrote exercise generator with explicit routing table for each skill
- W, B, E now use same generators as w, b, e (just different key in optimal solution)
- Fallback generator creates valid "move down N lines" exercise that's always completable

---

### Issue 3: Instant completion during setup
**Symptom**: Sometimes exercises would complete the moment they started.

**Root Cause**:
- `CursorMoved` autocmd could fire during initial cursor positioning
- No delay between setup and completion checking

**Fix** (session.lua):
- Added `state.ready` flag, initially `false`
- Set `state.ready = true` after 100ms delay via `vim.defer_fn`
- `check_completion()` returns early if `state.ready` is false

---

### Issue 4: Mastery always showed 100%
**Symptom**: No matter how suboptimal the keystrokes, mastery displayed as 100%.

**Root Cause**:
- Mastery was calculated as `successes / attempts` (completion rate)
- Every completed exercise counted as success, even with jjjj instead of 4j

**Fix** (session.lua, ui.lua):
- Changed mastery display to `optimal / attempts` (optimal rate)
- Now shows how often you use the best keystrokes, not just complete exercises
- Skill unlocking still uses success rate (you need to complete exercises to advance)

---

### Issue 5: "e" motion exercises never completed
**Symptom**: End-of-word exercises were impossible to complete.

**Root Cause**:
- Position calculation added +1 for space after EVERY word including the target
- For "the quick", calculated position 9 instead of 8 (end of "quick")

**Fix** (exercise.lua):
```lua
-- Before (wrong):
local target_col = -1
for i = 1, jump_count do
  target_col = target_col + #words[i] + 1  -- always added space
end

-- After (correct):
local target_col = -1
for i = 1, jump_count do
  target_col = target_col + #words[i]
  if i < jump_count then
    target_col = target_col + 1  -- only add space BETWEEN words
  end
end
```

---

### Issue 6: Skills unlocking too fast
**Symptom**: Higher tier skills unlocked after just 1-2 exercises.

**Root Cause**:
- No minimum attempt requirement
- Instant completions from buggy exercises inflated success rate

**Fix** (progress.lua):
- Added `MIN_ATTEMPTS_FOR_UNLOCK = 5`
- Skills require 5+ attempts AND 80% success rate to unlock next tier

---

## Commands Available
- `:VimWorkout` - Start practice session
- `:VimWorkoutSkills` - View skill tree and progress
- `:VimWorkoutStats` - View statistics
- `:VimWorkoutReset` - Reset all progress
- `:VimWorkoutFocus {skill_id}` - Practice specific skill
- `:VimWorkoutReload` - Reload plugin (development)

---

## Next Steps (Phase 2+)

### Phase 2: Operators & Verification
- [ ] Add operator skills (d, c, y)
- [ ] Buffer state verification (not just cursor position)
- [ ] Combined exercises (operator + motion, e.g., "d2w")

### Phase 3: Text Objects
- [ ] iw, aw (inner/around word)
- [ ] i", a", i', a' (quotes)
- [ ] i), a), i], a], i}, a} (brackets)
- [ ] ip, ap (paragraph)

### Phase 4: Advanced Features
- [ ] Tier 4-5 motion generators (f, t, gg, G, %, {, })
- [ ] Visual mode exercises
- [ ] Registers & macros
- [ ] Better educational tips with examples

### Known Limitations
- Keystroke capture uses `vim.on_key()` which may have edge cases
- No timeout for exercises (user must complete or quit)
- Optimal solution is pre-calculated, not dynamically determined

---

## File Structure
```
vim-workout/
├── plugin/vim-workout.lua      -- Entry point, commands
├── lua/vim-workout/
│   ├── init.lua                -- Main module
│   ├── ui.lua                  -- Floating windows
│   ├── session.lua             -- Exercise flow, keystroke capture
│   ├── verifier.lua            -- Completion checking
│   ├── progress.lua            -- Persistence, unlocking
│   ├── data.lua                -- Word lists
│   ├── exercises/              -- Exercise generators (categorized)
│   │   ├── init.lua            -- Core: generate, weights, routing
│   │   ├── motions.lua         -- Motion exercise generators
│   │   ├── operators.lua       -- Operator exercise generators
│   │   └── text_objects.lua    -- Text object generators (stub)
│   └── skills/
│       ├── init.lua            -- Skill registry
│       ├── motions.lua         -- Motion skill definitions
│       └── operators.lua       -- Operator skill definitions
└── .claude/DEVLOG.md           -- This file
```

---

## Testing Notes
- Always restart Neovim or use `:VimWorkoutReload` after code changes
- Use `:VimWorkoutReset` to clear corrupted progress data
- Progress stored at `~/.local/share/nvim/vim-workout/progress.json`

---

## Session 2: Phase 3 - Operators Implementation (2026-01-15)

### What Was Added

#### New Files
- `lua/vim-workout/skills/operators.lua` - Operator skill definitions (Tier 6)

#### Operator Skills Implemented
- **operator_d** - Delete with motion (d{motion})
- **operator_c** - Change with motion (c{motion})
- **operator_y** - Yank with motion (y{motion})
- **operator_dd** - Delete entire line
- **operator_cc** - Change entire line
- **operator_yy** - Yank entire line
- **operator_D** - Delete to end of line
- **operator_C** - Change to end of line

#### Exercise Generators Added
All operators have custom exercise generators in `exercise.lua`:

1. **Delete exercises**:
   - `gen_delete_word` - Delete single word (dw)
   - `gen_delete_words` - Delete multiple words (d2w, d3w)
   - `gen_delete_to_end` - Delete to end of line (d$ or D)
   - `gen_delete_line` - Delete entire line (dd)

2. **Change exercises**:
   - `gen_change_motion` - Change word to new text (cw)
   - `gen_change_to_end` - Change to end of line (c$ or C)
   - `gen_change_line` - Change entire line (cc)

3. **Yank exercises**:
   - `gen_yank_motion` - Uses line yank (yy + p)
   - `gen_yank_line` - Yank and paste line (yy + p)

### Implementation Notes

#### Buffer State Verification
- Operator exercises use `expected_lines` instead of `expected_cursor`
- The verifier routes to `check_buffer_content()` which compares line by line
- Exercises complete when buffer matches expected state

#### Yank Exercise Simplification
- Originally planned `yw + p` (yank word and paste)
- Simplified to `yy + p` (duplicate line) because:
  - Character-wise paste (`p` after `yw`) has complex cursor behavior
  - Line-wise operations are more predictable for verification
  - Still teaches core yank concept effectively

#### Unlock System
Operators unlock when Tier 3 line motions are mastered:
- `operator_d` requires: `motion_0`, `motion_dollar`
- `operator_c` requires: `operator_d`
- `operator_y` requires: `motion_0`, `motion_dollar`
- Line-wise operators (dd, cc, yy) require their base operator
- End-of-line shortcuts (D, C) require base operator + `motion_dollar`

### Known Issues / Future Improvements

1. **Change exercises leave user in insert mode**
   - After `cw`, user types replacement text and hits `<Esc>`
   - Keystroke capture includes typed characters
   - Optimal comparison includes exact characters to type

2. **Yank verification is indirect**
   - Can't directly verify register contents
   - Exercise requires yank+paste to verify via buffer state

3. **No `de` vs `dw` distinction yet**
   - Both delete to end of word vs to start of next word
   - Could add more nuanced exercises later

### Files Modified
- `lua/vim-workout/skills/init.lua` - Added operator skill registration
- `lua/vim-workout/exercise.lua` - Added operator exercise generators

### Next Steps (Phase 4: Text Objects)
- [ ] Add text object skills (iw, aw, i", a", etc.)
- [ ] Create exercises for operator + text object combinations (diw, ci", etc.)
- [ ] Implement Tier 4-5 motion generators (f, t, gg, G, %, {, })

---

## Session 3: Exercise Module Restructure (2026-01-15)

### What Was Done

Refactored the monolithic `exercise.lua` (674 lines) into a categorized `exercises/` directory to improve maintainability and prepare for future skill categories.

### New Structure

```
exercises/
├── init.lua         -- Core: generate(), calculate_weights(), routing (119 lines)
├── motions.lua      -- Motion exercise generators: hjkl, w/b/e, 0/^/$ (223 lines)
├── operators.lua    -- Operator exercise generators: d/c/y, dd/cc/yy, D/C (316 lines)
└── text_objects.lua -- Stub for Phase 4 text object exercises
```

### Why This Structure

- **Mirrors `skills/`**: Exercise generators parallel skill definitions
- **Scales for future phases**: Easy to add `visual.lua`, `macros.lua`, etc.
- **Reduces file size**: Each file is now <320 lines vs 674 lines before

### Adding New Exercise Generators

When adding new exercises (e.g., for text objects):

1. Create generator functions in the appropriate file (e.g., `exercises/text_objects.lua`)
2. Add routing entry in `exercises/init.lua` under `M.generate_for_skill()`
3. Ensure generators return the standard exercise table structure:
   ```lua
   return {
     instruction = "...",
     buffer_content = { lines },
     cursor_start = { row, col },
     expected_cursor = { row, col },  -- OR expected_lines = { lines }
     optimal_keys = { "key1", "key2" },
     skills = { skill },
   }
   ```

### Files Changed
- Created: `lua/vim-workout/exercises/init.lua`
- Created: `lua/vim-workout/exercises/motions.lua`
- Created: `lua/vim-workout/exercises/operators.lua`
- Created: `lua/vim-workout/exercises/text_objects.lua`
- Modified: `lua/vim-workout/session.lua` (updated import)
- Deleted: `lua/vim-workout/exercise.lua`

---

## Session 4: Phase 4 - Text Objects Implementation (2026-01-16)

### What Was Added

#### New Files
- `lua/vim-workout/skills/text_objects.lua` - Text object skill definitions (Tier 7)

#### Text Object Skills Implemented (18 total)

**Word text objects:**
- `textobj_iw` - Inner word (diw, ciw)
- `textobj_aw` - Around word (daw)

**Quote text objects:**
- `textobj_i_dquote` - Inner double quote (di", ci")
- `textobj_a_dquote` - Around double quote (da")
- `textobj_i_squote` - Inner single quote (di', ci')
- `textobj_a_squote` - Around single quote (da')

**Bracket text objects:**
- `textobj_i_paren` - Inner parentheses (di), ci))
- `textobj_a_paren` - Around parentheses (da))
- `textobj_i_bracket` - Inner square brackets (di], ci])
- `textobj_a_bracket` - Around square brackets (da])
- `textobj_i_brace` - Inner curly braces (di}, ci})
- `textobj_a_brace` - Around curly braces (da})
- `textobj_i_angle` - Inner angle brackets (di>, ci>)
- `textobj_a_angle` - Around angle brackets (da>)

**Paragraph text objects:**
- `textobj_ip` - Inner paragraph (dip)
- `textobj_ap` - Around paragraph (dap)

**Tag text objects:**
- `textobj_it` - Inner tag (dit, cit)
- `textobj_at` - Around tag (dat)

#### Exercise Generators Added

All text objects have custom exercise generators in `exercises/text_objects.lua`:

1. **Word exercises** - Delete/change word while cursor is in middle of word
2. **Quote exercises** - Delete/change content inside or including quotes
3. **Bracket exercises** - Delete/change function args, array elements, object properties
4. **Paragraph exercises** - Delete paragraph blocks with/without trailing blank lines
5. **Tag exercises** - Delete/change HTML/XML tag content

### Implementation Notes

#### Text Objects Always Use Operators
- Unlike motions which can be practiced solo, text objects require an operator
- Exercise generator randomly picks `d` (delete) or `c` (change)
- This teaches the practical usage pattern (diw, ci", da}, etc.)

#### Cursor Placement
- Exercises place cursor INSIDE the target area (middle of word, between quotes, etc.)
- This mimics real-world usage where you're editing something you're looking at

#### Inner vs Around Distinction
- **Inner (i)**: Deletes/changes content only (quotes/brackets remain)
- **Around (a)**: Deletes/changes content AND surrounding delimiters/spaces
- Exercises demonstrate this difference clearly

#### Unlock System
Text objects unlock progressively after mastering operators:
- `textobj_iw` requires: `operator_d`, `operator_c`
- `textobj_aw` requires: `textobj_iw`
- Quote objects unlock after word objects
- Bracket objects unlock after word objects
- Tag objects unlock after angle bracket objects

### Files Modified
- `lua/vim-workout/skills/init.lua` - Added text object skill registration
- `lua/vim-workout/exercises/init.lua` - Added routing for 18 text object generators
- `lua/vim-workout/exercises/text_objects.lua` - Full implementation (was stub)

### Updated File Structure
```
vim-workout/
├── plugin/vim-workout.lua
├── lua/vim-workout/
│   ├── init.lua
│   ├── ui.lua
│   ├── session.lua
│   ├── verifier.lua
│   ├── progress.lua
│   ├── data.lua
│   ├── exercises/
│   │   ├── init.lua          -- Core + routing (now 138 lines)
│   │   ├── motions.lua       -- Motion generators (223 lines)
│   │   ├── operators.lua     -- Operator generators (316 lines)
│   │   └── text_objects.lua  -- Text object generators (741 lines)
│   └── skills/
│       ├── init.lua          -- Skill registry
│       ├── motions.lua       -- Motion skills (Tier 1-5)
│       ├── operators.lua     -- Operator skills (Tier 6)
│       └── text_objects.lua  -- Text object skills (Tier 7)
└── .claude/
    ├── PLAN.md
    └── DEVLOG.md
```

### Bug Fix: d$/D and c$/C exercises never completed

**Symptom**: Exercises using `d$` or `c$` never detected completion.

**Root Cause**:
- Cursor was positioned at start of a word (e.g., position after "word1 word2 ")
- `d$` deletes from cursor to end, leaving "word1 word2 " (with trailing space)
- But `expected_line` was built as `table.concat(words, " ")` = "word1 word2" (no trailing space)
- Buffer content never matched expected content

**Fix** (exercises/operators.lua):
```lua
-- Before (wrong):
local expected_line = table.concat(expected_words, " ")

-- After (correct):
local expected_line = line:sub(1, start_col)  -- Exact substring up to cursor
```

Same issue fixed for `c$`/`C` which also had a double-space bug.

---

### Next Steps (Phase 5+)
- [ ] Implement Tier 4-5 motion generators (f, t, gg, G, %, {, })
- [ ] Visual mode exercises
- [ ] Registers & macros
- [ ] Session configuration options

