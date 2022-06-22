local api = vim.api
local buf, win
local position = 0

-- make the content in center by filling space
local function center(str)
  local width = api.nvim_win_get_width(0)
  local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
  return string.rep(" ", shift) .. str
end

-- open a float window with border api
local function open_window()
  buf = vim.api.nvim_create_buf(false, true)

  -- It was created as not listed buffer (first argument) and "scratch-buffer" (second argument; see :h scratch-buffer)
  -- Also we set it to be deleted when hidden bufhidden = wipe.
  local border_buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "whid")

  local width = vim.api.nvim_get_option("columns")
  local height = vim.api.nvim_get_option("lines")

  local win_height = math.ceil(height * 0.8 - 4)
  local win_width = math.ceil(width * 0.8)
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  -- win opt
  local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
  }

  -- a bigger win as border
  -- buf win ope
  local border_opts = {
    style = "minimal",
    relative = "editor",
    width = win_width + 2,
    height = win_height + 2,
    row = row - 1,
    col = col - 1,
  }

  -- border content
  local border_lines = { "╔" .. string.rep("═", win_width) .. "╗" }
  local middle_line = "║" .. string.rep(" ", win_width) .. "║"
  for i = 1, win_height do
    table.insert(border_lines, middle_line)
  end
  table.insert(border_lines, "╚" .. string.rep("═", win_width) .. "╝")
  -- fill border content
  vim.api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)

  -- open border win
  local border_win = vim.api.nvim_open_win(border_buf, true, border_opts)
  win = api.nvim_open_win(buf, true, opts)
  -- close buf_win when win close by autocmd
  api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "' .. border_buf)

  -- show cursorline
  vim.wo.cursorline = true

  -- the 0~2 line content
  -- the first line is header
  api.nvim_buf_set_lines(buf, 0, -1, false, { center("What have i done?"), "", "" })
  -- first line hightlight.
  -- We will link to existing default highlights group instead of setting color by ourselves.
  -- the higlight groups declared in "../plugin/whid.vim"
  api.nvim_buf_add_highlight(buf, -1, "WhidHeader", 0, 0, -1)
end

-- update buf content api
local function update_view(direction)
  -- Is nice to prevent user from editing interface, so
  -- we should enabled it before updating view and disabled after it.
  vim.bo.modifiable = true
  position = position + direction
  if position < 0 then -- HEAD~0 is the newest state
    position = 0
  end

  -- get content
  -- systemplist reture the resutl as list
  local result = vim.fn.systemlist("git diff-tree --no-commit-id --name-only -r HEAD~" .. position)

  -- if empty result
  if #result == 0 then
    table.insert(result, "")
  end

  -- a little indent
  for k, v in pairs(result) do
    result[k] = "  " .. result[k]
  end

  -- add HEAD~.. in buf as sub header
  api.nvim_buf_set_lines(buf, 1, 2, false, { center("HEAD~" .. position) })
  api.nvim_buf_set_lines(buf, 3, -1, false, result)

  api.nvim_buf_add_highlight(buf, -1, "whidSubHeader", 1, 0, -1)
  -- after update, disable modifiable
  vim.bo.modifiable = false
end

-- close current win api
local function close_window()
  api.nvim_win_close(win, true)
end

-- open file under cursor
local function open_file()
  local str = api.nvim_get_current_line()
  close_window()
  api.nvim_command("edit " .. str)
end

-- File list start at line 4, so we can prevent reaching above it
-- from bottm the end of the buffer will limit movment
local function move_cursor()
  local new_pos = math.max(4, api.nvim_win_get_cursor(win)[1] - 1)
  api.nvim_win_set_cursor(win, { new_pos, 0 })
end

-- map key in the buf
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
    api.nvim_buf_set_keymap(buf, "n", k, ':lua require"whid".' .. v .. "<cr>", {
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
  for k, v in ipairs(other_chars) do
    api.nvim_buf_set_keymap(buf, "n", v, "", { nowait = true, noremap = true, silent = true })
    api.nvim_buf_set_keymap(buf, "n", v:upper(), "", { nowait = true, noremap = true, silent = true })
    api.nvim_buf_set_keymap(buf, "n", "<c-" .. v .. ">", "", { nowait = true, noremap = true, silent = true })
  end
end

-- import core api
local function whid()
  position = 0
  open_window()
  set_mappings()
  update_view(0)
  api.nvim_win_set_cursor(win, { 4, 0 })
end

return {
  whid = whid,
  update_view = update_view,
  open_file = open_file,
  move_cursor = move_cursor,
  close_window = close_window,
}
