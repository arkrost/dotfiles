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

vim.opt.foldenable = false

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

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
vim.keymap.set('n', '<C-t>', ':tabedit<CR>', { silent = true, desc = 'New Tab' })
vim.keymap.set('n', 'wq', '<C-w>c', { desc = 'Close window' })

-- diagnostics
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

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
      lazy = false,
      priority = 1000,
      opts = {
        contrast = 'hard'
      },
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
        { '<leader>f', function() require('telescope.builtin').find_files() end, 'n', desc = 'Find files' },
        { '<leader>/', function() require('telescope.builtin').live_grep() end,  'n', desc = 'Grep files' },
        { '<leader>b', function() require('telescope.builtin').buffers() end,    'n', desc = 'Find buffers' }
      }
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
              ['aa'] = '@parameter.outer',
              ['ia'] = '@parameter.inner',
              ['af'] = '@function.outer',
              ['if'] = '@function.inner',
              ['ac'] = '@class.outer',
              ['ic'] = '@class.inner',
            },
          },
          move = {
            enable = true,
            set_jumps = true, -- whether to set jumps in the jumplist
            goto_next_start = {
              [']m'] = '@function.outer',
              [']]'] = '@class.outer',
            },
            goto_next_end = {
              [']M'] = '@function.outer',
              [']['] = '@class.outer',
            },
            goto_previous_start = {
              ['[m'] = '@function.outer',
              ['[['] = '@class.outer',
            },
            goto_previous_end = {
              ['[M'] = '@function.outer',
              ['[]'] = '@class.outer',
            },
          },
          swap = {
            enable = true,
            swap_next = {
              ['<leader>ra'] = '@parameter.inner',
            },
            swap_previous = {
              ['<leader>rA'] = '@parameter.inner',
            },
          },
        },
      },
      config = function(_, opts)
        vim.wo.foldmethod = 'expr'
        vim.wo.foldexpr = 'nvim_treesitter#foldexpr()'
        require('nvim-treesitter.configs').setup(opts)
      end
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
      init = function()
        vim.g.undotree_SetFocusWhenToggle = 1
        vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle, { desc = 'Undo tree' })
      end,
    },
    {
      'lukas-reineke/indent-blankline.nvim',
      enabled = false,
      main = 'ibl',
      opts = {
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
      },
      opts = function()
        local cmp = require('cmp')
        local luasnip = require('luasnip')
        return {
          snippet = {
            expand = function(args)
              luasnip.lsp_expand(args.body)
            end,
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
        local lspconfig = require('lspconfig')
        lspconfig.rust_analyzer.setup({})
        lspconfig.lua_ls.setup({})
        lspconfig.zls.setup({})
        lspconfig.marksman.setup({})
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
