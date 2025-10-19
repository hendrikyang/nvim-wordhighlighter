local M = {}

-- 8 distinct light/dark color pairs (high contrast)
local colors = {
  "#ffc0cb", -- Pink
  "#4caf50", -- Green
  "#2196f3", -- Blue
  "#ffeb3b", -- Yellow
  "#9c27b0", -- Purple
  "#ff9800", -- Orange
  "#00bcd4", -- Cyan
  "#f44336"  -- Dark red
}

-- Track state globally (shared across all buffers)
local global_state = {
  used_words = {},
  used_colors = {},
  available_colors = vim.deepcopy(colors)
}

local ns_id = vim.api.nvim_create_namespace("ProgrammerWordHighlighter")

-- Create highlight groups for 8 colors
local function create_highlight_groups()
  for i, color in ipairs(colors) do
    local hl_name = "ProgrammerWordHighlight_" .. i
    vim.api.nvim_set_hl(0, hl_name, {
      bg = color,
      fg = "#000000",
      bold = true
    })
  end
end

-- Check if position is a whole programming word
local function is_whole_programming_word(line, start_pos, end_pos)
  local non_word_chars = "[^%w_]"
  local start_ok = (start_pos == 1) or (line:sub(start_pos - 1, start_pos - 1):match(non_word_chars) ~= nil)
  local end_ok = (end_pos == #line) or (line:sub(end_pos + 1, end_pos + 1):match(non_word_chars) ~= nil)
  return start_ok and end_ok
end

-- Update highlights for a specific buffer
local function update_buffer_highlights(buf)
  if not buf or not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)

  for i, word in ipairs(global_state.used_words) do
    local color = global_state.used_colors[i]
    local hl_idx = vim.fn.index(colors, color) + 1
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

-- Update highlights in all open buffers
local function update_all_highlights()
  local bufs = vim.api.nvim_list_bufs()
  for _, buf in ipairs(bufs) do
    update_buffer_highlights(buf)
  end
end

-- Toggle highlight for word under cursor (global)
function M.highlight_cursor_word()
  local word = vim.fn.expand("<cword>")
  if not word or word == "" then
    vim.notify("No word under cursor!", vim.log.levels.WARN)
    return
  end

  -- Toggle removal
  local word_idx = vim.fn.index(global_state.used_words, word)
  if word_idx ~= -1 then
    local freed_color = table.remove(global_state.used_colors, word_idx + 1)
    table.remove(global_state.used_words, word_idx + 1)
    table.insert(global_state.available_colors, freed_color)
    update_all_highlights()
    return
  end

  -- Add new highlight
  if #global_state.available_colors == 0 then
    vim.notify("No more colors available! (Max 8)", vim.log.levels.WARN)
    return
  end

  local next_color = table.remove(global_state.available_colors, 1)
  table.insert(global_state.used_words, word)
  table.insert(global_state.used_colors, next_color)
  update_all_highlights()
end

-- Clear all highlights globally
function M.clear_all_highlights()
  global_state = {
    used_words = {},
    used_colors = {},
    available_colors = vim.deepcopy(colors)
  }

  local bufs = vim.api.nvim_list_bufs()
  for _, buf in ipairs(bufs) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
    end
  end
end

-- Setup function with AstroNvim compatibility
function M.setup()
  create_highlight_groups()

  -- Fix: Ensure proper keybinding syntax (common cause of "invalid '" errors)
  vim.keymap.set("n", "<leader>m", M.highlight_cursor_word, {
    desc = "Toggle highlight",
    noremap = true,
    silent = true -- Add silent to prevent command output
  })

  vim.keymap.set("n", "<leader>M", M.clear_all_highlights, {
    desc = "Clear all highlights",
    noremap = true,
    silent = true
  })

  -- Auto-highlight new buffers
  vim.api.nvim_create_autocmd("BufEnter", { -- Use BufEnter instead of BufLoad for better compatibility
    pattern = "*",
    callback = function(args)
      if vim.api.nvim_buf_is_valid(args.buf) then
        update_buffer_highlights(args.buf)
      end
    end
  })

  update_all_highlights()
end

return M
