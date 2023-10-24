--[[ Options ]]

vim.scriptencoding = 'utf-8'
vim.opt.encoding = 'utf-8'
vim.opt.fileencoding = 'utf-8'

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = 'yes'

vim.opt.termguicolors = true

vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.autoindent = true
vim.opt.smartindent = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv('HOME') .. '/.vim/undodir'
vim.opt.undofile = true

vim.opt.title = true
vim.opt.scrolloff = 10
vim.opt.colorcolumn = '100'

vim.opt.inccommand = 'split'
vim.opt.backspace = 'start,eol,indent'

vim.opt.foldenable = false

vim.opt.path:append { '**' } -- Find files - search into subfolders
vim.opt.wildignore:append { '*/node_modules/*' }

--[[ Keymaps ]]

vim.g.mapleader = ' '
vim.keymap.set('n', '<leader>pv', vim.cmd.Ex)

-- do not yank
vim.keymap.set({'n', 'v'}, 'x', '"_x')
vim.keymap.set({'n', 'v'}, '<leader>d', '"_d')
vim.keymap.set('x', '<leader>p', '"_dP')

-- save position
vim.keymap.set('n', 'J', 'mzJ`z')

-- center screen
vim.keymap.set('n', '<C-d>', '<C-d>zzzv')
vim.keymap.set('n', '<C-u>', '<C-u>zzzv')
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')

-- move lines
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")

-- exit i mode
vim.keymap.set('i', '<C-c>', '<Esc>', { desc = 'Exit insert mode' })

-- replace
vim.keymap.set('n', '<leader>s', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- tabs
vim.keymap.set('n', 'te', ':tabedit<CR>', { silent = true})
vim.keymap.set('n', 'wq', '<C-w>c')

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
      'navarasu/onedark.nvim',
      lazy = false,
      priority = 1000,
      init = function ()
        vim.cmd('colorscheme onedark')
      end
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
        { '<C-p>', function() require('telescope.builtin').find_files() end, 'n', 'Find files' },
        { '<leader>ps', function() require('telescope.builtin').live_grep() end, 'n', 'Grep files' },
        { '<leader>pb', function() require('telescope.builtin').buffers() end, 'n', 'Find buffers' }
      }
    },
    {
      'nvim-treesitter/nvim-treesitter',
      dependencies = {
        'windwp/nvim-ts-autotag',
        'nvim-treesitter/nvim-treesitter-textobjects',
        { 'nvim-treesitter/nvim-treesitter-context', opts = { } },
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
              ['<leader>a'] = '@parameter.inner',
            },
            swap_previous = {
              ['<leader>A'] = '@parameter.inner',
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
        vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle)
      end,
    },
    {
      'tpope/vim-fugitive',
      cmd = 'G'
    },
    {
      'lukas-reineke/indent-blankline.nvim',
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
        { 'folke/neodev.nvim', config = true },
        { 'williamboman/mason.nvim', config = true, cmd = 'Mason' },
        'williamboman/mason-lspconfig.nvim',
        'nvim-telescope/telescope.nvim', -- see on_attach keys
        { 'hrsh7th/cmp-nvim-lsp', dependencies = { 'hrsh7th/nvim-cmp' } }
      },
      -- event = { 'BufReadPre', 'BufNewFile' },
      ft = { 'lua', 'rust' },
      config = function()
        local servers = {
          -- pyright = {},
          rust_analyzer = {},
          -- tsserver = {},
          -- html = { filetypes = { 'html', 'twig', 'hbs'} },

          lua_ls = {
            Lua = {
              workspace = { checkThirdParty = false },
              telemetry = { enable = false },
            },
          },
        }

        local on_attach = function(_, bufnr)
          local nmap = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
          end

          nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
          nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

          nmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
          nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
          nmap('gI', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
          nmap('<leader>D', vim.lsp.buf.type_definition, 'Type [D]efinition')
          nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
          nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

          -- See `:help K` for why this keymap
          nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
          nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

          -- Lesser used LSP functionality
          nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
          nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
          nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
          nmap('<leader>wl', function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
          end, '[W]orkspace [L]ist Folders')

          -- Create a command `:Format` local to the LSP buffer
          vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
            vim.lsp.buf.format()
          end, { desc = 'Format current buffer with LSP' })
        end

        local capabilities = vim.lsp.protocol.make_client_capabilities()
        capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

        local mason_lspconfig = require('mason-lspconfig')

        mason_lspconfig.setup {
          ensure_installed = vim.tbl_keys(servers),
        }

        mason_lspconfig.setup_handlers {
          function(server_name)
            require('lspconfig')[server_name].setup {
              capabilities = capabilities,
              on_attach = on_attach,
              settings = servers[server_name],
              filetypes = (servers[server_name] or {}).filetypes,
            }
          end
        }
      end
    },
  },
  {
    defaults = { lazy = true },
    ui = {
      -- text icons
      icons = {
        cmd = '[cmd]',
        config = '[cfg]',
        event = '[evt]',
        ft = '[ft]',
        init = '[ini]',
        keys = '[key]',
        plugin = '[dep]',
        runtime = '[rt]',
        source = '[src]',
        start = '[st]',
        task = '[tsk]',
        lazy = '[Zz]',
      },
    },
  }
)
