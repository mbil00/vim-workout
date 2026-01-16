# Working with vim-workout

## Quick Reference

| Need | File |
|------|------|
| Architecture & roadmap | `.claude/PLAN.md` |
| What's implemented | `.claude/FEATURES.md` |
| Past bugs & patterns | `.claude/BUGS.md` |
| Current status | `.claude/DEVLOG.md` |
| Session history | `.claude/archive/sessions.md` |

## Development Workflow

1. **Before coding**: Read `FEATURES.md` for implemented features, `BUGS.md` for known patterns
2. **During coding**: Use `:VimWorkoutReload` to test changes without restarting Neovim
3. **After session**: Update `DEVLOG.md` "New Session Notes" section

## Updating Documentation

**FEATURES.md** - Update when:
- New skill tier added
- New command added
- Significant feature completed

**BUGS.md** - Update when:
- Bug fixed (add to table)
- Include code snippet only if pattern likely to recur

**DEVLOG.md** - Keep minimal:
- Update "Current Status" section
- Add brief session notes at bottom
- Move detailed session history to `archive/sessions.md`

## Key Files

```
lua/vim-workout/
├── session.lua      -- Exercise flow, keystroke capture
├── verifier.lua     -- Completion checking
├── exercises/*.lua  -- Exercise generators (motions, operators, text_objects)
└── skills/*.lua     -- Skill definitions and unlock requirements
```

## Testing

```vim
:VimWorkoutReload    " Reload after code changes
:VimWorkoutReset     " Clear corrupted progress
:VimWorkoutFocus X   " Test specific skill
```

Data: `~/.local/share/nvim/vim-workout/`
