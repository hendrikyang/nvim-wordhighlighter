return {
  "hendrikyang/nvim-wordhighlighter",
  config = function()
    require("wordhighlighter").setup()
  end,
  lazy = false, -- Doubao said: keybindings won't work if lazy-loaded
}
