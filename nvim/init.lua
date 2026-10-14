-- ~/.config/nvim/init.lua

-- Line numbers
vim.opt.number = true
-- vim.opt.relativenumber = true  -- remove this line if you just want absolute numbers

-- Smart-case search (case-insensitive, but auto-switches to case-sensitive
-- if your search term contains an uppercase letter)
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.hlsearch = true

-- Tabs = 4 spaces
vim.opt.tabstop = 4      -- how many spaces a tab character visually looks like
vim.opt.shiftwidth = 4   -- how many spaces used for indent operations (>>, <<, autoindent)
vim.opt.softtabstop = 4  -- how many spaces the Tab key inserts
vim.opt.expandtab = true -- convert typed tabs into actual spaces

-- Scroll offset: keeps 15 lines visible above/below cursor at all times
vim.opt.scrolloff = 15

-- Show whitespace characters (spaces, tabs, trailing space, etc.)
vim.opt.list = true
vim.opt.listchars = {
  tab = "» ",
  trail = "·",
  space = "·",   -- shows every space as a middle dot
  nbsp = "␣",
}

-- System clipboard integration (yank/paste with y/p go to system clipboard)
vim.opt.clipboard = "unnamedplus"

local secondary_register = "a"

local function save_visual_to_secondary()
    -- Saving into a named register normally also modifies the unnamed register.
    -- Preserve both the unnamed register and system clipboard.
    local unnamed = vim.fn.getreg('"')
    local unnamed_type = vim.fn.getregtype('"')

    local clipboard = vim.fn.getreg("+")
    local clipboard_type = vim.fn.getregtype("+")

    -- Current visual selection -> register a
    vim.cmd('normal! "' .. secondary_register .. "y")

    -- Restore normal/system clipboard registers
    vim.fn.setreg('"', unnamed, unnamed_type)
    vim.fn.setreg("+", clipboard, clipboard_type)
end

-- Visual delete:
-- selection -> register a
-- system clipboard remains untouched
vim.keymap.set("x", "d", function()
    save_visual_to_secondary()
    vim.cmd('normal! gv"_d')
end, { noremap = true })

vim.keymap.set("x", "x", function()
    save_visual_to_secondary()
    vim.cmd('normal! gv"_d')
end, { noremap = true })

-- Visual change:
-- selection -> register a
-- system clipboard remains untouched
vim.keymap.set("x", "c", function()
    save_visual_to_secondary()
    vim.cmd('normal! gv"_c')
end, { noremap = true })

vim.keymap.set("x", "s", function()
    save_visual_to_secondary()
    vim.cmd('normal! gv"_c')
end, { noremap = true })

-- Visual paste:
-- replaced selection -> register a
-- pasted text comes from system clipboard
-- system clipboard remains unchanged
vim.keymap.set("x", "p", function()
    save_visual_to_secondary()
    vim.cmd('normal! gv"_d"+P')
end, { noremap = true })

vim.keymap.set("x", "P", function()
    save_visual_to_secondary()
    vim.cmd('normal! gv"_d"+P')
end, { noremap = true })

-- Ctrl+P -> paste secondary register
vim.keymap.set("n", "<C-p>", '"' .. secondary_register .. "p", {
    noremap = true,
})

vim.keymap.set("x", "<C-p>", '"' .. secondary_register .. "p", {
    noremap = true,
})

-- Make netrw's left/right splits open on the right side
vim.g.netrw_altv = 1

-- Open file explorer (netrw) with Ctrl+b
vim.keymap.set("n", "<C-b>", ":20Vex<CR>", { noremap = true, silent = true })

-- Ctrl+/ toggles comment on current line (normal mode)
-- and on the selected lines (visual mode)
vim.keymap.set("n", "<leader>c", "gcc", { remap = true, silent = true })
vim.keymap.set("v", "<leader>c", "gc", { remap = true, silent = true })
