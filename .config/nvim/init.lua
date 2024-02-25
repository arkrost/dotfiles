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

vim.opt.list = true
vim.opt.listchars = { tab = '» ', leadmultispace = '┊ ', trail = '␣', nbsp = '⍽' }

vim.opt.foldlevelstart = 99
vim.opt.foldmethod = 'indent' -- or 'expr' to use treesitter

vim.opt.shortmess:append('aI')

--[[ Keymaps ]]

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- clipboard register
vim.keymap.set({ 'n', 'x' }, '<leader>\'', '<cmd>let @+=@"<CR>', { desc = '" to +' })
vim.keymap.set({ 'n', 'x' }, '<leader>"', '<cmd>let @"=@+<CR>', { desc = '+ to "' })

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
vim.keymap.set('n', 'wq', '<cmd>bdelete<cr>', { desc = 'Close window' })
vim.keymap.set('n', ',t', vim.cmd.tabnext, { desc = 'Next tab' })
vim.keymap.set('n', ',T', vim.cmd.tabprevious, { desc = 'Prev tab' })

-- diagnostics
vim.keymap.set('n', ',d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ',D', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>D', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>d', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- quickfixlist
vim.keymap.set('n', '<leader>q', vim.cmd.copen, { desc = 'Open quickfix list' })
vim.keymap.set('n', ',q', function()
  return pcall(vim.cmd.cnext) or pcall(vim.cmd.cfirst) or vim.notify('No errors')
end
, { desc = 'Next quickfix item' })
vim.keymap.set('n', ',Q', function()
  return pcall(vim.cmd.cprevious) or pcall(vim.cmd.clast) or vim.notify('No errors')
end, { desc = 'Prev quickfix item' })

-- save
vim.keymap.set('n', ',,', vim.cmd.update, { desc = 'Save' })

-- folds
vim.keymap.set('n', ',Z', function()
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

vim.keymap.set('n', ',z', function()
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

function vim.getVisualSelection()
  vim.cmd('noau normal! "vy"')
  local text = vim.fn.getreg('v')
  vim.fn.setreg('v', {})

  text = string.gsub(text, "\n", "")
  if #text > 0 then
    return text
  else
    return ''
  end
end

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
      config = function()
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
        vim.cmd('colorscheme gruvbox')
      end
    },
    {
      'nvim-lualine/lualine.nvim',
      event = 'VeryLazy',
      opts = {
        options = {
          icons_enabled = false,
          theme = 'jellybeans',
          component_separators = '|',
          section_separators = '',
        },
      },
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
      event = 'VeryLazy',
      init = function()
        vim.opt.listchars:remove('leadmultispace')
      end,
    },
    {
      'folke/which-key.nvim',
      event = 'VeryLazy',
      init = function()
        vim.opt.timeout = true
        vim.opt.timeoutlen = 300
      end,
      opts = {
        icons = {
          separator = '->',
          breadcrumb = '>>',
        }
      },
      keys = {
        { '?', '<cmd>:WhichKey<cr>', desc = 'Help keys' }
      },
    },
    {
      'nvim-telescope/telescope.nvim',
      lazy = false,
      dependencies = {
        'nvim-lua/plenary.nvim', --required
        'nvim-telescope/telescope-ui-select.nvim',
        'nvim-telescope/telescope-file-browser.nvim',
        'jonarrien/telescope-cmdline.nvim'
      },
      opts = {
        defaults = {
          path_display = {
            shorten = {
              len = 1,
              exclude = { 1, 2, 3, -1 }
            },
          },
        },
        extensions = {
          file_browser = {
            hijack_netrw = true,
            follow_symlinks = true,
          },
          cmdline = {
            mappings = {
              run_input = '<C-CR>',
              run_selection = '<CR>',
            }
          }
        }
      },
      keys = {
        { '<leader>b', function() require('telescope.builtin').buffers() end,            desc = 'Find buffers' },
        { '<leader>d', function() require('telescope.builtin').diagnostics() end,        desc = 'Open diagnostics list' },
        { '<leader>q', function() require('telescope.builtin').quickfix() end,           desc = 'Open quickfix list' },
        { ';',         function() require('telescope').extensions.cmdline.cmdline() end, desc = 'Cmdline' },
        { ';',         function() require('telescope').extensions.cmdline.visual() end,  desc = 'Cmdline',              mode = 'v' },
        { '<leader>/', function() require('telescope.builtin').live_grep() end,          desc = 'Grep files' },
        {
          '<leader>/',
          function()
            require('telescope.builtin').live_grep({ default_text = vim.getVisualSelection() })
          end,
          desc = 'Grep files',
          mode = 'v'
        },
        {
          '<leader>f',
          function()
            local is_git = vim.fn.isdirectory('.git') ~= 0
            if is_git then
              require('telescope.builtin').git_files({ show_untracked = true })
            else
              require('telescope.builtin').find_files({ hidden = true, follow = true })
            end
          end,
          desc = 'Find project files'
        },
      },
      config = function(_, opts)
        require('telescope').setup(opts)
        require('telescope').load_extension('ui-select')
        require('telescope').load_extension('file_browser')
        require('telescope').load_extension('cmdline')
      end,
    },
    {
      'numToStr/Comment.nvim',
      opts = {},
      keys = {
        { 'gc', mode = { 'n', 'v' } },
        { 'gb', mode = { 'n', 'v' } }
      }
    },
    {
      'nvim-treesitter/nvim-treesitter',
      dependencies = {
        'windwp/nvim-ts-autotag',
        'nvim-treesitter/playground',
        { 'nvim-treesitter/nvim-treesitter-context', opts = {} },
      },
      build = ':TSUpdate',
      event = 'VeryLazy',
      cmd = {
        'TSInstall',
        'TSUninstall',
        'TSUpdate',
        'TSUpdateSync',
        'TSInstallInfo',
        'TSInstallSync',
        'TSInstallFromGrammar',
      },
      main = 'nvim-treesitter.configs',
      init = function()
        vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
      end,
      opts = {
        auto_install = false,
        ensure_installed = {
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
          'lua',
          'go',
          'markdown',
          'nix',
          'proto',
          'zig',
          'diff',
          'fish',
        },
        highlight = { enable = true },
        indent = { enable = true },
        autotag = { enable = true },
      }
    },
    {
      'ThePrimeagen/harpoon',
      dependencies = {
        'nvim-lua/plenary.nvim',
      },
      event = 'BufRead',
      keys = {
        { '<leader>m', function() require('harpoon.mark').add_file() end,        desc = 'Mark file' },
        { '<leader>M', function() require('harpoon.ui').toggle_quick_menu() end, desc = 'View marks' },
        { ',m',        function() require('harpoon.ui').nav_next() end,          desc = 'Next mark' },
        { ',M',        function() require('harpoon.ui').nav_prev() end,          desc = 'Prev mark' },
      },
      opts = {},
    },
    {
      'tpope/vim-fugitive',
      cmd = {
        'G',
        'Git',
        'Gdiffsplit',
        'Gvdiffsplit',
        'Gread',
        'Gwrite',
        'Ggrep',
        'Gmove',
        'Gdelete',
        'Gbrowse',
        'Gclog'
      },
      keys = {
        { '<leader>g', '<cmd>Gedit :<cr>', desc = 'Git status' }
      }
    },
    {
      'lewis6991/gitsigns.nvim',
      event = { 'BufRead', 'BufNewFile' },
      opts = {
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation
          map({ 'n', 'v' }, ',h', function()
            vim.schedule(function()
              gs.next_hunk()
            end)
            return '<Ignore>'
          end, { expr = true, desc = 'Jump to next hunk' })

          map({ 'n', 'v' }, ',H', function()
            vim.schedule(function()
              gs.prev_hunk()
            end)
            return '<Ignore>'
          end, { expr = true, desc = 'Jump to previous hunk' })

          -- Actions
          -- visual mode
          map('v', '<leader>hs', function()
            gs.stage_hunk({ vim.fn.line '.', vim.fn.line 'v' })
          end, { desc = 'stage git hunk' })
          map('v', '<leader>hX', function()
            gs.reset_hunk({ vim.fn.line '.', vim.fn.line 'v' })
          end, { desc = 'reset git hunk' })
          -- normal mode
          map('n', '<leader>hs', gs.stage_hunk, { desc = 'git stage hunk' })
          map('n', '<leader>hX', gs.reset_hunk, { desc = 'git reset hunk' })
          map('n', '<leader>hu', gs.undo_stage_hunk, { desc = 'undo stage hunk' })
          map('n', '<leader>hp', gs.preview_hunk, { desc = 'preview git hunk' })
          map('n', '<leader>hb', function() gs.blame_line({ full = false }) end, { desc = 'git blame line' })
          map('n', '<leader>hd', gs.diffthis, { desc = 'git diff against index' })
          map('n', '<leader>hD', function() gs.diffthis('~') end, { desc = 'git diff against last commit' })
          -- Text object
          map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', { desc = 'select git hunk' })
        end,
      },
    },
    {
      'windwp/nvim-autopairs',
      opts = {},
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
            format = lspkind.cmp_format({
              mode = 'symbol',
              before = function(_, vim_item)
                vim_item.menu = ''
                return vim_item
              end
            }),
          },
          mapping = cmp.mapping.preset.insert {
            ['<C-n>'] = cmp.mapping.select_next_item(),
            ['<C-p>'] = cmp.mapping.select_prev_item(),
            ['<C-u>'] = cmp.mapping.scroll_docs(-4),
            ['<C-d>'] = cmp.mapping.scroll_docs(4),
            ['<C-c>'] = cmp.mapping.close(),
            ['<C-CR>'] = cmp.mapping.complete({}),
            ['<CR>'] = cmp.mapping.confirm {
              behavior = cmp.ConfirmBehavior.Replace,
              select = true,
            },

          },
          sources = {
            { name = 'nvim_lsp' },
            { name = 'luasnip' },
          }
        }
      end,
    },
    {
      'github/copilot.vim',
      event = 'VeryLazy',
      cmd = 'Copilot',
      config = function()
        vim.g.copilot_assume_mapped = true
        vim.g.copilot_filetypes = {
          ['*'] = false,
          ['lua'] = true,
          ['rust'] = true,
        }
      end
    },
    {
      'neovim/nvim-lspconfig',
      dependencies = {
        'nvim-telescope/telescope.nvim', -- see on_attach keys
        { 'folke/neodev.nvim',    opts = {} },
        { 'hrsh7th/cmp-nvim-lsp', dependencies = { 'hrsh7th/nvim-cmp' } },
        {
          'j-hui/fidget.nvim',
          opts = {
            notification = {
              window = { winblend = 0 },
            }
          }
        },
      },
      event = { 'BufReadPre', 'BufNewFile' },
      config = function()
        local on_attach = function(_, bufnr)
          local nmap = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
          end

          nmap('<leader>a', vim.lsp.buf.code_action, 'Code Action')

          nmap('<leader>sd', require('telescope.builtin').lsp_document_symbols, 'Document Symbols')
          nmap('<leader>sw', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Workspace Symbols')

          nmap('gd', require('telescope.builtin').lsp_definitions, 'Goto Definition')
          nmap('gr', require('telescope.builtin').lsp_references, 'Goto References')
          nmap('gt', require('telescope.builtin').lsp_type_definitions, 'Goto Type')
          nmap('gi', require('telescope.builtin').lsp_implementations, 'Goto Implementation')

          -- See `:help K` for why this keymap
          nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
          nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

          -- `:Format` command
          vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
            vim.lsp.buf.format()
          end, { desc = 'Format current buffer with LSP' })

          -- `:Rename` command
          vim.api.nvim_buf_create_user_command(bufnr, 'Rename', function(_)
            vim.lsp.buf.rename()
          end, { desc = 'Rename symbol with LSP' })
        end

        local capabilities = vim.lsp.protocol.make_client_capabilities()
        capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

        local servers = {
          rust_analyzer = {
            settings = {
              ['rust-analyzer'] = {
                checkOnSave = {
                  command = 'clippy'
                }
              }
            }
          },
          lua_ls = {
            settings = {
              Lua = {
                telemetry = { enable = false },
                diagnostics = {
                  globals = { 'vim' },
                },
              }
            }
          },
          zls = {},
          marksman = {},
        }

        for server, config in pairs(servers) do
          require('lspconfig')[server].setup({
            capabilities = capabilities,
            on_attach = on_attach,
            settings = config.settings,
            filetypes = config.filetypes,
          })
        end
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
