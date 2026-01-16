-- vim-workout: Learn vim through interactive, progressive exercises
-- This file is auto-loaded by Neovim and registers user commands

if vim.g.loaded_vim_workout then
  return
end
vim.g.loaded_vim_workout = true

-- Use global for reload capability
_G.vim_workout = require("vim-workout")

-- Main commands
vim.api.nvim_create_user_command("VimWorkout", function()
  _G.vim_workout.start()
end, { desc = "Start a vim-workout session" })

vim.api.nvim_create_user_command("VimWorkoutSkills", function()
  _G.vim_workout.show_skills()
end, { desc = "View skill tree and progress" })

vim.api.nvim_create_user_command("VimWorkoutStats", function()
  _G.vim_workout.show_stats()
end, { desc = "View detailed statistics" })

vim.api.nvim_create_user_command("VimWorkoutReset", function()
  _G.vim_workout.reset_progress()
end, { desc = "Reset all progress (with confirmation)" })

vim.api.nvim_create_user_command("VimWorkoutFocus", function(opts)
  _G.vim_workout.focus_skill(opts.args)
end, { nargs = 1, desc = "Practice a specific skill" })

vim.api.nvim_create_user_command("VimWorkoutSettings", function()
  _G.vim_workout.show_settings()
end, { desc = "Open vim-workout settings editor" })

-- Development: reload all modules
vim.api.nvim_create_user_command("VimWorkoutReload", function()
  -- Clear cached modules
  for name, _ in pairs(package.loaded) do
    if name:match("^vim%-workout") then
      package.loaded[name] = nil
    end
  end
  -- Reload main module
  _G.vim_workout = require("vim-workout")
  vim.notify("vim-workout: Reloaded!", vim.log.levels.INFO)
end, { desc = "Reload vim-workout plugin (development)" })
