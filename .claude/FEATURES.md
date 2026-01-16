# vim-workout Features

High-level summary of implemented features. For detailed session history, see `archive/sessions.md`.

---

## Core Infrastructure (Phase 1-2)

**Plugin Structure**
- Lua-based Neovim plugin with modular architecture
- Entry point: `plugin/vim-workout.lua` with user commands
- Core modules: `init.lua`, `ui.lua`, `session.lua`, `verifier.lua`, `progress.lua`

**Floating Window UI**
- Exercise prompts displayed in floating windows
- Feedback screens show keystroke comparison and tips
- Settings screen with interactive vim-style navigation

**Session Management** (`session.lua`)
- Keystroke capture via `vim.on_key()`
- Exercise state machine: ready -> capturing -> completing -> feedback
- `Ctrl-C` to abort, `Ctrl-R` to restart exercise
- 2-second completion delay to observe results before feedback

**Progress System** (`progress.lua`)
- Persistence to `~/.local/share/nvim/vim-workout/progress.json`
- Skill unlock: 80% success rate + 5 minimum attempts (configurable)
- Weighted random skill selection favors skills needing practice

---

## Motion Skills (Tier 1-5)

**Tier 1: Basic Movement** - h/j/k/l
- Count-based exercises (e.g., "move down 4 lines" -> `4j`)

**Tier 2: Word Motions** - w, b, e, W, B, E
- Word-based exercises with variable jump counts
- Position calculation handles word boundaries correctly

**Tier 3: Line Motions** - 0, ^, $
- Start/end of line exercises

**Tier 4: Character Search** - f, t, F, T, ;, ,
- Find/till exercises with characters from actual text
- Repeat-find (`;`, `,`) teaches combo patterns

**Tier 5: File Navigation** - gg, G, %, {, }
- Multi-line buffers for gg/G exercises
- Bracket matching with code templates for `%`
- Paragraph navigation for `{`/`}`

**Implementation**: `exercises/motions.lua` (~550 lines)

---

## Operator Skills (Tier 6)

**Delete**: d, dd, D
- Delete with motion (dw, d2w), delete line, delete to end

**Change**: c, cc, C
- Change with motion (cw), change line, change to end
- Exercises include replacement text in optimal solution

**Yank**: y, yy
- Line-wise yank+paste to verify (buffer state comparison)

**Key Design Decisions**:
- Buffer state verification instead of cursor position
- Yank simplified to `yy+p` for predictable verification
- Operators unlock after Tier 3 line motions mastered

**Implementation**: `exercises/operators.lua` (Tier 6 portion: ~320 lines)

---

## Text Object Skills (Tier 7)

**18 text objects implemented**:
- **Word**: iw, aw
- **Quotes**: i", a", i', a'
- **Brackets**: i), a), i], a], i}, a}, i>, a>
- **Paragraph**: ip, ap
- **Tags**: it, at

**Key Design Decisions**:
- Always paired with operator (d or c) - text objects need operators
- Cursor placed inside target area (middle of word, between quotes)
- Inner vs around distinction clearly demonstrated

**Implementation**: `exercises/text_objects.lua` (~740 lines)

---

## Advanced Operator Skills (Tier 8)

**9 advanced operators implemented**:

**Indent Operators**:
- `>` - Indent with motion (>j, >2j)
- `>>` - Indent current line
- `<` - Outdent with motion (<j)
- `<<` - Outdent current line

**Case Operators**:
- `gu` - Lowercase with motion (guw)
- `gU` - Uppercase with motion (gUw)
- `g~` - Toggle case with motion (g~w)

**Format Operators**:
- `gq` - Format/wrap text (gqq)
- `=` - Auto-indent code (==)

**Key Design Decisions**:
- Uses 2-space indentation for predictable verification
- Case exercises use word motion (guw) for simplicity
- Format exercises use controlled text for predictable wrapping
- Prerequisites chain from Tier 6 operators (d, c)

**Implementation**: `exercises/operators.lua` (~360 lines added)

---

## Settings System

**Configurable Options** (`settings.lua`):
| Setting | Default | Range |
|---------|---------|-------|
| `completion_delay_ms` | 2000 | 500-5000ms |
| `unlock_threshold` | 0.80 | 50-100% |
| `min_attempts_for_unlock` | 5 | 1-20 |
| `show_tips` | true | boolean |
| `accept_better_solutions` | true | boolean |

**Interactive UI**: `:VimWorkoutSettings` with j/k navigation, +/- adjustment

---

## Keystroke Equivalence

**Problem**: `D` marked suboptimal when `d$` was expected.

**Solution** (`verifier.lua`): Alias system accepts equivalent keystrokes:
- `D` <-> `d$`
- `C` <-> `c$`
- `x` <-> `dl`
- `X` <-> `dh`
- `s` <-> `cl`
- `S` <-> `cc`
- `Y` <-> `yy`

Also accepts fewer keystrokes when result is correct (user found better solution).

---

## Commands

| Command | Description |
|---------|-------------|
| `:VimWorkout` | Start practice session |
| `:VimWorkoutSkills` | View skill tree and progress |
| `:VimWorkoutStats` | View statistics |
| `:VimWorkoutReset` | Reset all progress |
| `:VimWorkoutFocus {skill}` | Practice specific skill |
| `:VimWorkoutSettings` | Open settings editor |
| `:VimWorkoutReload` | Reload plugin (dev) |
