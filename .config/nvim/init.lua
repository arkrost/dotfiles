--[[ Options ]]
vim.opt.number = true -- show absolute line numbers
vim.opt.relativenumber = true -- show relative line numbers
vim.opt.colorcolumn = '100' -- highlight max line length
vim.opt.signcolumn = 'yes' -- keep sign column visible

vim.opt.termguicolors = true -- enable true color

vim.opt.expandtab = true -- use spaces for tabs
vim.opt.shiftwidth = 2 -- indent width
vim.opt.tabstop = 2 -- tab display width
vim.opt.softtabstop = 2 -- tab key shift width

vim.opt.hlsearch = false -- no persistent search highlight
vim.opt.ignorecase = true -- ignore case by default

vim.opt.wrap = false -- disable line wrapping

vim.opt.swapfile = false -- disable swap files
vim.opt.undofile = true -- persist undo

vim.opt.title = true -- set terminal title
vim.opt.scrolloff = 10 -- keep context above/below cursor
vim.opt.sidescrolloff = 10 -- keep context left/right of cursor

vim.opt.inccommand = 'split' -- preview substitutions

vim.opt.list = true -- show whitespace chars
vim.opt.listchars = { tab = '» ', leadmultispace = '┊ ', trail = '␣', nbsp = '⍽' } -- whitespace glyphs

vim.opt.foldlevelstart = 99 -- open folds by default
vim.opt.foldmethod = 'indent' -- fold by indent

vim.opt.winborder = 'rounded' -- rounded floating borders
vim.opt.shortmess:append('aI')

vim.opt.path:append({ '**' }) -- finding files - search down into subfolders
vim.opt.wildignore:append({ '*/node_modules/*' })

vim.opt.grepprg = 'rg --vimgrep --smart-case --hidden'                      -- use ripgrep for :grep
vim.opt.completeopt = { 'menu', 'menuone', 'noinsert', 'fuzzy', 'preview' } -- completion menu behavior
vim.opt.pumheight = 10                                                      -- completion menu height

vim.opt.diffopt = {                                                         -- diff layout and heuristics
  'internal',
  'filler',
  'closeoff',
  'vertical',
  'algorithm:histogram',
  'indent-heuristic',
  'linematch:60',
  'inline:char'
}

--[[ Keymaps ]]

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
local map = vim.keymap.set

map('n', '<leader>w', '<cmd>update<cr>', { desc = 'Update' })
map('n', '<leader>q', '<cmd>bdelete<cr>', { desc = 'Close buffer' })
map('n', '<leader>Q', '<cmd>bdelete!<cr>', { desc = 'Close buffer (force)' })
map('n', '<leader>d', vim.diagnostic.open_float, { desc = 'Open diagnostic popup' })

-- clipboard register
map({ 'n', 'x' }, '<leader>\'', '<cmd>let @+=@"<CR>', { desc = '" to +' })
map({ 'n', 'x' }, '<leader>"', '<cmd>let @"=@+<CR>', { desc = '+ to "' })

-- terminal
map('t', '<Esc><Esc>', [[<C-\><C-n>]], { silent = true, desc = 'Exit terminal mode' })

-- macos
map('i', '<M-BS>', '<C-w>', { silent = true, desc = 'Kill word (mac)' })
map('c', '<M-BS>', '<C-w>', { desc = 'Kill word (mac)' })

-- tabs
for i = 1, 8 do
  map({ 'n', 't' }, '<leader>' .. i, '<cmd>tabnext ' .. i .. '<cr>')
end

--[[ Plugins ]]
vim.api.nvim_create_user_command('PackUpdate', function()
  vim.pack.update()
end, { desc = 'Update vim.pack plugins' })

vim.api.nvim_create_user_command('PackClean', function()
  local unused_plugins = {}

  for _, plugin in ipairs(vim.pack.get()) do
    if not plugin.active then
      table.insert(unused_plugins, plugin.spec.name)
    end
  end

  vim.pack.del(unused_plugins)
end, { desc = 'Cleanup unused vim.pack plugins' })

vim.pack.add({
  { src = 'https://github.com/neovim/nvim-lspconfig' },
  { src = 'https://github.com/folke/which-key.nvim' },
  { src = 'https://github.com/folke/snacks.nvim' },
  { src = 'https://github.com/stevearc/oil.nvim' },
  { src = 'https://github.com/lewis6991/gitsigns.nvim' },
  { src = 'https://github.com/mbbill/undotree' },
  { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range('^1') },
  --treesitter
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter-context' }, -- note: does not require setup({..})
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects', version = 'main' },
  -- themes
  { src = 'https://github.com/ellisonleao/gruvbox.nvim' },
  { src = 'https://github.com/vague2k/vague.nvim' },
  { src = 'https://github.com/arkrost/alabaster.nvim' },
})


require('which-key').setup({
  icons = {
    separator = '->',
    breadcrumb = '>>',
  }
})
map('n', '?', '<cmd>WhichKey<cr>', { desc = 'Help keys' })

require('oil').setup({
  view_options = {
    show_hidden = true,
  },
})
map('n', '-', '<cmd>Oil<cr>', { desc = 'Open oil' })

require('gitsigns').setup({
  attach_to_untracked = true,
})

vim.g.undotree_SetFocusWhenToggle = 1
map('n', '<leader>u', vim.cmd.UndotreeToggle, { desc = 'Undo tree' })

require('blink.cmp').setup({
  completion = {
    menu = {
      auto_show = false,
      draw = { gap = 3 },
      border = 'rounded',
    },
    documentation = {
      auto_show = false,
      window = {
        border = 'rounded'
      }
    },
    ghost_text = { enabled = true },
    trigger = { show_in_snippet = false },
  },
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
  },
  signature = { enabled = true },
  keymap = {
    preset = 'default',
    ['<C-z>'] = { 'show', 'select_next' },
    ['<C-e>'] = { 'show_documentation', 'hide_documentation' },
    ['<C-c>'] = { 'cancel', 'fallback_to_mappings' },
    ['<Tab>'] = { 'accept', 'snippet_forward', 'fallback' },
    ['<C-n>'] = { function(cmp) return cmp.select_next({ on_ghost_text = true }) end, 'fallback_to_mappings' },
    ['<C-p>'] = { function(cmp) return cmp.select_prev({ on_ghost_text = true }) end, 'fallback_to_mappings' },
    ['<CR>'] = {
      function(cmp)
        if cmp.is_menu_visible() then
          return cmp.accept()
        end
      end,
      'fallback'
    },
  },
  cmdline = {
    keymap = {
      ['<CR>'] = { 'accept', 'fallback' },
    },
  },
})

require('snacks').setup({
  indent = {
    indent = {
      char = '┊'
    },
    scope = {
      enabled = false
    }
  }
})

--[[ Pickers ]]
map('n', '<leader>/', function() Snacks.picker.grep({ hidden = true }) end, { desc = 'Grep' })
map('n', '<leader>b', function() Snacks.picker.buffers() end, { desc = 'Buffers' })
map('n', '<leader>o', function() Snacks.picker.treesitter() end, { desc = 'Outline' })
map('n', '<leader>f', function() Snacks.picker.files({ hidden = true }) end, { desc = 'Files' })
map('n', '<leader>gf', function() Snacks.picker.git_files() end, { desc = 'Git Files' })
map('n', '<leader>D', function() Snacks.picker.diagnostics_buffer() end, { desc = 'Buffer Diagnostics' })

-- lsp
map('n', "gd", function() Snacks.picker.lsp_definitions() end, { desc = "Goto Definition" })
map('n', "gD", function() Snacks.picker.lsp_declarations() end, { desc = "Goto Declaration" })
map('n', "grr", function() Snacks.picker.lsp_references() end, { desc = "References" })
map('n', "gri", function() Snacks.picker.lsp_implementations() end, { desc = "Goto Implementation" })

--[[ Treesitter ]]
local treesitter_langs = {
  'vimdoc',
  'kotlin',
  'java',
  'javascript',
  'typescript',
  'html',
  'json',
  'css',
  'rust',
  'toml',
  'yaml',
  'lua',
  'go',
  'markdown',
  'nix',
  'proto',
  'zig',
  'diff',
  'fish',
  'regex'
}

require('nvim-treesitter').install(treesitter_langs, { summary = false })

vim.api.nvim_create_autocmd('FileType', {
  pattern = treesitter_langs,
  callback = function()
    -- vim.wo.foldmethod = 'expr'
    -- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    -- vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    local ok, err = pcall(vim.treesitter.start)
    if not ok then
      vim.notify(('treesitter start failed: %s'):format(err), vim.log.levels.WARN)
    end
  end,
})

require('nvim-treesitter-textobjects').setup({
  select = {
    lookahead = true,
  },
})

local ts_select = function(obj)
  return function()
    return require('nvim-treesitter-textobjects.select').select_textobject(obj, 'textobjects')
  end
end

map({ 'x', 'o' }, 'aa', ts_select('@parameter.outer'))
map({ 'x', 'o' }, 'ia', ts_select('@parameter.inner'))
map({ 'x', 'o' }, 'af', ts_select('@function.outer'))
map({ 'x', 'o' }, 'if', ts_select('@function.inner'))
map({ 'x', 'o' }, 'ac', ts_select('@class.outer'))
map({ 'x', 'o' }, 'ic', ts_select('@class.inner'))

--[[ Theme ]]
require('gruvbox').setup({
  palette_overrides = {
    dark0 = '#1F1F28',
    dark1 = '#2A2A37',
    -- gruvbox-material
    bright_red = '#EA6962',
    bright_orange = '#E78A4E',
    bright_yellow = '#E9B143',
    bright_green = '#A9B665',
    bright_aqua = '#89B482',
    bright_blue = '#80AA9E',
    bright_purple = '#D3869B',
  },
  overrides = {
    SignColumn = { link = 'Normal' },
    Keyword = { link = 'GruvboxRed' },
    Operator = { link = 'GruvboxFg0' },
    Delimiter = { link = 'GruvboxFg0' },
    Identifier = { link = 'GruvboxFg0' },
    Function = { link = 'GruvboxBlue' },
    Constant = { link = 'Special' },
    Property = { link = 'GruvboxPurple' },
    ['@boolean'] = { link = 'Constant' },
    ['@number'] = { link = 'Constant' },
    ['@type.qualifier'] = { link = 'Special' },
    ['@keyword.conditional'] = { link = 'Conditional' },
    ['@keyword.return'] = { link = 'Conditional' },
    ['@keyword.exception'] = { link = 'Conditional' },
    ['@keyword.repeat'] = { link = 'Conditional' },
    ['@function.builtin'] = { link = 'Function' },
    ['@constant.builtin'] = { link = 'Constant' },
    ['@lsp.type.interface'] = { link = '@type' },
    ['@variable.member'] = { link = 'Property' },
    ['@lsp.type.property'] = { link = 'Property' },
  }
})

require('vague').setup({ transparent = true })
-- vim.cmd(':hi statusline guibg=NONE')

vim.cmd.colorscheme('alabaster')

-- [[ LSP ]]
vim.lsp.config['lua_ls'] = {
  settings = {
    Lua = {
      workspace = {
        library = {
          vim.env.VIMRUNTIME
        }
      }
    }
  }
}

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('MyLspOnAttach', {}),
  callback = function(args)
    -- `:Format` command
    vim.api.nvim_buf_create_user_command(args.buf, 'Format', function(_)
      vim.lsp.buf.format()
    end, { desc = 'Format current buffer with LSP' })

    -- `:Rename` command
    vim.api.nvim_buf_create_user_command(args.buf, 'Rename', function(_)
      vim.lsp.buf.rename()
    end, { desc = 'Rename symbol with LSP' })

    -- `:CodeActions` command
    vim.api.nvim_buf_create_user_command(args.buf, 'CodeActions', function(_)
      vim.lsp.buf.code_action()
    end, { desc = 'Code Actions' })
  end
})

vim.lsp.enable({ 'lua_ls', 'ts_ls', 'rust_analyzer', 'kotlin_lsp', 'zls' })
