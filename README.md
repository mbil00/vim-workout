# vim-workout

A Neovim plugin that teaches vim through interactive, progressively unlocking exercises with educational feedback. Skills are randomly mixed into exercises once unlocked, creating natural spaced repetition.

## Features

- **Progressive Skill System** - Master basic motions before unlocking operators and text objects
- **Dynamic Exercise Generation** - Exercises are generated from your pool of unlocked skills
- **Educational Feedback** - See your keystrokes vs optimal solution with explanations
- **Mastery Tracking** - Struggling skills appear more often for focused practice
- **Persistent Progress** - Your progress is saved between sessions

## Requirements

- Neovim 0.8.0 or later

## Installation

### Option 1: Using a Plugin Manager (Recommended)

#### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "mbil00/vim-workout",
}
```

#### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use "mbil00/vim-workout"
```

#### [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'mbil00/vim-workout'
```

---

### Option 2: Manual Installation (One-Time Copy)

Copy the plugin files to your Neovim runtime path:

```bash
# Create the plugin directory if it doesn't exist
mkdir -p ~/.local/share/nvim/site/pack/plugins/start/

# Clone or copy the repository
cp -r /path/to/vim-workout ~/.local/share/nvim/site/pack/plugins/start/vim-workout
```

Or clone directly from the repository:

```bash
git clone https://github.com/mbil00/vim-workout.git \
  ~/.local/share/nvim/site/pack/plugins/start/vim-workout
```

---

### Option 3: Development Installation (Symlink)

For active development and testing, create a symlink to your working directory. This allows you to edit the plugin and see changes immediately without copying files.

```bash
# Create the plugin directory if it doesn't exist
mkdir -p ~/.local/share/nvim/site/pack/plugins/start/

# Create symlink from the pack directory to your development repo
ln -s /path/to/your/vim-workout ~/.local/share/nvim/site/pack/plugins/start/vim-workout
```

**Example** (using the actual development path):

```bash
ln -s ~/repos/vim-workout ~/.local/share/nvim/site/pack/plugins/start/vim-workout
```

To verify the symlink is working:

```bash
ls -la ~/.local/share/nvim/site/pack/plugins/start/vim-workout
```

To remove the development symlink later:

```bash
rm ~/.local/share/nvim/site/pack/plugins/start/vim-workout
```

> [!TIP]
> When developing, restart Neovim or run `:source %` on Lua files to reload changes.

---

## Usage

### Commands

| Command | Description |
|---------|-------------|
| `:VimWorkout` | Start a random exercise session |
| `:VimWorkoutSkills` | View skill tree and progress |
| `:VimWorkoutStats` | View detailed statistics |
| `:VimWorkoutReset` | Reset progress (with confirmation) |
| `:VimWorkoutFocus {skill}` | Practice a specific skill |

### Quick Start

1. Open Neovim
2. Run `:VimWorkout` to start your first exercise
3. Follow the on-screen instructions
4. Press `Enter` to proceed through exercises, `q` to quit

## Skill Progression

The plugin teaches vim skills in progressive tiers:

1. **Tier 1**: Basic motions (`h`, `j`, `k`, `l`)
2. **Tier 2**: Word motions (`w`, `b`, `e`, `W`, `B`, `E`)
3. **Tier 3**: Line motions (`0`, `^`, `$`)
4. **Tier 4**: Character search (`f`, `t`, `F`, `T`, `;`, `,`)
5. **Tier 5**: File navigation (`gg`, `G`, `%`, `{`, `}`)
6. **Tier 6**: Basic operators (`d`, `c`, `y`)
7. **Tier 7**: Text objects (`iw`, `aw`, `i"`, `a"`, etc.)

Skills unlock automatically as you master prerequisites (80% success rate with minimum 5 attempts).

## Progress Storage

Your progress is saved to:

```
~/.local/share/nvim/vim-workout/progress.json
```

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.
