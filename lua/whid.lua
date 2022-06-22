--[[
let &runtimepath.="," . getcwd()
]]

local api = vim.api
local buf, win

-- oepn window api
local function open_window()
  buf = vim.api.nvim_create_buf(false, true)
  local border_buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "whid")

  -- get dimensions
  local width = api.nvim_get_option("columns")
  local height = api.nvim_get_option("lines")

  -- calculate our floating window size
  local win_height = math.ceil(height * 0.8 - 4)
  local win_width = math.ceil(width * 0.8)

  -- and its starting position
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  -- set some options
  local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
  }

  -- a bigger buffer as boder
  local border_opts = {
    style = "minimal",
    relative = "editor",
    width = win_width + 2,
    height = win_height + 2,
    row = row - 1,
    col = col - 1,
  }
  -- fill border_buffer with "box-drawing" characters.
  local border_lines = { "╔" .. string.rep("═", win_width) .. "╗" }
  local middle_line = "║" .. string.rep(" ", win_width) .. "║"
  for i = 1, win_height do
    table.insert(border_lines, middle_line)
  end
  table.insert(border_lines, "╚" .. string.rep("═", win_width) .. "╝")
  vim.api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)

  local border_win = api.nvim_open_win(border_buf, true, border_opts)
  win = api.nvim_open_win(buf, true, opts)
  api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "' .. border_buf)
end

-- update content in buf
local position = 0
local function update_view(direction)
  position = position + direction -- git position
  if position < 0 then
    position = 0
  end -- HEAD~0 is the newest stat
  local result = vim.fn.systemlist("git diff-tree --no-commit-id --name-only -r HEAD~" .. position)
  -- with small indentation results will look better
  for k, _ in pairs(result) do
    result[k] = "  " .. result[k]
  end

  api.nvim_buf_set_lines(buf, 0, -1, false, result)

  -- add hightlight
  -- config hightlight in ../plugin/whid.vim
  -- add hightlight
  api.nvim_buf_add_highlight(buf, -1, "WhidHeader", 0, 0, -1)
  api.nvim_buf_add_highlight(buf, -1, "WhidSubHeader", 1, 0, -1)
  vim.bo.modifiable = false
end

-- open file under cursor
local function open_file()
  local str = api.nvim_get_current_line()
end

local function close_window()
  api.nvim_win_close(win, true)
end

-- Our file list start at line 4, so we can prevent reaching above it
-- from bottm the end of the buffer will limit movment
local function move_cursor()
  local new_pos = math.max(4, api.nvim_win_get_cursor(win)[1] - 1)
  api.nvim_win_set_cursor(win, { new_pos, 0 })
end

-- Open file under cursor
local function open_file()
  local str = api.nvim_get_current_line()
  close_window()
  api.nvim_command("edit " .. str)
end

-- user input
local function set_mappings()
  local mappings = {
    ["["] = "update_view(-1)",
    ["]"] = "update_view(1)",
    ["<cr>"] = "open_file()",
    h = "update_view(-1)",
    l = "update_view(1)",
    q = "close_window()",
    k = "move_cursor()",
  }
  for k, v in pairs(mappings) do
    api.nvim_buf_set_keymap(buf, "n", "k", 'lua require"whid"' .. v .. "<cr>", {
      nowait = true,
      noremap = true,
      silent = true,
    })
  end
  -- disable other key
  -- stylua: ignore
  local other_chars = {
    "a", "b", "c", "d", "e", "f", "g", "i", "n", "o", "p", "r", "s", "t", "u", "v", "w", "x", "y", "z",
  }
  for _, v in ipairs(other_chars) do
    api.nvim_buf_set_keymap(buf, "n", v, "", { nowait = true, noremap = true, silent = true })
    api.nvim_buf_set_keymap(buf, "n", v:upper(), "", { nowait = true, noremap = true, silent = true })
    api.nvim_buf_set_keymap(buf, "n", "<c-" .. v .. ">", "", { nowait = true, noremap = true, silent = true })
  end
end

local function whid()
  position = 0 -- if you want to preserve last displayed state just omit this line
  open_window()
  set_mappings()
  update_view(0)
  api.nvim_win_set_cursor(win, { 4, 0 }) -- set cursor on first list entry
end

return {
  whid = whid,
  --[[ update_view = update_view,
  open_file = open_file,
  move_cursor = move_cursor,
  close_window = close_window, ]]
}
