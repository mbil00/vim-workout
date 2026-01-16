# vim-workout Development Log

## Current Status: Phase 5 Complete (All Core Features)

All planned skill tiers implemented:
- **Tier 1-5**: Motion skills (h/j/k/l, w/b/e, 0/^/$, f/t/F/T/;/,, gg/G/%/{/})
- **Tier 6**: Operators (d/c/y, dd/cc/yy, D/C)
- **Tier 7**: Text objects (18 total: iw/aw, quotes, brackets, paragraph, tags)
- **Settings**: Configurable unlock threshold, completion delay, tips, keystroke equivalence

For feature details, see `FEATURES.md`. For bug history, see `BUGS.md`.

---

## File Structure

```
vim-workout/
├── plugin/vim-workout.lua      -- Entry point, commands
├── lua/vim-workout/
│   ├── init.lua                -- Main module
│   ├── ui.lua                  -- Floating windows, settings UI
│   ├── session.lua             -- Exercise flow, keystroke capture
│   ├── verifier.lua            -- Completion checking, keystroke comparison
│   ├── progress.lua            -- Persistence, unlocking
│   ├── settings.lua            -- User settings load/save
│   ├── data.lua                -- Word lists
│   ├── exercises/
│   │   ├── init.lua            -- Core: generate, weights, routing
│   │   ├── motions.lua         -- Motion exercise generators
│   │   ├── operators.lua       -- Operator exercise generators
│   │   └── text_objects.lua    -- Text object generators
│   └── skills/
│       ├── init.lua            -- Skill registry
│       ├── motions.lua         -- Motion skill definitions
│       ├── operators.lua       -- Operator skill definitions
│       └── text_objects.lua    -- Text object skill definitions
└── .claude/
    ├── PLAN.md                 -- Architecture & roadmap
    ├── FEATURES.md             -- Feature summaries
    ├── BUGS.md                 -- Bug history with root causes
    ├── DEVLOG.md               -- This file (current status)
    └── archive/
        └── sessions.md         -- Full session history
```

---

## Testing Notes

- Restart Neovim or use `:VimWorkoutReload` after code changes
- Use `:VimWorkoutReset` to clear corrupted progress data
- Progress stored at `~/.local/share/nvim/vim-workout/progress.json`
- Settings stored at `~/.local/share/nvim/vim-workout/settings.json`

---

## Commands

| Command | Description |
|---------|-------------|
| `:VimWorkout` | Start practice session |
| `:VimWorkoutSkills` | View skill tree |
| `:VimWorkoutStats` | View statistics |
| `:VimWorkoutReset` | Reset progress |
| `:VimWorkoutFocus {skill}` | Practice specific skill |
| `:VimWorkoutSettings` | Open settings |
| `:VimWorkoutReload` | Reload plugin (dev) |

---

## New Session Notes

<!-- Add notes for new development sessions below -->
