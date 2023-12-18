if vim.g.vscode then
  return
end

--[[ Options ]]

vim.scriptencoding = 'utf-8'
vim.opt.encoding = 'utf-8'
vim.opt.fileencoding = 'utf-8'

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = 'yes'
vim.opt.colorcolumn = '100'

vim.opt.termguicolors = true

vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2

vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.ignorecase = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true

vim.opt.title = true
vim.opt.scrolloff = 10
vim.opt.sidescrolloff = 10

vim.opt.inccommand = 'split'
vim.opt.backspace = 'start,eol,indent'

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.foldlevelstart = 99
vim.opt.foldmethod = 'indent' -- or 'expr' to use treesitter

--[[ Keymaps ]]

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- do not yank
vim.keymap.set({ 'n', 'v' }, 'x', '"_x')

-- save position
vim.keymap.set('n', 'J', 'mzJ`z', { desc = 'Join lines' })

-- center screen
vim.keymap.set('n', '<C-d>', '<C-d>zzzv', { desc = 'Scroll screen down' })
vim.keymap.set('n', '<C-u>', '<C-u>zzzv', { desc = 'Scroll screen up' })
vim.keymap.set('n', 'n', 'nzzzv', { desc = 'Next match' })
vim.keymap.set('n', 'N', 'Nzzzv', { desc = 'Prev match' })

-- move lines
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move line down' })
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move line up' })

-- tabs
vim.keymap.set('n', '<C-t>', vim.cmd.tabnew, { silent = true, desc = 'New Tab' })
vim.keymap.set('n', 'wq', '<C-w>c', { desc = 'Close window' })
vim.keymap.set('n', ']t', vim.cmd.tabnext, { desc = 'Next tab' })
vim.keymap.set('n', '[t', vim.cmd.tabprevious, { desc = 'Prev tab' })

-- diagnostics
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- folds
vim.keymap.set('n', '[z', function()
  local count = vim.v.count1
  local curLnum = vim.api.nvim_win_get_cursor(0)[1]
  local cnt = 0
  local lnum
  for i = curLnum - 1, 1, -1 do
    if vim.fn.foldclosed(i) == i then
      cnt = cnt + 1
      lnum = i
      if cnt == count then
        break
      end
    end
  end
  if lnum then
    vim.cmd('norm! m`')
    vim.api.nvim_win_set_cursor(0, { lnum, 0 })
  end
end, { desc = 'Prev closed fold' })
vim.keymap.set('n', ']z', function()
  local count = vim.v.count1
  local curLnum = vim.api.nvim_win_get_cursor(0)[1]
  local lineCount = vim.api.nvim_buf_line_count(0)
  local cnt = 0
  local lnum
  for i = curLnum + 1, lineCount do
    if vim.fn.foldclosed(i) == i then
      cnt = cnt + 1
      lnum = i
      if cnt == count then
        break
      end
    end
  end
  if lnum then
    vim.cmd('norm! m`')
    vim.api.nvim_win_set_cursor(0, { lnum, 0 })
  end
end, { desc = 'Next closed fold' })

--[[ Plugins ]]

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup(
  {
    {
      'ellisonleao/gruvbox.nvim',
      opts = function()
        local palette = require('gruvbox').palette
        return {
          contrast = 'hard',
          overrides = {
            SignColumn = { link = 'GruvboxBg0' },
            Keyword = { link = 'GruvboxPurple' },
            Repeat = { link = 'GruvboxPurple' },
            Conditional = { link = 'GruvboxPurple' },
            Function = { link = 'GruvboxBlue' },
            Comment = { italic = true, fg = palette.bright_orange },
            Operator = { link = 'GruvboxFg1' },
            Delimiter = { link = 'GruvboxFg1' },
            ['@keyword.operator'] = { link = 'GruvboxPurple' },
            ['@text.todo.unchecked.markdown'] = { link = 'GruvboxYellow' },
            ['@text.todo.checked.markdown'] = { link = 'GruvboxFg1' },

            -- lua
            luaStatement = { link = 'GruvboxPurple' },
            luaCond = { link = 'GruvboxPurple' },
            luaCondElse = { link = 'GruvboxPurple' },
            luaFunction = { link = 'GruvboxPurple' },
            luaSymbolOperator = { link = 'GruvboxFg1' },
            luaTable = { link = 'GruvboxFg1' },
            ['@constructor.lua'] = { link = 'GruvboxFg1' }
          }
        }
      end,
      init = function()
        vim.cmd('colorscheme gruvbox')
      end
    },
    {
      'folke/which-key.nvim',
      event = 'VeryLazy',
      init = function()
        vim.opt.timeout = true
        vim.opt.timeoutlen = 300
      end,
      opts = {},
      keys = {
        { '?', '<cmd>:WhichKey<cr>', desc = 'Help keys' }
      },
    },
    {
      'nvim-telescope/telescope.nvim',
      lazy = false,
      dependencies = {
        'nvim-lua/plenary.nvim', --required
      },
      opts = {
        defaults = {
          path_display = { 'smart' }
        }
      },
      keys = {
        { '<leader>f', function() require('telescope.builtin').find_files() end, desc = 'Find files' },
        { '<leader>/', function() require('telescope.builtin').live_grep() end,  desc = 'Grep files' },
        { '<leader>b', function() require('telescope.builtin').buffers() end,    desc = 'Find buffers' }
      }
    },
    {
      'numToStr/Comment.nvim',
      dependencies = {
        { 'JoosepAlviste/nvim-ts-context-commentstring', opts = { enable_autocmd = false } }
      },
      event = { 'BufRead', 'BufNewFile' },
      keys = {
        { '<C-c>', '<Plug>(comment_toggle_linewise_current)', desc = 'Comment toggle linewise' },
        { '<C-c>', '<Plug>(comment_toggle_linewise_visual)',  mode = 'x',                      desc = 'Comment toggle linewise' }
      },
      opts = function()
        return {
          pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
        }
      end,
    },
    {
      'nvim-treesitter/nvim-treesitter',
      dependencies = {
        'windwp/nvim-ts-autotag',
        'nvim-treesitter/playground',
        'nvim-treesitter/nvim-treesitter-textobjects',
        { 'nvim-treesitter/nvim-treesitter-context', opts = {} },
      },
      build = ':TSUpdate',
      event = { 'BufReadPre', 'BufNewFile' },
      main = 'nvim-treesitter.configs',
      init = function()
        vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
      end,
      opts = {
        auto_install = false,
        ensure_installed = {
          'kotlin',
          'java',
          'javascript',
          'typescript',
          'html',
          'json',
          'css',
          'rust',
          'toml',
          'lua',
          'go',
          'markdown',
          'nix',
          'proto',
          'zig',
          'diff'
        },
        highlight = { enable = true },
        indent = { enable = true },
        autotag = { enable = true },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = '<C-Space>',
            node_incremental = '<C-Space>',
            scope_incremental = '<C-S>',
            node_decremental = '<M-Space>',
          },
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
            keymaps = {
              -- You can use the capture groups defined in textobjects.scm
              ['aa'] = { query = '@parameter.outer', desc = 'Select argument (outer)' },
              ['ia'] = { query = '@parameter.inner', desc = 'Select argument (inner)' },
              ['af'] = { query = '@function.outer', desc = 'Select function (outer)' },
              ['if'] = { query = '@function.inner', desc = 'Select function (inner)' },
              ['ac'] = { query = '@class.outer', desc = 'Select class (outer)' },
              ['ic'] = { query = '@class.inner', desc = 'Select class (inner)' },
            },
          },
          move = {
            enable = true,
            set_jumps = true, -- whether to set jumps in the jumplist
            goto_next_start = {
              [']]'] = { query = '@function.outer', desc = 'Next method start' },
              [']c'] = { query = '@class.outer', desc = 'Next class start' },
            },
            goto_next_end = {
              [']['] = { query = '@function.outer', desc = 'Next method end' },
              [']C'] = { query = '@class.outer', desc = 'Next class end' },
            },
            goto_previous_start = {
              ['[['] = { query = '@function.outer', desc = 'Prev method start' },
              ['[c'] = { query = '@class.outer', desc = 'Prev class start' },
            },
            goto_previous_end = {
              ['[]'] = { query = '@function.outer', desc = 'Prev method end' },
              ['[C'] = { query = '@class.outer', desc = 'Prev class end' }
            },
          },
          swap = {
            enable = true,
            swap_next = {
              ['<leader>ra'] = { query = '@parameter.inner', desc = 'Swap args' },
            },
            swap_previous = {
              ['<leader>rA'] = { query = '@parameter.inner', desc = 'Swap args backward' },
            },
          },
        },
      }
    },
    {
      'windwp/nvim-autopairs',
      opts = {
        enable_check_bracket_line = false,
        ignored_next_char = '[%w%.]',
        fast_wrap = {},
      },
      event = 'InsertEnter',
    },
    {
      'mbbill/undotree',
      cmd = 'UndotreeToggle',
      keys = {
        { '<leader>u', vim.cmd.UndotreeToggle, desc = 'Undo tree' }
      },
      init = function()
        vim.g.undotree_SetFocusWhenToggle = 1
      end,
    },
    {
      'lukas-reineke/indent-blankline.nvim',
      main = 'ibl',
      opts = {
        scope = {
          enabled = false
        },
        indent = {
          char = '┊',
        }
      },
      event = 'VeryLazy'
    },
    {
      'L3MON4D3/LuaSnip',
      dependencies = {
        'rafamadriz/friendly-snippets',
      },
      config = function()
        require('luasnip.loaders.from_vscode').lazy_load()
        require('luasnip.config').setup({})
      end
    },
    {
      'hrsh7th/nvim-cmp',
      dependencies = {
        'hrsh7th/cmp-nvim-lsp',
        'L3MON4D3/LuaSnip',
        'saadparwaiz1/cmp_luasnip',
        'onsails/lspkind.nvim'
      },
      opts = function()
        local cmp = require('cmp')
        local luasnip = require('luasnip')
        local lspkind = require('lspkind')
        return {
          snippet = {
            expand = function(args)
              luasnip.lsp_expand(args.body)
            end,
          },
          formatting = {
            format = lspkind.cmp_format({}),
          },
          mapping = cmp.mapping.preset.insert {
            ['<C-n>'] = cmp.mapping.select_next_item(),
            ['<C-p>'] = cmp.mapping.select_prev_item(),
            ['<C-d>'] = cmp.mapping.scroll_docs(-4),
            ['<C-f>'] = cmp.mapping.scroll_docs(4),
            ['<C-Space>'] = cmp.mapping.complete({}),
            ['<CR>'] = cmp.mapping.confirm {
              behavior = cmp.ConfirmBehavior.Replace,
              select = true,
            },
            ['<Tab>'] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
              elseif luasnip.expand_or_locally_jumpable() then
                luasnip.expand_or_jump()
              else
                fallback()
              end
            end, { 'i', 's' }),
            ['<S-Tab>'] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_prev_item()
              elseif luasnip.locally_jumpable(-1) then
                luasnip.jump(-1)
              else
                fallback()
              end
            end, { 'i', 's' }),
          },
          sources = {
            { name = 'nvim_lsp' },
            { name = 'luasnip' },
          }
        }
      end,
    },
    {
      'neovim/nvim-lspconfig',
      dependencies = {
        'nvim-telescope/telescope.nvim', -- see on_attach keys
        { 'folke/neodev.nvim',    opts = {} },
        { 'hrsh7th/cmp-nvim-lsp', dependencies = { 'hrsh7th/nvim-cmp' } }
      },
      event = { 'BufReadPre', 'BufNewFile' },
      config = function()
        vim.api.nvim_create_autocmd('LspAttach', {
          group = vim.api.nvim_create_augroup('UserLspConfig', {}),
          callback = function(ev)
            local nmap = function(keys, func, desc)
              vim.keymap.set('n', keys, func, { buffer = ev.buf, desc = desc })
            end

            nmap('<leader>rn', vim.lsp.buf.rename, 'Rename')
            nmap('<leader>ca', vim.lsp.buf.code_action, 'Code Action')

            nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, 'Document Symbols')
            nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Workspace Symbols')

            nmap('gd', require('telescope.builtin').lsp_definitions, 'Goto Definition')
            nmap('gr', require('telescope.builtin').lsp_references, 'Goto References')
            nmap('gt', require('telescope.builtin').lsp_type_definitions, 'Goto Type')
            nmap('gi', require('telescope.builtin').lsp_implementations, 'Goto Implementation')

            -- See `:help K` for why this keymap
            nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
            nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

            -- Create a command `:Format` local to the LSP buffer
            vim.api.nvim_buf_create_user_command(ev.buf, 'Format', function(_)
              vim.lsp.buf.format()
            end, { desc = 'Format current buffer with LSP' })
          end
        })

        local capabilities = vim.lsp.protocol.make_client_capabilities()
        capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

        local lspconfig = require('lspconfig')
        lspconfig.util.default_config = vim.tbl_deep_extend('force', lspconfig.util.default_config, {
          capabilities = capabilities,
        })

        lspconfig.rust_analyzer.setup({})
        lspconfig.lua_ls.setup({})
        lspconfig.zls.setup({})
        lspconfig.marksman.setup({})
      end
    },
  },
  {
    defaults = { lazy = true },
    install = {
      missing = true,
      colorscheme = { 'gruvbox', 'habamax' },
      performance = {
        rtp = {
          disabled_plugins = {
            'gzip',
            'tarPlugin',
            'tohtml',
            'tutor',
            'zipPlugin',
          },
        },
      },
    }
  }
)
