local M = {}

-- 8 distinct light/dark color pairs (high contrast)
local colors = {
  "#ffcccc", -- Very light red (almost pink)
  "#4caf50",   -- Green
  "#2196f3",   -- Blue
  "#ffeb3b",   -- Yellow
  "#9c27b0",   -- Purple
  "#ff9800",   -- Orange
  "#00bcd4",   -- Cyan
  "#f44336"    -- Dark red
}

-- Track state:
-- { [buffer_id] = {
--     used_words = { "word1", "word2" },  -- Tracked words
--     used_colors = { "color1", "color2" },  -- Colors assigned to words
--     available_colors = { "color3", "color4" }  -- Colors not currently in use
--   }
-- }
local state = {}
local ns_id = vim.api.nvim_create_namespace("ProgrammerWordHighlighter")

-- Initialize available colors for a buffer (all colors start available)
local function init_available_colors(buf)
  state[buf] = state[buf] or {
    used_words = {},
    used_colors = {},
    available_colors = vim.deepcopy(colors) -- Start with all colors available
  }
end

-- Create highlight groups for 8 colors
local function create_highlight_groups()
  for i, color in ipairs(colors) do
    local hl_name = "ProgrammerWordHighlight_" .. i
    vim.api.nvim_set_hl(0, hl_name, {
      bg = color,
      fg = "#000000", -- Dark text for contrast
      bold = true
    })
  end
end

-- Check if a position in a line is a whole "programming word"
local function is_whole_programming_word(line, start_pos, end_pos)
  local non_word_chars = "[^%w_]" -- Non-identifiers (spaces, symbols)
  local start_ok = (start_pos == 1) or (line:sub(start_pos - 1, start_pos - 1):match(non_word_chars) ~= nil)
  local end_ok = (end_pos == #line) or (line:sub(end_pos + 1, end_pos + 1):match(non_word_chars) ~= nil)
  return start_ok and end_ok
end

-- Update highlights (only whole programming words)
local function update_highlights(buf)
  vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1) -- Clear old highlights
  local buf_state = state[buf]

  for i, word in ipairs(buf_state.used_words) do
    local color = buf_state.used_colors[i]
    local hl_idx = vim.fn.index(colors, color) + 1 -- Get 1-based index
    local hl_name = "ProgrammerWordHighlight_" .. hl_idx

    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    for line_num, line in ipairs(lines) do
      local start_pos, end_pos = line:find(word, 1, true)
      while start_pos do
        if is_whole_programming_word(line, start_pos, end_pos) then
          vim.api.nvim_buf_set_extmark(
            buf, ns_id, line_num - 1, start_pos - 1,
            { end_col = end_pos, hl_group = hl_name, priority = 1000 }
          )
        end
        start_pos, end_pos = line:find(word, end_pos + 1, true)
      end
    end
  end
end

-- Toggle highlight for whole programming word under cursor
function M.highlight_cursor_word()
  local buf = vim.api.nvim_get_current_buf()
  local word = vim.fn.expand("<cword>")
  if not word or word == "" then
    vim.notify("No word under cursor!", vim.log.levels.WARN)
    return
  end

  init_available_colors(buf) -- Ensure buffer state exists
  local buf_state = state[buf]

  -- Toggle: Remove if already highlighted (free its color)
  local word_idx = vim.fn.index(buf_state.used_words, word)
  if word_idx ~= -1 then
    -- Get the color being freed
    local freed_color = table.remove(buf_state.used_colors, word_idx + 1)
    -- Remove the word
    table.remove(buf_state.used_words, word_idx + 1)
    -- Add the freed color BACK to available_colors (so it can be reused)
    table.insert(buf_state.available_colors, freed_color)
    -- vim.notify("Freed color for: " .. word, vim.log.levels.INFO)
    update_highlights(buf)
    return
  end

  -- Check if any colors are available (including freed ones)
  if #buf_state.available_colors == 0 then
    vim.notify("No more colors available! (Max 8 highlighted words)", vim.log.levels.WARN)
    return
  end

  -- Use the OLDEST available color (first in the available list)
  local next_color = table.remove(buf_state.available_colors, 1) -- Take first available
  table.insert(buf_state.used_words, word)
  table.insert(buf_state.used_colors, next_color)
  -- vim.notify("Highlighted: " .. word .. " (using freed color if available)", vim.log.levels.INFO)
  update_highlights(buf)
end

-- Clear all highlights in current buffer (reset all colors)
function M.clear_all_highlights()
  local buf = vim.api.nvim_get_current_buf()
  state[buf] = {
    used_words = {},
    used_colors = {},
    available_colors = vim.deepcopy(colors) -- Reset to all colors available
  }
  vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
  -- vim.notify("Cleared all highlights (all colors available again)", vim.log.levels.INFO)
end

-- Setup keybindings and highlights
function M.setup()
  create_highlight_groups()

  -- Toggle highlight (reuses freed colors first)
  vim.keymap.set("n", "<leader>m", M.highlight_cursor_word, {
    desc = "Toggle highlight",
    noremap = true
  })

  -- Clear all highlights
  vim.keymap.set("n", "<leader>M", M.clear_all_highlights, {
    desc = "Clear all highlights",
    noremap = true
  })
end

return M
