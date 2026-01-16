# vim-workout Session History

Archived session-by-session development history for reference.

---

## Session 2: Phase 3 - Operators Implementation (2025-01-15)

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

---

## Session 3: Exercise Module Restructure (2025-01-15)

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

## Session 4: Phase 4 - Text Objects Implementation (2025-01-16)

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

---

## Session 5: Completion Delay & Retry Feature (2025-01-16)

### What Was Added

#### Completion Delay
- After completing an exercise, a "Success!" indicator appears in the top-right corner
- User sees their completed change for 2 seconds before the feedback screen appears
- Allows users to observe the result of their action (deleted text, changed content, etc.)

#### Retry Functionality
- Press `Ctrl-R` during an exercise to restart it
- Resets buffer content to original state
- Resets cursor to starting position
- Clears captured keystrokes
- Shows "Exercise restarted" notification
- Useful when you accidentally hit wrong keys

### Implementation Details

#### New State Variables (session.lua)
```lua
state = {
  ...
  completing = false,  -- Prevents actions during 2-second delay
  indicator_win = nil,  -- Tracks completion indicator window
  feedback_win = nil,   -- Tracks feedback window
}
```

#### Window Tracking
- Added `close_floating_windows()` helper function
- Tracks both indicator and feedback windows in state
- Ensures windows are properly closed before showing new ones
- Fixes bug where feedback window persisted into next exercise

#### New Functions
- `M.restart_exercise()` - Resets exercise to initial state
- `close_floating_windows()` - Cleanup helper for floating windows

#### UI Changes
- `ui.show_completion_indicator()` - Small floating window showing success
- `ui.show_feedback()` now returns window handle for tracking
- Exercise prompt now shows: "During exercise: Ctrl-R to restart, Ctrl-C to abort"

### Keybindings During Exercise
- `Ctrl-C` - Abort exercise and end session
- `Ctrl-R` - Restart current exercise

### Files Modified
- `lua/vim-workout/session.lua` - Added completing state, window tracking, restart function
- `lua/vim-workout/ui.lua` - Added completion indicator, return window handle from show_feedback

---

## Session 6: Tier 4-5 Motion Generators (2025-01-16)

### What Was Added

Implemented proper exercise generators for all Tier 4 and Tier 5 motion skills, replacing the fallback generators that previously substituted `j` motions.

#### Tier 4: Character Search Motions (6 skills)

**`motion_f` - Find character forward:**
- Generates line with random words
- Picks a target character from a word in the middle of the line
- User presses `f{char}` to jump to that character
- Optimal: `{ "f", target_char }`

**`motion_t` - Till character forward:**
- Similar to `f` but cursor stops one position BEFORE the target
- User presses `t{char}` to jump to just before that character
- Optimal: `{ "t", target_char }`

**`motion_F` - Find character backward:**
- Starts cursor at end of line
- User presses `F{char}` to jump backward to character
- Optimal: `{ "F", target_char }`

**`motion_T` - Till character backward:**
- Starts cursor at end of line
- Cursor stops one position AFTER the target (moving backward)
- Optimal: `{ "T", target_char }`

**`motion_semicolon` - Repeat find (;):**
- Creates line with repeated distinctive characters (x, z, q, k)
- User must use `f{char}` then `;` to reach the second occurrence
- Teaches the combo pattern: `f` followed by `;` to repeat
- Optimal: `{ "f", char, ";" }`

**`motion_comma` - Repeat find reverse (,):**
- Starts cursor at end of line
- User must use `F{char}` then `,` to find the next occurrence in reverse
- Teaches the reverse repeat pattern
- Optimal: `{ "F", char, "," }`

#### Tier 5: File Navigation Motions (5 skills)

**`motion_gg` - Go to top:**
- Generates 10-line buffer
- Starts cursor on line 5-9
- User presses `gg` to jump to first line
- Optimal: `{ "g", "g" }`

**`motion_G` - Go to bottom:**
- Generates 10-line buffer
- Starts cursor on line 1
- User presses `G` to jump to last line
- Optimal: `{ "G" }`

**`motion_percent` - Matching bracket (%):**
- Uses predefined code templates with brackets: `()`, `[]`, `{}`
- Cursor starts on opening bracket
- User presses `%` to jump to matching closing bracket
- Templates include: if conditions, array access, function bodies, nested expressions
- Optimal: `{ "%" }`

**`motion_brace_open` - Paragraph up ({):**
- Generates 3-paragraph buffer with blank line separators
- Starts in third paragraph
- User presses `{` to jump to previous blank line
- Optimal: `{ "{" }`

**`motion_brace_close` - Paragraph down (}):**
- Generates 3-paragraph buffer with blank line separators
- Starts in first paragraph
- User presses `}` to jump to next blank line
- Optimal: `{ "}" }`

### Implementation Notes

#### Character Selection for f/t/F/T
- Characters are selected from actual words in the line (not injected)
- Position calculations account for word lengths and spaces
- For `t` and `T`, special care to ensure there's a valid position before/after the target

#### Repeat Find (; and ,) Design
- These skills require teaching the combo pattern (f then ;, F then ,)
- Uses distinctive characters (x, z, q, k) to avoid accidental matches
- Instruction explicitly tells user to use the combo

#### Bracket Matching Templates
- Pre-calculated positions to ensure accuracy
- Each template tests cursor start and expected end positions
- Covers common code patterns: conditionals, arrays, objects

### Files Modified
- `lua/vim-workout/exercises/motions.lua` - Added 11 new generator functions (325+ lines)
- `lua/vim-workout/exercises/init.lua` - Added 11 routing entries for Tier 4-5 skills

### Generator Functions Added
```lua
-- Tier 4: Character search
M.gen_find_char(skill)           -- f
M.gen_till_char(skill)           -- t
M.gen_find_char_backward(skill)  -- F
M.gen_till_char_backward(skill)  -- T
M.gen_repeat_find(skill)         -- ;
M.gen_repeat_find_reverse(skill) -- ,

-- Tier 5: File navigation
M.gen_goto_top(skill)            -- gg
M.gen_goto_bottom(skill)         -- G
M.gen_goto_line(skill, use_gg)   -- nG or ngg (helper, not routed)
M.gen_match_bracket(skill)       -- %
M.gen_paragraph_up(skill)        -- {
M.gen_paragraph_down(skill)      -- }
```

---

## Session 7: Settings Screen & Equivalent Keystrokes (2025-01-16)

### What Was Added

#### Part 1: Accept Equivalent/Better Keystrokes

**Problem**: Using `D` instead of `d$` was marked as suboptimal, even though it's more efficient.

**Solution** (verifier.lua):
- Added `KEYSTROKE_ALIASES` mapping shortcuts to expanded forms:
  - `D` -> `d$`
  - `C` -> `c$`
  - `x` -> `dl`
  - `X` -> `dh`
  - `s` -> `cl`
  - `S` -> `cc`
  - `Y` -> `yy`

- Updated `compare_keystrokes()` to accept:
  1. Exact matches
  2. Fewer keystrokes (user found a better solution)
  3. User keys that expand to match optimal (via aliases)
  4. Optimal keys that expand to match user keys (user used shortcut)
  5. Both expand to the same sequence

#### Part 2: Settings System

**New File**: `lua/vim-workout/settings.lua`
- Settings persisted to `~/.local/share/nvim/vim-workout/settings.json`
- Caching for performance
- Load/save/get/set/reset functions

**Configurable Settings**:

| Setting | Default | Description |
|---------|---------|-------------|
| `completion_delay_ms` | 2000 | Delay before showing feedback (500-5000ms) |
| `unlock_threshold` | 0.80 | Success rate to unlock next tier (50-100%) |
| `min_attempts_for_unlock` | 5 | Minimum attempts before unlock (1-20) |
| `show_tips` | true | Show educational tips |
| `accept_better_solutions` | true | Accept shorter/equivalent keystrokes as optimal |

#### Part 3: Interactive Settings UI

**New Command**: `:VimWorkoutSettings`

Opens an interactive floating window with vim-style navigation:
- `j`/`k` - Navigate between settings
- `+`/`-`/`h`/`l` - Adjust numeric values
- `Space`/`Enter` - Toggle boolean values
- `r` - Reset all to defaults
- `q`/`Esc` - Save and close

### Files Created/Modified

| File | Action | Changes |
|------|--------|---------|
| `lua/vim-workout/settings.lua` | Created | Settings load/save/defaults/cache |
| `lua/vim-workout/verifier.lua` | Modified | Keystroke aliases + equivalence logic |
| `lua/vim-workout/session.lua` | Modified | Uses `completion_delay_ms` setting |
| `lua/vim-workout/progress.lua` | Modified | Uses `unlock_threshold` and `min_attempts_for_unlock` |
| `lua/vim-workout/ui.lua` | Modified | Added `show_settings()` interactive editor |
| `lua/vim-workout/init.lua` | Modified | Added `show_settings()` function |
| `plugin/vim-workout.lua` | Modified | Registered `:VimWorkoutSettings` command |

### Implementation Notes

#### Settings Module Design
- Uses caching to avoid repeated file reads
- `clear_cache()` available for testing
- Merges user settings with defaults to handle new settings in updates

#### Keystroke Equivalence Logic
- Result is already verified correct before checking keystrokes
- If result is correct AND keystrokes are fewer -> user found better solution
- Alias expansion works bidirectionally (D<->d$ both ways)
