# vim-workout Bug History

Documented issues with root causes and fixes. Includes code snippets for patterns likely to recur.

---

## Bug Reference Table

| # | Issue | Symptom | Root Cause | Fix Location |
|---|-------|---------|------------|--------------|
| 1 | Exercises after first never completed | First exercise worked, subsequent showed buffer but never completed | `state.practice_win` captured from floating window; buffer/window state inconsistent | `session.lua` |
| 2 | Unimplemented skills (W,B,E) completed instantly | Exercises showed "success" with 0 keystrokes | Fallback generator set `cursor_start == expected_cursor` | `exercise.lua` |
| 3 | Instant completion during setup | Exercises completed the moment they started | `CursorMoved` autocmd fired during initial positioning | `session.lua` |
| 4 | Mastery always showed 100% | Suboptimal keystrokes still showed 100% mastery | Mastery was `successes/attempts` (completion rate) not optimal rate | `session.lua`, `ui.lua` |
| 5 | "e" motion exercises never completed | End-of-word exercises impossible to complete | Position calculation added +1 for space after EVERY word including target | `exercise.lua` |
| 6 | Skills unlocking too fast | Higher tier skills unlocked after 1-2 exercises | No minimum attempt requirement | `progress.lua` |
| 7 | d$/c$ exercises never completed | Delete/change to end of line never detected completion | Expected line built with `table.concat` vs actual line substring | `exercises/operators.lua` |

---

## Detailed Bug Analysis

### Bug 1: Window State Inconsistency

**Symptom**: First exercise worked, subsequent exercises showed buffer but never registered completion.

**Root Cause**: `state.practice_win` was captured from `nvim_get_current_win()` which could return floating window after prompts closed. Buffer/window state became inconsistent between exercises.

**Fix** (`session.lua`):
- Save `original_win` at session start, not just `original_buf`
- Use `vim.fn.bufwinid(state.practice_buf)` to find correct window
- Explicitly focus `original_win` before creating practice buffer
- Add `pcall` wrappers for safer error handling

---

### Bug 3: Instant Completion During Setup

**Symptom**: Sometimes exercises would complete the moment they started.

**Root Cause**: `CursorMoved` autocmd could fire during initial cursor positioning. No delay between setup and completion checking.

**Fix** (`session.lua`):
- Added `state.ready` flag, initially `false`
- Set `state.ready = true` after 100ms delay via `vim.defer_fn`
- `check_completion()` returns early if `state.ready` is false

---

### Bug 5: "e" Motion Position Calculation (Recurring Pattern)

**Symptom**: End-of-word exercises were impossible to complete.

**Root Cause**: Position calculation added +1 for space after EVERY word including the target word.

**Pattern to watch**: When calculating positions from word lists, space handling between vs after words.

```lua
-- WRONG: Always added space
local target_col = -1
for i = 1, jump_count do
  target_col = target_col + #words[i] + 1  -- added space after every word
end

-- CORRECT: Only add space BETWEEN words
local target_col = -1
for i = 1, jump_count do
  target_col = target_col + #words[i]
  if i < jump_count then
    target_col = target_col + 1  -- only add space between words
  end
end
```

---

### Bug 7: d$/c$ Expected Content Mismatch (Recurring Pattern)

**Symptom**: Exercises using `d$` or `c$` never detected completion.

**Root Cause**: Cursor positioned at start of word N. `d$` deletes from cursor to end, leaving `"word1 word2 "` (with trailing space). But `expected_line` was built as `table.concat(words, " ")` = `"word1 word2"` (no trailing space).

**Pattern to watch**: When verifying buffer content after operators, use exact substring of original line, not reconstructed text.

```lua
-- WRONG: Reconstructed from words
local expected_line = table.concat(expected_words, " ")

-- CORRECT: Exact substring of original
local expected_line = line:sub(1, start_col)  -- substring up to cursor
```

---

## Feedback Window Persistence (Minor)

**Symptom**: After completing an exercise, the feedback window remained visible overlapping the next exercise.

**Root Cause**: Feedback window wasn't being tracked, so when `next_exercise()` was called, the old window wasn't explicitly closed.

**Fix**:
- Track `feedback_win` in session state
- Call `close_floating_windows()` in `reset_exercise_state()`
