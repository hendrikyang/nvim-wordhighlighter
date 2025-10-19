# nvim-wordhighlighter

A Neovim plugin to highlight programming symbols with 8 distinct colors.

## Features

- Highlight programming symbol
- 8 high-contrast colors
- Same symbol get highlighted in all buffers
- Toggles highlights with `<leader>m`  (*clear* highlight if already toggled)
- Clears all colors with `<leader>M`
- If colors are drained, there will be a notify: "*No more colors available! (Max 8)*"
- Then, either you have to manually select one color to be freed (*toggle* action), or you have to clear all colors

## Future improve

- Pop a window for us to select which one to remove highlight 
- OR, recycle the color: the first color get applied will be deprived for current requirement

## Notice

- This plugin is tested by me, but totally written by **[doubao](https://www.doubao.com)**
- My first github project was done by **AI** ^_^

## Install

- AstroNvim (lazy.vim)
  modify lua/plugins/user.lua: 
  1. comment the first line  
    `*if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE*`  (add '--' at the beginning)
  2. add following configuration:
      ```
      return {
          {
            "hendrikyang/nvim-wordhighlighter",
            config = function()
              require("wordhighlighter").setup()
            end,
            lazy = false
          },
      }
      ```
- TODO: test with other package manager (suggest you to ask *AI*, for example, *Doubao* ^_^)
